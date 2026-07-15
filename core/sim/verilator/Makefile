RTL_DIR     = ../../rtl/verilog
BENCH_DIR   = ../../bench/verilog
RTL_SIM_DIR = ../rtl_sim

TOPLEVEL  = tb_openMSP430
EXE_NAME  = ipe-sim

BUILD_DIR ?= build
BOOTCODE_NAME ?= bootcode.s43

EXE_FILE      = $(BUILD_DIR)/$(EXE_NAME)
BOOTCODE_ELF  = $(BUILD_DIR)/bootcode.elf
VERILATOR_HDR = $(BUILD_DIR)/V$(TOPLEVEL).mk

# Configurable memory sizes (bytes) — must match core/rtl/verilog/openMSP430_defines.v
PMEM_SIZE ?= 41984
DMEM_SIZE ?= 10240

# Fixed hardware constants
BMEM_SIZE = 1024
PER_SIZE  = 4096

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

EXTRA_IPE_FLAG=
ifdef __OMIT_IPE_FIXES
	EXTRA_IPE_FLAG+= -DOMIT_IPE_FIXES
endif
ifdef __OMIT_SP_SWITCHING
	EXTRA_IPE_FLAG+= -DOMIT_SP_SWITCHING
endif
ifdef __IPE_IRQ_SW
	EXTRA_IPE_FLAG+= -DSECURE_IRQ_SW
endif
ifdef __IPE_IRQ_FW
	EXTRA_IPE_FLAG += -DSECURE_IRQ_FW 
endif

DEPS = $(abspath main.cpp) \
       $(abspath loguru/loguru.cpp)

# Verilator 4.x: suppress known-harmless warnings from legacy Verilog
VERILATOR_WARNS = -Wno-fatal -Wno-TIMESCALEMOD -Wno-UNOPTFLAT

all: $(EXE_FILE) $(BOOTCODE_ELF)

$(EXE_FILE): $(VERILATOR_HDR) $(DEPS)
	$(MAKE) -C $(BUILD_DIR) -f V$(TOPLEVEL).mk $(EXE_NAME)

$(VERILATOR_HDR): $(BENCH_DIR)/$(TOPLEVEL).v $(RTL_DIR)/openMSP430_defines.v FORCE
	verilator --cc --exe --trace -O3 \
	    -CFLAGS "$(CFLAGS)" \
	    $(VERILATOR_WARNS) \
	    -Mdir $(BUILD_DIR) \
	    $(VERILOG_INCLUDES) \
	    $(BENCH_DIR)/$(TOPLEVEL).v \
	    $(DEPS) \
		$(EXTRA_IPE_FLAG) \
	    -o $(EXE_NAME)

# ── Bootcode ──────────────────────────────────────────────────────────────────

$(BOOTCODE_ELF): $(BUILD_DIR)
	cd $(RTL_SIM_DIR)/bin && ./build_bootcode.sh $(BOOTCODE_NAME)
	cp $(RTL_SIM_DIR)/bin/bootcode.elf $(BOOTCODE_ELF)

$(BUILD_DIR):
	mkdir -p $@

FORCE:

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean FORCE
