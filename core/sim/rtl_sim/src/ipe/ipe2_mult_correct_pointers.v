wire [15:0] ipc0 = dut.ipe.MPUIPC0;
wire [15:0] segb2 = dut.ipe.MPUIPSEGB2;
wire [15:0] segb1 = dut.ipe.MPUIPSEGB1;
wire [15:0] ip2c0 = dut.ipe.MPUIP2C0;
wire [15:0] seg2b2 = dut.ipe.MPUIP2SEGB2;
wire [15:0] seg2b1 = dut.ipe.MPUIP2SEGB1;
wire [15:0] ip3c0 = dut.ipe.MPUIP3C0;
wire [15:0] seg3b2 = dut.ipe.MPUIP3SEGB2;
wire [15:0] seg3b1 = dut.ipe.MPUIP3SEGB1;
wire [15:0] ip4c0 = dut.ipe.MPUIP4C0;
wire [15:0] seg4b2 = dut.ipe.MPUIP4SEGB2;
wire [15:0] seg4b1 = dut.ipe.MPUIP4SEGB1;

initial
   begin
      $display("===============================================");
      $display("                 START SIMULATION             |");
      $display("===============================================");
      #10;

      repeat(5) @(posedge mclk);
      stimulus_done = 0;

      /* ----------------------  END OF TEST --------------- */
      @(r0==16'hFFFF);

      if(ipc0 !== 16'h00E0)
         tb_error("====== IPE settings incorrectly set ======");
      if(segb2 !== 16'h0840)
	     tb_error("====== IPE SEGB2 incorrectly set ======");
      if(segb1 !== 16'h0800)
	    tb_error("====== IPE SEGB1 incorrectly set ======");
      if(ip2c0 !== 16'h00E0)
         tb_error("====== IPE2 settings incorrectly set ======");
      if(seg2b2 !== 16'h0880)
	     tb_error("====== IPE2 SEGB2 incorrectly set ======");
      if(seg2b1 !== 16'h0840)
	    tb_error("====== IPE2 SEGB1 incorrectly set ======");
      if(ip3c0 !== 16'h00E0)
         tb_error("====== IPE3 settings incorrectly set ======");
      if(seg3b2 !== 16'h08C0)
	     tb_error("====== IPE3 SEGB2 incorrectly set ======");
      if(seg3b1 !== 16'h0880)
	    tb_error("====== IPE3 SEGB1 incorrectly set ======");
      if(ip4c0 !== 16'h00E0)
         tb_error("====== IPE4 settings incorrectly set ======");
      if(seg4b2 !== 16'h0900)
	     tb_error("====== IPE4 SEGB2 incorrectly set ======");
      if(seg4b1 !== 16'h08C0)
	    tb_error("====== IPE4 SEGB1 incorrectly set ======");

      stimulus_done = 1;
   end
