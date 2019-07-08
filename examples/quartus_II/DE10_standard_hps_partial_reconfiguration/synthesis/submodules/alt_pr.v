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

module alt_pr(
	clk,
	nreset,
	freeze,
	pr_start,
	double_pr,
	status,
	data,
	data_valid,
	data_ready,
	avmm_slave_address,
	avmm_slave_read,
	avmm_slave_readdata,
	avmm_slave_write,
	avmm_slave_writedata,
	avmm_slave_waitrequest,
	pr_ready_pin,
	pr_done_pin,
	pr_error_pin,
	pr_request_pin,
	pr_clk_pin,
	pr_data_pin,
	crc_error_pin
);
	parameter PR_INTERNAL_HOST = 1; // '1' means Internal Host, '0' means External Host
	parameter CDRATIO = 1; // valid: 1, 2, 4
	parameter DATA_WIDTH_INDEX = 16; // valid: 1, 2, 4, 8, 16, 32. For Avalon-MM interface, always set to 16.
	parameter CB_DATA_WIDTH = 16;
	parameter ENABLE_AVMM_SLAVE = 0; // '1' means Enable Avalon-MM slave interface, '0' means Conduit interface
	parameter ENABLE_JTAG = 1;	// '1' means Enable JTAG debug mode, '0' means Disable
	parameter EDCRC_OSC_DIVIDER = 1; // valid: 1, 2, 4, 8, 16, 32, 64, 128, 256
	parameter DEVICE_FAMILY	= "Stratix V";
    parameter EXT_HOST_TARGET_DEVICE_FAMILY	= "Stratix V"; // Target device family for PR when External Host is enabled. 
	parameter ENABLE_PRPOF_ID_CHECK = 1; // '1' means Enable, '0' means Disable
	parameter EXT_HOST_PRPOF_ID = 0; // valid: 32-bit integer value
	
	input clk;
	input nreset;
	input pr_start;
	input double_pr;
	input data_valid;
	input [DATA_WIDTH_INDEX-1:0] data;
	input avmm_slave_address;
	input avmm_slave_read;
	input avmm_slave_write;
	input [DATA_WIDTH_INDEX-1:0] avmm_slave_writedata;
	input pr_ready_pin;
	input pr_done_pin;
	input pr_error_pin;
	input crc_error_pin;
	
	output freeze;
	output data_ready;
	output [2:0] status;
	output [DATA_WIDTH_INDEX-1:0] avmm_slave_readdata;
	output avmm_slave_waitrequest;
	output pr_request_pin;
	output pr_clk_pin;
	output [CB_DATA_WIDTH-1:0] pr_data_pin;

	reg [1:0] pr_csr;
	reg [2:0] status_reg; // pr_csr[4:2]
	reg lock_error_reg;
	reg nreset_reg1;
	reg nreset_reg2;
	
	wire clk_w;
	wire nreset_w;
	wire pr_start_w;
	wire freeze_w;
	wire double_pr_w;
	wire crc_error_w;
	wire pr_error_w;
	wire pr_ready_w;
	wire pr_done_w;
	wire pr_clk_w;
	wire [CB_DATA_WIDTH-1:0] pr_data_w;
	wire [CB_DATA_WIDTH-1:0] data_w;
	wire data_valid_w;
	wire data_ready_w;
	wire [DATA_WIDTH_INDEX-1:0] data_int_w;
	wire data_valid_int_w;
	wire data_ready_int_w;
	wire jtag_control_w;
	wire jtag_start_w;
	wire jtag_tck_w;
	wire jtag_double_pr_w;
	wire [CB_DATA_WIDTH-1:0] jtag_data_w;
	wire jtag_data_valid_w;
	wire jtag_data_ready_w;
	wire [CB_DATA_WIDTH-1:0] stardard_data_w;
	wire stardard_data_valid_w;
	wire stardard_data_ready_w;
	wire bitstream_incompatible_w;
	wire bitstream_ready_w;
	wire avmm_start_w;
	wire avmm_double_pr_w;
	wire waitrequest_w;
	
	assign freeze = freeze_w;
	assign clk_w = jtag_control_w ? jtag_tck_w : clk;
	assign nreset_w = nreset_reg2;
	
	// avoid async reset removal issue 
	always @(negedge nreset or posedge clk_w)
	begin
		if (~nreset) begin
			{nreset_reg2, nreset_reg1} <= 2'b0;
		end
		else begin
			{nreset_reg2, nreset_reg1} <= {nreset_reg1, 1'b1};
		end
	end
	
	// manage status[2:0]
	always @(posedge clk_w)
	begin
		if (~nreset_w) begin
			// power-up or nreset asserted
			status_reg <= 3'b000;
			lock_error_reg <= 1'b0;
		end
		else if (crc_error_w && ~lock_error_reg) begin
			// CRC_ERROR detected
			status_reg <= 3'b010;
			lock_error_reg <= 1'b1;
		end
		else if (freeze_w) begin
			if (bitstream_incompatible_w && ~lock_error_reg) begin
				// incompatible bitstream error detected
				status_reg <= 3'b011;
				lock_error_reg <= 1'b1;
			end
			else if (pr_error_w && ~lock_error_reg) begin
				// PR_ERROR detected
				status_reg <= 3'b001;
				lock_error_reg <= 1'b1;
			end
		end
		else if (~freeze_w && (status_reg == 3'b100)) begin
			// PR operation passed
			status_reg <= 3'b101;
			lock_error_reg <= 1'b0;
		end
		else if (pr_start_w) begin
			// PR operation in progress
			status_reg <= 3'b100;
			lock_error_reg <= 1'b0;
		end
	end
	
	// Avalon-MM slave interface or conduit interface
	generate
		if (ENABLE_AVMM_SLAVE == 1) begin
			assign avmm_start_w = pr_csr[0];
			assign avmm_double_pr_w = pr_csr[1];
			assign data_int_w = avmm_slave_writedata;
			assign data_valid_int_w = avmm_slave_write && ~avmm_slave_address;
			assign avmm_slave_readdata = avmm_slave_address ? {{(DATA_WIDTH_INDEX-5){1'b0}}, status_reg[2:0], pr_csr[1:0]} : {(DATA_WIDTH_INDEX){1'b0}};
			assign avmm_slave_waitrequest = jtag_control_w ? 1'b1 : waitrequest_w;
			assign waitrequest_w = ~nreset_w || avmm_start_w || (freeze_w && data_valid_int_w && ~data_ready_int_w);
			assign pr_start_w = jtag_control_w ? jtag_start_w : avmm_start_w;
			assign double_pr_w = jtag_control_w ? jtag_double_pr_w : avmm_double_pr_w;
			
			always @(posedge clk_w)
			begin
				if (~nreset_w) begin
					pr_csr[1:0] <= 2'd0;
				end
				else if (avmm_slave_write && avmm_slave_address) begin
					pr_csr[0] <= avmm_slave_writedata[0];
					pr_csr[1] <= avmm_slave_writedata[1];
				end
				else begin
					pr_csr[0] <= 1'b0;
				end
			end
		end
		else begin
			assign status[2:0] = status_reg[2:0];
			assign data_ready = data_ready_int_w;
			assign data_int_w = data;
			assign data_valid_int_w = data_valid;
			assign avmm_slave_readdata = {(DATA_WIDTH_INDEX){1'b0}};
			assign avmm_slave_waitrequest = 1'b1;
			assign pr_start_w = jtag_control_w ? jtag_start_w : pr_start;
			assign double_pr_w = jtag_control_w ? jtag_double_pr_w : double_pr;
		end
	endgenerate
	
	alt_pr_cb_host alt_pr_cb_host(
		.clk(clk_w),
		.nreset(nreset_w),
		.pr_start(pr_start_w),
		.double_pr(double_pr_w),
		.o_freeze(freeze_w),
		.o_crc_error(crc_error_w),
		.o_pr_error(pr_error_w),
		.o_pr_ready(pr_ready_w),
		.o_pr_done(pr_done_w),
		.pr_clk(pr_clk_w),
		.pr_ready_pin(pr_ready_pin),
		.pr_done_pin(pr_done_pin),
		.pr_error_pin(pr_error_pin),
		.o_pr_request_pin(pr_request_pin),
		.o_pr_clk_pin(pr_clk_pin),
		.o_pr_data_pin(pr_data_pin),
		.crc_error_pin(crc_error_pin),
		.pr_data(pr_data_w),
		.bitstream_ready(bitstream_ready_w)
	);
	defparam alt_pr_cb_host.CDRATIO = CDRATIO; 
	defparam alt_pr_cb_host.CB_DATA_WIDTH = CB_DATA_WIDTH;
	defparam alt_pr_cb_host.EDCRC_OSC_DIVIDER = EDCRC_OSC_DIVIDER;
	defparam alt_pr_cb_host.PR_INTERNAL_HOST = PR_INTERNAL_HOST;
	defparam alt_pr_cb_host.DEVICE_FAMILY = DEVICE_FAMILY;
    defparam alt_pr_cb_host.EXT_HOST_TARGET_DEVICE_FAMILY = EXT_HOST_TARGET_DEVICE_FAMILY;
    
	
	alt_pr_bitstream_host alt_pr_bitstream_host(
		.clk(clk_w),
		.nreset(nreset_w),
		.pr_start(pr_start_w),
		.double_pr(double_pr_w),
		.freeze(freeze_w),
		.crc_error(crc_error_w),
		.pr_error(pr_error_w),
		.pr_ready(pr_ready_w),
		.pr_done(pr_done_w),
		.data(data_w),
		.data_valid(data_valid_w),
		.o_data_ready(data_ready_w),
		.o_pr_clk(pr_clk_w),
		.o_pr_data(pr_data_w),
		.o_bitstream_incompatible(bitstream_incompatible_w),
		.o_bitstream_ready(bitstream_ready_w)
	);
	defparam alt_pr_bitstream_host.PR_INTERNAL_HOST = PR_INTERNAL_HOST; 
	defparam alt_pr_bitstream_host.CDRATIO = CDRATIO; 
	defparam alt_pr_bitstream_host.DONE_TO_END = ((CDRATIO==1) ? 7 : ((CDRATIO==2) ? 3 : 1 ));
	defparam alt_pr_bitstream_host.CB_DATA_WIDTH = CB_DATA_WIDTH; 
	defparam alt_pr_bitstream_host.ENABLE_PRPOF_ID_CHECK = ENABLE_PRPOF_ID_CHECK;
	defparam alt_pr_bitstream_host.EXT_HOST_PRPOF_ID = EXT_HOST_PRPOF_ID;
	defparam alt_pr_bitstream_host.DEVICE_FAMILY = DEVICE_FAMILY;
    defparam alt_pr_bitstream_host.EXT_HOST_TARGET_DEVICE_FAMILY = EXT_HOST_TARGET_DEVICE_FAMILY;
	
	alt_pr_data_source_controller alt_pr_data_source_controller(
		.clk(clk_w),
		.nreset(nreset_w),
		.jtag_control(jtag_control_w),
		.jtag_data(jtag_data_w),
		.jtag_data_valid(jtag_data_valid_w),
		.o_jtag_data_ready(jtag_data_ready_w),
		.standard_data(stardard_data_w),
		.standard_data_valid(stardard_data_valid_w),
		.o_standard_data_ready(stardard_data_ready_w),
		.data_ready(data_ready_w),
		.o_data(data_w),
		.o_data_valid(data_valid_w)
	);
	defparam alt_pr_data_source_controller.CB_DATA_WIDTH = CB_DATA_WIDTH; 
	
	alt_pr_standard_data_interface alt_pr_standard_data_interface(
		.clk(clk_w),
		.nreset(nreset_w),
		.freeze(freeze_w),
		.o_stardard_data(stardard_data_w),
		.o_stardard_data_valid(stardard_data_valid_w),
		.stardard_data_ready(stardard_data_ready_w),
		.data(data_int_w),
		.data_valid(data_valid_int_w),
		.o_data_ready(data_ready_int_w)
	);
	defparam alt_pr_standard_data_interface.CB_DATA_WIDTH = CB_DATA_WIDTH; 
	defparam alt_pr_standard_data_interface.DATA_WIDTH_INDEX = DATA_WIDTH_INDEX; 

	generate
		if (ENABLE_JTAG == 1) begin
			alt_pr_jtag_interface alt_pr_jtag_interface(
				.nreset(nreset_w),
				.freeze(freeze_w),
				.pr_ready(pr_ready_w),
				.pr_done(pr_done_w),
				.pr_error(pr_error_w),
				.crc_error(crc_error_w),
				.o_tck(jtag_tck_w),
				.o_double_pr(jtag_double_pr_w),
				.o_jtag_control(jtag_control_w),
				.o_jtag_start(jtag_start_w),
				.o_jtag_data(jtag_data_w),
				.o_jtag_data_valid(jtag_data_valid_w),
				.jtag_data_ready(jtag_data_ready_w),
				.bitstream_incompatible(bitstream_incompatible_w)
			);
			defparam alt_pr_jtag_interface.PR_INTERNAL_HOST = PR_INTERNAL_HOST;
			defparam alt_pr_jtag_interface.CB_DATA_WIDTH = CB_DATA_WIDTH;
		end
		else begin
			assign jtag_tck_w = 1'b0;
			assign jtag_double_pr_w = 1'b0;
			assign jtag_control_w = 1'b0;
			assign jtag_start_w = 1'b0;
			assign jtag_data_w = 1'b0;
			assign jtag_data_valid_w = 1'b0;
		end
	endgenerate 
	
endmodule

