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
  input        [1:0]  eu_mb_wr,
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
  output wire [3:0] ipe_executing,
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

// Register base address (must be aligned to decoder bit width)
parameter       [14:0] BASE_ADDR2   = 15'h05B0;

//============================================================================
// 2)  REGISTER DECODER
//============================================================================

// Local register selection
wire              reg_sel   =  per_en & (per_addr[13:DEC_WD-1]==BASE_ADDR[14:DEC_WD]);

wire 		  reg_sel2  =  per_en & (per_addr[13:DEC_WD-1]==BASE_ADDR2[14:DEC_WD]);


// Register local address
wire [DEC_WD-1:0] reg_addr  =  {per_addr[DEC_WD-2:0], 1'b0};

// Register address decode
wire [DEC_SZ-1:0] reg_dec = (IPC0_OFFSET_D & {DEC_SZ{(reg_addr == IPC0_OFFSET)}}) |
                            (IPSEGB2_OFFSET_D & {DEC_SZ{(reg_addr == IPSEGB2_OFFSET)}}) |
                            (IPSEGB1_OFFSET_D & {DEC_SZ{(reg_addr == IPSEGB1_OFFSET)}}) |
                            (IPE_ACTIVE_OFFSET_D & {DEC_SZ{(reg_addr == IPE_ACTIVE_OFFSET)}});

// Read/Write probes
wire              reg_write =  |per_we & (reg_sel | reg_sel2);
wire              reg_read  = ~|per_we & (reg_sel | reg_sel2);

// Read/Write vectors
wire [DEC_SZ-1:0] reg_wr    = reg_dec & {DEC_SZ{reg_write}};
wire [DEC_SZ-1:0] reg_rd    = reg_dec & {DEC_SZ{reg_read}};


//============================================================================
// 3) REGISTERS
//============================================================================

wire [1:0] ipe_enabled;
wire [1:0] ipe_puc_on_violation;
wire [1:0] ipe_locked;
`ifdef IPE_GRAN
  wire [1:0] ipe_granularity;
  wire [2:0] shift_amt [1:0];
`endif
`ifdef IPE_PC
  wire [1:0] ipe_child;
  wire [1:0] ipe1_parent;
  wire [1:0] ipe2_parent;
`endif


// MPUIPC0 Register
//-----------------
reg  [15:0] MPUIPC0;

assign ipe_puc_on_violation[0] = MPUIPC0[5];  // TODO: use this
assign ipe_enabled[0] = MPUIPC0[6];
assign ipe_locked[0] = MPUIPC0[7];
`ifdef IPE_GRAN
  assign ipe_granularity[0] = MPUIPC0[8];
`endif
`ifdef IPE_PC
  assign ipe_child[0] = MPUIPC0[9];
  assign ipe1_parent     = MPUIPC0[9] ? 1 << (MPUIPC0[12:10] - 1) : 4'b0;
`endif

wire ipc0_wr = reg_wr[IPC0_OFFSET] & (~ipe_locked[0]) & reg_sel;

always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)      MPUIPC0 <=  16'h0000;
  else if (ipc0_wr) MPUIPC0 <=  per_din;

reg  [15:0] MPUIP2C0;

assign ipe_puc_on_violation[1] = MPUIP2C0[5];  // TODO: use this
assign ipe_enabled[1] = MPUIP2C0[6];
assign ipe_locked[1] = MPUIP2C0[7];
`ifdef IPE_GRAN
  assign ipe_granularity[1] = MPUIPC0[8];
`endif
`ifdef IPE_PC
  assign ipe_child[1] = MPUIP2C0[9];
  assign ipe2_parent     = MPUIP2C0[9] ? 1 << (MPUIP2C0[12:10] - 1) : 4'b0;
`endif

wire ip2c0_wr = reg_wr[IPC0_OFFSET] & (~ipe_locked[1]) & reg_sel2;

always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)      MPUIP2C0 <=  16'h0000;
  else if (ip2c0_wr) MPUIP2C0 <=  per_din;

`ifdef IPE_GRAN
  assign shift_amt[0] = ipe_granularity[0] ? 3'd0 : 3'd4;
  assign shift_amt[1] = ipe_granularity[1] ? 3'd0 : 3'd4;
`endif


// MPUIPSEGB2 Register
//-----------------
`ifdef IPE_GRAN
  reg  [15:0] MPUIPSEGB2;
  reg  [15:0] MPUIP2SEGB2;
`else
  reg  [12:0] MPUIPSEGB2;
  reg  [12:0] MPUIP2SEGB2;
`endif

wire segb2_wr = reg_wr[IPSEGB2_OFFSET] & (~ipe_locked[0]) & reg_sel;
wire seg2b2_wr = reg_wr[IPSEGB2_OFFSET] & (~ipe_locked[1]) & reg_sel2;

`ifdef IPE_GRAN
  always @ (posedge mclk or posedge puc_rst)
    if (puc_rst)       MPUIPSEGB2 <=  16'h0000;
    else if (segb2_wr) MPUIPSEGB2 <=  per_din;

  always @ (posedge mclk or posedge puc_rst)
    if (puc_rst)       MPUIP2SEGB2 <=  16'h0000;
    else if (seg2b2_wr) MPUIP2SEGB2 <=  per_din;

  assign ipe_seg_end = ((MPUIP2SEGB2 << shift_amt[1]) & {16{ipe_executing[1]}}) | 
                       ((MPUIPSEGB2 << shift_amt[0]) & {16{ipe_executing[0]}});
`else
  always @ (posedge mclk or posedge puc_rst)
    if (puc_rst)       MPUIPSEGB2 <=  16'h0000;
    else if (segb2_wr) MPUIPSEGB2 <=  per_din[12:0];

  always @ (posedge mclk or posedge puc_rst)
    if (puc_rst)       MPUIP2SEGB2 <=  16'h0000;
    else if (seg2b2_wr) MPUIP2SEGB2 <=  per_din[12:0];

  assign ipe_seg_end = (MPUIP2SEGB2 << 4 & {16{ipe_executing[1]}}) | 
                       (MPUIPSEGB2 << 4 & {16{ipe_executing[0]}});

`endif



// MPUIPSEGB1 Register
//-----------------
`ifdef IPE_GRAN
  reg  [15:0] MPUIPSEGB1;
  reg  [15:0] MPUIP2SEGB1;
`else
  reg  [12:0] MPUIPSEGB1;
  reg  [12:0] MPUIP2SEGB1;
`endif

wire segb1_wr = reg_wr[IPSEGB1_OFFSET] & (~ipe_locked[0]) & reg_sel;
wire seg2b1_wr = reg_wr[IPSEGB1_OFFSET] & (~ipe_locked[1]) & reg_sel2;

`ifdef IPE_GRAN
  always @ (posedge mclk or posedge puc_rst)
    if (puc_rst)       MPUIPSEGB1 <=  16'h0000;
    else if (segb1_wr) MPUIPSEGB1 <=  per_din;

  always @ (posedge mclk or posedge puc_rst)
    if (puc_rst)       MPUIP2SEGB1 <=  16'h0000;
    else if (seg2b1_wr) MPUIP2SEGB1 <=  per_din;

`else
  always @ (posedge mclk or posedge puc_rst)
    if (puc_rst)       MPUIPSEGB1 <=  16'h0000;
    else if (segb1_wr) MPUIPSEGB1 <=  per_din[12:0];

  always @ (posedge mclk or posedge puc_rst)
    if (puc_rst)       MPUIP2SEGB1 <=  16'h0000;
    else if (seg2b1_wr) MPUIP2SEGB1 <=  per_din[12:0];

`endif


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


`ifdef IPE_GRAN
  function automatic [1:0] address_in_ipe (input [15:0] addr);
  begin
    address_in_ipe = {((addr >> shift_amt[1]) < MPUIP2SEGB2 & (addr >> shift_amt[1]) >= MPUIP2SEGB1),
                      ((addr >> shift_amt[0]) < MPUIPSEGB2 & (addr >> shift_amt[0]) >= MPUIPSEGB1)};    
  end
  endfunction
`else
  function automatic [1:0] address_in_ipe (input [15:0] addr);
  begin
    address_in_ipe = {(addr >> 4) < MPUIP2SEGB2 & (addr >> 4) >= MPUIP2SEGB1, (addr >> 4) < MPUIPSEGB2 & (addr >> 4) >= MPUIPSEGB1};
  end
  endfunction
`endif


`ifdef IPE_PC
  function automatic [1:0] ipe_parent (input [1:0] ipe_id);
  begin
    ipe_parent = (ipe1_parent & {4{ipe_id[0]}}) | (ipe2_parent & {4{ipe_id[1]}});
  end
  endfunction
`endif

`ifndef OMIT_IPE_FIXES
  wire      [1:0] pc_in_ipe = address_in_ipe (buff_pc);
`else
  wire      [1:0] pc_in_ipe = address_in_ipe (fe_pc);
`endif

wire    [1:0] eu_mem_in_ipe = address_in_ipe (eu_mab);
wire       [1:0] dma_in_ipe = address_in_ipe (dma_addr);
wire       [1:0] dbg_in_ipe = address_in_ipe (dbg_mem_addr);

`ifndef OMIT_IPE_FIXES

  `ifdef IPE_GRAN
    wire [15:0] entry_point = (MPUIPSEGB1 << shift_amt[0]) + 8;
    wire [15:0] entry_point2 = (MPUIP2SEGB1 << shift_amt[1]) + 8;
  `else
    wire [15:0] entry_point = (MPUIPSEGB1 << 4) + 8;
    wire [15:0] entry_point2 = (MPUIP2SEGB1 << 4) + 8;
  `endif
  wire       [1:0] fe_pc_in_ipe = address_in_ipe (fe_pc);
  wire   [1:0] fe_pc_nxt_in_ipe = address_in_ipe (fe_pc_nxt);
  wire    [1:0] fe_nxt_in_entry = {(fe_pc_nxt == entry_point2), (fe_pc_nxt == entry_point)};
  //wire fe_nxt_in_bootcode_entry = (fe_pc_nxt == `BMEM_BASE);
    // only used for the manual isr register test -> but ipe should still not be able to jump to bootcode TODO

`ifdef SECURE_IRQ_FW
  wire ipe_fe_violation_c = |(ipe_enabled & ~fe_pc_in_ipe & (fe_pc_nxt_in_ipe & ~fe_nxt_in_entry)) & ~(ipe_bootcode_exec & |fe_pc_nxt_in_ipe);
`else
  `ifdef SECURE_IRQ_FW
    wire ipe_fe_violation_c = |(ipe_enabled & ~fe_pc_in_ipe) & (|(fe_pc_nxt_in_ipe & ~fe_nxt_in_entry) & ~fe_pc_in_bootcode);  // allow the bootcode to jump to IPE memory
  `else
    wire ipe_fe_violation_c = |(ipe_enabled & ~fe_pc_in_ipe & (fe_pc_nxt_in_ipe & ~fe_nxt_in_entry));
  `endif
`endif

wire ipe_exec_two;

`endif
`ifdef SECURE_IRQ_FW
  `ifdef IPE_PC
    assign  ipe_eu_violation = |(ipe_enabled & ~pc_in_ipe & eu_mem_in_ipe) & ~ipe_bootcode_exec & ~|(ipe_parent(eu_mem_in_ipe & ipe_child) & pc_in_ipe);  // allow bootcode to access ipe memory
  `else
    assign  ipe_eu_violation = |(ipe_enabled & ~pc_in_ipe & eu_mem_in_ipe) & ~ipe_bootcode_exec;  // allow bootcode to access ipe memory
  `endif
`else
  `ifdef IPE_PC
    assign  ipe_eu_violation = |(ipe_enabled & ~pc_in_ipe & eu_mem_in_ipe) & ~|(ipe_parent(eu_mem_in_ipe & ipe_child) & pc_in_ipe);
  `else
    assign ipe_eu_violation = |(ipe_enabled & ~pc_in_ipe & eu_mem_in_ipe);
  `endif
`endif
assign ipe_dma_violation = |(ipe_enabled & dma_in_ipe);
assign ipe_dbg_mem_violation = |(ipe_enabled & dbg_in_ipe);
assign ipe_exec_two = ipe_enabled & pc_in_ipe;
assign ipe_executing = {2'b00, ipe_exec_two};

function automatic address_in_bootcode (input [15:0] addr);
begin
  address_in_bootcode = addr < (`BMEM_BASE + `BMEM_PROT_SIZE) & addr >= `BMEM_BASE;
end
endfunction

wire    eu_mem_in_bootcode = address_in_bootcode (eu_mab);
wire fe_pc_in_bootcode = address_in_bootcode (fe_pc);
wire fe_pc_nxt_in_bootcode = address_in_bootcode (fe_pc_nxt);
assign bootcode_dma_violation = address_in_bootcode (dma_addr);
assign bootcode_dbg_violation = address_in_bootcode (dbg_mem_addr);

`ifdef SECURE_IRQ_FW
wire fe_pc_nxt_in_firmware_ivt = fe_pc_nxt < (`BMEM_BASE + `BMEM_PROT_SIZE) & fe_pc_nxt >= (`BMEM_BASE + `BMEM_PROT_SIZE - 32);
wire bootcode_fe_violation_c = ~fe_pc_in_bootcode & fe_pc_nxt_in_bootcode & ~ipe_bootcode_exec & ~fe_pc_nxt_in_firmware_ivt; //& ~fe_nxt_in_bootcode_entry; // allow entry to bootcode through IVT
`else
wire bootcode_fe_violation_c = ~fe_pc_in_bootcode & fe_pc_nxt_in_bootcode & ~ipe_bootcode_exec;
`endif
assign bootcode_eu_violation = ~ipe_bootcode_exec & eu_mem_in_bootcode & |eu_mb_wr;

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
  else if (|pc_in_ipe) IPE_ACTIVE[1:0] <= pc_in_ipe;
  else if (!fe_pc_in_bootcode) IPE_ACTIVE <= 0;

// Data output mux
wire [15:0] ipc0_rd  = MPUIPC0  & {16{reg_rd[IPC0_OFFSET]}} & {16{reg_sel}};
wire [15:0] segb2_rd  = MPUIPSEGB2  & {16{reg_rd[IPSEGB2_OFFSET]}} & {16{reg_sel}};
wire [15:0] segb1_rd  = MPUIPSEGB1  & {16{reg_rd[IPSEGB1_OFFSET]}} & {16{reg_sel}};
wire [15:0] ip2c0_rd  = MPUIP2C0  & {16{reg_rd[IPC0_OFFSET]}} & {16{reg_sel2}};
wire [15:0] seg2b2_rd  = MPUIP2SEGB2  & {16{reg_rd[IPSEGB2_OFFSET]}} & {16{reg_sel2}};
wire [15:0] seg2b1_rd  = MPUIP2SEGB1  & {16{reg_rd[IPSEGB1_OFFSET]}} & {16{reg_sel2}};
wire [15:0] active_rd  = IPE_ACTIVE  & {16{reg_rd[IPE_ACTIVE_OFFSET]}};

assign per_dout        =  (ipc0_rd | ip2c0_rd) |
                          (segb2_rd | seg2b2_rd) |
                          (segb1_rd | seg2b1_rd) |
                          active_rd;

endmodule // template_periph_16b
