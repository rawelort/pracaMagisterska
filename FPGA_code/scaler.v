//-----------------------------------//
// Title:   scaler.v
// Author: 	Robert Walczak
// Date:	   17.08.2016
//-----------------------------------//

//parameter INPUT_DATA_BITWIDTH = 32;
//parameter SCALING_FACTOR_BITWIDTH = 12;
//parameter QUANTISATION_BITWIDTH = 12;
//parameter BLOCK_SIZE = 1024;
//parameter MAX_SCALING_FACTOR_VALUE = 4095; // (2^SCALING_FACTOR_BITWIDTH)-1 = (2^12)-1 = 4095
//parameter MAX_QUANTISATION_VALUE = 2047; // (2^(QUANTISATION_BITWIDTH-1))-1 = (2^(12-1))-1 = 2047
import system_parameters;

module scaler
(
   input    reg                              clk,
   input    reg                              rst,
   input    reg                              syncTo10ms,
   input    reg [INPUT_DATA_BITWIDTH-1:0]    inData,
   input    reg                              inValid, // for AXI-Lite
   output   reg                              outValid, // AXI-Lite
   //output   reg                              outUser, // AXI-Lite
   //output   reg                              ready, // AXI-Lite
   output   reg [INPUT_DATA_BITWIDTH-1:0]    scalerOutput
);

reg            [INPUT_DATA_BITWIDTH/2-1:0]               maxComplexComponent = 16'h0000; // [15:0]
reg            [BLOCK_SIZE-1:0][INPUT_DATA_BITWIDTH-1:0] incomingDataBlock; // [1023:0][31:0]
reg            [BLOCK_SIZE-1:0][INPUT_DATA_BITWIDTH-1:0] collectedDataBlock; // [1023:0][31:0]
reg unsigned   [SCALING_FACTOR_BITWIDTH-1:0]             scalingFactor = 12'h000; // [11:0]
reg unsigned   [9:0]                                     numOfCollectedSamples = 10'h0;

// wydzielenie wspólczynników próbki zespolonej i utworzenie ich wartości absolutnych
wire [0:15] inDataI = (inData[15]==1'b1) ? inData[INPUT_DATA_BITWIDTH/2-1:0] : -inData[INPUT_DATA_BITWIDTH/2-1:0]; // [15:0]
wire [0:15] inDataQ = (inData[31]==1'b1) ? inData[INPUT_DATA_BITWIDTH-1:INPUT_DATA_BITWIDTH/2-1] : -inData[INPUT_DATA_BITWIDTH-1:INPUT_DATA_BITWIDTH/2-1]; // [31:16]

// porównywanie współczynników nowej próbki z największym dotychczasowym
always@(posedge clk)begin
   if(rst)begin
      maxComplexComponent <= 16'h0000;
   end
   else begin
      if (inDataI >= inDataQ) begin
         if (inDataI > maxSample) begin
            maxComplexComponent <= inDataI;
         end
      end
      else begin
         if (inDataQ > maxSample) begin
            maxComplexComponent <= inDataQ;
         end
      end
   end
end

// kolekcjonowanie próbek w bloku
always@(posedge clk)begin
   if(rst)begin
      scalingFactor <= 12'h000;
      numOfCollectedSamples <= 0;
   end
   else begin
//TODO może zastosować rejetr kołowy?
      if (numOfCollectedSamples == 10'h000) begin
         collectedDataBlock <= incomingDataBlock;
      end
      incomingDataBlock[numOfCollectedSamples] <= inData;
      numOfCollectedSamples <= numOfCollectedSamples + 1;
   end
end

// obliczanie maksymalnej wartości kwantyzacji podzielonej pzez współczynnik skalowania dla zebranego bloku danych
always@(posedge clk)begin
   if(numOfCollectedSamples == 10'h000)begin
// zegar dla danych przeskalowanych ten sam co dla przychodzących. zysk na bitach wykorzystany do przesłania danych kontrolnyc
      if(MAX_SCALING_FACTOR_VALUE > maxComplexComponent)begin
         scalingFactor <= MAX_SCALING_FACTOR_VALUE;
         fractionForScaling <= MAX_QUANTISATION_VALUE/MAX_SCALING_FACTOR_VALUE;
      end
      else begin
         scalingFactor <= maxComplexComponent;
         fractionForScaling <= MAX_QUANTISATION_VALUE/maxComplexComponent;
      end
   end
end

// wysyłanie próbek przemnożonych przez współczynnik skalowania
always@(posedge clk)begin
   if(numOfCollectedSamples == 10'h000)begin
      scalerOutput <= scalingFactor;
   end
   else begin
      scalerOutput <= collectedDataBlock[numOfCollectedSamples]*fractionForScaling;
   end
end

endmodule
