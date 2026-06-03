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
      if (r10 != 16'h42)
         tb_error("====== Parent and Child not set up correctly ======");

      @(r12 == 16'hBEEF);
      if (r10 != 16'h3FFF)
         tb_error("====== Child accessing Parent memory is not allowed ======");


      /* ----------------------  END OF TEST --------------- */
      @(r0==16'hFFFF);
  
      stimulus_done = 1;
   end
