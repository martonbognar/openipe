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

      /* ----------------------  END OF TEST --------------- */
      @(r0==16'hFFFF);

      if (r14 !== 16'd42)
         tb_error("====== secret not protected ======");

      if (r15 == 16'd0)
         tb_error("====== stack wrong offset ======");

      stimulus_done = 1;
   end
