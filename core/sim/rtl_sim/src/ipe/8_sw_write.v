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
      if (mem200 !== 16'd42)
         tb_error("====== secret incorrectly set ======");


      /* ----------------------  END OF TEST --------------- */
      @(r0==16'hFFFF);
      if (mem200 !== 16'd42)
         tb_error("====== secret overwritten ======");

      stimulus_done = 1;
   end
