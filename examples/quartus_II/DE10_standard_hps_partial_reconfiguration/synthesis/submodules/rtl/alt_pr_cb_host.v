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

module alt_pr_cb_host(
	clk,
	nreset,
	pr_start,
	double_pr,
	o_freeze,
	o_crc_error,
	o_pr_error,
	o_pr_ready,
	o_pr_done,
	pr_clk,
	pr_data,
	pr_ready_pin,
	pr_done_pin,
	pr_error_pin,
	o_pr_request_pin,
	o_pr_clk_pin,
	o_pr_data_pin,
	crc_error_pin,
	bitstream_ready
);
	parameter PR_INTERNAL_HOST = 1;
	parameter CDRATIO = 1;
	parameter CB_DATA_WIDTH = 16;
	parameter EDCRC_OSC_DIVIDER = 1;
	parameter DEVICE_FAMILY	= "Stratix V";
    parameter EXT_HOST_TARGET_DEVICE_FAMILY	= "Stratix V";
						
	input clk;
	input nreset;
	input pr_clk;
	input [CB_DATA_WIDTH-1:0] pr_data;
	input pr_start;
	input double_pr;
	input bitstream_ready;

	output o_freeze;
	output o_crc_error;
	output o_pr_error;
	output o_pr_ready;
	output o_pr_done;

	input pr_ready_pin;
	input pr_done_pin;
	input pr_error_pin;
	input crc_error_pin;
	output o_pr_request_pin;
	output o_pr_clk_pin;
	output [CB_DATA_WIDTH-1:0] o_pr_data_pin;
	
	generate
		if (PR_INTERNAL_HOST == 1) begin
            if ((DEVICE_FAMILY == "Stratix V") || (DEVICE_FAMILY == "Cyclone V") ||
                (DEVICE_FAMILY == "Arria V") || (DEVICE_FAMILY == "Arria V GZ")) begin
                alt_pr_cb_controller_v1 alt_pr_cb_controller_v1(
                    .clk(clk),
                    .nreset(nreset),
                    .pr_start(pr_start),
                    .double_pr(double_pr),
                    .o_freeze(o_freeze),
                    .o_crc_error(o_crc_error),
                    .o_pr_error(o_pr_error),
                    .o_pr_ready(o_pr_ready),
                    .o_pr_done(o_pr_done),
                    .pr_clk(pr_clk),
                    .pr_data(pr_data),
                    .pr_ready_pin(pr_ready_pin),
                    .pr_done_pin(pr_done_pin),
                    .pr_error_pin(pr_error_pin),
                    .o_pr_request_pin(o_pr_request_pin),
                    .o_pr_clk_pin(o_pr_clk_pin),
                    .o_pr_data_pin(o_pr_data_pin),
                    .crc_error_pin(crc_error_pin),
                    .bitstream_ready(bitstream_ready)
                );
                defparam alt_pr_cb_controller_v1.CDRATIO = CDRATIO; 
                defparam alt_pr_cb_controller_v1.CB_DATA_WIDTH = CB_DATA_WIDTH;
                defparam alt_pr_cb_controller_v1.EDCRC_OSC_DIVIDER = EDCRC_OSC_DIVIDER;
                defparam alt_pr_cb_controller_v1.PR_INTERNAL_HOST = PR_INTERNAL_HOST;
                defparam alt_pr_cb_controller_v1.DEVICE_FAMILY = DEVICE_FAMILY;
            end
            else begin
                // for Arria 10 onwards
                alt_pr_cb_controller_v2 alt_pr_cb_controller_v2(
                    .clk(clk),
                    .nreset(nreset),
                    .pr_start(pr_start),
                    .o_freeze(o_freeze),
                    .o_crc_error(o_crc_error),
                    .o_pr_error(o_pr_error),
                    .o_pr_ready(o_pr_ready),
                    .o_pr_done(o_pr_done),
                    .pr_clk(pr_clk),
                    .pr_data(pr_data),
                    .pr_ready_pin(pr_ready_pin),
                    .pr_done_pin(pr_done_pin),
                    .pr_error_pin(pr_error_pin),
                    .o_pr_request_pin(o_pr_request_pin),
                    .o_pr_clk_pin(o_pr_clk_pin),
                    .o_pr_data_pin(o_pr_data_pin),
                    .crc_error_pin(crc_error_pin)
                );
                defparam alt_pr_cb_controller_v2.CDRATIO = CDRATIO; 
                defparam alt_pr_cb_controller_v2.CB_DATA_WIDTH = CB_DATA_WIDTH;
                defparam alt_pr_cb_controller_v2.EDCRC_OSC_DIVIDER = EDCRC_OSC_DIVIDER;
                defparam alt_pr_cb_controller_v2.PR_INTERNAL_HOST = PR_INTERNAL_HOST;
                defparam alt_pr_cb_controller_v2.DEVICE_FAMILY = DEVICE_FAMILY;
            end
        end
        else begin
            if ((EXT_HOST_TARGET_DEVICE_FAMILY == "Stratix V") || (EXT_HOST_TARGET_DEVICE_FAMILY == "Cyclone V") ||
                (EXT_HOST_TARGET_DEVICE_FAMILY == "Arria V") || (EXT_HOST_TARGET_DEVICE_FAMILY == "Arria V GZ")) begin
                alt_pr_cb_controller_v1 alt_pr_cb_controller_v1(
                    .clk(clk),
                    .nreset(nreset),
                    .pr_start(pr_start),
                    .double_pr(double_pr),
                    .o_freeze(o_freeze),
                    .o_crc_error(o_crc_error),
                    .o_pr_error(o_pr_error),
                    .o_pr_ready(o_pr_ready),
                    .o_pr_done(o_pr_done),
                    .pr_clk(pr_clk),
                    .pr_data(pr_data),
                    .pr_ready_pin(pr_ready_pin),
                    .pr_done_pin(pr_done_pin),
                    .pr_error_pin(pr_error_pin),
                    .o_pr_request_pin(o_pr_request_pin),
                    .o_pr_clk_pin(o_pr_clk_pin),
                    .o_pr_data_pin(o_pr_data_pin),
                    .crc_error_pin(crc_error_pin),
                    .bitstream_ready(bitstream_ready)
                );
                defparam alt_pr_cb_controller_v1.CDRATIO = CDRATIO; 
                defparam alt_pr_cb_controller_v1.CB_DATA_WIDTH = CB_DATA_WIDTH;
                defparam alt_pr_cb_controller_v1.EDCRC_OSC_DIVIDER = EDCRC_OSC_DIVIDER;
                defparam alt_pr_cb_controller_v1.PR_INTERNAL_HOST = PR_INTERNAL_HOST;
            end
            else begin
                // for Arria 10 onwards
                alt_pr_cb_controller_v2 alt_pr_cb_controller_v2(
                    .clk(clk),
                    .nreset(nreset),
                    .pr_start(pr_start),
                    .o_freeze(o_freeze),
                    .o_crc_error(o_crc_error),
                    .o_pr_error(o_pr_error),
                    .o_pr_ready(o_pr_ready),
                    .o_pr_done(o_pr_done),
                    .pr_clk(pr_clk),
                    .pr_data(pr_data),
                    .pr_ready_pin(pr_ready_pin),
                    .pr_done_pin(pr_done_pin),
                    .pr_error_pin(pr_error_pin),
                    .o_pr_request_pin(o_pr_request_pin),
                    .o_pr_clk_pin(o_pr_clk_pin),
                    .o_pr_data_pin(o_pr_data_pin),
                    .crc_error_pin(crc_error_pin)
                );
                defparam alt_pr_cb_controller_v2.CDRATIO = CDRATIO; 
                defparam alt_pr_cb_controller_v2.CB_DATA_WIDTH = CB_DATA_WIDTH;
                defparam alt_pr_cb_controller_v2.EDCRC_OSC_DIVIDER = EDCRC_OSC_DIVIDER;
                defparam alt_pr_cb_controller_v2.PR_INTERNAL_HOST = PR_INTERNAL_HOST;
            end
        end
	endgenerate
	
endmodule

