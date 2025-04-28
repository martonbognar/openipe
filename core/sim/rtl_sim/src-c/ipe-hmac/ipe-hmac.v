reg [63:0] counter, tsc1, tsc2;

always @(posedge mclk or posedge puc_rst)
  if (puc_rst)     counter = 0;
  else  counter = counter + 1;

`define NO_TIMEOUT

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
      $fflush;
      @(negedge dut.ipe_bootcode_exec);
      $display("\t[OK]");
      //repeat(100) @(posedge mclk) $display("%s", msp_debug_0.inst_full);

      if (!dut.ipe.ipe_enabled)
         tb_error("====== IPE not enabled ======");

      $write("waiting for main function..     ");
      $fflush;
      @(r8==16'hDEAD);
      $display("\t[OK]");

      $write("waiting for IPE call..          ");
      $fflush;
      @(posedge dut.ipe.ipe_executing);
      $display("\t[OK]");
      tsc1 <= counter;
      repeat(5) @(posedge mclk);

      $write("waiting for IPE return..          ");
      $fflush;
      @(negedge dut.ipe.ipe_executing);
      tsc2 <= counter;
      $display("\t[OK]");

      @(r8);
      if (r8 === 8'b0)
         tb_error("====== HMAC didn't change ======");

      repeat(5) @(posedge mclk);
      $display("IPE took %d cycles", tsc2-tsc1);

      stimulus_done = 1;

      $display("");
      $display(" ===============================================");
      $display("|               SIMULATION DONE                 |");
      $display("|       (stopped through verilog stimulus)      |");
      $display(" ===============================================");
      $finish;
   end
