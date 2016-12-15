//-----------------------------------//
// Title:   rescaler.v
// Author: 	Robert Walczak
// Date:	   17.08.2016
//-----------------------------------//
import system_parameters;

module rescaler
(
   input    reg                                    clk,
   input    reg                                    rst,
   input    reg                                    syncTo10ms,
   input    reg   [QUANTISATION_BITWIDTH*2-1:0]    quantizedData,
   input    reg                                    inValid, // for AXI-Lite
   output   reg                                    outValid, // AXI-Lite
   //output   reg                                    outUser, // AXI-Lite
   //output   reg                                    ready, // AXI-Lite
   output   reg   [OUTPUT_DATA_BITWIDTH-1:0]       rescalerOutput
);

reg unsigned [9:0]   numOfRescaledSamples = 10'h000;
reg                  syncTo10ms_d=1'b0;
reg [SCALING_FACTOR_BITWIDTH-1:0] scalingFactor;

always@(posedge clk)begin
   if(rst)begin
      numOfRescaledSamples <= 10'h000;
      syncTo10ms_d <= 1'b0;
   end
   else if(syncTo10ms && ~syncTo10ms_d)begin
      numOfRescaledSamples <= 10'h000;
   end
   else begin
      numOfRescaledSamples <= numOfRescaledSamples+1;
   end
end

always@(posedge clk)begin
   if(rst)begin
      rescalerOutput <= 32'h0;
      scalingFactor <= 12'h000;
   end
// to jakoś inczej zrobić żebynie było przerwy na jeden takt zegara w reskalowaniu danych?
   else if(numOfRescaledSamples == 10'h000)begin
      scalingFactor <= quantizedData/MAX_QUANTISATION_VALUE;
   end
   else begin
      rescalerOutput <= quantizedData*scalingFactor;
   end
end

endmodule