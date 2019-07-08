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

module alt_pr_cb_controller_v1(
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

	localparam DONE_TO_LAST_CLOCK = 20;
	localparam ERROR_TO_LAST_CLOCK = 20;
	
	// slightly larger than 1 frame size for biggest SV device
	// may need update for A10 and future device
	localparam COMPUTE_EMR_TIME = 1001;
	
	localparam [3:0]	IDLE = 0,
						WAIT_TO_ASSERT_REQUEST = 1,
						WAIT_FOR_PR_READY = 2,
						SEND_PR_DATA = 3,
						WAIT_DONE_TO_LAST_CLOCK = 4,
						WAIT_PR_ERROR_TO_LAST_CLOCK = 5,
						WAIT_CRC_COMPUTE_EMR_TIME = 6, 
						WAIT_CRC_ERROR_TO_LAST_CLOCK = 7, 
						PR_PROCESS_DONE = 8;
						
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
				
	reg [3:0] pr_state;
	reg [1:0] pr_pass_cnt;
	reg [11:0] count;
	reg pr_request_reg;
	
	wire pr_start;
	wire pr_ready_w;
	wire pr_done_w;
	wire pr_error_w;
	wire crc_error_w;
	
	assign o_freeze = (pr_state != IDLE);
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
	
	initial begin
		pr_state <= IDLE;
		count <= 0;
	end
	
	always @(posedge clk)
	begin
		if (~nreset) begin
			pr_state <= IDLE;
		end
		else begin
			case (pr_state)
				IDLE: 
				begin
					pr_request_reg <= 0;
					pr_pass_cnt <= 0;
					
					if (pr_start) begin
						pr_state <= WAIT_TO_ASSERT_REQUEST;
					end
					else if (count < 12'd3000) begin
						count <= count + 12'd1;
					end
				end

				WAIT_TO_ASSERT_REQUEST:
				begin
					// considering worst number of clock cycles 
					// needed to meet 30us PR_REQUEST spec @100MHz
					if (count < 12'd3000) begin
						count <= count + 12'd1;
					end
					else begin
						pr_state <= WAIT_FOR_PR_READY;
						pr_request_reg <= 1'b1;
						count <= 0;
					end
				end
				
				WAIT_FOR_PR_READY: 
				begin
					if (pr_ready_w) begin
						pr_state <= SEND_PR_DATA;
					end
				end

				SEND_PR_DATA: 
				begin
					// bitstream host handles pr_clk and pr_data
					// here monitoring for passing or failing condition
					if (pr_error_w) begin
						pr_state <= WAIT_PR_ERROR_TO_LAST_CLOCK;
						pr_request_reg <= 0;
						count <= 0;
					end
					else if (crc_error_w) begin
						pr_state <= WAIT_CRC_COMPUTE_EMR_TIME;
						count <= 0;
					end
					else if (pr_done_w) begin
						pr_state <= WAIT_DONE_TO_LAST_CLOCK;
						pr_request_reg <= 0;
						count <= 0;
					end
				end

				WAIT_DONE_TO_LAST_CLOCK: 
				begin
					if (!bitstream_ready) begin
						count <= 0;
					end
					else if (count < ((DONE_TO_LAST_CLOCK * CDRATIO) - 1)) begin
						count <= count + 12'd1;
					end
					else if (!pr_done_w) begin
						pr_pass_cnt <= pr_pass_cnt + 2'd1;
						pr_state <= PR_PROCESS_DONE;
						count <= 0;
					end
				end

				WAIT_PR_ERROR_TO_LAST_CLOCK: 
				begin
					if (count < ((ERROR_TO_LAST_CLOCK * CDRATIO) - 1)) begin
						count <= count + 12'd1;
					end
					else if (!pr_error_w) begin
						pr_state <= IDLE;
						count <= 0;
					end
				end

				WAIT_CRC_COMPUTE_EMR_TIME:
				begin
					if (count < ((COMPUTE_EMR_TIME * CDRATIO) - 1)) begin
						count <= count + 12'd1;
					end
					else begin
						pr_state <= WAIT_CRC_ERROR_TO_LAST_CLOCK;
						pr_request_reg <= 0;
						count <= 0;
					end
				end

				WAIT_CRC_ERROR_TO_LAST_CLOCK: 
				begin
					if (count < ((ERROR_TO_LAST_CLOCK * CDRATIO) - 1)) begin
						count <= count + 12'd1;
					end
					else if (!crc_error_w) begin
						pr_state <= IDLE;
						count <= 0;
					end
				end

				PR_PROCESS_DONE: 
				begin
					count <= 0;
					if (double_pr && (pr_pass_cnt == 2'd1)) begin
						pr_state <= WAIT_TO_ASSERT_REQUEST;
					end
					else if (~pr_start) begin
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

