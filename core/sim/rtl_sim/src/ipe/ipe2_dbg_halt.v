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
      repeat(200) @(posedge mclk);
      if (r14 !== 16'd42)       tb_error("====== did not halt normally =====");
      dbg_uart_wr(CPU_CTL,  16'h0002); // RUN

      /* checkpoint 2 */
      @(r12 == 16'hBEEF);

      dbg_uart_wr(CPU_CTL,  16'h0001);  // HALT
      repeat(200) @(posedge mclk);
      if (r14 !== 16'd0)       tb_error("====== halted during IPE =====");
      dbg_uart_wr(CPU_CTL,  16'h0002); // RUN

      /* ----------------------  END OF TEST --------------- */
      @(r0==16'hFFFF);

      stimulus_done = 1;
`endif // TODO: i2c debug
   end
