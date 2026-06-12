`ifdef OMSP_NO_INCLUDE
`else
`include "openMSP430_defines.v"
`endif

// Thin Verilator top-level for ipe-sim.
// Exposes pmem/bmem/dmem as ports so the C++ harness manages all three
// memories externally. Ties off debug, DMA, and scan inputs which are
// unused during software simulation.
module sim_top (
    input  wire                   dco_clk,
    input  wire                   reset_n,

    // Program memory (C++ managed)
    output wire [`PMEM_MSB:0]     pmem_addr,
    output wire                   pmem_cen,
    output wire             [1:0] pmem_wen,
    output wire            [15:0] pmem_din,
    input  wire            [15:0] pmem_dout,

    // Bootcode memory (C++ managed)
    output wire [`BMEM_MSB:0]     bmem_addr,
    output wire                   bmem_cen,
    output wire             [1:0] bmem_wen,
    output wire            [15:0] bmem_din,
    input  wire            [15:0] bmem_dout,

    // Data memory (C++ managed)
    output wire [`DMEM_MSB:0]     dmem_addr,
    output wire                   dmem_cen,
    output wire             [1:0] dmem_wen,
    output wire            [15:0] dmem_din,
    input  wire            [15:0] dmem_dout,

    output wire                   cpuoff
);

/* verilator lint_off PINMISSING */
openMSP430 dut (
    .dco_clk          (dco_clk),
    .reset_n          (reset_n),

    .pmem_addr        (pmem_addr),
    .pmem_cen         (pmem_cen),
    .pmem_wen         (pmem_wen),
    .pmem_din         (pmem_din),
    .pmem_dout        (pmem_dout),

    .bmem_addr        (bmem_addr),
    .bmem_cen         (bmem_cen),
    .bmem_wen         (bmem_wen),
    .bmem_din         (bmem_din),
    .bmem_dout        (bmem_dout),

    .dmem_addr        (dmem_addr),
    .dmem_cen         (dmem_cen),
    .dmem_wen         (dmem_wen),
    .dmem_din         (dmem_din),
    .dmem_dout        (dmem_dout),

    .cpuoff           (cpuoff),

    // No external peripherals in simulation
    .per_dout         (16'h0000),

    // CPU always enabled, debug interface disabled
    .cpu_en           (1'b1),
    .dbg_en           (1'b0),
    .dbg_i2c_addr     (7'h00),
    .dbg_i2c_broadcast(7'h00),
    .dbg_i2c_scl      (1'b1),
    .dbg_i2c_sda_in   (1'b1),
    .dbg_uart_rxd     (1'b1),

    // No low-frequency oscillator needed
    .lfxt_clk         (1'b0),

    // DMA disabled
    .dma_addr         (15'h0000),
    .dma_din          (16'h0000),
    .dma_en           (1'b0),
    .dma_priority     (1'b0),
    .dma_we           (2'h0),
    .dma_wkup         (1'b0),

    // No interrupts or wake-up sources
    .nmi              (1'b0),
    .irq              ({`IRQ_NR-2{1'b0}}),
    .wkup             (1'b0),

    // Scan disabled
    .scan_enable      (1'b0),
    .scan_mode        (1'b0)
);
/* verilator lint_on PINMISSING */

endmodule
