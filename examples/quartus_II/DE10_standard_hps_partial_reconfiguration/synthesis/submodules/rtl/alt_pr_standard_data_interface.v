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

module alt_pr_standard_data_interface(
	clk,
	nreset,
	freeze,
	o_stardard_data,
	o_stardard_data_valid,
	stardard_data_ready,
	data,
	data_valid,
	o_data_ready
);

	parameter DATA_WIDTH_INDEX = 16;
	parameter CB_DATA_WIDTH = 16;

	input clk;
	input nreset;
	input freeze;
	input stardard_data_ready;
	input [DATA_WIDTH_INDEX-1:0] data;
	input data_valid;

	output [CB_DATA_WIDTH-1:0] o_stardard_data;
	output o_stardard_data_valid;
	output o_data_ready;

	generate
		if (DATA_WIDTH_INDEX < CB_DATA_WIDTH)
		begin
			// data upsize converter
			// x1, x2, x4, x8 ---> x16
			alt_pr_up_converter alt_pr_up_converter(
				.clk(clk),
				.nreset(nreset),
				.data_in(data),
				.flash_data_ready(data_valid),
				.flash_data_read(o_data_ready),
				.data_out(o_stardard_data),
				.data_request(freeze),
				.data_ready(o_stardard_data_valid),
				.data_read(stardard_data_ready)
			);
			defparam alt_pr_up_converter.DATA_IN_WIDTH = DATA_WIDTH_INDEX;
			defparam alt_pr_up_converter.DATA_OUT_WIDTH = CB_DATA_WIDTH;
			defparam alt_pr_up_converter.STREAM_MODE = "ON";
		end
		else if (DATA_WIDTH_INDEX > CB_DATA_WIDTH) begin
			// data downsize converter
			// x32 ---> x16
			alt_pr_down_converter alt_pr_down_converter(
				.clk(clk),
				.nreset(nreset),
				.data_in(data),
				.flash_data_ready(data_valid),
				.flash_data_read(o_data_ready),
				.data_out(o_stardard_data),
				.data_request(freeze),
				.data_ready(o_stardard_data_valid),
				.data_read(stardard_data_ready)
			);
			defparam alt_pr_down_converter.DATA_IN_WIDTH = DATA_WIDTH_INDEX;
			defparam alt_pr_down_converter.DATA_OUT_WIDTH = CB_DATA_WIDTH;
			defparam alt_pr_down_converter.STREAM_MODE = "ON";
		end
		else begin
			assign o_stardard_data = data;
			assign o_stardard_data_valid = data_valid;
			assign o_data_ready = stardard_data_ready;
		end
	endgenerate

endmodule

