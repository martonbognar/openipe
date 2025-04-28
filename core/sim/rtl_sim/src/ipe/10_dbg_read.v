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

      dbg_uart_wr(MEM_ADDR, 16'h8000);  // select memory address
      dbg_uart_wr(MEM_CTL,  16'h0001);  // read memory
      dbg_uart_rd(MEM_DATA);            // read data
      if (dbg_uart_buf !== 16'd1337)  tb_error("====== incorrect cleartext read =====");

      repeat(10) @(posedge mclk);

      // READ CPU REGISTERS
      dbg_uart_wr(MEM_ADDR, 16'd15);  // select register
      dbg_uart_wr(MEM_CTL,  16'd0005);  // read register
      dbg_uart_rd(MEM_DATA);            // read data
      if (dbg_uart_buf !== 16'd1337)  tb_error("====== incorrect unprotected register read =====");

      /* checkpoint 2 */
      @(r12 == 16'hBEEF);

      dbg_uart_wr(MEM_ADDR, 16'h8002);  // select memory address
      dbg_uart_wr(MEM_CTL,  16'h0001);  // read memory
      dbg_uart_rd(MEM_DATA);            // read data
      if (dbg_uart_buf == 16'd1338)  tb_error("====== secret not protected =====");

      /* checkpoint 2 */
      @(r12 == 16'hDEAD);

      // READ CPU REGISTERS
      dbg_uart_wr(MEM_ADDR, 16'd10);  // select register
      dbg_uart_wr(MEM_CTL,  16'd0005);  // read register
      dbg_uart_rd(MEM_DATA);            // read data
      if (dbg_uart_buf == 16'd1338)  tb_error("====== register not protected =====");

      /* ----------------------  END OF TEST --------------- */
      @(r0==16'hFFFF);

      stimulus_done = 1;
`endif // TODO: i2c debug
   end
