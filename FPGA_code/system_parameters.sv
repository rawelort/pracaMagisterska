//-----------------------------------//
// Title:   system_parameters.sv
// Author: 	Robert Walczak
// Date:	   17.08.2016
//-----------------------------------//

package system_parameters;

parameter INPUT_DATA_BITWIDTH = 32;
parameter SCALING_FACTOR_BITWIDTH = 12;
parameter QUANTISATION_BITWIDTH = 12;
parameter BLOCK_SIZE = 1024;
parameter MAX_SCALING_FACTOR_VALUE = 4095; // (2^SCALING_FACTOR_BITWIDTH)-1 = (2^12)-1 = 4095
parameter MAX_QUANTISATION_VALUE = 2047; // (2^(QUANTISATION_BITWIDTH-1))-1 = (2^(12-1))-1 = 2047
parameter OUTPUT_DATA_BITWIDTH = INPUT_DATA_BITWIDTH;

endpackage
