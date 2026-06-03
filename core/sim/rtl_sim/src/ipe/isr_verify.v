wire [15:0] base = 16'd468;

initial
   begin
      $display("===============================================");
      $display("                 START SIMULATION             |");
      $display("===============================================");
      #10;


      repeat(5) @(posedge mclk);
      stimulus_done = 0;


      @(r12==16'hBEEF);
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
      
      @(r12==16'hCAFE);
      $display("registered?: %x", r9);

      if (r9 != 16'h1)
               tb_error("====== ipe handler not correctly verified ======");





      
      /* ----------------------  END OF TEST --------------- */
      @(r0==16'hFFFF);
      
      stimulus_done = 1;
   end
