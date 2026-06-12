RTL_DIR  = ../../rtl/verilog
BENCH_DIR = ../../bench/verilog

TOPLEVEL  = sim_top
EXE_NAME  = ipe-sim

ifndef BUILD_DIR
  BUILD_DIR = build
endif

EXE_FILE  = $(BUILD_DIR)/$(EXE_NAME)
VERILATOR_HDR = $(BUILD_DIR)/V$(TOPLEVEL).mk

# Memory sizes in bytes — must match core/rtl/verilog/openMSP430_defines.v
PMEM_SIZE ?= 41984
DMEM_SIZE ?= 10240
BMEM_SIZE ?= 1024
PER_SIZE  ?= 4096

CFLAGS = -O3 -std=c++14 -DLOGURU_STACKTRACES=0 \
         -DPMEM_SIZE=$(PMEM_SIZE) -DDMEM_SIZE=$(DMEM_SIZE) \
         -DBMEM_SIZE=$(BMEM_SIZE) -DPER_SIZE=$(PER_SIZE)

VERILOG_INCLUDES = \
    -I$(RTL_DIR) \
    -I$(RTL_DIR)/periph \
    -I$(BENCH_DIR)

DEPS = $(shell pwd)/main.cpp \
       $(shell pwd)/loguru/loguru.cpp

# Verilator 4.x: suppress known-harmless warnings from legacy Verilog
VERILATOR_WARNS = -Wno-fatal -Wno-TIMESCALEMOD -Wno-UNOPTFLAT

# Ubuntu 22.04+ ships Verilator that requires -Wno-TIMESCALEMOD
UBUNTU_VERSION = $(shell lsb_release -rs 2>/dev/null)
ifeq ($(UBUNTU_VERSION),22.04)
  VERILATOR_WARNS += -Wno-TIMESCALEMOD
endif

all: $(EXE_FILE)

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

FORCE:

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean FORCE
