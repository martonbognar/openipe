`define LONG_TIMEOUT

`define IPE_ENTRY_START 16'h8008
`define IPE_ENTRY_END 16'h805C

`define IPE_OCALL_START 16'h805c
`define IPE_OCALL_END 16'h8094

`define OCALL_STUB_START 16'h80AC
`define OCALL_STUB_END 16'h80C0

`define IPE_OCALL_CONT_START 16'h5C92
`define IPE_OCALL_CONT_END 16'h5C98

`define ECALL_RET_START 16'h5C98
`define ECALL_RET_END 16'h5C9A

`define ECALL_STUB_START 16'h5C86
`define ECALL_STUB_END 16'h5C92

integer ipe_entry_1, ipe_ocall_1, ocall_stub_1, ipe_ocall_cont_1, ecall_ret_1, ecall_stub_1;

always @(posedge mclk or posedge puc_rst) begin
   if (puc_rst) ipe_entry_1 <= 0;
   else if (inst_pc >= `IPE_ENTRY_START && inst_pc < `IPE_ENTRY_END) ipe_entry_1 <= ipe_entry_1 + 1;
end

always @(posedge mclk or posedge puc_rst) begin
   if (puc_rst) ipe_ocall_1 <= 0;
   else if (inst_pc >= `IPE_OCALL_START && inst_pc < `IPE_OCALL_END) ipe_ocall_1 <= ipe_ocall_1 + 1;
end

always @(posedge mclk or posedge puc_rst) begin
   if (puc_rst) ocall_stub_1 <= 0;
   else if (inst_pc >= `OCALL_STUB_START && inst_pc < `OCALL_STUB_END) ocall_stub_1 <= ocall_stub_1 + 1;
end

always @(posedge mclk or posedge puc_rst) begin
   if (puc_rst) ipe_ocall_cont_1 <= 0;
   else if (inst_pc >= `IPE_OCALL_CONT_START && inst_pc < `IPE_OCALL_CONT_END) ipe_ocall_cont_1 <= ipe_ocall_cont_1 + 1;
end

always @(posedge mclk or posedge puc_rst) begin
   if (puc_rst) ecall_ret_1 <= 0;
   else if (inst_pc >= `ECALL_RET_START && inst_pc < `ECALL_RET_END) ecall_ret_1 <= ecall_ret_1 + 1;
end

always @(posedge mclk or posedge puc_rst) begin
   if (puc_rst) ecall_stub_1 <= 0;
   else if (inst_pc >= `ECALL_STUB_START && inst_pc < `ECALL_STUB_END) ecall_stub_1 <= ecall_stub_1 + 1;
end

initial
   begin
      $display(" ===============================================");
      $display("|                 START SIMULATION              |");
      $display(" ===============================================");
      // Disable automatic DMA verification
      #10;
      dma_verif_on = 0;

      repeat(5) @(posedge mclk);
      stimulus_done = 0;

      //---------------------------------------
      // Generate stimulus
      //---------------------------------------

      $write("waiting for bootcode to finish..");
      @(negedge dut.ipe_bootcode_exec);
      $display("\t[OK]");
      //repeat(100) @(posedge mclk) $display("%s", msp_debug_0.inst_full);

      if (!dut.ipe.ipe_enabled)
         tb_error("====== IPE not enabled ======");

      $write("waiting for main function..     ");
      @(r8==16'hDEAD);
      $display("\t[OK]");

      $write("waiting for IPE mem access..    ");
      @(r8==16'h3FFF);
      $display("\t[OK]");

      $write("waiting for IPE call..          ");
      @(dut.ipe.ipe_executing);
      $display("\t[OK]");

      @(r8==16'h0);
      repeat(100) @(posedge mclk);

      $write("waiting for IPE result..        ");
      @(r8==16'hABD0);
      $display("\t[OK]");

      stimulus_done = 1;

      $display(" ===============================================");
      $display("|               SIMULATION DONE                 |");
      $display("|       (stopped through verilog stimulus)      |");
      $display(" ===============================================");

      $display(" ===============================================");
      $display("|  Debug information for overhead measurement   |");
      $display("|   WARNING! Depends on hardcoded addresses!    |");
      $display(" ===============================================");

      $display("Size of IPE_ENTRY:\t",      `IPE_ENTRY_END - `IPE_ENTRY_START,           " time: ", ipe_entry_1);
      $display("Size of IPE_OCALL:\t",      `IPE_OCALL_END - `IPE_OCALL_START,           " time: ", ipe_ocall_1);
      $display("Size of OCALL_STUB:\t",     `OCALL_STUB_END - `OCALL_STUB_START,         " time: ", ocall_stub_1);
      $display("Size of IPE_OCALL_CONT:\t", `IPE_OCALL_CONT_END - `IPE_OCALL_CONT_START, " time: ", ipe_ocall_cont_1);
      $display("Size of ECALL_RET:\t",      `ECALL_RET_END - `ECALL_RET_START,           " time: ", ecall_ret_1);
      $display("Size of ECALL_STUB:\t",     `ECALL_STUB_END - `ECALL_STUB_START,         " time: ", ecall_stub_1);

      $finish;
   end
