initial
   begin
      $display(" ===============================================");
      $display("|                 START SIMULATION              |");
      $display(" ===============================================");


`ifdef DBG_UART
      #1 dbg_en = 1;

      repeat(10) @(posedge mclk);
      stimulus_done = 0;

      // SEND UART SYNCHRONIZATION FRAME
      dbg_uart_tx(DBG_SYNC);

      repeat(200) @(posedge mclk);

      if (dut.ipe_bootcode_exec)
         tb_error("====== halted before bootcode finished =====");

    `ifdef DBG_RST_BRK_EN
      dbg_uart_wr(CPU_CTL,  16'h0002);  // RUN
   `endif

      /* checkpoint 1 */
      @(r12 == 16'hCAFE);

      dbg_uart_wr(CPU_CTL,  16'h0001);  // HALT

      // WRITE CPU REGISTERS
      dbg_uart_wr(MEM_ADDR, 16'd12);  // select register
      dbg_uart_wr(MEM_DATA, 16'd42);  // write data
      dbg_uart_wr(MEM_CTL,  16'h0007);  // write register
      repeat(20) @(posedge mclk);
      if (r12 != 16'd42)  tb_error("====== could not write register normally =====");

      repeat(200) @(posedge mclk);
      if (r14 !== 16'd42)       tb_error("====== did not halt normally =====");
      dbg_uart_wr(CPU_CTL,  16'h0002); // RUN

      /* checkpoint 2 */
      @(r12 == 16'hBEEF);

      dbg_uart_wr(CPU_CTL,  16'h0001);  // HALT
      if (~dut.ipe_bootcode_exec)       tb_error("====== halt attempt did not hit firmware =====");

      // WRITE CPU REGISTERS
      dbg_uart_wr(MEM_ADDR, 16'd12);  // select register
      dbg_uart_wr(MEM_DATA, 16'd42);  // write data
      dbg_uart_wr(MEM_CTL,  16'h0007);  // write register

      repeat(200) @(posedge mclk);
      if (dut.ipe_bootcode_exec)       tb_error("====== halted during firmware =====");
      dbg_uart_wr(CPU_CTL,  16'h0002); // RUN

      /* ----------------------  END OF TEST --------------- */
      @(r0==16'hFFFF);
      if (r15 == 16'd42)  tb_error("====== register not protected =====");

      stimulus_done = 1;
`endif // TODO: i2c debug
   end
