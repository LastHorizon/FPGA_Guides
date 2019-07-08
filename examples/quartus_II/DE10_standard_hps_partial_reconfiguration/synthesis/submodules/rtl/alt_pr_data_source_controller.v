// (C) 2001-2015 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera MegaCore Function License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


// synthesis VERILOG_INPUT_VERSION VERILOG_2001

module alt_pr_data_source_controller(
	clk,
	nreset,
	jtag_control,
	jtag_data,
	jtag_data_valid,
	o_jtag_data_ready,
	standard_data,
	standard_data_valid,
	o_standard_data_ready,
	data_ready,
	o_data_valid,
	o_data
);	
	parameter CB_DATA_WIDTH = 16;
	
	input clk; 
	input nreset;
	input jtag_control;
	input [CB_DATA_WIDTH-1:0] jtag_data;
	input jtag_data_valid;
	input [CB_DATA_WIDTH-1:0] standard_data;
	input standard_data_valid;
	input data_ready;
	
	output o_jtag_data_ready;
	output o_standard_data_ready;
	output o_data_valid;
	output [CB_DATA_WIDTH-1:0] o_data;
	
	assign o_jtag_data_ready = jtag_control ? data_ready : 1'b0;
	assign o_standard_data_ready = jtag_control ? 1'b0 : data_ready;
	assign o_data_valid = jtag_control ? jtag_data_valid : standard_data_valid;
	assign o_data = jtag_control ? jtag_data : standard_data;
	
endmodule

