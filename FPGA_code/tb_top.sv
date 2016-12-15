//-----------------------------------//
// Title:   tb_top.sv
// Author:  Robert Walczak
// Date:    17.08.2016
//-----------------------------------//
`timescale 1ns/100ps

import system_parameters::*;

module tb_top();
parameter TEST_VECTOR_LENGTH = 32;
reg                              clk;
reg                              rst;
reg                              syncTo10ms;
reg [INPUT_DATA_BITWIDTH-1:0]    inData;
reg                              inValid;

reg                              outValid;
reg                              outUser;
reg                              ready;
reg [INPUT_DATA_BITWIDTH-1:0]    outData;

integer                              clkTicksCounter = 0;

initial begin
   clk = 1'b0;
   rst = 1'b0;
   syncTo10ms = 1'b0;
   inData = 32'h0000_0000;
   inValid = 1'b0;
end

// clk
always begin
   #50
   clk = ~clk;
end

// 10 ms tick
always@(posedge clk) begin
   if(clkTicksCounter < 10)begin
      syncTo10ms <= 1'b0;
      clkTicksCounter++;
   end
   else begin 
      syncTo10ms <= 1'b1;
      clkTicksCounter <= 0;
   end
end

integer fileid;
integer fileHandler;
integer sample = 0;
reg[1:0][INPUT_DATA_BITWIDTH-1:0] testVector [TEST_VECTOR_LENGTH-1:0];
shortreal tempSampleI;
shortreal tempSampleQ;

initial begin
   $display("Opening file.");
   fileid = $fopen("LteTestVector_short.txt", "r");
   if(fileid == 0)begin
      $display("ERROR : CAN'T OPEN THE FILE OR FILE DOESN'T EXIST!");
      $finish;
   end
   while(!$feof(fileid)) begin
      $display(sample);
      // zczytać do temp floata, przemnożyć i przypisać gdzie trzeba
      fileHandler = $fscanf(fileid, "%f   %f\n", tempSampleQ, tempSampleI);
      testVector[sample][1] = tempSampleQ*1e6;
      testVector[sample][0] = tempSampleI*1e6;
      sample++;
      if(sample > 40)begin
         $finish;
      end
   end
   $fclose(fileid);
   $display("File closed.");
end

integer sentTestSamples = 0;
always@(posedge clk)begin
   inValid <= 1'b1;
   if(sentTestSamples < TEST_VECTOR_LENGTH)begin
      inData <= {testVector[sentTestSamples][1],testVector[sentTestSamples][0]};
      sentTestSamples <= sentTestSamples + 1;
   end
   else begin
      $finish;
   end
end

top top
(
   .clk(clk),
   .rst(rst),
   .syncTo10ms(syncTo10ms),
   .inData(inData),
   .inValid(inValid),
   .outValid(outValid),
   .outUser(outUser),
   .ready(ready),
   .outData(outData)
);

endmodule
   