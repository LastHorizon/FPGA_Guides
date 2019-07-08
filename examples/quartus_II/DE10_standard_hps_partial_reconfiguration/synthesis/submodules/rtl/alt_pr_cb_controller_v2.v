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

module alt_pr_cb_controller_v2(
	clk,
	nreset,
	pr_start,
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
	crc_error_pin
);
	parameter PR_INTERNAL_HOST = 1;
	parameter CDRATIO = 1;
	parameter CB_DATA_WIDTH = 16;
	parameter EDCRC_OSC_DIVIDER = 1;
	parameter DEVICE_FAMILY	= "Arria 10";
	
	localparam [2:0]	IDLE = 0,
						WAIT_FOR_PR_READY_HIGH = 1,
						SEND_PR_DATA = 2,
						WAIT_FOR_PR_READY_LOW = 3,
						WAIT_FOR_PR_STATUS_LOW = 4,
						WAIT_FOR_EXIT = 5;
						
	input clk;
	input nreset;
	input pr_clk;
	input [CB_DATA_WIDTH-1:0] pr_data;
	input pr_start;

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
				
	reg [2:0] pr_state;
	reg pr_request_reg;
	reg freeze_reg;
	
	wire pr_start;
	wire pr_ready_w;
	wire pr_done_w;
	wire pr_error_w;
	wire crc_error_w;
	
	assign o_freeze = freeze_reg;
	assign o_crc_error = crc_error_w;
	assign o_pr_error = pr_error_w;
	assign o_pr_ready = pr_ready_w;
	assign o_pr_done = pr_done_w;
	
	generate
		if (PR_INTERNAL_HOST == 1) begin
			alt_pr_cb_interface alt_pr_cb_interface(
				.clk(clk),
				.pr_clk(pr_clk),
				.pr_data(pr_data),
				.pr_request(pr_request_reg),
				.o_pr_ready(pr_ready_w),
				.o_pr_done(pr_done_w),
				.o_pr_error(pr_error_w),
				.shiftnld(1'b1),
				.o_crc_error(crc_error_w)
			);
			defparam alt_pr_cb_interface.CB_DATA_WIDTH = CB_DATA_WIDTH; 
			defparam alt_pr_cb_interface.EDCRC_OSC_DIVIDER = EDCRC_OSC_DIVIDER;
			defparam alt_pr_cb_interface.DEVICE_FAMILY = DEVICE_FAMILY;
			
			assign o_pr_clk_pin = 1'b0;
			assign o_pr_data_pin = {(CB_DATA_WIDTH){1'b0}};
			assign o_pr_request_pin = 1'b0;
		end
		else begin
			assign o_pr_clk_pin = pr_clk;
			assign o_pr_data_pin = pr_data;
			assign o_pr_request_pin = pr_request_reg;
			assign pr_ready_w = pr_ready_pin;
			assign pr_done_w = pr_done_pin;
			assign pr_error_w = pr_error_pin;
			assign crc_error_w = crc_error_pin;
		end
	endgenerate
	
	always @(posedge clk)
	begin
		if (~nreset) begin
			pr_state <= IDLE;
		end
		else begin
			case (pr_state)
				IDLE: 
				begin
					pr_request_reg <= 1'b0;
					
					if (pr_start && ~pr_ready_w && ~pr_error_w) begin
						freeze_reg <= 1'b1;
						pr_request_reg <= 1'b1;
						pr_state <= WAIT_FOR_PR_READY_HIGH;
					end
					else if (pr_ready_w || pr_error_w) begin
						freeze_reg <= 1'b1;
					end
					else begin
						freeze_reg <= 1'b0;
					end
				end
				
				WAIT_FOR_PR_READY_HIGH: 
				begin
					if (pr_ready_w) begin
						pr_state <= SEND_PR_DATA;
					end
					else if (pr_error_w) begin
						pr_state <= IDLE;
					end
				end

				SEND_PR_DATA: 
				begin
					// bitstream host handles pr_clk and pr_data
					// here monitoring for passing or failing condition
					if (pr_error_w || crc_error_w || pr_done_w) begin
						pr_state <= WAIT_FOR_PR_READY_LOW;
					end
				end

				WAIT_FOR_PR_READY_LOW: 
				begin
					if (~pr_ready_w) begin
						pr_request_reg <= 1'b0;
						pr_state <= WAIT_FOR_PR_STATUS_LOW;
					end
				end

				WAIT_FOR_PR_STATUS_LOW: 
				begin
					if (~pr_error_w && ~pr_done_w) begin
						pr_state <= WAIT_FOR_EXIT;
					end
				end
				
				WAIT_FOR_EXIT: 
				begin
					if (~pr_start) begin
						pr_state <= IDLE;
					end
				end

				default: 
				begin
					pr_state <= IDLE;
				end
			endcase
		end
	end
	
endmodule

