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

      @(posedge nmi_detect);

      /* ----------------------  END OF TEST --------------- */
      @(r0==16'hFFFF || r0==16'h0000);

      if (r15 !== 16'h0)
        tb_error("====== ilegal instruction executed ======");

      stimulus_done = 1;
      stimulus_kill = 1;
   end
