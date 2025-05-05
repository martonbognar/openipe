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

      if (bmem_0.mem[0] !== 16'h9382)
         tb_error("====== unexpected bootcode start value ======");

      dma_write_16b(`BMEM_BASE, 16'd42, 1'b1);

      /* ----------------------  END OF TEST --------------- */
      @(r0==16'hFFFF);

      if (bmem_0.mem[0] !== 16'h9382)
         tb_error("====== bootcode overwritten ======");

      stimulus_done = 1;
   end
