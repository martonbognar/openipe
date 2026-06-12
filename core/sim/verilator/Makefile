RTL_DIR     = ../../rtl/verilog
BENCH_DIR   = ../../bench/verilog
RTL_SIM_DIR = ../rtl_sim

TOPLEVEL  = sim_top
EXE_NAME  = ipe-sim

ifndef BUILD_DIR
  BUILD_DIR = build
endif

EXE_FILE      = $(BUILD_DIR)/$(EXE_NAME)
BOOTCODE_ELF  = $(BUILD_DIR)/bootcode.elf
VERILATOR_HDR = $(BUILD_DIR)/V$(TOPLEVEL).mk

# Memory sizes in bytes — must match core/rtl/verilog/openMSP430_defines.v
PMEM_SIZE ?= 41984
DMEM_SIZE ?= 10240
BMEM_SIZE ?= 1024
PER_SIZE  ?= 4096

# Derived addresses (decimal, for shell arithmetic)
PMEM_BASE            = $(shell python3 -c "print(0x10000 - $(PMEM_SIZE))")
BMEM_BASE            = $(shell python3 -c "print($(PER_SIZE) + $(DMEM_SIZE))")
BMEM_IVT_BASE        = $(shell python3 -c "print($(PER_SIZE) + $(DMEM_SIZE) + $(BMEM_SIZE) - 0x24)")
BMEM_TRAMPOLINE_BASE = $(shell python3 -c "print($(PER_SIZE) + $(DMEM_SIZE) + $(BMEM_SIZE) - 4)")

CFLAGS = -O3 -std=c++14 -DLOGURU_STACKTRACES=0

VERILOG_INCLUDES = \
    -I$(RTL_DIR) \
    -I$(RTL_DIR)/periph \
    -I$(BENCH_DIR)

DEPS = $(shell pwd)/main.cpp \
       $(shell pwd)/loguru/loguru.cpp

# Verilator 4.x: suppress known-harmless warnings from legacy Verilog
VERILATOR_WARNS = -Wno-fatal -Wno-TIMESCALEMOD -Wno-UNOPTFLAT

all: $(EXE_FILE) $(BOOTCODE_ELF)

$(EXE_FILE): $(VERILATOR_HDR) $(DEPS)
	$(MAKE) -C $(BUILD_DIR) -f V$(TOPLEVEL).mk $(EXE_NAME)

$(VERILATOR_HDR): $(TOPLEVEL).v $(RTL_DIR)/openMSP430_defines.v FORCE
	verilator --cc --exe --trace -O3 \
	    -CFLAGS "$(CFLAGS)" \
	    $(VERILATOR_WARNS) \
	    -Mdir $(BUILD_DIR) \
	    $(VERILOG_INCLUDES) \
	    $(TOPLEVEL).v \
	    $(DEPS) \
	    -o $(EXE_NAME)

# ── Bootcode ──────────────────────────────────────────────────────────────────

# pmem_defs.asm — symbols used by bootcode.s43: PMEM_BASE (size-dependent)
# plus fixed hardware IPE register addresses (from template_defs.asm)
$(BUILD_DIR)/pmem_defs.asm: | $(BUILD_DIR)
	printf '.set PMEM_BASE, %d\n.set MPUIPC0, 0x05AA\n.set MPUIPSEGB2, 0x05AC\n.set MPUIPSEGB1, 0x05AE\n' \
	    $(PMEM_BASE) > $@

# Linker script from template via Python string.Template
$(BUILD_DIR)/bootcode.x: $(RTL_SIM_DIR)/bin/ipe_linker.x | $(BUILD_DIR)
	python3 -c "\
import string; \
t = string.Template(open('$<').read()); \
open('$@','w').write(t.safe_substitute( \
    per_size=$(PER_SIZE), \
    dmem_size=$(DMEM_SIZE), \
    pmem_base=$(PMEM_BASE), \
    pmem_size=$(PMEM_SIZE), \
    bmem_base=$(BMEM_BASE), \
    bmem_total_size=$(BMEM_SIZE), \
    bmem_ivt_base=$(BMEM_IVT_BASE), \
    bmem_trampoline_base=$(BMEM_TRAMPOLINE_BASE)))"

$(BOOTCODE_ELF): $(BUILD_DIR)/pmem_defs.asm $(BUILD_DIR)/bootcode.x
	cd $(BUILD_DIR) && msp430-elf-as -alsm \
	    $(abspath $(RTL_SIM_DIR)/src/ipe/bootcode.s43) \
	    -o bootcode.o > bootcode.l43
	msp430-elf-ld -T $(BUILD_DIR)/bootcode.x $(BUILD_DIR)/bootcode.o -o $@

$(BUILD_DIR):
	mkdir -p $@

FORCE:

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean FORCE
