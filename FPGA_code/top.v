//-----------------------------------//
// Title:   top.v
// Author: 	Robert Walczak
// Date:	   17.08.2016
//-----------------------------------//
import system_parameters;

module top
(
   // wejścia
   input    reg                              clk,
   input    reg                              rst,
   input    reg                              syncTo10ms,
   input    reg [INPUT_DATA_BITWIDTH-1:0]    inData,
   input    reg                              inValid, // for AXI-Lite
   // wyjścia
   output   reg                              outValid, // AXI-Lite
   output   reg                              outUser, // AXI-Lite
   output   reg                              ready, // AXI-Lite
   output   reg [INPUT_DATA_BITWIDTH-1:0]    outData
);
// łącza dla sygnału valid
wire           valid_scaler2Quantizer;
wire           valid_quantizer2rescaler;
wire           valid_rescaler2outValid;
// łącza dla danych
wire [INPUT_DATA_BITWIDTH-1:0]      scalerOutput;
wire [QUANTISATION_BITWIDTH*2-1:0]  quantizedData;
wire [OUTPUT_DATA_BITWIDTH-1:0]     rescalerOutput;

always@(posedge clk)begin
   if(rst)begin
      outData <= 32'h00000000;
      outValid <= 1'b0;
      ready <= 1'b0;
      outUser <= 1'b0;
   end
   else begin
      outData <= rescalerOutput;
      outValid <= valid_rescaler2outValid;
      ready <= 1'b1;
      outUser <= 1'b0;
   end
end

scaler scaler(
.clk(clk),
.rst(rst),
.syncTo10ms(syncTo10ms),
.inData(inData),
.inValid(inValid),
.outValid(valid_scaler2Quantizer),
.scalerOutput(scalerOutput)
);

quantizer quzntizer(
.clk(clk),
.rst(rst),
.syncTo10ms(syncTo10ms),
.inData(scalerOutput),
.inValid(valid_scaler2Quantizer),
.outValid(valid_quantizer2rescaler),
.quantizedData(quantizedData)
);

rescaler rescaler(
.clk(clk),
.rst(rst),
.syncTo10ms(syncTo10ms),
.inData(quantizedData),
.inValid(valid_scaler2Quantizer),
.outValid(outValid),
.rescalerOutput(rescalerOutput)
);

endmodule