
reg [15:0] bmem_base = `BMEM_BASE;
reg [15:0] bmem_index; 
initial
   begin
      $display("===============================================");
      $display("                 START SIMULATION             |");
      $display("===============================================");
      #10;


      repeat(5) @(posedge mclk);
      stimulus_done = 0;

   /*
      @(r0==16'h385a);
      bmem_index = (r10 - bmem_base) >> 1;
      $display("struct 1 address is %x", bmem_0.mem[bmem_index]);
      $display("struct 2 address is %x", bmem_0.mem[bmem_index+1]);
      $display("struct 3 address is %x", bmem_0.mem[bmem_index+2]);
      $display("struct 4 address is %x", bmem_0.mem[bmem_index+3]);
     */ 

      @(r0==16'h38e0);
      bmem_index = (r10 - bmem_base) >> 1;

      if (bmem_0.mem[bmem_index] != 16'h8000)
         tb_error("====== Address pointers not correctly ordered ======");
      if (bmem_0.mem[bmem_index+1] != 16'h8400) 
         tb_error("====== Address pointers not correctly ordered ======");
      if (bmem_0.mem[bmem_index+2] != 16'h8800)
         tb_error("====== Address pointers not correctly ordered ======");
      if (bmem_0.mem[bmem_index+3] != 16'h8C00)
         tb_error("====== Address pointers not correctly ordered ======");

      $display("ordered struct 1 address is %x", bmem_0.mem[bmem_index]);
      $display("ordered struct 2 address is %x", bmem_0.mem[bmem_index+1]);
      $display("ordered struct 3 address is %x", bmem_0.mem[bmem_index+2]);
      $display("ordered struct 4 address is %x", bmem_0.mem[bmem_index+3]);

      
      /* ----------------------  END OF TEST --------------- */
      @(r0==16'hFFFF);
      
      stimulus_done = 1;
   end
