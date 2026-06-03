wire [15:0] ipc0 = dut.ipe.MPUIPC0;
wire [15:0] segb2 = dut.ipe.MPUIPSEGB2;
wire [15:0] segb1 = dut.ipe.MPUIPSEGB1;
wire [15:0] ip2c0 = dut.ipe.MPUIP2C0;
wire [15:0] seg2b2 = dut.ipe.MPUIP2SEGB2;
wire [15:0] seg2b1 = dut.ipe.MPUIP2SEGB1;
`define PMEM_BASE  ((16'hffff-`PMEM_SIZE+1))
initial
   begin
      $display("===============================================");
      $display("                 START SIMULATION             |");
      $display("===============================================");
      #10;

      repeat(5) @(posedge mclk);
      stimulus_done = 0;

      /* ----------------------  END OF TEST --------------- */
      @(dut.execution_unit_0.mb_wr && dut.execution_unit_0.mab == `PMEM_BASE);
      repeat(2) @(posedge mclk);
      @(dut.execution_unit_0.mb_wr && dut.execution_unit_0.mab == `PMEM_BASE+2);

      repeat(2) @(posedge mclk);

      stimulus_done = 1;
      stimulus_kill = 1;
   end
