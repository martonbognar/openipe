
initial
   begin
      $display("===============================================");
      $display("                 START SIMULATION             |");
      $display("===============================================");
      #10;

      repeat(5) @(posedge mclk);
      stimulus_done = 0;

      /* checkpoint 1 */
      @(r12 == 16'hCAFE);
      if (bmem_0.mem[0] !== 16'h9382)
         tb_error("====== unexpected bootcode start value ======");


      /* ----------------------  END OF TEST --------------- */
      @(r0==16'hFFFF);
      if (bmem_0.mem[0] !== 16'h9382)
         tb_error("====== bootcode overwritten ======");

      stimulus_done = 1;
   end
