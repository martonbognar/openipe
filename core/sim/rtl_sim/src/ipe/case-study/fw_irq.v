integer counter, handler;
always @(posedge mclk or posedge puc_rst) begin
   if (puc_rst) counter <= 0;
   else counter <= counter + 1;
end

initial
   begin
      $display("===============================================");
      $display("                 START SIMULATION             |");
      $display("===============================================");
      #10;

      `ifndef SECURE_IRQ_FW
         tb_error("====== This test needs to be run with the SECURE_IRQ_FW macro in openMSP430_defines! ======");
         $finish;
      `endif

      repeat(5) @(posedge mclk);
      stimulus_done = 0;

      $display("waiting for unprotected Timer_A IRQ -> unprotected..");
      @(tb_openMSP430.dut.irq == 16'h0100); // untrusted handling of timer_a
      @(posedge tb_openMSP430.dut.ipe_bootcode_exec); // entering bootcode for handling

      $display("waiting for unprotected WDT IRQ -> IPE..");
      @(posedge tb_openMSP430.dut.wdt_irq); // wdt interrupt
      handler = counter;
      @(posedge tb_openMSP430.dut.ipe_bootcode_exec); // entering bootcode for handling
      @(posedge tb_openMSP430.dut.ipe_executing); // vectoring to IPE to handle WDT interrupt
      @(negedge tb_openMSP430.dut.ipe_executing); // reti to unprotected
      @(r2[3] == 1);
      $display("Total ISR took", counter - handler - 16, " cycles");

      $display("waiting for protected Timer_A IRQ -> unprotected..");
      @(posedge tb_openMSP430.dut.ipe_executing); // entering IPE normally
      @(tb_openMSP430.dut.irq == 16'h0100); // untrusted handling of timer_a
      handler = counter;
      @(posedge tb_openMSP430.dut.ipe_bootcode_exec); // entering bootcode for handling
      @(negedge tb_openMSP430.dut.ipe_executing); // vectoring outside to handle timer_a interrupt
      @(posedge tb_openMSP430.dut.ipe_executing); // returning from the ISR
      @(r2[3] == 1);
      $display("Total ISR took", counter - handler - 10, " cycles");

      $display("waiting for protected WDT IRQ -> IPE.. 1");
      @(posedge tb_openMSP430.dut.wdt_irq); // wdt interrupt
      $display("waiting for protected WDT IRQ -> IPE.. 1");
      @(posedge tb_openMSP430.dut.ipe_bootcode_exec); // entering bootcode for handling
      $display("waiting for protected WDT IRQ -> IPE.. 1");
      @(posedge tb_openMSP430.dut.ipe_executing); // entering IPE for handling

      /* ----------------------  END OF TEST --------------- */
      $display("waiting for end of test..");
      @(r0==16'hFFFF);

      stimulus_done = 1;
   end
