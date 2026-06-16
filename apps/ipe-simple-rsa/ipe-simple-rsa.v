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

      $write("waiting for IPE call..          ");
      @(dut.ipe.ipe_executing);
      $display("\t[OK]");

      $write("waiting for IPE return..          ");
      @(r8==16'hBEEF);
      $display("\t[OK]");

      if(r7 !== 16'd31)
         tb_error("Wrong cipher computed");


      $write("waiting to get plain text..          ");
      @(r8==16'hCACA);
      $display("\t[OK]");

      if(r7 !== 16'h4)
         tb_error("Wrong plain text computed");

      stimulus_done = 1;

      $display(" ===============================================");
      $display("|               SIMULATION DONE                 |");
      $display("|       (stopped through verilog stimulus)      |");
      $display(" ===============================================");

      $finish;
   end
