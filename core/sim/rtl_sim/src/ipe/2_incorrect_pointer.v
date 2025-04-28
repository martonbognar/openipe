initial
   begin
      $display("===============================================");
      $display("                 START SIMULATION             |");
      $display("===============================================");
      #10;

      repeat(5) @(posedge mclk);
      stimulus_done = 0;

      $display("Waiting for mass erase loop...");

      /* ----------------------  END OF TEST --------------- */
      @(dut.execution_unit_0.mb_wr && dut.execution_unit_0.mab == 0);  // TODO: what does this check?
      @(dut.execution_unit_0.mb_wr && dut.execution_unit_0.mab == 2);

      stimulus_done = 1;
      stimulus_kill = 1;
   end
