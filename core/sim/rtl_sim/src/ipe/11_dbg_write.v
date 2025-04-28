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

    `ifdef DBG_RST_BRK_EN
      dbg_uart_wr(CPU_CTL,  16'h0002);  // RUN
   `endif

      /* checkpoint 1 */
      @(r12 == 16'hCAFE);

      dbg_uart_wr(MEM_ADDR, 16'h8000);  // select register
      dbg_uart_wr(MEM_DATA, 16'd43);  // write data
      dbg_uart_wr(MEM_CTL,  16'h0003);  // write memory

      repeat(10) @(posedge mclk);

      // WRITE CPU REGISTERS
      dbg_uart_wr(MEM_ADDR, 16'd15);  // select register
      dbg_uart_wr(MEM_DATA, 16'd42);  // write data
      dbg_uart_wr(MEM_CTL,  16'h0007);  // write register
      repeat(20) @(posedge mclk);
      if (r15 !== 16'd42)  tb_error("====== cannot write public =====");

      /* checkpoint 2 */
      @(r12 == 16'hBEEF);

      if (r15 !== 16'd43)
         tb_error("====== secret not written ======");

      dbg_uart_wr(MEM_ADDR, 16'h8000);  // select register
      dbg_uart_wr(MEM_DATA, 16'd42);  // write data
      dbg_uart_wr(MEM_CTL,  16'h0003);  // write memory

      /* checkpoint 2 */
      @(r12 == 16'hDEAD);

      // WRITE CPU REGISTERS
      dbg_uart_wr(MEM_ADDR, 16'd10);  // select register
      dbg_uart_wr(MEM_DATA, 16'd42);  // write data
      dbg_uart_wr(MEM_CTL,  16'h0007);  // write register
      repeat(20) @(posedge mclk);
      if (r10 == 16'd42)  tb_error("====== register not protected =====");

      /* ----------------------  END OF TEST --------------- */
      @(r0==16'hFFFF);

      if (r15 !== 16'd43)
         tb_error("====== protected secret overwritten ======");

      stimulus_done = 1;
`endif // TODO: i2c debug
   end
