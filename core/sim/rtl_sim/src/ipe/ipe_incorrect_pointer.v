`define PMEM_BASE  ((16'hffff-`PMEM_SIZE+1))

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
      @(dut.execution_unit_0.mb_wr && dut.execution_unit_0.mab == `PMEM_BASE);
      repeat(2) @(posedge mclk);
      @(dut.execution_unit_0.mb_wr && dut.execution_unit_0.mab == `PMEM_BASE+2);

      repeat(2) @(posedge mclk);
      stimulus_done = 1;
      stimulus_kill = 1;
   end
