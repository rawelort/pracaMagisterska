//-----------------------------------//
// Title:   top.v
// Author: 	Robert Walczak
// Date:	   17.08.2016
//-----------------------------------//
import system_parameters::*;

module iq_compressor
(
   // wejścia
   input    reg                                  clk,
   input    reg                                  rst,
   output   reg  [SCALING_FACTOR_BITWIDTH-1:0]   inControlData,
   input    reg  [INPUT_DATA_BITWIDTH-1:0]       inData,
   // wyjścia
   output   wire [23:0]                          evm,
   output   wire [SCALING_FACTOR_BITWIDTH-1:0]   outControlData,
   output   wire [OUTPUT_DATA_BITWIDTH-1:0]      outData
);
// łącza dla sygnału valid
wire           valid_scaler2Quantizer;
wire           valid_quantizer2interleaver;
wire           valid_rescaler2outValid;
// łącza dla flagi przesyłanej commy
wire           comma_scaler2quantizer;
wire           comma_quantizer2interleaver;
// łącza dla danych
wire [INPUT_DATA_BITWIDTH-1:0]      scalerOutput;
wire [QUANTIZATION_BITWIDTH*2-1:0]  quantizedData;
wire [OUTPUT_DATA_BITWIDTH-1:0]     interleavedData;
wire [OUTPUT_DATA_BITWIDTH-1:0]     rescalerOutput;
wire [SCALING_FACTOR_BITWIDTH-1:0]  scalingFactor_scaler2quantizer;
wire [SCALING_FACTOR_BITWIDTH-1:0]  scalingFactor_quantizer2interleaver;

always@(posedge clk)begin
   if(rst)begin
      outData <= 32'h00000000;
   end
   else begin
      outData <= rescalerOutput;
   end
end

iq_scaler iq_scaler(
   .clk(clk),
   .rst(rst),
   .inData(inData),
   .scalingFactorOut(scalingFactor_scaler2quantizer),
   .comma(comma_scaler2quantizer),
   .dataOut(scalerOutput)
);

quantizer quantizer(
   .clk(clk),
   .rst(rst),
   .scaledData(scalerOutput),
   .scalingFactorIn(scalingFactor_scaler2quantizer),
   .commaIn(comma_scaler2quantizer),
   .commaOut(comma_quantizer2interleaver),
   .quantizedData(quantizedData),
   .scalingFactorOut(scalingFactor_quantizer2interleaver)
);

interleaver interleaver(
   .clk(clk),
   .rst(rst),
   .comma(comma_quantizer2interleaver),
   .quantizedData(quantizedData),
   .scalingFactorIn(scalingFactor_quantizer2interleaver),
   .controlData(inControlData),
   .interleavedData(interleavedData),
);

rescaler rescaler(
   .clk(clk),
   .rst(rst),
   .inData(quantizedData),
   .orgData(inData),
   .outControlData(outControlData),
   .outData(rescalerOutput),
   .evm(evm)
);

endmodule