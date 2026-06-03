wire [15:0] base = 16'd468;

initial
   begin
      $display("===============================================");
      $display("                 START SIMULATION             |");
      $display("===============================================");
      #10;


      repeat(5) @(posedge mclk);
      stimulus_done = 0;

      @(r12==16'hCAFE);

    
      $display("ivt jump 0 in ipe : %b", bmem_0.mem[base][7:0]);
      $display("ivt jump 1 in ipe : %b", bmem_0.mem[base][15:8]);
      $display("ivt jump 2 in ipe: %b", bmem_0.mem[base+1][7:0]);
      $display("ivt jump 3 in ipe: %b", bmem_0.mem[base+1][15:8]);
      $display("ivt jump 4 in ipe: %b", bmem_0.mem[base+2][7:0]);
      $display("ivt jump 5 in ipe: %b", bmem_0.mem[base+2][15:8]);
      $display("ivt jump 6 in ipe: %b", bmem_0.mem[base+3][7:0]);
      $display("ivt jump 7 in ipe: %b", bmem_0.mem[base+3][15:8]);
      $display("ivt jump 8 in ipe: %b", bmem_0.mem[base+4][7:0]);
      $display("ivt jump 9 in ipe: %b", bmem_0.mem[base+4][15:8]);
      $display("ivt jump 10 in ipe: %b", bmem_0.mem[base+5][7:0]);
      $display("ivt jump 11 in ipe: %b", bmem_0.mem[base+5][15:8]);
      $display("ivt jump 12 in ipe: %b", bmem_0.mem[base+6][7:0]);
      $display("ivt jump 13 in ipe: %b", bmem_0.mem[base+6][15:8]);
      $display("ivt jump 14 in ipe: %b", bmem_0.mem[base+7][7:0]);
      $display("ivt jump 15 in ipe: %b", bmem_0.mem[base+7][15:8]);

      $display("registered handlers for ipe 1: %b", bmem_0.mem[base+8]);
      $display("registered handlers for ipe 2: %b", bmem_0.mem[base+9]);
      $display("registered handlers for ipe 3: %b", bmem_0.mem[base+10]);
      $display("registered handlers for ipe 4: %b", bmem_0.mem[base+11]);

      
    




      if (bmem_0.mem[base][7:0] != 8'b00000010)
         tb_error("====== ipe handlers not correctly registered ======");
      if (bmem_0.mem[base][15:8] != 8'b00000001)
         tb_error("====== ipe handlers not correctly registered ======");
      if (bmem_0.mem[base+1][7:0] != 8'b00001000)
         tb_error("====== ipe handlers not correctly registered ======");
      if (bmem_0.mem[base+1][15:8] != 8'b00000010)
         tb_error("====== ipe handlers not correctly registered ======");
      if (bmem_0.mem[base+2][7:0] != 8'b00000001)
         tb_error("====== ipe handlers not correctly registered ======");
      if (bmem_0.mem[base+2][15:8] != 8'b00001000)
         tb_error("====== ipe handlers not correctly registered ======");
      if (bmem_0.mem[base+3][7:0] != 8'b00000100)
         tb_error("====== ipe handlers not correctly registered ======");
      if (bmem_0.mem[base+3][15:8] != 8'b00000001)
         tb_error("====== ipe handlers not correctly registered ======");
      if (bmem_0.mem[base+4][7:0] != 8'b00000000)
         tb_error("====== ipe handlers not correctly registered ======");
      if (bmem_0.mem[base+4][15:8] != 8'b00000100)
         tb_error("====== ipe handlers not correctly registered ======");
      if (bmem_0.mem[base+5][7:0] != 8'b00000001)
         tb_error("====== ipe handlers not correctly registered ======");
      if (bmem_0.mem[base+5][15:8] != 8'b00000000)
         tb_error("====== ipe handlers not correctly registered ======");
      if (bmem_0.mem[base+6][7:0] != 8'b00000100)
         tb_error("====== ipe handlers not correctly registered ======");
      if (bmem_0.mem[base+6][15:8] != 8'b00000010)
         tb_error("====== ipe handlers not correctly registered ======");
      if (bmem_0.mem[base+7][7:0] != 8'b00000000)
         tb_error("====== ipe handlers not correctly registered ======");
      if (bmem_0.mem[base+7][15:8] != 8'b00001000)
         tb_error("====== ipe handlers not correctly registered ======");



      
      /* ----------------------  END OF TEST --------------- */
      @(r0==16'hFFFF);
      
      stimulus_done = 1;
   end
