//-----------------------------------//
// Title:   interleaver.v
// Author: 	Robert Walczak
// Date:	   17.08.2016
//-----------------------------------//
import system_parameters::*;

module interleaver
(
   input    reg                                 clk,
   input    reg                                 rst,
   input    reg                                 comma,
   input    reg [QUANTIZATION_BITWIDTH*2-1:0]   quantizedData,
   input    reg [SCALING_FACTOR_BITWIDTH-1:0]   scalingFactorIn,
   input    reg [SCALING_FACTOR_BITWIDTH-1:0]   controlData, // dane sterujące zmieniają się co 3 cykle zegarowe
   output   reg [INPUT_DATA_BITWIDTH-1:0]       interleavedData
);

reg  [SCALING_FACTOR_BITWIDTH-1:0]                      controlDataShiftReg = 12'h000;
reg  [INPUT_DATA_BITWIDTH-QUANTIZATION_BITWIDTH*2-1:0]  partialData = 8'h0;
reg                                                     sendScalingFactor = 1'b0;
reg  [1:0]                                              countParts = 2'h0;

always@(posedge clk)begin
   if(rst)begin
      countParts <= 2'h0;
      sendScalingFactor <= 1'b0;
      controlDataShiftReg <= 12'h000;
   end
   else if(comma)begin
      countParts <= 2'h2;
      sendScalingFactor <= 1'b1;
      controlDataShiftReg <= 12'h000;
   end
   else if(countParts == 2'h2)begin
      if(sendScalingFactor == 1'b1)begin
         controlDataShiftReg <= scalingFactorIn;
         sendScalingFactor <= 1'b0;
      end
      else begin
         controlDataShiftReg <= controlData;
      end
      countParts <= 2'h0;
   end
   else begin
      controlDataShiftReg <= {controlDataShiftReg[7:0], 4'h0};
      countParts <= countParts + 2'h1;
   end
end

always@(posedge clk)begin
   if(rst)begin
      interleavedData <= 32'h0000_0000;
   end
   else if(comma)begin // bity [7:0] z wejścia scalingFactorIn zawierają resztę niekompresowanej próbki z symbolem commy
      interleavedData <= {scalingFactorIn[7:4],quantizedData[QUANTIZATION_BITWIDTH*2-1:QUANTIZATION_BITWIDTH],scalingFactorIn[3:0],quantizedData[QUANTIZATION_BITWIDTH-1:0]};
   end
   else begin
      interleavedData <= {controlDataShiftReg[SCALING_FACTOR_BITWIDTH-1:8], quantizedData};
   end
end

endmodule