#!/usr/bin/env python3

from pyosys import libyosys as ys
import argparse

def run_analysis(report_timing: bool, design_file: str, top_module: str, timing_target: int, cell_library: str, ipe_number: int, ipe_gran: bool, ipe_pc: bool) -> None:
    design = ys.Design()

    config = ""
    # read design
    if ipe_gran:
       config += "-D IPE_GRAN "
    if ipe_pc:
       config += "-D IPE_PC "
    if ipe_number == 1:
       config += "-D IPE_1REGIONS "
    elif ipe_number == 2:
       config += "-D IPE_2REGIONS "
    elif ipe_number == 3:
       config += "-D IPE_3REGIONS "
    else: 
       config += "-D IPE_4REGIONS "

    #ys.run_pass(f"read_verilog -D IPE_1REGIONS -I master-thesis-alexander-croes/core/rtl/verilog/periph master-thesis-alexander-croes/core/rtl/verilog/periph/ipe_periph_select.v master-thesis-alexander-croes/core/rtl/verilog/*.v ", design)
    ys.run_pass(f"read_verilog {config} -I master-thesis-alexander-croes/core/rtl/verilog/periph master-thesis-alexander-croes/core/rtl/verilog/periph/ipe_periph_select.v master-thesis-alexander-croes/core/rtl/verilog/*.v ", design)
    #ys.run_pass(f"read_verilog -D IPE_1REGIONS -D IPE_PC -I master-thesis-alexander-croes/core/rtl/verilog/periph master-thesis-alexander-croes/core/rtl/verilog/periph/ipe_periph_select.v master-thesis-alexander-croes/core/rtl/verilog/*.v ", design)
    #ys.run_pass(f"read_verilog -D IPE_1REGIONS -D IPE_GRAN -D IPE_PC -I master-thesis-alexander-croes/core/rtl/verilog/periph master-thesis-alexander-croes/core/rtl/verilog/periph/ipe_periph_select.v master-thesis-alexander-croes/core/rtl/verilog/*.v ", design)
    #ys.run_pass(f"read_verilog -D IPE_4REGIONS -D IPE_GRAN -D IPE_PC -I master-thesis-alexander-croes/core/rtl/verilog/periph master-thesis-alexander-croes/core/rtl/verilog/periph/ipe_periph_select.v master-thesis-alexander-croes/core/rtl/verilog/*.v ", design)
    #ys.run_pass(f"read_verilog -D IPE_4REGIONS -D IPE_GRAN -I master-thesis-alexander-croes/core/rtl/verilog/periph master-thesis-alexander-croes/core/rtl/verilog/periph/ipe_periph_select.v master-thesis-alexander-croes/core/rtl/verilog/*.v ", design)
    #ys.run_pass(f"read_verilog openipe/core/rtl/verilog/periph/*.v openipe/core/rtl/verilog/*.v", design)
    #ys.run_pass(f"read_verilog -I sancus-core/core/rtl/verilog -I sancus-core/core/rtl/verilog/crypto -I sancus-core/core/rtl/verilog/periph sancus-core/core/rtl/verilog/crypto/*.v sancus-core/core/rtl/verilog/periph/*.v sancus-core/core/rtl/verilog/*.v", design)
    #ys.run_pass(f"read_verilog soteria-core/core/rtl/verilog/periph/*.v soteria-core/core/rtl/verilog/spongent/*.v soteria-core/core/rtl/verilog/*.v", design)  
    #ys.run_pass(f"read_verilog -I ASAP/openmsp430/msp_core/ -I ASAP/openmsp430/msp_memory/ -I ASAP/openmsp430/msp_periph/ -I ASAP/scripts/build-verif/ ASAP/scripts/build-verif/hwmod.v ASAP/openmsp430/msp_periph/*.v ASAP/openmsp430/msp_memory/*.v ASAP/openmsp430/msp_core/*.v ASAP/openmsp430/fpga/*.v", design)
    #ys.run_pass(f"read_verilog -I garota/openmsp430/msp_core/ -I garota/openmsp430/msp_memory/ -I garota/openmsp430/msp_periph/ -I garota/garota/hw-mod garota/garota/hw-mod/garota.v garota/openmsp430/msp_periph/*.v garota/openmsp430/msp_memory/*.v garota/openmsp430/msp_core/*.v garota/openmsp430/fpga/*.v", design)
    #ys.run_pass(f"read_verilog -I UCCA/openmsp430/msp_core/ -I UCCA/openmsp430/msp_memory/ -I UCCA/openmsp430/msp_periph/ -I UCCA/ucca/hw-mod UCCA/ucca/hw-mod/hwmod.v UCCA/ucca/hw-mod/return_address_tracker.v UCCA/openmsp430/msp_periph/*.v UCCA/openmsp430/msp_memory/*.v UCCA/openmsp430/msp_core/*.v UCCA/openmsp430/fpga/*.v", design)
    #ys.run_pass(f"read_verilog -I vrased/vrased/hw-mod/ -I vrased/openmsp430/msp_core/ -I vrased/openmsp430/msp_memory/ -I vrased/openmsp430/msp_periph/ vrased/vrased/hw-mod/vrased.v vrased/openmsp430/msp_core/*.v vrased/openmsp430/msp_memory/*.v vrased/openmsp430/msp_periph/*.v", design)

    # elaborate design hierarchy
    ys.run_pass(f"hierarchy -check -top {top_module}", design)

    if report_timing:
        # flatten the design
        ys.run_pass("flatten", design)

    # the high-level stuff
    ys.run_pass("proc; opt; fsm; opt; memory; opt", design)

    # mapping to internal cell library
    ys.run_pass("techmap; opt", design)

    # mapping flip-flops to cell library
    ys.run_pass(f"dfflibmap -liberty {cell_library}", design)

    if report_timing:
        # mapping logic to cell library with timing constraint
        ys.run_pass(f"abc -liberty {cell_library} -fast -D {timing_target}", design)
    else:
        # mapping logic to cell library
        ys.run_pass(f"abc -liberty {cell_library}", design)

    # cleanup
    ys.run_pass("clean", design)

    # write synthesized design
    ys.run_pass("write_verilog result.v", design)

    # get ASIC gate count and area numbers
    ys.run_pass(f"stat -liberty {cell_library}", design)

def main() -> None:
    parser = argparse.ArgumentParser(description="Synthesize a design for ASIC using Yosys.")
    parser.add_argument("design_file", type=str, help="Path to the Verilog design file.")
    parser.add_argument("--top-module", type=str, default="Core", help="Name of the top module (default: Core).")
    parser.add_argument("--cell-library", default="freepdk-45nm/stdcells.lib", help="Path to the cell library (default: FreePDK).")
    parser.add_argument("--report-timing", action="store_true", help="Enable timing analysis during synthesis.")
    parser.add_argument("--timing-target", type=int, default=2500, help="Target timing constraint (in picoseconds, default: 2500).")
    parser.add_argument("--ipe-number", type=int, default=4, help="Number of enclaves supported by hardware.")
    parser.add_argument("--ipe-gran", type=int, default=0, help="Hardware support for finer granularity of IPE boundaries.")
    parser.add_argument("--ipe-pc", type=int, default=0, help="Hardware support for parent-child relationships.")
    args = parser.parse_args()

    run_analysis(args.report_timing, args.design_file, args.top_module, args.timing_target, args.cell_library, args.ipe_number, args.ipe_gran, args.ipe_pc)

if __name__ == "__main__":
    main()
