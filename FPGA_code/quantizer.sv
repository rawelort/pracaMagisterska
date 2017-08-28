//-----------------------------------//
// Title:   quantizer.v
// Author: 	Robert Walczak
// Date:	   17.08.2016
//-----------------------------------//

import system_parameters::*;

module quantizer
(
   input    reg                                 clk,
   input    reg                                 rst,
   input    reg [INPUT_DATA_BITWIDTH-1:0]       scaledData,
   input    reg [SCALING_FACTOR_BITWIDTH-1:0]   scalingFactorIn,
   input    reg                                 commaIn,
   output   reg                                 commaOut,
   output   reg [QUANTIZATION_BITWIDTH*2-1:0]   quantizedData,
   output   reg [SCALING_FACTOR_BITWIDTH-1:0]   scalingFactorOut
);

always@(posedge clk)begin
   if(rst)begin
      scalingFactorOut <= 12'h000;
      commaOut <= 1'b0;
   end
   else if(commaIn)begin // przypisanie młodszych bitów commy do współczynnika skalowania
      scalingFactorOut <= {4'h0,scaledData[INPUT_DATA_BITWIDTH-QUANTIZATION_BITWIDTH-1:INPUT_DATA_BITWIDTH/2],scaledData[INPUT_DATA_BITWIDTH/2-1-QUANTIZATION_BITWIDTH:0]};
      commaOut <= commaIn;
   end
   else begin
      scalingFactorOut <= scalingFactorIn;
      commaOut <= commaIn;
   end
end

always@(posedge clk)begin
   if(rst) begin
      quantizedData <= 24'h0;
   end
   else begin
      quantizedData[QUANTIZATION_BITWIDTH*2-1:QUANTIZATION_BITWIDTH] <= scaledData[INPUT_DATA_BITWIDTH-1:INPUT_DATA_BITWIDTH-1-QUANTIZATION_BITWIDTH];
      quantizedData[QUANTIZATION_BITWIDTH-1:0] <= scaledData[INPUT_DATA_BITWIDTH/2-1:INPUT_DATA_BITWIDTH/2-1-QUANTIZATION_BITWIDTH];
   end
end

endmodule