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

      if (bmem_0.mem[0] !== 16'h9382)
         tb_error("====== unexpected bootcode start value ======");
      dbg_uart_wr(MEM_ADDR, `BMEM_BASE);  // select register
      dbg_uart_wr(MEM_DATA, 16'd43);  // write data
      dbg_uart_wr(MEM_CTL,  16'h0003);  // write memory

      /* ----------------------  END OF TEST --------------- */
      @(r0==16'hFFFF);

      if (bmem_0.mem[0] !== 16'h9382)
         tb_error("====== bootcode overwritten ======");

      stimulus_done = 1;
`endif // TODO: i2c debug
   end
