wire [15:0] ipc0 = dut.ipe.MPUIPC0;
wire [15:0] segb2 = dut.ipe.MPUIPSEGB2;
wire [15:0] segb1 = dut.ipe.MPUIPSEGB1;

initial
   begin
      $display("===============================================");
      $display("                 START SIMULATION             |");
      $display("===============================================");
      #10;

      repeat(5) @(posedge mclk);
      stimulus_done = 0;

      $display("waiting for first reset..");
      @(r12==16'hCAFE); // first reset

      if(ipc0 !== 16'h0040)
         tb_error("====== IPE settings incorrectly set ======");
      if(segb2 !== 16'h0480)
         tb_error("====== IPE SEGB2 incorrectly set ======");
      if(segb1 !== 16'h0440)
         tb_error("====== IPE SEGB1 incorrectly set ======");

      $display("waiting for second reset..");
      @(posedge puc_rst);
      @(r12==16'hdead);

      if(ipc0 !== 16'h0040)
         tb_error("====== IPE settings overwritten ======");
      if(segb2 !== 16'h0480)
         tb_error("====== IPE SEGB2 overwritten ======");
      if(segb1 !== 16'h0440)
         tb_error("====== IPE SEGB1 overwritten ======");

      stimulus_done = 1;
   end
