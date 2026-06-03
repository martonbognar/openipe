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

      $display("waiting for unprotected WDT IRQ -> IPE..");
      @(posedge tb_openMSP430.dut.wdt_irq); // wdt interrupt
      handler = counter;
      @(posedge tb_openMSP430.dut.ipe_bootcode_exec); // entering bootcode for handling
      @(posedge (tb_openMSP430.dut.ipe_executing[0])); // vectoring to IPE 1 to handle WDT interrupt
      @(negedge (tb_openMSP430.dut.ipe_executing[0])); // reti to unprotected
      @(r2[3] == 1);
      $display("Total ISR took", counter - handler - 16, " cycles");

      $display("waiting for unprotected Timer_A IRQ -> IPE..");
      @(posedge tb_openMSP430.irq_ta1); // timer interrupt
      handler = counter;
      @(posedge tb_openMSP430.dut.ipe_bootcode_exec); // entering bootcode for handling
      @(posedge (tb_openMSP430.dut.ipe_executing[1])); // vectoring to IPE 2 to handle timer interrupt
      @(negedge (tb_openMSP430.dut.ipe_executing[1])); // reti to unprotected
      @(r2[3] == 1);
      $display("Total ISR took", counter - handler - 16, " cycles");


      /* ----------------------  END OF TEST --------------- */
      $display("waiting for end of test..");
      @(r0==16'hFFFF);

      stimulus_done = 1;
   end
