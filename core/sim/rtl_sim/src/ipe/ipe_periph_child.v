wire [15:0] ipc0 = dut.ipe.MPUIPC0;
wire [15:0] segb2 = dut.ipe.MPUIPSEGB2;
wire [15:0] segb1 = dut.ipe.MPUIPSEGB1;
wire [15:0] op1 = dut.multiplier_0.op1;
wire [15:0] op2 = dut.multiplier_0.op2;
reg [63:0] counter, start1, end1start2, end2start3, end3start4, end4start5, end5start6, end6;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst) counter = 0;
  else         counter = counter + 1;

initial
   begin
      $display("===============================================");
      $display("                 START SIMULATION             |");
      $display("===============================================");
      #10;

      repeat(5) @(posedge mclk);
      stimulus_done = 0;
      @(r12 == 16'hCAFE);
      if (op1 != 16'h8)
         tb_error("====== Writing incorrectly to Multiplier peripheral ======");
      if (op2 != 16'h9)
         tb_error("====== Writing incorrectly to Multiplier peripheral ======");
      if (r10 != 16'h48)
         tb_error("====== Writing incorrectly to Multiplier peripheral ======");

       @(r12 == 16'hBEEF);
      if (op1 != 16'h8)
         tb_error("====== Writing to Multiplier peripheral not allowed ======");
      if (op2 != 16'h9)
         tb_error("====== Writing to Multiplier peripheral not allowed ======");
      if (r10 != 16'h3FFF)
         tb_error("====== Writing to Multiplier peripheral not allowed ======");     

      /* ----------------------  END OF TEST --------------- */
      @(r0==16'hFFFF);
      if (op1 != 16'h8)
         tb_error("====== Writing to Multiplier peripheral not allowed ======");
      if (op2 != 16'h9)
         tb_error("====== Writing to Multiplier peripheral not allowed ======");
      if (r10 != 16'h3FFF)
         tb_error("====== Writing to Multiplier peripheral not allowed ======"); 

      
      stimulus_done = 1;
   end
