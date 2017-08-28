//-----------------------------------//
// Title:   rescaler.v
// Author: 	Robert Walczak
// Date:	   17.08.2016
//-----------------------------------//
import system_parameters::*;

module rescaler
(
   input    reg                                    clk,
   input    reg                                    rst,
   input    reg   [INPUT_DATA_BITWIDTH-1:0]        inData,
   input    reg   [INPUT_DATA_BITWIDTH-1:0]        orgData,
   output   reg   [SCALING_FACTOR_BITWIDTH-1:0]    outControlData,
   output   reg   [OUTPUT_DATA_BITWIDTH-1:0]       outData,
   output   reg   [23:0]                           evm
);

reg  unsigned [9:0]                  numOfReceivedSamples = 10'h000;
reg                                  commaDetected = 1'b0;
reg                                  commaDetected_d1 = 1'b0;
reg                                  commaDetected_d2 = 1'b0;
reg                                  commaDetected_d3 = 1'b0;
reg  [1:0]                           countParts = 2'h0;
reg  [OUTPUT_DATA_BITWIDTH-1:0]      inData_d1 = 32'h000000;
reg  [OUTPUT_DATA_BITWIDTH-1:0]      inData_d2 = 32'h000000;
reg  [OUTPUT_DATA_BITWIDTH-1:0]      inData_d3 = 32'h000000;
reg                                  collectScalingFactor = 1'b0;
reg  [SCALING_FACTOR_BITWIDTH-1:0]   scalingFactor = 12'h000;
reg  [SCALING_FACTOR_BITWIDTH-1:0]   controlDataShiftReg = 12'h000;

reg  [INPUT_DATA_BITWIDTH/2-1:0]     diffRe = 16'h0000;
reg  [INPUT_DATA_BITWIDTH/2-1:0]     diffIm = 16'h0000;
reg  [31:0]                          diffRePower = 32'h0000;
reg  [31:0]                          diffImPower = 32'h0000;
reg  [INPUT_DATA_BITWIDTH-1:0]       orgData_d1 = 32'h0000_0000;
reg  [31:0]                          orgRePower = 32'h0000;
reg  [31:0]                          orgImPower = 32'h0000;
reg  [INPUT_DATA_BITWIDTH-1:0]       diffSum = 32'h0000_0000;
reg  [INPUT_DATA_BITWIDTH-1:0]       orgSum = 32'h0000_0000;
reg  [INPUT_DATA_BITWIDTH-1:0]       division = 32'h0000_0000;
wire [31:0]                          out_adder_diff;
reg  [31:0]                          sum_diff_d0 = 32'h0000_0000;
reg  [31:0]                          sum_diff_d1 = 32'h0000_0000;
reg  [31:0]                          sum_diff_d2 = 32'h0000_0000;
reg  [31:0]                          sum_diff_d3 = 32'h0000_0000;
reg  [31:0]                          sum_diff_d4 = 32'h0000_0000;
reg  [31:0]                          sum_diff_d5 = 32'h0000_0000;
reg  [31:0]                          sum_diff_d6 = 32'h0000_0000;
reg  [31:0]                          sum_diff_d7 = 32'h0000_0000;
wire [31:0]                          out_adder_org;
reg  [31:0]                          sum_org_d0 = 32'h0000_0000;
reg  [31:0]                          sum_org_d1 = 32'h0000_0000;
reg  [31:0]                          sum_org_d2 = 32'h0000_0000;
reg  [31:0]                          sum_org_d3 = 32'h0000_0000;
reg  [31:0]                          sum_org_d4 = 32'h0000_0000;
reg  [31:0]                          sum_org_d5 = 32'h0000_0000;
reg  [31:0]                          sum_org_d6 = 32'h0000_0000;
reg  [31:0]                          sum_org_d7 = 32'h0000_0000;
reg  [15:0]                          raw_evm = 16'h0000;

wire [INPUT_DATA_BITWIDTH/2-1:0]     out_mult_inData_d3_lower;              //         [15:0]
wire [INPUT_DATA_BITWIDTH/2-1:0]     out_mult_inData_d3_upper;              //         [15:0]
wire [31:0]                          out_pow_diffRe;
wire [31:0]                          out_pow_diffIm;
wire [31:0]                          out_pow_orgData_lower;
wire [31:0]                          out_pow_orgData_upper;
wire [15:0]                          out_subst_re;
wire [15:0]                          out_subst_im;
wire [31:0]                          out_par_diffSum;
wire [31:0]                          out_par_orgSum;
wire [31:0]                          out_div_division;
wire [15:0]                          out_sqrt_evm;
wire [23:0]                          out_mult_evm;

mult_16x12 mult_inData_d3_lower(
	.dataa(inData_d3[OUTPUT_DATA_BITWIDTH/2-1:0]),
	.datab(scalingFactor),
	.result(out_mult_inData_d3_lower)
);

mult_16x12 mult_inData_d3_upper(
	.dataa(inData_d3[OUTPUT_DATA_BITWIDTH-1:OUTPUT_DATA_BITWIDTH/2]),
	.datab(scalingFactor),
	.result(out_mult_inData_d3_upper)
);

power_16 pow_diffRe(
   .dataa(diffRe),
   .result(out_pow_diffRe)
);

power_16 pow_diffIm(
	.dataa(diffIm),
	.result(out_pow_diffIm)
);

power_16 pow_orgData_lower(
	.dataa(orgData_d1[INPUT_DATA_BITWIDTH/2-1:0]),
	.result(out_pow_orgData_lower)
);

power_16 pow_orgData_upper(
	.dataa(orgData_d1[INPUT_DATA_BITWIDTH-1:INPUT_DATA_BITWIDTH/2]),
	.result(out_pow_orgData_upper)
);

subst_16 subst_re(
	.dataa(outData[INPUT_DATA_BITWIDTH/2-1:0]),
	.datab(orgData[INPUT_DATA_BITWIDTH/2-1:0]),
	.result(out_subst_re)
);

subst_16 subst_im(
	.dataa(outData[INPUT_DATA_BITWIDTH-1:INPUT_DATA_BITWIDTH/2]),
	.datab(orgData[INPUT_DATA_BITWIDTH-1:INPUT_DATA_BITWIDTH/2]),
	.result(out_subst_im)
);

adder_32 adder_diff(
	.dataa(diffRePower),
	.datab(diffImPower),
	.result(out_adder_diff)
);

adder_32 adder_org(
	.dataa(orgRePower),
	.datab(orgImPower),
	.result(out_adder_org)
);

parallel_adder_32 par_diffSum(
	.data0x(sum_diff_d0),
	.data1x(sum_diff_d1),
	.data2x(sum_diff_d2),
	.data3x(sum_diff_d3),
	.data4x(sum_diff_d4),
	.data5x(sum_diff_d5),
	.data6x(sum_diff_d6),
	.data7x(sum_diff_d7),
	.result(out_par_diffSum)
);

parallel_adder_32 par_orgSum(
	.data0x(sum_org_d0),
	.data1x(sum_org_d1),
	.data2x(sum_org_d2),
	.data3x(sum_org_d3),
	.data4x(sum_org_d4),
	.data5x(sum_org_d5),
	.data6x(sum_org_d6),
	.data7x(sum_org_d7),
	.result(out_par_orgSum)
);

divider_32 div_division(
	.denom(diffSum),
	.numer(orgSum),
	.quotient(out_div_division),
	.remain()
);

square_32 sqrt_evm(
	.radical(division),
	.q(out_sqrt_evm),
	.remainder()
);

mult_16x100 mult_evm(
	.dataa(raw_evm),
	.result(out_mult_evm)
);

// detekcja commy oraz zliczanie odebranych próbek
always@(posedge clk)begin
   if(rst)begin
      numOfReceivedSamples <= 10'h000;
      commaDetected <= 1'b0;
   end
   else if( (inData[7:0] == 8'hfc) || (inData[15:8] == 8'hfc) || (inData[23:16] == 8'hfc) || (inData[31:24] == 8'hfc) )begin
      commaDetected <= 1'b1;
      numOfReceivedSamples <= 10'h000;
   end
   else begin
      numOfReceivedSamples <= numOfReceivedSamples+1;
      commaDetected <= 1'b0;
   end
end

// opóźnienie danych w oczekiwaniu na odtworzenie współczynnika skalowania
always@(posedge clk)begin
   if(rst)begin
      commaDetected_d1 <= 1'b0;
      commaDetected_d2 <= 1'b0;
      commaDetected_d3 <= 1'b0;
      inData_d1 <= 32'h0000_0000;
      inData_d2 <= 32'h0000_0000;
      inData_d3 <= 32'h0000_0000;
      //numOfReceivedSamples_d1 <= 10'h000;
      //numOfReceivedSamples_d2 <= 10'h000;
      //numOfReceivedSamples_d3 <= 10'h000;
   end
   else begin
      inData_d1 <= inData;
      inData_d2 <= inData_d1;
      inData_d3 <= inData_d2;
      //numOfReceivedSamples_d1 <= numOfReceivedSamples;
      //numOfReceivedSamples_d2 <= numOfReceivedSamples_d1;
      //numOfReceivedSamples_d3 <= numOfReceivedSamples_d2;
      commaDetected_d1 <= commaDetected;
      commaDetected_d2 <= commaDetected_d1;
      commaDetected_d3 <= commaDetected_d2;
   end
end

// składanie sfragmentowanych danych sterujących i współczynnika skalowania
always@(posedge clk)begin
   if(rst)begin
      countParts <= 2'h0;
      scalingFactor <= 12'h000;
      outControlData <= 12'h000;
      controlDataShiftReg <= 12'h000;
      collectScalingFactor <= 1'b0;
   end
   else if(commaDetected)begin
      countParts <= 2'h0;
      outControlData <= 12'h0fc;
      collectScalingFactor <= 1'b1;
      controlDataShiftReg <= {controlDataShiftReg[7:0],inData[OUTPUT_DATA_BITWIDTH-1:OUTPUT_DATA_BITWIDTH-1-SCALING_FACTOR_BITWIDTH]};
   end
   else if(numOfReceivedSamples == BLOCK_SIZE-1)begin // 10'h3ff = 10'd1023
      countParts <= 2'h0;
      outControlData <= 12'he0b;
      collectScalingFactor <= 1'b1;
      controlDataShiftReg <= {controlDataShiftReg[7:0],inData[OUTPUT_DATA_BITWIDTH-1:OUTPUT_DATA_BITWIDTH-1-SCALING_FACTOR_BITWIDTH]};
   end
   else if(countParts == 2'h2)begin
      countParts <= 2'h0;
      controlDataShiftReg <= {controlDataShiftReg[7:0],inData[OUTPUT_DATA_BITWIDTH-1:OUTPUT_DATA_BITWIDTH-1-SCALING_FACTOR_BITWIDTH]};
      if(collectScalingFactor)begin
         scalingFactor <= controlDataShiftReg;
         outControlData <= 12'h05f;
         collectScalingFactor <= 1'b0;
      end
      else begin
         outControlData <= controlDataShiftReg;
      end
   end
   else begin
      countParts <= countParts + 2'h1;
      controlDataShiftReg <= {controlDataShiftReg[7:0],inData[OUTPUT_DATA_BITWIDTH-1:OUTPUT_DATA_BITWIDTH-1-SCALING_FACTOR_BITWIDTH]};
   end
end

// reskalowanie próbek
always@(posedge clk)begin
   if(rst)begin
      outData <= 32'h0000_0000;
   end
   else if(commaDetected_d3)begin
      outData <= inData_d3;
   end
   else begin
      outData <= {out_mult_inData_d3_upper, out_mult_inData_d3_lower};
   end
end

// obliczanie EVM
always@(posedge clk)begin
   if(rst)begin
      evm <= 16'h0000_0000;
   end
   else begin
      // różnica współczynników odtworzonego i oryginalnego
		diffRe <= out_subst_re;
      diffIm <= out_subst_im;
      // kwadraty różnicy
		diffRePower <= out_pow_diffRe;
      diffImPower <= out_pow_diffIm;
      // kwadraty współczynników próbki oryginalnej
		orgRePower <= out_pow_orgData_lower;
      orgImPower <= out_pow_orgData_upper;
	   // sumy kwadratów różnic z ostatnich ośmiu próbek 
		sum_diff_d0 <= out_adder_diff;
	   sum_diff_d1 <= sum_diff_d0;
	   sum_diff_d2 <= sum_diff_d1;
	   sum_diff_d3 <= sum_diff_d2;
	   sum_diff_d4 <= sum_diff_d3;
	   sum_diff_d5 <= sum_diff_d4;
	   sum_diff_d6 <= sum_diff_d5;
	   sum_diff_d7 <= sum_diff_d6;
	   // sumy kwadratów z ostatnich ośmiu oryginalnych próbek
	   sum_org_d0 <= out_adder_org;
	   sum_org_d1 <= sum_org_d0;
	   sum_org_d2 <= sum_org_d1;
	   sum_org_d3 <= sum_org_d2;
	   sum_org_d4 <= sum_org_d3;
	   sum_org_d5 <= sum_org_d4;
	   sum_org_d6 <= sum_org_d5;
	   sum_org_d7 <= sum_org_d6;
		// sumy ostatnich ośmiu sum
		diffSum <= out_par_diffSum;
      orgSum <= out_par_orgSum;
		// dzielenie
      division <= out_div_division;
		// pierwiastek
		raw_evm <= out_sqrt_evm;
		// EVM%
		evm <= out_mult_evm;
   end
end

endmodule