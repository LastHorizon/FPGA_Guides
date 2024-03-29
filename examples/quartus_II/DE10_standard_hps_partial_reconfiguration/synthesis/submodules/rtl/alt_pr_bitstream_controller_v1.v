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

//`define INC_PR_DATA_COUNT

module alt_pr_bitstream_controller_v1(
	clk,
	nreset,
	pr_start,
	double_pr,
	freeze,
	crc_error,
	pr_error,
	pr_ready,
	pr_done,
	data,
	data_valid,
	o_data_ready,
	o_pr_clk,
	o_pr_data,
	bitstream_incompatible,
	o_bitstream_ready
);
	parameter CDRATIO = 1; // valid: 1, 2, or 4
	parameter DONE_TO_END = 7; // normal:7, encrypt:3, compress:1, compress+enc:1
	parameter CB_DATA_WIDTH = 16;
	
	localparam [1:0]	IDLE = 0,
						WAIT_FOR_READY = 1,
						SEND_PR_DATA = 2;
						
	input clk; 
	input nreset;
	input pr_start;
	input double_pr;
	input freeze;
	input crc_error;
	input pr_error;
	input pr_ready;
	input pr_done;
	input [CB_DATA_WIDTH-1:0] data;
	input data_valid;
	input bitstream_incompatible;
	
	output o_data_ready;
	output o_pr_clk;
	output [CB_DATA_WIDTH-1:0] o_pr_data;
	output o_bitstream_ready;
						
	reg [1:0] bitstream_state;
	reg [CB_DATA_WIDTH-1:0] pr_data_reg;
	reg [2:0] done_to_end_cnt;
	reg [1:0] count;
	reg pr_second_pass;
	reg last_data_reg;
	reg pr_done_reg;
	reg enable_dclk_reg;
	reg enable_dclk_neg_reg;

`ifdef INC_PR_DATA_COUNT
	reg [29:0] PR_DATA_COUNT /* synthesis noprune */;
`endif
	
	assign o_data_ready = ~last_data_reg && (count == (CDRATIO-1)) && (bitstream_state == SEND_PR_DATA);
	assign o_pr_clk = ~clk && enable_dclk_reg && enable_dclk_neg_reg;
	assign o_pr_data = pr_data_reg;
	assign o_bitstream_ready = (bitstream_state == IDLE) || (double_pr && (bitstream_state == WAIT_FOR_READY));
	
	// get rid of glitch
	always @(negedge clk)
	begin
		if (~nreset) begin
			enable_dclk_neg_reg <= 0;
		end
		else begin
			enable_dclk_neg_reg <= enable_dclk_reg;
		end
	end
	
	always @(posedge clk)
	begin
		if (~nreset) begin
			bitstream_state <= IDLE;
		end
		else begin
			case (bitstream_state)
				IDLE: 
				begin
					count <= 0;
					pr_data_reg <= 0;
`ifdef INC_PR_DATA_COUNT
					PR_DATA_COUNT <= 0;
`endif
					done_to_end_cnt <= 0;
					pr_second_pass <= 0;
					last_data_reg <= 0;
					pr_done_reg <= 0;
					
					if (pr_start && ~freeze) begin
						enable_dclk_reg <= 1;
						bitstream_state <= WAIT_FOR_READY;
					end
					else if (freeze) begin
						enable_dclk_reg <= 1;
					end
					else begin
						enable_dclk_reg <= 0;
					end
				end

				WAIT_FOR_READY: 
				begin
					last_data_reg <= 0;
					done_to_end_cnt <= 0;
					
					if (pr_ready) begin
						// wait 3 clock cycles before sending 
						// actual PR data at 4th clock
						if (count == 3) begin
							count <= 0;
							bitstream_state <= SEND_PR_DATA;
							enable_dclk_reg <= 0;
						end
						else begin
							count <= count + 2'd1;
						end
					end
				end
				
				SEND_PR_DATA: 
				begin
					if (pr_done && (DONE_TO_END == 1)) begin
						last_data_reg <= 1;
					end
					else begin
						last_data_reg <= 0;
					end
								
					if (~crc_error && ~pr_error) begin
						if (data_valid || (pr_done && (DONE_TO_END == 1))) begin
							if (count == (CDRATIO-1)) begin
								count <= 0;
								enable_dclk_reg <= 1;
								
								if (~bitstream_incompatible) begin
									pr_data_reg <= data;
								end
								else begin
									// send all 0's to assert PR_ERROR
									pr_data_reg <= 0;
								end
								
`ifdef INC_PR_DATA_COUNT
								PR_DATA_COUNT <= PR_DATA_COUNT + 30'd1;
`endif
								if (pr_done) begin
									pr_done_reg <= 1;
								end
								
								if (pr_done || pr_done_reg) begin
									if (done_to_end_cnt == (DONE_TO_END-1)) begin
										count <= 0;
										if (double_pr && ~pr_second_pass) begin
											pr_done_reg <= 0;
											pr_second_pass <= 1;
											bitstream_state <= WAIT_FOR_READY;
										end
										else begin
											bitstream_state <= IDLE;
										end
									end
									else begin
										done_to_end_cnt <= done_to_end_cnt + 3'd1;
									end
								end
							end
							else begin
								count <= count + 2'd1;
							end
						end
						else if (count == (CDRATIO-1)) begin
							enable_dclk_reg <= 0;
							pr_data_reg <= 0;
						end
						else begin
							count <= count + 2'd1;
						end
					end
					else begin
						bitstream_state <= IDLE;
					end
				end
				
				default: 
				begin
					bitstream_state <= IDLE;
				end
			endcase
		end
	end
						
endmodule

