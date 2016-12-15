//-----------------------------------//
// Title:   quantizer.v
// Author: 	Robert Walczak
// Date:	   17.08.2016
//-----------------------------------//

import system_parameters;

module quantizer
(
   input    reg                                 clk,
   input    reg                                 rst,
   input    reg [INPUT_DATA_BITWIDTH-1:0]       scaledData,
   input    reg                              inValid, // for AXI-Lite
   output   reg                              outValid, // AXI-Lite
   //output   reg                              outUser, // AXI-Lite
   //output   reg                              ready, // AXI-Lite
   output   reg [QUANTISATION_BITWIDTH*2-1:0]   quantizedData
);

wire [INPUT_DATA_BITWIDTH/2-1:0]    dataI = scaledData[INPUT_DATA_BITWIDTH/2-1:0];   //[15:0]
wire [INPUT_DATA_BITWIDTH/2-1:0]    dataQ = scaledData[INPUT_DATA_BITWIDTH-1:INPUT_DATA_BITWIDTH/2];   //[32:16]

always@(posedge clk)begin
   quantizedData <= {dataQ[QUANTISATION_BITWIDTH-1:0],dataI[QUANTISATION_BITWIDTH-1:0]};
end
   
endmodule