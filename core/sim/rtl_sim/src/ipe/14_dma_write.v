initial
   begin
      $display(" ===============================================");
      $display("|                 START SIMULATION              |");
      $display(" ===============================================");
      // Disable automatic DMA verification
      #10;
      dma_verif_on = 0;
      dma_priority=0;

      repeat(5) @(posedge mclk);
      stimulus_done = 0;

      /* checkpoint 1 */
      @(r12 == 16'hCAFE);

      dma_write_16b(`DMEM_BASE, 16'd43, 1'b0);

      /* checkpoint 2 */
      @(r12 == 16'hBEEF);

      if (r15 !== 16'd43)
         tb_error("====== secret not written ======");

      dma_write_16b(`DMEM_BASE, 16'd42, 1'b1);

      /* ----------------------  END OF TEST --------------- */
      @(r0==16'hFFFF);

      if (r15 !== 16'd43)
         tb_error("====== protected secret overwritten ======");

      stimulus_done = 1;
   end
