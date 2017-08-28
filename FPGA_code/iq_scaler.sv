//-----------------------------------//
// Title:   scaler.v
// Author: 	Robert Walczak
// Date:	   17.08.2016
//-----------------------------------//

import system_parameters::*;

module iq_scaler
(
   input    reg                                 clk,
   input    reg                                 rst,
   input    reg [INPUT_DATA_BITWIDTH-1:0]       inData,
   output   reg [SCALING_FACTOR_BITWIDTH-1:0]   scalingFactorOut,
   output   reg                                 comma,
   output   reg [OUTPUT_DATA_BITWIDTH-1:0]      dataOut
);

reg            [INPUT_DATA_BITWIDTH-1:0]                    inData_d1 = 32'h0000_0000;
reg            [INPUT_DATA_BITWIDTH/2-1:0]                  maxComplexComponent = 16'h0000;  //         [15:0]
reg            [BLOCK_SIZE-1:0][INPUT_DATA_BITWIDTH/2-1:0]  dataBuffer_I_0;                  // [1023:0][15:0]
reg            [BLOCK_SIZE-1:0][INPUT_DATA_BITWIDTH/2-1:0]  dataBuffer_Q_0;                  // [1023:0][15:0]
reg            [BLOCK_SIZE-1:0][INPUT_DATA_BITWIDTH/2-1:0]  dataBuffer_I_1;                  // [1023:0][15:0]
reg            [BLOCK_SIZE-1:0][INPUT_DATA_BITWIDTH/2-1:0]  dataBuffer_Q_1;                  // [1023:0][15:0]
reg            [INPUT_DATA_BITWIDTH-1:0]                    sampleToScale;                   //    [1:0][31:0]
reg unsigned   [1:0][SCALING_FACTOR_BITWIDTH-1:0]           fractionForScaling;              //    [1:0][11:0]
reg unsigned   [SCALING_FACTOR_BITWIDTH-1:0]                quotient;                        //    [1:0][11:0]
reg unsigned   [9:0]                                        numOfCollectedSamples = 10'h0;   //         [9:0]
reg unsigned   [9:0]                                        sendSamples = 10'h0;             //         [9:0]
reg                                                         dataBufferSelector = 1'b0;
reg            [1:0]                                        commaAppeared = 2'b0;
wire           [INPUT_DATA_BITWIDTH/2-1:0]                  out_mult_dataBuffer_I_0;              //         [15:0]
wire           [INPUT_DATA_BITWIDTH/2-1:0]                  out_mult_dataBuffer_I_1;              //         [15:0]
wire           [INPUT_DATA_BITWIDTH/2-1:0]                  out_mult_dataBuffer_Q_0;              //         [15:0]
wire           [INPUT_DATA_BITWIDTH/2-1:0]                  out_mult_dataBuffer_Q_1;              //         [15:0]

// wydzielenie wspólczynników próbki zespolonej i utworzenie ich wartości absolutnych
// TODO czy tu na pewno 0:15 a nie 15:0?
// RISK może być problem z zamknięciem timingów dla tego warunku i może byc potrzebna zmiana na rejestr (+1 tick?)
wire [15:0] inDataI = (inData[INPUT_DATA_BITWIDTH/2-1]==1'b1) ? inData[INPUT_DATA_BITWIDTH/2-1:0] : -inData[INPUT_DATA_BITWIDTH/2-1:0]; // [15:0]
wire [15:0] inDataQ = (inData[INPUT_DATA_BITWIDTH-1]==1'b1) ? inData[INPUT_DATA_BITWIDTH-1:INPUT_DATA_BITWIDTH/2-1] : -inData[INPUT_DATA_BITWIDTH-1:INPUT_DATA_BITWIDTH/2-1]; // [31:16]

divider_16 fraction_divider(
	.denom(maxComplexComponent),
	.numer(MAX_QUANTIZATION_VALUE),
	.quotient(quotient),
	.remain()
);

mult_16x12 mult_dataBuffer_I_0(
	.dataa(dataBuffer_I_0[numOfCollectedSamples]),
	.datab(fractionForScaling[~dataBufferSelector]),
	.result(out_mult_dataBuffer_I_0)
);

mult_16x12 mult_dataBuffer_I_1(
	.dataa(dataBuffer_I_1[numOfCollectedSamples]),
	.datab(fractionForScaling[~dataBufferSelector]),
	.result(out_mult_dataBuffer_I_1)
);

mult_16x12 mult_dataBuffer_Q_0(
	.dataa(dataBuffer_Q_0[numOfCollectedSamples]),
	.datab(fractionForScaling[~dataBufferSelector]),
	.result(out_mult_dataBuffer_Q_0)
);

mult_16x12 mult_dataBuffer_Q_1(
	.dataa(dataBuffer_Q_1[numOfCollectedSamples]),
	.datab(fractionForScaling[~dataBufferSelector]),
	.result(out_mult_dataBuffer_Q_1)
);

// opóźnienie danych wejściowych
always@(posedge clk)begin
   inData_d1 <= inData;
end

// porównywanie współczynników nowej próbki z największym dotychczasowym współczynnikiem
always@(posedge clk)begin
   if(rst) begin
      maxComplexComponent <= 16'h0000;
   end
   else begin
      if (inDataI >= inDataQ)begin
         if (inDataI > maxComplexComponent)begin
            maxComplexComponent <= inDataI;
         end
      end
      else begin
         if (inDataQ > maxComplexComponent)begin
            maxComplexComponent <= inDataQ;
         end
      end
   end
end

// zliczanie odebranych próbek i synchronizowanie ich do K28.7
always@(posedge clk)begin
   if(rst) begin
      numOfCollectedSamples <= 10'h000;
      commaAppeared <= 2'b0;
   end
   else if( (inData[7:0] == 8'hfc) || (inData[15:8] == 8'hfc) || (inData[23:16] == 8'hfc) || (inData[31:24] == 8'hfc) )begin
      numOfCollectedSamples <= 10'h000;
      dataBufferSelector <= ~dataBufferSelector;
      commaAppeared[~dataBufferSelector] <= 1'b1;
   end
   else begin
      numOfCollectedSamples <= numOfCollectedSamples + 10'h1;
   end
   
   if (numOfCollectedSamples == BLOCK_SIZE-1)begin
      dataBufferSelector <= ~dataBufferSelector;
      commaAppeared[~dataBufferSelector] <= 1'b0;
   end
end

// kolekcjonowanie próbek w bloku
always@(posedge clk)begin
// Dane dla bloków zapisywane są naprzemiennie w dwóch rejestrach
   case (dataBufferSelector)
      1'b0 : begin
         dataBuffer_I_0[numOfCollectedSamples] <= inData_d1[15:0];
         dataBuffer_Q_0[numOfCollectedSamples] <= inData_d1[31:16];
      end
      1'b1 : begin
         dataBuffer_I_1[numOfCollectedSamples] <= inData_d1[15:0];
         dataBuffer_Q_1[numOfCollectedSamples] <= inData_d1[31:16];
      end
   endcase
end

// obliczanie maksymalnej wartości kwantyzacji podzielonej pzez współczynnik skalowania dla zebranego bloku danych
always@(posedge clk)begin
   if(rst) begin
      fractionForScaling <= '0;
   end
   else if(numOfCollectedSamples == 10'h000)begin
      fractionForScaling[dataBufferSelector] <= 12'h0;
   end
// zegar dla danych przeskalowanych ten sam co dla przychodzących. zysk na bitach wykorzystany do przesłania danych kontrolnych
   else begin
      if(maxComplexComponent > MAX_SCALING_FACTOR_VALUE)begin
         fractionForScaling[dataBufferSelector] <= MAX_QUANTIZATION_VALUE/MAX_SCALING_FACTOR_VALUE; // tu dzielący ip core!
      end
      else begin
         fractionForScaling[dataBufferSelector] <= quotient; // tu dzielący ip core! DONE
      end
   end
end

// TODO mnożenie
always@(posedge clk)begin
   if (rst) begin
      dataOut <= 32'b0;
   end
   else begin
      case ({commaAppeared[~dataBufferSelector],~dataBufferSelector}) // negacja żeby wysłać dane z bufora już skompletowanego podczas gdy do drugiego zbierane sa nowe dane
         2'b00 : begin
            dataOut[15:0]  <= out_mult_dataBuffer_I_0; // ip core też dla mnożarki?
            dataOut[31:16] <= out_mult_dataBuffer_Q_0; // ip core też dla mnożarki?
            comma <= 1'b0;
         end
         2'b01 : begin
            dataOut[15:0]  <= out_mult_dataBuffer_I_1; // ip core też dla mnożarki?
            dataOut[31:16] <= out_mult_dataBuffer_Q_1; // ip core też dla mnożarki?
            comma <= 1'b0;
         end
         2'b10 : begin
            if (numOfCollectedSamples == 10'h0)begin // przypisanie próbki z K28.7
               dataOut[15:0]  <= dataBuffer_I_0[numOfCollectedSamples];
               dataOut[31:16] <= dataBuffer_Q_0[numOfCollectedSamples];
               comma <= 1'b1;
            end
            else begin // przypisanie pozostałych próbek
               dataOut[15:0]  <= out_mult_dataBuffer_I_0; // ip core też dla mnożarki?
               dataOut[31:16] <= out_mult_dataBuffer_Q_0; // ip core też dla mnożarki?
               comma <= 1'b0;
            end
         end
         2'b11 : begin
            if (numOfCollectedSamples == 10'h0)begin // przypisanie próbki z K28.7
               dataOut[15:0]  <= dataBuffer_I_1[numOfCollectedSamples];
               dataOut[31:16] <= dataBuffer_Q_1[numOfCollectedSamples];
               comma <= 1'b1;
            end
            else begin
               dataOut[15:0]  <= out_mult_dataBuffer_I_1; // ip core też dla mnożarki?
               dataOut[31:16] <= out_mult_dataBuffer_Q_1; // ip core też dla mnożarki?
               comma <= 1'b0;
            end
         end
      endcase
      scalingFactorOut <= fractionForScaling[~dataBufferSelector];
   end
end

endmodule
