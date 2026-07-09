#include "Vtb_openMSP430.h"
#include <verilated.h>

#include <memory>
#include <vector>
#include <fstream>
#include <sys/stat.h>
#include <cstdint>
#include <csignal>
#include <cstdlib>
#include <cstdio>
#include <unistd.h>
#include <getopt.h>

#include "loguru/loguru.hpp"

// Configurable memory sizes (bytes) — match openMSP430_defines.v
static uint32_t pmem_size = 41984;
static uint32_t dmem_size = 10240;

// Fixed hardware constants
static const uint32_t bmem_size = 1024;
static const uint32_t per_size  = 4096;

const int    CLOCK_FREQUENCY = 20 * 1000000;
const double TIMESCALE       = 1e-9;
const int    CLOCK_PERIOD    = (int)(1.0 / (CLOCK_FREQUENCY * TIMESCALE));

static uint64_t   MAX_CYCLES = 100000000ULL;
static uint64_t mainTime;

enum exit_codes { status_success, status_error, status_timeout, status_no_input };

// ─── Minimal instruction trace ────────────────────────────────────────────────
//
// A full Verilator VCD of this design dumps the entire signal hierarchy every
// cycle, producing multi-GB files. For extracting instruction lengths we only
// need a handful of taps (see tb_openMSP430.v): the decoded PC, an
// instruction-boundary pulse, and whether the core is executing inside the IPE.
// This writer emits a tiny VCD holding just those signals, sampled once per
// CPU cycle. The VCD time axis is the cycle counter itself, so the length of an
// instruction (in cycles) is simply the gap between successive `decode` pulses.
class TraceVcd {
public:
    bool open(const char* path)
    {
        _f = std::fopen(path, "w");
        if (!_f) return false;
        std::fprintf(_f,
            "$comment\n"
            "  openIPE minimal instruction trace.\n"
            "  One VCD time unit = one CPU clock cycle.\n"
            "  Instruction length (cycles) = gap between successive 'decode' pulses.\n"
            "  'ipe_executing' marks instructions running inside the IPE.\n"
            "$end\n"
            "$timescale 1 ns $end\n"
            "$scope module tb_openMSP430 $end\n"
            "$var wire 16 p pc [15:0] $end\n"
            "$var wire  1 d decode $end\n"
            "$var wire  1 e exec_done $end\n"
            "$var wire  1 i ipe_executing $end\n"
            "$upscope $end\n"
            "$enddefinitions $end\n");
        return true;
    }

    void sample(uint64_t cycle, uint16_t pc, bool decode, bool exec_done, bool ipe)
    {
        bool first = !_have_prev;
        if (!first && pc == _pc && decode == _decode &&
            exec_done == _exec_done && ipe == _ipe)
            return;  // nothing changed → keep the VCD sparse

        std::fprintf(_f, "#%llu\n", (unsigned long long)cycle);
        if (first || pc  != _pc)        emit_vec(pc, 'p');
        if (first || decode != _decode) std::fprintf(_f, "%dd\n", decode);
        if (first || exec_done != _exec_done) std::fprintf(_f, "%de\n", exec_done);
        if (first || ipe != _ipe)       std::fprintf(_f, "%di\n", ipe);

        _pc = pc; _decode = decode; _exec_done = exec_done; _ipe = ipe;
        _have_prev = true;
    }

    void close()
    {
        if (_f) { std::fclose(_f); _f = nullptr; }
    }

private:
    void emit_vec(uint16_t v, char id)
    {
        char bits[17];
        for (int i = 0; i < 16; i++)
            bits[i] = (v & (0x8000u >> i)) ? '1' : '0';
        bits[16] = '\0';
        const char* p = bits;
        while (p[1] && *p == '0') p++;  // trim leading zeros, keep ≥1 digit
        std::fprintf(_f, "b%s %c\n", p, id);
    }

    std::FILE* _f = nullptr;
    bool       _have_prev = false;
    uint16_t   _pc = 0;
    bool       _decode = false, _exec_done = false, _ipe = false;
};

static bool     tracer_enabled = false;
static TraceVcd tracer_g;

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

static std::unique_ptr<Vtb_openMSP430> top_g;
static void sig_handler(int)
{
    top_g.reset();
    tracer_g.close();
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
        "  --firmware FILE    IPE bootcode ELF loaded into bmem (required)\n"
        "  -d, --dump FILE    Write a minimal instruction-length VCD to FILE\n"
        "                     (pc, decode, exec_done, ipe_executing; time unit = cycle)\n"
        "  --dump-start N     Start VCD dump at cycle N (default 0)\n"
        "  -c, --cycles N     Cycle timeout; 0 = unlimited (default 100M)\n"
        "  --pmem-size N      Program memory size in bytes (default 41984)\n"
        "                     valid: 1K 2K 4K 8K 12K 16K 24K 32K 41K 48K 51K 54K 55K\n"
        "  --dmem-size N      Data memory size in bytes (default 10240)\n"
        "                     valid: 128 256 512 1K 2K 4K 5K 8K 10K 16K 24K 32K\n"
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
        case 'v': verbosity++; break;
        case 'h': print_usage(argv[0]); return 0;
        default:  print_usage(argv[0]); return status_error;
        }
    }

    if (fw_path.empty()) {
        fprintf(stderr, "error: --firmware is required\n");
        print_usage(argv[0]);
        return status_error;
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

    // ── Load firmware ELF (bmem) ──────────────────────────────────────
    CHECK_F(file_exists(fw_path.c_str()), "Firmware not found: %s", fw_path.c_str());
    std::string fw_ihex = objcopy_to_ihex(fw_path);
    auto fw_recs = parseIHex(fw_ihex);
    unlink(fw_ihex.c_str());
    recs.insert(recs.end(), fw_recs.begin(), fw_recs.end());

    LOG_F(INFO, "Memory map: PMEM [0x%04x-0x%04x]  DMEM [0x%04x-0x%04x]  BMEM [0x%04x-0x%04x]",
        PMEM_BASE, 0xFFFFu,
        DMEM_BASE, DMEM_BASE + dmem_size - 1,
        BMEM_BASE, BMEM_BASE + bmem_size - 1);

    // ── Verilator init ────────────────────────────────────────────────
    Verilated::commandArgs(argc, argv);
    top_g = std::unique_ptr<Vtb_openMSP430>{new Vtb_openMSP430};
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
    if (tracer_enabled)
        CHECK_F(tracer_g.open(vcd_path.c_str()), "Cannot open VCD file: %s", vcd_path.c_str());

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

            if (tracer_enabled && cycle >= dump_start)
                tracer_g.sample(cycle, top.trace_pc, top.trace_decode,
                                top.trace_exec_done, top.trace_ipe_executing);
        }

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

    top_g.reset();
    tracer_g.close();
    return result;
}
