`define VERY_LONG_TIMEOUT

integer count = 0;

initial
   begin
      $display(" ===============================================");
      $display("|                 START SIMULATION              |");
      $display(" ===============================================");
      // Disable automatic DMA verification
      #10;
      dma_verif_on = 0;


      `ifndef SECURE_IRQ_FW
         tb_error("====== This test needs to be run with the SECURE_IRQ_FW macro in openMSP430_defines! ======");
         $finish;
      `endif

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

      $write("waiting for ssteper initialisation..");
      @(r8==16'hCACA);
      $display("\t[OK]");

      
      while(r8!==16'hBEEF)
         begin
            count = count + 1;
            //$write("Waiting for IRQ %d", count);
            $write("Waiting for IRQ");
            @(tb_openMSP430.dut.irq == 16'h0100 || r8=== 16'hBEEF);
            $display("\t[OK]");

            $write("waiting for the mesure          ");
            wait(r12==16'hCACB || r8 == 16'hBEEF);

            if(r8 !== 16'hBEEF)
               begin
                  $display("\t[OK]");
                  if(r11 > 7 && r12 == 0)
                     $display("SSTEP latency is too small");
                  else 
                     $display("Time of the interrupted instr: %d", r11);
               end
            else 
               begin
                  $display("Value of r7: %b", r7);
                  $display("\t[OK]");
               end
         end

      stimulus_done = 1;

      $display(" ===============================================");
      $display("|               SIMULATION DONE                 |");
      $display("|       (stopped through verilog stimulus)      |");
      $display(" ===============================================");

      $finish;
   end
