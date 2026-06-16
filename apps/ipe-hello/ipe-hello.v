`define LONG_TIMEOUT

initial
   begin
      $display(" ===============================================");
      $display("|                 START SIMULATION              |");
      $display(" ===============================================");
      // Disable automatic DMA verification
      #10;
      dma_verif_on = 0;

      repeat(5) @(posedge mclk);
      stimulus_done = 0;

      //---------------------------------------
      // Generate stimulus
      //---------------------------------------

      $write("waiting for bootcode to finish..");
      @(negedge dut.ipe_bootcode_exec);
      $display("\t[OK]");
      //repeat(100) @(posedge mclk) $display("%s", msp_debug_0.inst_full);

      if (!dut.ipe.ipe_enabled)
         tb_error("====== IPE not enabled ======");

      $write("waiting for main function..     ");
      @(r8==16'hDEAD);
      $display("\t[OK]");

      $write("waiting for IPE mem access..    ");
      @(r8==16'h3FFF);
      $display("\t[OK]");

      $write("waiting for IPE call..          ");
      @(dut.ipe.ipe_executing);
      $display("\t[OK]");

      @(r8==16'h0);
      repeat(100) @(posedge mclk);

      $write("waiting for IPE result 1..        ");
      @(r9==16'hCACA);
      $display("\t[OK]");
      if(r8 !== 16'hABCD)
         $error("Error while running ipe_func");

      $write("waiting for IPE result 2..        ");
      @(r9==16'hCACB);
      $display("\t[OK]");
      if(r8 !== 16'h2)
         $error("Error while running ipe_func");

      stimulus_done = 1;

      $display(" ===============================================");
      $display("|               SIMULATION DONE                 |");
      $display("|       (stopped through verilog stimulus)      |");
      $display(" ===============================================");

      $finish;
   end
