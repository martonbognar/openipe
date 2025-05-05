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

      /* checkpoint 1 */
      @(r12 == 16'hCAFE);

      if(ipc0 !== 16'h00E0)
         tb_error("====== IPE settings incorrectly set ======");
      if(segb2 !== 16'h0480)
         tb_error("====== IPE SEGB2 incorrectly set ======");
      if(segb1 !== 16'h0440)
         tb_error("====== IPE SEGB1 incorrectly set ======");

      /* ----------------------  END OF TEST --------------- */
      @(r15==16'h1234);

      if(ipc0 !== 16'h00E0)
         tb_error("====== IPE settings modified ======");
      if(segb2 !== 16'h0480)
         tb_error("====== IPE SEGB2 modified ======");
      if(segb1 !== 16'h0440)
         tb_error("====== IPE SEGB1 modified ======");

      stimulus_done = 1;
   end
