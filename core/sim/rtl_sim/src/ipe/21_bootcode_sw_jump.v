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

      /* checkpoint 2 */
      @(r12 == 16'hCAFE);
      @(posedge dut.exec_done); // wait for branch to complete

      if (nmi_detect !== 1)
        tb_error("====== NMI was not triggered ======");

      /* ----------------------  END OF TEST --------------- */
      @(r0==16'hFFFF);

      stimulus_done = 1;
   end
