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
      if (r15!==16'h3FFF)
         tb_error("====== secret not protected ======");
      if (r14!==16'd43)
         tb_error("====== secret2 incorrect ======");

      /* checkpoint 2 */
      @(r12 == 16'hBEEF);
      if (r15!==16'h0000)
         tb_error("====== secret incorrect ======");
      if (r14!==16'h3FFF)
         tb_error("====== secret2 not protected ======");

      /* ----------------------  END OF TEST --------------- */
      @(r0==16'hFFFF);

      stimulus_done = 1;
   end
