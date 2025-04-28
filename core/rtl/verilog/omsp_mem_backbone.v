//----------------------------------------------------------------------------
// Copyright (C) 2009 , Olivier Girard
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of the authors nor the names of its contributors
//       may be used to endorse or promote products derived from this software
//       without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
// OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
// THE POSSIBILITY OF SUCH DAMAGE
//
//----------------------------------------------------------------------------
//
// *File Name: omsp_mem_backbone.v
//
// *Module Description:
//                       Memory interface backbone (decoder + arbiter)
//
// *Author(s):
//              - Olivier Girard,    olgirard@gmail.com
//
//----------------------------------------------------------------------------
// $Rev: 103 $
// $LastChangedBy: olivier.girard $
// $LastChangedDate: 2011-03-05 15:44:48 +0100 (Sat, 05 Mar 2011) $
//----------------------------------------------------------------------------
`ifdef OMSP_NO_INCLUDE
`else
`include "openMSP430_defines.v"
`endif

module  omsp_mem_backbone (

// OUTPUTs
    cpu_halt_cmd,                       // Halt CPU command
    dbg_mem_din,                        // Debug unit Memory data input
    dmem_addr,                          // Data Memory address
    dmem_cen,                           // Data Memory chip enable (low active)
    dmem_din,                           // Data Memory data input
    dmem_wen,                           // Data Memory write enable (low active)
    eu_mdb_in,                          // Execution Unit Memory data bus input
    fe_mdb_in,                          // Frontend Memory data bus input
    fe_pmem_wait,                       // Frontend wait for Instruction fetch
    dma_dout,                           // Direct Memory Access data output
    dma_ready,                          // Direct Memory Access is complete
    dma_resp,                           // Direct Memory Access response (0:Okay / 1:Error)
    per_addr,                           // Peripheral address
    per_din,                            // Peripheral data input
    per_we,                             // Peripheral write enable (high active)
    per_en,                             // Peripheral enable (high active)
    pmem_addr,                          // Program Memory address
    pmem_cen,                           // Program Memory chip enable (low active)
    pmem_din,                           // Program Memory data input (optional)
    pmem_wen,                           // Program Memory write enable (low active) (optional)
    bmem_addr,                          // Bootcode Memory address
    bmem_cen,                           // Bootcode Memory chip enable (low active)
    bmem_din,                           // Bootcode Memory data input (optional)
    bmem_wen,                           // Bootcode Memory write enable (low active) (optional)
    pmem_writing,                       // Currently writing to program memory

// INPUTs
    cpu_halt_st,                        // Halt/Run status from CPU
    dbg_halt_cmd,                       // Debug interface Halt CPU command
    dbg_mem_addr,                       // Debug address for rd/wr access
    dbg_mem_dout,                       // Debug unit data output
    dbg_mem_en,                         // Debug unit memory enable
    dbg_mem_wr,                         // Debug unit memory write
    dmem_dout,                          // Data Memory data output
    eu_mab,                             // Execution Unit Memory address bus
    eu_mb_en,                           // Execution Unit Memory bus enable
    eu_mb_wr,                           // Execution Unit Memory bus write transfer
    eu_mdb_out,                         // Execution Unit Memory data bus output
    fe_mab,                             // Frontend Memory address bus
    fe_mb_en,                           // Frontend Memory bus enable
    mclk,                               // Main system clock
    dma_addr,                           // Direct Memory Access address
    dma_din,                            // Direct Memory Access data input
    dma_en,                             // Direct Memory Access enable (high active)
    dma_priority,                       // Direct Memory Access priority (0:low / 1:high)
    dma_we,                             // Direct Memory Access write byte enable (high active)
    per_dout,                           // Peripheral data output
    pmem_dout,                          // Program Memory data output
    bmem_dout,                          // Bootcode Memory data output
    puc_rst,                            // Main system reset
    scan_enable,                        // Scan enable (active during scan shifting),
    ipe_bootcode_exec,
    ipe_eu_violation,
    ipe_dma_violation,
    ipe_dbg_mem_violation,
    bootcode_eu_violation,
    bootcode_dma_violation,
    bootcode_dbg_violation,
    bootcode_fe_violation,
    ipe_fe_violation,
);

// OUTPUTs
//=========
output               cpu_halt_cmd;      // Halt CPU command
output        [15:0] dbg_mem_din;       // Debug unit Memory data input
output [`DMEM_MSB:0] dmem_addr;         // Data Memory address
output               dmem_cen;          // Data Memory chip enable (low active)
output        [15:0] dmem_din;          // Data Memory data input
output         [1:0] dmem_wen;          // Data Memory write enable (low active)
output        [15:0] eu_mdb_in;         // Execution Unit Memory data bus input
output        [15:0] fe_mdb_in;         // Frontend Memory data bus input
output               fe_pmem_wait;      // Frontend wait for Instruction fetch
output        [15:0] dma_dout;          // Direct Memory Access data output
output               dma_ready;         // Direct Memory Access is complete
output               dma_resp;          // Direct Memory Access response (0:Okay / 1:Error)
output        [13:0] per_addr;          // Peripheral address
output        [15:0] per_din;           // Peripheral data input
output         [1:0] per_we;            // Peripheral write enable (high active)
output               per_en;            // Peripheral enable (high active)
output [`PMEM_MSB:0] pmem_addr;         // Program Memory address
output               pmem_cen;          // Program Memory chip enable (low active)
output        [15:0] pmem_din;          // Program Memory data input (optional)
output         [1:0] pmem_wen;          // Program Memory write enable (low active) (optional)
output [`BMEM_MSB:0] bmem_addr;         // Bootcode Memory address
output               bmem_cen;          // Bootcode Memory chip enable (low active)
output        [15:0] bmem_din;          // Bootcode Memory data input (optional)
output         [1:0] bmem_wen;          // Bootcode Memory write enable (low active) (optional)
output               pmem_writing;

// INPUTs
//=========
input                cpu_halt_st;       // Halt/Run status from CPU
input                dbg_halt_cmd;      // Debug interface Halt CPU command
input         [15:1] dbg_mem_addr;      // Debug address for rd/wr access
input         [15:0] dbg_mem_dout;      // Debug unit data output
input                dbg_mem_en;        // Debug unit memory enable
input          [1:0] dbg_mem_wr;        // Debug unit memory write
input         [15:0] dmem_dout;         // Data Memory data output
input         [14:0] eu_mab;            // Execution Unit Memory address bus
input                eu_mb_en;          // Execution Unit Memory bus enable
input          [1:0] eu_mb_wr;          // Execution Unit Memory bus write transfer
input         [15:0] eu_mdb_out;        // Execution Unit Memory data bus output
input         [14:0] fe_mab;            // Frontend Memory address bus
input                fe_mb_en;          // Frontend Memory bus enable
input                mclk;              // Main system clock
input         [15:1] dma_addr;          // Direct Memory Access address
input         [15:0] dma_din;           // Direct Memory Access data input
input                dma_en;            // Direct Memory Access enable (high active)
input                dma_priority;      // Direct Memory Access priority (0:low / 1:high)
input          [1:0] dma_we;            // Direct Memory Access write byte enable (high active)
input         [15:0] per_dout;          // Peripheral data output
input         [15:0] pmem_dout;         // Program Memory data output
input         [15:0] bmem_dout;         // Bootcode Memory data output
input                puc_rst;           // Main system reset
input                scan_enable;       // Scan enable (active during scan shifting)
input                ipe_bootcode_exec;
input                ipe_eu_violation;
input                ipe_dma_violation;
input                ipe_dbg_mem_violation;
input                bootcode_eu_violation;
input                bootcode_dma_violation;
input                bootcode_dbg_violation;
input                bootcode_fe_violation;
input                ipe_fe_violation;

wire                 ext_mem_en;
wire          [15:0] ext_mem_din;
wire                 ext_dmem_sel;
wire                 ext_dmem_en;
wire                 ext_pmem_sel;
wire                 ext_pmem_en;
wire                 ext_per_sel;
wire                 ext_per_en;


//=============================================================================
// 1)  DECODER
//=============================================================================

//------------------------------------------
// Arbiter between DMA and Debug interface
//------------------------------------------
`ifdef DMA_IF_EN

// Debug-interface always stops the CPU
// Master interface stops the CPU in priority mode
assign      cpu_halt_cmd  =  dbg_halt_cmd | (dma_en & dma_priority);

// Return ERROR response if address lays outside the memory spaces (Peripheral, Data & Program memories)
assign      dma_resp      = ~dbg_mem_en & (~(ext_dmem_sel | ext_pmem_sel | ext_per_sel) | ipe_dma_violation | bootcode_dma_violation) & dma_en;

// Master interface access is ready when the memory access occures
assign      dma_ready     = ~dbg_mem_en &  (ext_dmem_en  | ext_pmem_en  | ext_per_en | dma_resp);

// Use delayed version of 'dma_ready' to mask the 'dma_dout' data output
// when not accessed and reduce toggle rate (thus power consumption)
reg         dma_ready_dly;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)  dma_ready_dly <=  1'b0;
  else          dma_ready_dly <=  dma_ready;

// Mux between debug and master interface
assign      ext_mem_en    =  (dbg_mem_en & ~ipe_dbg_mem_violation & ~bootcode_dbg_violation) | (dma_en & ~ipe_dma_violation & ~bootcode_dma_violation);  // TODO: refactor to a single dma_violation, dbg_violation signal
wire  [1:0] ext_mem_wr    =  (dbg_mem_en & ~ipe_dbg_mem_violation & ~bootcode_dbg_violation) ? dbg_mem_wr    :  dma_we;
wire [15:1] ext_mem_addr  =  (dbg_mem_en & ~ipe_dbg_mem_violation & ~bootcode_dbg_violation) ? dbg_mem_addr  :  dma_addr;
wire [15:0] ext_mem_dout  =  (dbg_mem_en & ~ipe_dbg_mem_violation & ~bootcode_dbg_violation) ? dbg_mem_dout  :  dma_din;

// External interface read data
assign      dbg_mem_din   =  ext_mem_din;
assign      dma_dout      =  ext_mem_din & {16{dma_ready_dly}};


`else
// Debug-interface always stops the CPU
assign      cpu_halt_cmd  =  dbg_halt_cmd;

// Master interface access is always ready with error response when excluded
assign      dma_resp      =  1'b1;
assign      dma_ready     =  1'b1;

// Debug interface only
assign      ext_mem_en    =  (dbg_mem_en & ~ipe_dbg_mem_violation & ~bootcode_dbg_violation);
wire  [1:0] ext_mem_wr    =  dbg_mem_wr;
wire [15:1] ext_mem_addr  =  dbg_mem_addr;
wire [15:0] ext_mem_dout  =  dbg_mem_dout;

// External interface read data
assign      dbg_mem_din   =  ext_mem_din;
assign      dma_dout      =  16'h0000;

// LINT Cleanup
wire [15:1] UNUSED_dma_addr     = dma_addr;
wire [15:0] UNUSED_dma_din      = dma_din;
wire        UNUSED_dma_en       = dma_en;
wire        UNUSED_dma_priority = dma_priority;
wire  [1:0] UNUSED_dma_we       = dma_we;

`endif

//------------------------------------------
// DATA-MEMORY Interface
//------------------------------------------
parameter          DMEM_END      = `DMEM_BASE+`DMEM_SIZE;

// Execution unit access
wire               eu_dmem_sel   = (eu_mab>=(`DMEM_BASE>>1)) &
                                   (eu_mab< ( DMEM_END >>1));
wire               eu_dmem_en    = eu_mb_en & eu_dmem_sel & ~ipe_eu_violation;
wire        [15:0] eu_dmem_addr  = {1'b0, eu_mab}-(`DMEM_BASE>>1);

// Front-end access
// -- not allowed to execute from data memory --

// External Master/Debug interface access
assign             ext_dmem_sel  = (ext_mem_addr[15:1]>=(`DMEM_BASE>>1)) &
                                   (ext_mem_addr[15:1]< ( DMEM_END >>1));
assign             ext_dmem_en   = ext_mem_en &  ext_dmem_sel & ~eu_dmem_en;
wire        [15:0] ext_dmem_addr = {1'b0, ext_mem_addr[15:1]}-(`DMEM_BASE>>1);


// Data-Memory Interface
wire               dmem_cen      = ~(ext_dmem_en | eu_dmem_en);
wire         [1:0] dmem_wen      =   ext_dmem_en ? ~ext_mem_wr                 : ~eu_mb_wr;
wire [`DMEM_MSB:0] dmem_addr     =   ext_dmem_en ?  ext_dmem_addr[`DMEM_MSB:0] :  eu_dmem_addr[`DMEM_MSB:0];
wire        [15:0] dmem_din      =   ext_dmem_en ?  ext_mem_dout               :  eu_mdb_out;

//------------------------------------------
// BOOTCODE-MEMORY Interface
//------------------------------------------
parameter          BMEM_END      = `BMEM_BASE+`BMEM_SIZE;

// Execution unit access
wire               eu_bmem_sel   = (eu_mab>=(`BMEM_BASE>>1)) &
                                   (eu_mab< ( BMEM_END >>1));
wire               eu_bmem_en    = eu_mb_en & eu_bmem_sel & ~bootcode_eu_violation;
wire        [15:0] eu_bmem_addr  = {1'b0, eu_mab}-(`BMEM_BASE>>1);

// Front-end access
wire               fe_bmem_sel   = (fe_mab>=(`BMEM_BASE>>1)) &
                                   (fe_mab< ( BMEM_END >>1));
wire               fe_bmem_en    = fe_mb_en & fe_bmem_sel;
wire        [15:0] fe_bmem_addr  = {1'b0, fe_mab}-(`BMEM_BASE>>1);

// External Master/Debug interface access
// -- not allowed to access bootcode memory --

// Program-Memory Interface (Execution unit has priority over the Front-end)
wire               bmem_cen      = ~(fe_bmem_en | eu_bmem_en);
wire         [1:0] bmem_wen      =  eu_bmem_en ? ~eu_mb_wr                 : 2'b11;
wire [`BMEM_MSB:0] bmem_addr     =  eu_bmem_en  ?  eu_bmem_addr[`BMEM_MSB:0]  : fe_pmem_addr[`BMEM_MSB:0];
wire        [15:0] bmem_din      =  eu_mdb_out;

//------------------------------------------
// PROGRAM-MEMORY Interface
//------------------------------------------

parameter          PMEM_OFFSET   = (16'hFFFF-`PMEM_SIZE+1);

// Execution unit access
wire               eu_pmem_sel   = (eu_mab>=(PMEM_OFFSET>>1));
wire               eu_pmem_en    = eu_mb_en & eu_pmem_sel & ~ipe_eu_violation;
wire        [15:0] eu_pmem_addr  = eu_mab-(PMEM_OFFSET>>1);

// Front-end access
wire               fe_pmem_sel   = (fe_mab>=(PMEM_OFFSET>>1));
wire               fe_pmem_en    = fe_mb_en & fe_pmem_sel;
wire        [15:0] fe_pmem_addr  = fe_mab-(PMEM_OFFSET>>1);

// External Master/Debug interface access
assign             ext_pmem_sel  = (ext_mem_addr[15:1]>=(PMEM_OFFSET>>1));
assign             ext_pmem_en   = ext_mem_en & ext_pmem_sel & ~eu_pmem_en & ~fe_pmem_en;
wire        [15:0] ext_pmem_addr = {1'b0, ext_mem_addr[15:1]}-(PMEM_OFFSET>>1);


// Program-Memory Interface (Execution unit has priority over the Front-end)
wire               pmem_cen      = ~(fe_pmem_en | eu_pmem_en | ext_pmem_en);
wire         [1:0] pmem_wen      =  ext_pmem_en ? ~ext_mem_wr : eu_pmem_en ? ~eu_mb_wr                 : 2'b11;
wire [`PMEM_MSB:0] pmem_addr     =  ext_pmem_en ?  ext_pmem_addr[`PMEM_MSB:0] :
                                    eu_pmem_en  ?  eu_pmem_addr[`PMEM_MSB:0]  : fe_pmem_addr[`PMEM_MSB:0];
wire        [15:0] pmem_din      =  ext_pmem_en ? ext_mem_dout : eu_mdb_out;

wire               fe_pmem_wait  = (fe_pmem_en & eu_pmem_en) | (fe_bmem_en & eu_bmem_en);

//------------------------------------------
// PERIPHERALS Interface
//------------------------------------------

// Execution unit access
wire               eu_per_sel    =  (eu_mab<(`PER_SIZE>>1));
wire               eu_per_en     =  eu_mb_en & eu_per_sel;

// Front-end access
// -- not allowed to execute from peripherals memory space --

// External Master/Debug interface access
assign             ext_per_sel   =  (ext_mem_addr[15:1]<(`PER_SIZE>>1));
assign             ext_per_en    =  ext_mem_en & ext_per_sel & ~eu_per_en;

// Peripheral Interface
wire               per_en        =  ext_per_en | eu_per_en;
wire         [1:0] per_we        =  ext_per_en ? ext_mem_wr                 : eu_mb_wr;
wire  [`PER_MSB:0] per_addr_mux  =  ext_per_en ? ext_mem_addr[`PER_MSB+1:1] : eu_mab[`PER_MSB:0];
wire        [14:0] per_addr_ful  =  {{15-`PER_AWIDTH{1'b0}}, per_addr_mux};
wire        [13:0] per_addr      =  per_addr_ful[13:0];
wire        [15:0] per_din       =  ext_per_en ? ext_mem_dout               : eu_mdb_out;

// Register peripheral data read path
reg   [15:0] per_dout_val;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)  per_dout_val    <=  16'h0000;
  else          per_dout_val    <=  per_dout;


//------------------------------------------
// Frontend data Mux
//------------------------------------------
// Whenever the frontend doesn't access the program memory,  backup the data

reg fe_violation_buf;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst)  fe_violation_buf <= 1'b0;
  else          fe_violation_buf <= ipe_fe_violation | bootcode_fe_violation;

// Mux to select if FE is executing in bootcode or pmem
// otherwise FE loses instruction fetches when EU accesses the bootcode data
wire fe_pbmem_en = fe_bmem_en | fe_pmem_en;
wire [15:0] pbmem_dout  = fe_violation_buf ? 16'h3FFF     :
                          ipe_bootcode_exec ? bmem_dout : pmem_dout;

wire eu_pbmem_en = ipe_bootcode_exec ? eu_bmem_en : eu_pmem_en;
assign pmem_writing  = eu_pbmem_en & |eu_mb_wr;

// Detect whenever the data should be backuped and restored
reg         fe_pbmem_en_dly;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst) fe_pbmem_en_dly <=  1'b0;
  else         fe_pbmem_en_dly <=  fe_pbmem_en;

wire fe_pbmem_save    = (~fe_pbmem_en &  fe_pbmem_en_dly) & ~cpu_halt_st;
wire fe_pbmem_restore = ( fe_pbmem_en & ~fe_pbmem_en_dly) |  cpu_halt_st;

`ifdef CLOCK_GATING
wire mclk_bckup_gated;
omsp_clock_gate clock_gate_bckup (.gclk(mclk_bckup_gated),
                                  .clk (mclk), .enable(fe_pbmem_save), .scan_enable(scan_enable));
`define MCLK_BCKUP           mclk_bckup_gated
`else
wire    UNUSED_scan_enable = scan_enable;
`define MCLK_BCKUP           mclk        // use macro to solve delta cycle issues with some mixed VHDL/Verilog simulators
`endif

reg  [15:0] pbmem_dout_bckup;
always @(posedge `MCLK_BCKUP or posedge puc_rst)
  if (puc_rst)              pbmem_dout_bckup     <=  16'h0000;
`ifdef CLOCK_GATING
  else                      pbmem_dout_bckup     <=  pbmem_dout;
`else
  else if (fe_pbmem_save)   pbmem_dout_bckup     <=  pbmem_dout;
`endif

// Mux between the Program memory data and the backup
reg         pbmem_dout_bckup_sel;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst)               pbmem_dout_bckup_sel <=  1'b0;
  else if (fe_pbmem_save)    pbmem_dout_bckup_sel <=  1'b1;
  else if (fe_pbmem_restore) pbmem_dout_bckup_sel <=  1'b0;

assign fe_mdb_in = pbmem_dout_bckup_sel ? pbmem_dout_bckup :
                   (fe_bmem_en & ~bootcode_fe_violation) ? bmem_dout :
                   ~ipe_fe_violation ? pmem_dout :
                   16'h3FFF;
//assign fe_mdb_in = pmem_dout_bckup_sel ? pmem_dout_bckup :
//                   (bmem_dout_bckup_sel & ~fe_pmem_en) ? bmem_dout_bckup :
//                   fe_bmem_en ? bmem_dout : pmem_dout;

//------------------------------------------
// Execution-Unit data Mux
//------------------------------------------

// Select between Peripherals, Program, Bootcode, and Data memories
reg [2:0] eu_mdb_in_sel;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst)  eu_mdb_in_sel  <= 2'b00;
  else          eu_mdb_in_sel  <= {eu_pmem_en, eu_per_en, eu_bmem_sel};

reg ipe_eu_violation_buf;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst)  ipe_eu_violation_buf <= 1'b0;
  else          ipe_eu_violation_buf <= ipe_eu_violation;

reg bootcode_eu_violation_buf;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst)  bootcode_eu_violation_buf <= 1'b0;
  else          bootcode_eu_violation_buf <= bootcode_eu_violation;

// Mux
assign          eu_mdb_in       = (ipe_eu_violation_buf | bootcode_eu_violation_buf) ? 16'h3FFF :
                                  eu_mdb_in_sel[2] ? pmem_dout    :
                                  eu_mdb_in_sel[1] ? per_dout_val :
                                  eu_mdb_in_sel[0] ? bmem_dout : dmem_dout;


//------------------------------------------
// External Master/Debug interface data Mux
//------------------------------------------

// Select between Peripherals, Program and Data memories
reg   [1:0] ext_mem_din_sel;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst)  ext_mem_din_sel <= 2'b00;
  else          ext_mem_din_sel <= {ext_pmem_en, ext_per_en};

reg dma_violation_buf;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst)  dma_violation_buf <= 1'b0;
  else          dma_violation_buf <= ipe_dma_violation | bootcode_dma_violation;

reg dbg_mem_violation_buf;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst)  dbg_mem_violation_buf <= 1'b0;
  else          dbg_mem_violation_buf <= ipe_dbg_mem_violation | bootcode_dbg_violation;

wire dma_violation_prev = dma_ready_dly & dma_violation_buf;

// Mux
assign          ext_mem_din      = dma_violation_prev ? 16'h3FFF     :
                                   (dbg_mem_violation_buf & ~dma_ready_dly) ?  16'h3FFF     : // since dbg_en is not used, we check here whether this is a response to a DMA request, and only return the violation value for DBG if it's a response to DBG
                                   ext_mem_din_sel[1] ? pmem_dout    :
                                   ext_mem_din_sel[0] ? per_dout_val : dmem_dout;


endmodule // omsp_mem_backbone

`ifdef OMSP_NO_INCLUDE
`else
`include "openMSP430_undefines.v"
`endif
