reg [63:0] counter, start1, start2, isr1, isr2, end1, end2;

always @(posedge mclk or posedge puc_rst)
  if (puc_rst) counter = 0;
  else         counter = counter + 1;

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

      @(r15 == 16'hcafe);
      start1 <= counter;
      @(r15 == 16'hbeef);
      isr1 <= counter;
      @(r15 == 16'hdead);
      end1 <= counter;

      @(r15 == 16'hcafe);
      start2 <= counter;
      @(r15 == 16'hbeef);
      isr2 <= counter;
      @(r15 == 16'hdead);
      end2 <= counter;

      if (isr1 - start1 != isr2 - start2)
         tb_error("Delay to ISR differs!");
      else
         $display("Matching delays to ISR (%d cycles)!", isr1 - start1);

      if (end1 - start1 != end2 - start2)
         tb_error("Total IRQ latency differs!");
      else
         $display("Matching total IRQ latencies (%d cycles)!", end1 - start1);

      /* ----------------------  END OF TEST --------------- */
      $display("waiting for end of test..");
      @(r0==16'hFFFF);

      stimulus_done = 1;
   end
