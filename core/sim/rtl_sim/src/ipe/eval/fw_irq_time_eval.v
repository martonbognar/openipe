wire [15:0] ipc0 = dut.ipe.MPUIPC0;
wire [15:0] segb2 = dut.ipe.MPUIPSEGB2;
wire [15:0] segb1 = dut.ipe.MPUIPSEGB1;
wire [15:0] op1 = dut.multiplier_0.op1;
wire [15:0] op2 = dut.multiplier_0.op2;
wire [15:0] inst_fw = dut.fe_mdb_in;
reg [63:0] counter, start1, end1start2, end2start3, end3start4, end4start5, end5start6, end6, end2;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst) counter = 0;
  else         counter = counter + 1;

initial
   begin
      $display("===============================================");
      $display("                 START SIMULATION             |");
      $display("===============================================");
      #10;

      repeat(5) @(posedge mclk);
      stimulus_done = 0;

      @(r0==16'h3800)
      start1 <= counter;
      wait(inst_fw==16'h2482)
      end1start2 <= counter;
      wait(inst_fw==16'h2420)
      end2start3 <= counter;
      wait(inst_fw==16'h430B)
      end3start4 <= counter;
      wait(inst_fw==16'h403A)
      end4start5 <= counter;
      @(r0==16'h3BFC)
      end6 <= counter;
      /* ----------------------  END OF TEST --------------- */
      @(r0==16'hFFFF);
      $display("Latency of total ordening bootcode (%d cycles)!", end6 - start1);
      $display("Latency of checking structs (%d cycles)!", end1start2 - start1);
      $display("Latency of checking borders (%d cycles)!", end2start3 - end1start2);
      $display("Latency of overlap checking (%d cycles)!", end3start4 - end2start3);
      $display("Latency of evaluating structs (%d cycles)!", end4start5 - end3start4);
      $display("Latency of registering isrs (%d cycles)!", end6 - end4start5);




      
      stimulus_done = 1;
   end

