#include "Vsim_top.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

#include <memory>
#include <vector>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <sys/stat.h>
#include <cstdint>
#include <cassert>
#include <signal.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <getopt.h>

#include "loguru/loguru.hpp"

using namespace std;

// Default memory sizes (bytes) — match openMSP430_defines.v; overridable at runtime
static uint32_t pmem_size = 41984;
static uint32_t dmem_size = 10240;
static uint32_t bmem_size = 1024;
static uint32_t per_size  = 4096;

const int    CLOCK_FREQUENCY = 20 * 1000000;
const double TIMESCALE       = 1e-9;
const int    CLOCK_PERIOD    = (int)(1.0 / (CLOCK_FREQUENCY * TIMESCALE));

static uint64_t   MAX_CYCLES = 100000000ULL;
static vluint64_t mainTime;

enum exit_codes { status_success, status_error, status_timeout, status_no_input };

static bool tracer_enabled = false;
static VerilatedVcdC* tracer_g = nullptr;

// ─── IHEX parser ────────────────────────────────────────────────────────────

struct IHexRecord {
    uint32_t            address;
    std::vector<uint8_t> data;
};

static uint8_t hex2byte(const std::string& s, size_t pos)
{
    return (uint8_t)std::stoul(s.substr(pos, 2), nullptr, 16);
}

static std::vector<IHexRecord> parseIHex(const std::string& path)
{
    std::vector<IHexRecord> out;
    std::ifstream f(path);
    CHECK_F(f.is_open(), "Cannot open IHEX file: %s", path.c_str());

    std::string line;
    uint32_t upper = 0;
    while (std::getline(f, line)) {
        if (line.empty() || line[0] != ':') continue;
        uint8_t  len  = hex2byte(line, 1);
        uint16_t addr = ((uint16_t)hex2byte(line, 3) << 8) | hex2byte(line, 5);
        uint8_t  type = hex2byte(line, 7);

        if (type == 0x01) break;   // EOF record
        if (type == 0x04) {        // extended linear address
            upper = ((uint32_t)hex2byte(line,  9) << 24)
                  | ((uint32_t)hex2byte(line, 11) << 16);
            continue;
        }
        if (type != 0x00) continue;

        IHexRecord rec;
        rec.address = upper | (uint32_t)addr;
        for (int i = 0; i < len; i++)
            rec.data.push_back(hex2byte(line, 9 + i * 2));
        out.push_back(std::move(rec));
    }
    return out;
}

// ─── Memory ─────────────────────────────────────────────────────────────────

class Memory {
    using Word = uint16_t;
public:
    Memory(const char* name, CData* cen, CData* wen, SData* addr, SData* din, SData* dout)
        : _name(name), _cen(cen), _wen(wen), _addr(addr), _din(din), _dout(dout) {}

    void load(const std::vector<IHexRecord>& recs, uint32_t base, uint32_t size)
    {
        _mem.assign(size / 2, 0x0000);
        for (auto& rec : recs) {
            for (size_t i = 0; i < rec.data.size(); i++) {
                uint32_t baddr = rec.address + i;
                if (baddr < base || baddr >= base + size) continue;
                uint32_t off  = baddr - base;
                uint32_t word = off / 2;
                if (off & 1) _mem[word] = (_mem[word] & 0x00FFu) | ((Word)rec.data[i] << 8);
                else         _mem[word] = (_mem[word] & 0xFF00u) | rec.data[i];
            }
        }
        LOG_F(INFO, "%s loaded %zu words from ELF", _name, _mem.size());
    }

    void eval(bool rising)
    {
        if (!*_cen && *_wen != 0b11 && rising)
            write(*_addr, *_wen, *_din);
        if (rising) *_dout = read(_prev_addr);
        if (!*_cen)  _prev_addr = *_addr;
    }

private:
    Word read(uint32_t addr)
    {
        if (addr >= _mem.size()) return 0;
        return _mem[addr];
    }

    void write(uint32_t addr, uint8_t mask, Word val)
    {
        if (addr >= _mem.size()) _mem.resize(addr + 1, 0);
        Word m = 0;
        switch (mask) {
        case 0b00: m = 0xFFFFu; break;
        case 0b01: m = 0xFF00u; break;
        case 0b10: m = 0x00FFu; break;
        }
        _mem[addr] = (_mem[addr] & ~m) | (val & m);
    }

    const char*       _name;
    CData*            _cen;
    CData*            _wen;
    SData*            _addr;
    SData*            _din;
    SData*            _dout;
    uint32_t          _prev_addr = 0;
    std::vector<Word> _mem;
};

// ─── Helpers ─────────────────────────────────────────────────────────────────

static bool file_exists(const char* p) { struct stat s; return stat(p, &s) == 0; }

static std::string objcopy_to_ihex(const std::string& elf)
{
    char tmp[] = "/tmp/ipe_sim_XXXXXX";
    int fd = mkstemp(tmp);
    CHECK_F(fd >= 0, "mkstemp failed");
    close(fd);
    std::string ihex = std::string(tmp) + ".ihex";
    std::string cmd  = "msp430-elf-objcopy -O ihex " + elf + " " + ihex;
    LOG_F(INFO, ">> %s", cmd.c_str());
    CHECK_F(system(cmd.c_str()) == 0, "objcopy failed for %s", elf.c_str());
    unlink(tmp);
    return ihex;
}

static std::unique_ptr<Vsim_top> top_g;
static void sig_handler(int)
{
    top_g.reset();
    if (tracer_g) { tracer_g->close(); delete tracer_g; tracer_g = nullptr; }
    exit(status_error);
}

static void print_usage(const char* prog)
{
    fprintf(stderr,
        "Usage: %s [OPTIONS] PROGRAM.elf\n"
        "\n"
        "Run an MSP430 ELF on the openIPE Verilator simulation.\n"
        "\n"
        "Options:\n"
        "  --firmware FILE    IPE bootcode ELF loaded into bmem\n"
        "  -d, --dump FILE    Write VCD waveform to FILE\n"
        "  --dump-start N     Start VCD dump at cycle N (default 0)\n"
        "  -c, --cycles N     Cycle timeout; 0 = unlimited (default 100M)\n"
        "  --pmem-size N      Program memory size in bytes (default 41984)\n"
        "  --dmem-size N      Data memory size in bytes (default 10240)\n"
        "  --bmem-size N      Bootcode memory size in bytes (default 1024)\n"
        "  --per-size N       Peripheral address space size in bytes (default 4096)\n"
        "  -v, --verbose      Increase log verbosity (repeat for more detail)\n"
        "  -h, --help         Show this help\n",
        prog);
}

// ─── main ────────────────────────────────────────────────────────────────────

int main(int argc, char** argv)
{
    // ── Option parsing ────────────────────────────────────────────────
    static const struct option long_opts[] = {
        {"firmware",   required_argument, nullptr, 'f'},
        {"dump",       required_argument, nullptr, 'd'},
        {"dump-start", required_argument, nullptr, 's'},
        {"cycles",     required_argument, nullptr, 'c'},
        {"pmem-size",  required_argument, nullptr, 'P'},
        {"dmem-size",  required_argument, nullptr, 'D'},
        {"bmem-size",  required_argument, nullptr, 'B'},
        {"per-size",   required_argument, nullptr, 'E'},
        {"verbose",    no_argument,       nullptr, 'v'},
        {"help",       no_argument,       nullptr, 'h'},
        {nullptr, 0, nullptr, 0}
    };

    std::string fw_path, vcd_path;
    uint64_t dump_start = 0;
    int verbosity = 0;

    int opt;
    while ((opt = getopt_long(argc, argv, "d:c:f:s:vh", long_opts, nullptr)) != -1) {
        switch (opt) {
        case 'f': fw_path    = optarg; break;
        case 'd': vcd_path   = optarg; break;
        case 's': dump_start = (uint64_t)std::stoull(optarg); break;
        case 'c': MAX_CYCLES = (uint64_t)std::stoull(optarg); break;
        case 'P': pmem_size  = (uint32_t)std::stoul(optarg, nullptr, 0); break;
        case 'D': dmem_size  = (uint32_t)std::stoul(optarg, nullptr, 0); break;
        case 'B': bmem_size  = (uint32_t)std::stoul(optarg, nullptr, 0); break;
        case 'E': per_size   = (uint32_t)std::stoul(optarg, nullptr, 0); break;
        case 'v': verbosity++; break;
        case 'h': print_usage(argv[0]); return 0;
        default:  print_usage(argv[0]); return status_error;
        }
    }

    const uint32_t PMEM_BASE = 0x10000u - pmem_size;
    const uint32_t DMEM_BASE = per_size;
    const uint32_t BMEM_BASE = per_size + dmem_size;

    // Configure loguru without touching argv (avoids -v flag conflicts)
    loguru::g_preamble_thread = false;
    loguru::g_preamble_date   = false;
    loguru::g_preamble_uptime = false;
    loguru::g_preamble_time   = false;
    loguru::g_preamble_file   = false;
    loguru::g_stderr_verbosity = (verbosity == 0) ? loguru::Verbosity_INFO
                               : (verbosity == 1) ? 1
                               : loguru::Verbosity_MAX;

    if (optind >= argc || !file_exists(argv[optind])) {
        print_usage(argv[0]);
        return status_no_input;
    }
    std::string prog_elf = argv[optind];

    // ── Load program ELF ──────────────────────────────────────────────
    std::string prog_ihex = objcopy_to_ihex(prog_elf);
    auto recs = parseIHex(prog_ihex);
    unlink(prog_ihex.c_str());

    // ── Load firmware ELF (bmem) if given ────────────────────────────
    if (!fw_path.empty()) {
        CHECK_F(file_exists(fw_path.c_str()), "Firmware not found: %s", fw_path.c_str());
        std::string fw_ihex = objcopy_to_ihex(fw_path);
        auto fw_recs = parseIHex(fw_ihex);
        unlink(fw_ihex.c_str());
        recs.insert(recs.end(), fw_recs.begin(), fw_recs.end());
    }

    LOG_F(INFO, "Memory map: PMEM [0x%04x-0x%04x]  DMEM [0x%04x-0x%04x]  BMEM [0x%04x-0x%04x]",
        PMEM_BASE, 0xFFFFu,
        DMEM_BASE, DMEM_BASE + dmem_size - 1,
        BMEM_BASE, BMEM_BASE + bmem_size - 1);

    // ── Verilator init ────────────────────────────────────────────────
    Verilated::commandArgs(argc, argv);
    top_g = std::unique_ptr<Vsim_top>{new Vsim_top};
    auto& top = *top_g;

    top.reset_n   = 1;
    top.dco_clk   = 1;
    top.pmem_dout = 0;
    top.bmem_dout = 0;
    top.dmem_dout = 0;

    Memory pmem("[PMEM]", &top.pmem_cen, (CData*)&top.pmem_wen, &top.pmem_addr, &top.pmem_din, &top.pmem_dout);
    Memory bmem("[BMEM]", &top.bmem_cen, (CData*)&top.bmem_wen, &top.bmem_addr, &top.bmem_din, &top.bmem_dout);
    Memory dmem("[DMEM]", &top.dmem_cen, (CData*)&top.dmem_wen, &top.dmem_addr, &top.dmem_din, &top.dmem_dout);

    pmem.load(recs, PMEM_BASE, pmem_size);
    bmem.load(recs, BMEM_BASE, bmem_size);
    dmem.load(recs, DMEM_BASE, dmem_size);

    tracer_enabled = !vcd_path.empty();
    if (tracer_enabled) {
        Verilated::traceEverOn(true);
        tracer_g = new VerilatedVcdC;
        top.trace(tracer_g, 99);
        tracer_g->open(vcd_path.c_str());
    }

    struct sigaction sa{};
    sa.sa_handler = sig_handler;
    sigemptyset(&sa.sa_mask);
    sigaction(SIGINT, &sa, nullptr);

    // ── Simulation loop ───────────────────────────────────────────────
    mainTime        = 0;
    bool done       = false;
    int  result     = status_success;
    int  cpuoff_drain = 10;

    while (!done) {
        bool clk_edge = (mainTime % (CLOCK_PERIOD / 2) == 0);
        if (clk_edge) top.dco_clk = !top.dco_clk;

        if (mainTime >=  5 * CLOCK_PERIOD) top.reset_n = 0;
        if (mainTime >= 50 * CLOCK_PERIOD) top.reset_n = 1;

        // Double-eval: core and memory run in parallel in real hardware
        top.eval();
        bool rising = clk_edge && top.dco_clk;
        pmem.eval(rising);
        bmem.eval(rising);
        dmem.eval(rising);
        top.eval();

        if (rising) {
            uint64_t cycle = mainTime / CLOCK_PERIOD;
            if (MAX_CYCLES && cycle >= MAX_CYCLES) {
                LOG_F(WARNING, "Timeout after %llu cycles.", (unsigned long long)MAX_CYCLES);
                done   = true;
                result = status_timeout;
            }
            if (top.cpuoff && --cpuoff_drain <= 0)
                done = true;
        }

        if (tracer_enabled && mainTime / CLOCK_PERIOD >= dump_start)
            tracer_g->dump(mainTime);

        mainTime++;
    }

    uint64_t done_cycles = mainTime / CLOCK_PERIOD;
    LOG_F(INFO, "Simulation done: %llu cycles.", (unsigned long long)done_cycles);

    if (result == status_success)
        printf("PASS: cpuoff after %llu cycles\n", (unsigned long long)done_cycles);
    else
        printf("FAIL: %s after %llu cycles\n",
               result == status_timeout ? "timeout" : "aborted",
               (unsigned long long)done_cycles);

    // Destroy model before tracer so Verilator can finalize any pending trace data
    top_g.reset();
    if (tracer_g) { tracer_g->close(); delete tracer_g; tracer_g = nullptr; }
    return result;
}
