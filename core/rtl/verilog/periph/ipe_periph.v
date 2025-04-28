`ifdef OMSP_NO_INCLUDE
`else
`include "../openMSP430_defines.v"
`endif

module  ipe_periph (
  // peripheral INPUTs
  //=========
  input               mclk,  // Main system clock
  input        [13:0] per_addr,  // Peripheral address
  input        [15:0] per_din,  // Peripheral data input
  input               per_en,  // Peripheral enable (high active)
  input         [1:0] per_we,  // Peripheral write enable (high active)
  input               puc_rst,  // Main system reset

  // control INPUTs
  //=========
  input        [15:0] eu_mab,
  input        [15:0] fe_pc,
  input        [15:0] fe_pc_nxt,
  input               fe_decode,
  input               nmi_acc,
  input        [15:0] dma_addr,
  input        [15:0] dbg_mem_addr,

  // peripheral OUTPUTs
  //=========
  output       [15:0] per_dout,       // Peripheral data output

  // control OUTPUTs
  //=========
  `ifndef OMIT_IPE_FIXES
  output wire ipe_fe_violation,
  `endif
  output wire ipe_eu_violation,
  output wire ipe_dma_violation,
  output wire ipe_dbg_mem_violation,
  output wire ipe_executing,
  output reg ipe_bootcode_exec,
  output wire bootcode_fe_violation,
  output wire bootcode_eu_violation,
  output wire bootcode_dma_violation,
  output wire bootcode_dbg_violation

`ifdef SECURE_IRQ_SW
  ,
  output wire [15:0] ipe_seg_end
`endif

`ifdef SECURE_IRQ_FW
  ,
  input wire irq_handling
`endif
);

//=============================================================================
// 1)  PARAMETER DECLARATION
//=============================================================================

// Register base address (must be aligned to decoder bit width)
parameter       [14:0] BASE_ADDR   = 15'h05A8;

// Decoder bit width (defines how many bits are considered for address decoding)
parameter              DEC_WD      =  3;

// Register addresses offset
parameter [DEC_WD-1:0] IPE_ACTIVE_OFFSET= 'h0,
                       IPC0_OFFSET      = 'h2,
                       IPSEGB2_OFFSET   = 'h4,
                       IPSEGB1_OFFSET   = 'h6;

// Register one-hot decoder utilities
parameter              DEC_SZ      =  (1 << DEC_WD);
parameter [DEC_SZ-1:0] BASE_REG    =  {{DEC_SZ-1{1'b0}}, 1'b1};

// Register one-hot decoder
parameter [DEC_SZ-1:0] IPC0_OFFSET_D    = (BASE_REG << IPC0_OFFSET),
                       IPSEGB2_OFFSET_D = (BASE_REG << IPSEGB2_OFFSET),
                       IPSEGB1_OFFSET_D = (BASE_REG << IPSEGB1_OFFSET),
                       IPE_ACTIVE_OFFSET_D = (BASE_REG << IPE_ACTIVE_OFFSET);


//============================================================================
// 2)  REGISTER DECODER
//============================================================================

// Local register selection
wire              reg_sel   =  per_en & (per_addr[13:DEC_WD-1]==BASE_ADDR[14:DEC_WD]);

// Register local address
wire [DEC_WD-1:0] reg_addr  =  {per_addr[DEC_WD-2:0], 1'b0};

// Register address decode
wire [DEC_SZ-1:0] reg_dec = (IPC0_OFFSET_D & {DEC_SZ{(reg_addr == IPC0_OFFSET)}}) |
                            (IPSEGB2_OFFSET_D & {DEC_SZ{(reg_addr == IPSEGB2_OFFSET)}}) |
                            (IPSEGB1_OFFSET_D & {DEC_SZ{(reg_addr == IPSEGB1_OFFSET)}}) |
                            (IPE_ACTIVE_OFFSET_D & {DEC_SZ{(reg_addr == IPE_ACTIVE_OFFSET)}});

// Read/Write probes
wire              reg_write =  |per_we & reg_sel;
wire              reg_read  = ~|per_we & reg_sel;

// Read/Write vectors
wire [DEC_SZ-1:0] reg_wr    = reg_dec & {DEC_SZ{reg_write}};
wire [DEC_SZ-1:0] reg_rd    = reg_dec & {DEC_SZ{reg_read}};


//============================================================================
// 3) REGISTERS
//============================================================================

// MPUIPC0 Register
//-----------------
reg  [15:0] MPUIPC0;

wire ipe_puc_on_violation = MPUIPC0[5];  // TODO: use this
wire ipe_enabled = MPUIPC0[6];
wire ipe_locked = MPUIPC0[7];

wire ipc0_wr = reg_wr[IPC0_OFFSET] & (~ipe_locked);

always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)      MPUIPC0 <=  16'h0000;
  else if (ipc0_wr) MPUIPC0 <=  per_din;


// MPUIPSEGB2 Register
//-----------------
reg  [12:0] MPUIPSEGB2;

wire segb2_wr = reg_wr[IPSEGB2_OFFSET] & (~ipe_locked);

always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)       MPUIPSEGB2 <=  16'h0000;
  else if (segb2_wr) MPUIPSEGB2 <=  per_din[12:0];

assign ipe_seg_end = MPUIPSEGB2 << 4;

// MPUIPSEGB1 Register
//-----------------
reg  [12:0] MPUIPSEGB1;

wire segb1_wr = reg_wr[IPSEGB1_OFFSET] & (~ipe_locked);

always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)       MPUIPSEGB1 <=  16'h0000;
  else if (segb1_wr) MPUIPSEGB1 <=  per_din[12:0];


// IPE_ACTIVE Register
//-----------------
reg  [15:0] IPE_ACTIVE;

//============================================================================
// 4) DATA OUTPUT GENERATION
//============================================================================

`ifndef OMIT_IPE_FIXES
  reg [15:0] buff_pc;
  always @(posedge mclk or posedge puc_rst)
    if (puc_rst) buff_pc <= 0;
    else if (fe_decode) buff_pc <= fe_pc;
`endif

always @(posedge mclk or posedge puc_rst)
  if (puc_rst)     ipe_bootcode_exec <= 1;
  else if (fe_decode) ipe_bootcode_exec <= address_in_bootcode(fe_pc) & ~bootcode_fe_violation;

function automatic address_in_ipe (input [15:0] addr);
begin
  address_in_ipe = (addr >> 4) < MPUIPSEGB2 & (addr >> 4) >= MPUIPSEGB1;
end
endfunction

`ifndef OMIT_IPE_FIXES
  wire      pc_in_ipe = address_in_ipe (buff_pc);
`else
  wire      pc_in_ipe = address_in_ipe (fe_pc);
`endif

wire    eu_mem_in_ipe = address_in_ipe (eu_mab);
wire       dma_in_ipe = address_in_ipe (dma_addr);
wire       dbg_in_ipe = address_in_ipe (dbg_mem_addr);

`ifndef OMIT_IPE_FIXES

  wire [15:0] entry_point = (MPUIPSEGB1 << 4) + 8;
  wire       fe_pc_in_ipe = address_in_ipe (fe_pc);
  wire   fe_pc_nxt_in_ipe = address_in_ipe (fe_pc_nxt);
  wire    fe_nxt_in_entry = fe_pc_nxt == entry_point;

`ifdef SECURE_IRQ_FW
  wire ipe_fe_violation_c = ipe_enabled & ~fe_pc_in_ipe & (fe_pc_nxt_in_ipe & ~fe_nxt_in_entry) & ~(ipe_bootcode_exec & fe_pc_nxt_in_ipe);
`else
  `ifdef SECURE_IRQ_FW
    wire ipe_fe_violation_c = ipe_enabled & ~fe_pc_in_ipe & (fe_pc_nxt_in_ipe & ~fe_nxt_in_entry & ~fe_pc_in_bootcode);  // allow the bootcode to jump to IPE memory
  `else
    wire ipe_fe_violation_c = ipe_enabled & ~fe_pc_in_ipe & (fe_pc_nxt_in_ipe & ~fe_nxt_in_entry);
  `endif
`endif

`endif
`ifdef SECURE_IRQ_FW
assign  ipe_eu_violation = ipe_enabled & ~pc_in_ipe & eu_mem_in_ipe & ~ipe_bootcode_exec;  // allow bootcode to access ipe memory
`else
assign  ipe_eu_violation = ipe_enabled & ~pc_in_ipe & eu_mem_in_ipe;
`endif
assign ipe_dma_violation = ipe_enabled & dma_in_ipe;
assign ipe_dbg_mem_violation = ipe_enabled & dbg_in_ipe;
assign ipe_executing = ipe_enabled & pc_in_ipe;

function automatic address_in_bootcode (input [15:0] addr);
begin
  address_in_bootcode = addr < (`BMEM_BASE + `BMEM_SIZE) & addr >= `BMEM_BASE;
end
endfunction

wire    eu_mem_in_bootcode = address_in_bootcode (eu_mab);
wire fe_pc_in_bootcode = address_in_bootcode (fe_pc);
wire fe_pc_nxt_in_bootcode = address_in_bootcode (fe_pc_nxt);
assign bootcode_dma_violation = address_in_bootcode (dma_addr);
assign bootcode_dbg_violation = address_in_bootcode (dbg_mem_addr);

`ifdef SECURE_IRQ_FW
wire bootcode_fe_violation_c = 0;
//~fe_pc_in_bootcode & fe_pc_nxt_in_bootcode & ~ipe_bootcode_exec & ~irq_handling;
`else
wire bootcode_fe_violation_c = ~fe_pc_in_bootcode & fe_pc_nxt_in_bootcode & ~ipe_bootcode_exec;
`endif
assign bootcode_eu_violation = ~ipe_bootcode_exec & eu_mem_in_bootcode;

// these need to be buffered until the triggered NMI is accepted
`ifndef OMIT_IPE_FIXES
  reg ipe_fe_violation_reg;
  always @(posedge mclk or posedge puc_rst)
    if (puc_rst) ipe_fe_violation_reg <= 0;
    else if (ipe_fe_violation_c) ipe_fe_violation_reg <= 1;
    else if (nmi_acc) ipe_fe_violation_reg <= 0;
  assign ipe_fe_violation = ipe_fe_violation_reg & ~nmi_acc; //| ipe_fe_violation_c;
`endif

reg bootcode_fe_violation_reg;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst) bootcode_fe_violation_reg <= 0;
  else if (bootcode_fe_violation_c) bootcode_fe_violation_reg <= 1;
  else if (nmi_acc) bootcode_fe_violation_reg <= 0;

assign bootcode_fe_violation = bootcode_fe_violation_reg | bootcode_fe_violation_c;

always @(posedge mclk or posedge puc_rst)
  if (puc_rst)     IPE_ACTIVE <= 0;
  else if (pc_in_ipe) IPE_ACTIVE <= 1;
  else if (!fe_pc_in_bootcode) IPE_ACTIVE <= 0;

// Data output mux
wire [15:0] ipc0_rd  = MPUIPC0  & {16{reg_rd[IPC0_OFFSET]}};
wire [15:0] segb2_rd  = MPUIPSEGB2  & {16{reg_rd[IPSEGB2_OFFSET]}};
wire [15:0] segb1_rd  = MPUIPSEGB1  & {16{reg_rd[IPSEGB1_OFFSET]}};
wire [15:0] active_rd  = IPE_ACTIVE  & {16{reg_rd[IPE_ACTIVE_OFFSET]}};

assign per_dout        =  ipc0_rd  |
                          segb2_rd |
                          segb1_rd |
                          active_rd;

endmodule // template_periph_16b
