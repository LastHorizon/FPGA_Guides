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

module alt_pr_cb_interface(
	clk,
	pr_clk,
	pr_data,
	pr_request,
	o_pr_ready,
	o_pr_done,
	o_pr_error,
	o_externalrequest,
	shiftnld,
	o_crc_error,
	o_regout
);
	parameter CB_DATA_WIDTH = 16;
	parameter EDCRC_OSC_DIVIDER = 1;
	parameter DEVICE_FAMILY	= "Stratix V";
	
	input clk; 
	input pr_clk;
	input [CB_DATA_WIDTH-1:0] pr_data;
	input pr_request;
	input shiftnld;

	output o_pr_ready;
	output o_pr_done;
	output o_pr_error;
	output o_externalrequest;
	output o_crc_error;
	output o_regout;

	// -----------------------------------------------------------------------
	// Instantiate wysiwyg for prblock and crcblock according to device family
	// -----------------------------------------------------------------------
	generate
		if (DEVICE_FAMILY == "Arria 10") begin
			twentynm_prblock m_prblock
			(
				.clk(pr_clk),
				.corectl(1'b1),
				.prrequest(pr_request),
				.data(pr_data),
				.externalrequest(o_externalrequest),
				.error(o_pr_error),
				.ready(o_pr_ready),
				.done(o_pr_done)
			);
		end
		else if (DEVICE_FAMILY == "Cyclone V") begin
			cyclonev_prblock m_prblock
			(
				.clk(pr_clk),
				.corectl(1'b1),
				.prrequest(pr_request),
				.data(pr_data),
				.externalrequest(o_externalrequest),
				.error(o_pr_error),
				.ready(o_pr_ready),
				.done(o_pr_done)
			);
		end
		else if (DEVICE_FAMILY == "Arria V") begin
			arriav_prblock m_prblock
			(
				.clk(pr_clk),
				.corectl(1'b1),
				.prrequest(pr_request),
				.data(pr_data),
				.externalrequest(o_externalrequest),
				.error(o_pr_error),
				.ready(o_pr_ready),
				.done(o_pr_done)
			);
		end
		else if (DEVICE_FAMILY == "Arria V GZ") begin
			arriavgz_prblock m_prblock
			(
				.clk(pr_clk),
				.corectl(1'b1),
				.prrequest(pr_request),
				.data(pr_data),
				.externalrequest(o_externalrequest),
				.error(o_pr_error),
				.ready(o_pr_ready),
				.done(o_pr_done)
			);
		end
		else begin	// default to Stratix V
			stratixv_prblock m_prblock
			(
				.clk(pr_clk),
				.corectl(1'b1),
				.prrequest(pr_request),
				.data(pr_data),
				.externalrequest(o_externalrequest),
				.error(o_pr_error),
				.ready(o_pr_ready),
				.done(o_pr_done)
			);
		end
	endgenerate
	
	generate
		if (DEVICE_FAMILY == "Arria 10") begin
			twentynm_crcblock m_crcblock
			(
				.clk(clk),
				.shiftnld(shiftnld),
				.crcerror(o_crc_error),
				.regout(o_regout)
			);
			defparam m_crcblock.oscillator_divider = EDCRC_OSC_DIVIDER;
		end
		else if (DEVICE_FAMILY == "Cyclone V") begin
			cyclonev_crcblock m_crcblock
			(
				.clk(clk),
				.shiftnld(shiftnld),
				.crcerror(o_crc_error),
				.regout(o_regout)
			);
			defparam m_crcblock.oscillator_divider = EDCRC_OSC_DIVIDER;
		end
		else if (DEVICE_FAMILY == "Arria V") begin
			arriav_crcblock m_crcblock
			(
				.clk(clk),
				.shiftnld(shiftnld),
				.crcerror(o_crc_error),
				.regout(o_regout)
			);
			defparam m_crcblock.oscillator_divider = EDCRC_OSC_DIVIDER;
		end
		else if (DEVICE_FAMILY == "Arria V GZ") begin
			arriavgz_crcblock m_crcblock
			(
				.clk(clk),
				.shiftnld(shiftnld),
				.crcerror(o_crc_error),
				.regout(o_regout)
			);
			defparam m_crcblock.oscillator_divider = EDCRC_OSC_DIVIDER;
		end
		else begin	// default to Stratix V
			stratixv_crcblock m_crcblock
			(
				.clk(clk),
				.shiftnld(shiftnld),
				.crcerror(o_crc_error),
				.regout(o_regout)
			);
			defparam m_crcblock.oscillator_divider = EDCRC_OSC_DIVIDER;
		end
	endgenerate
	
endmodule

