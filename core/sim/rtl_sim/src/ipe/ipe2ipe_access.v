wire [15:0] ipc0 = dut.ipe.MPUIPC0;
wire [15:0] segb2 = dut.ipe.MPUIPSEGB2;
wire [15:0] segb1 = dut.ipe.MPUIPSEGB1;

initial
   begin
      $display("===============================================");
      $display("                 START SIMULATION             |");
      $display("===============================================");
      #10;

      repeat(5) @(posedge mclk);
      stimulus_done = 0;

      /* checkpoint 1 */
      @(r10==16'hCAFE);

      if (r12 !== 16'd43)
         tb_error("====== secret not accessible from inside ======");     

      if (r13 !== 16'h3FFF)
         tb_error("====== secret not protected ======");
      
      if (r14 !== 16'h3FFF)
         tb_error("====== secret not protected ======");

      if (r15 !== 16'h3FFF)
         tb_error("====== secret not protected ======");

      /* checkpoint 2 */
      @(r10==16'hBEEF);

      if (r12 !== 16'h3FFF)
         tb_error("====== secret not protected ======");    

      if (r13 !== 16'd53)
         tb_error("====== secret not accessible from inside ======"); 
         
      if (r14 !== 16'h3FFF)
         tb_error("====== secret not protected ======");

      if (r15 !== 16'h3FFF)
         tb_error("====== secret not protected ======");

      /* checkpoint 3 */
      @(r10==16'hDEAD);

      if (r12 !== 16'h3FFF)
         tb_error("====== secret not protected ======");

      if (r13 !== 16'h3FFF)
         tb_error("====== secret not protected ======");
      
      if (r14 !== 16'd63)
         tb_error("====== secret not accessible from inside ======");

      if (r15 !== 16'h3FFF)
         tb_error("====== secret not protected ======");

      
      /* ----------------------  END OF TEST --------------- */
      @(r0==16'hFFFF);

      if (r12 !== 16'h3FFF)
         tb_error("====== secret not protected ======");

      if (r13 !== 16'h3FFF)
         tb_error("====== secret not protected ======");
      
      if (r14 !== 16'h3FFF)
         tb_error("====== secret not protected ======");

      if (r15 !== 16'd73)
         tb_error("====== secret not accessible from inside ======");

      stimulus_done = 1;
   end
