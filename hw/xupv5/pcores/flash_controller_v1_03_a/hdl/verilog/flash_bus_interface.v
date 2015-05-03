//
// This file is part of the Ming II source release from The Non-volatile Systems
// Laboratory at UCSD.  If you use this code in your research, please acknowledge
// the NVSL in any papers you publish.
// 
// Contact info: Steven Swanson <swanson@cs.ucsd.edu>, (858) 534 - 1743
//  
//        University of California, San Diego 
//        Department of Computer Science and Engineering 
//        9500 Gilman Drive, Dept 0114 
//        La Jolla CA 92093-0114 USA
// 
// 
// Copyright 2009-2012 The Regents of the University of California
//
/**
 * flash_bus_interface.v - The interface to a flash bus, mirrors dist_mem interface
 *
 * This module sits in between the state machines of the flash technology
 * controller and each flash bus.  If there is only one bus in the flash
 * technology controller, this interface isn't needed because dist_mem
 * provides the same interface
 *
 **/
 module flash_bus_interface #(
	parameter CMD_FIFO_DATA_WIDTH 	= 72,
	parameter WR_FIFO_DATA_WIDTH 	= 128,
	parameter RD_FIFO_DATA_WIDTH 	= 136,
	parameter RSLT_FIFO_DATA_WIDTH 	= 26,
	parameter RD_FIFO_COUNT_WIDTH	= 11,
	parameter WR_FIFO_COUNT_WIDTH	= 11
 )
 (
	// System signals
	input 	i_clk,		// System clock
	input 	i_rst,		// System reset
	
	// Command FIFO Signals
	input	[CMD_FIFO_DATA_WIDTH-1:0]	i_cmd_fifo_data,
	output	[CMD_FIFO_DATA_WIDTH-1:0]	o_cmd_fifo_data,
	input					i_cmd_fifo_re,
	input					i_cmd_fifo_we,
	output	 				o_cmd_fifo_empty,
	output	 				o_cmd_fifo_full,

	// Write FIFO Signals
	input	[WR_FIFO_DATA_WIDTH-1:0]	i_wr_fifo_data,
	output	[WR_FIFO_DATA_WIDTH-1:0]	o_wr_fifo_data,
	input				        i_wr_fifo_re,
	input					i_wr_fifo_we,
	output					o_wr_fifo_almost_empty,
	output					o_wr_fifo_empty,
	output					o_wr_fifo_almost_full,
	output					o_wr_fifo_full,
	output	[WR_FIFO_COUNT_WIDTH-1:0]	o_wr_fifo_count,
	
	// Read FIFO Signals
	input	[RD_FIFO_DATA_WIDTH-1:0]	i_rd_fifo_data,
	output	[RD_FIFO_DATA_WIDTH-1:0]	o_rd_fifo_data,
	input					i_rd_fifo_re,
	input					i_rd_fifo_we,
	output					o_rd_fifo_almost_empty,
	output					o_rd_fifo_empty,
	output					o_rd_fifo_almost_full,
	output					o_rd_fifo_full,
	output	[RD_FIFO_COUNT_WIDTH-1:0]	o_rd_fifo_count,
	
	// Result FIFO Signals
	input	[RSLT_FIFO_DATA_WIDTH-1:0]	i_rslt_fifo_data,
	output	[RSLT_FIFO_DATA_WIDTH-1:0]	o_rslt_fifo_data,
	input					i_rslt_fifo_re,
	input					i_rslt_fifo_we,
	output					o_rslt_fifo_empty,
	output					o_rslt_fifo_full
);

	// Begin module architecture
	
	// Command FIFO
	command_fifo cmd_fifo (
		.clk(i_clk),
		.srst(i_rst),
		.din(i_cmd_fifo_data),
		.wr_en(i_cmd_fifo_we),
		.rd_en(i_cmd_fifo_re),
		.dout(o_cmd_fifo_data),
		.full(o_cmd_fifo_full),
		.empty(o_cmd_fifo_empty)
	);

	// Write FIFO
	write_fifo wr_fifo (
		.clk(i_clk),
		.srst(i_rst),
		.din(i_wr_fifo_data),
		.wr_en(i_wr_fifo_we),
		.rd_en(i_wr_fifo_re),
		.dout(o_wr_fifo_data),
		.almost_full(o_wr_fifo_almost_full),
		.full(o_wr_fifo_full),
		.almost_empty(o_wr_fifo_almost_empty),
		.empty(o_wr_fifo_empty),
		.data_count(o_wr_fifo_count)
	);
	
	// Read FIFO
	read_fifo rd_fifo (
		.clk(i_clk),
		.srst(i_rst),
		.din(i_rd_fifo_data),
		.wr_en(i_rd_fifo_we),
		.rd_en(i_rd_fifo_re),
		.dout(o_rd_fifo_data), 
		.almost_full(o_rd_fifo_almost_full),
		.full(o_rd_fifo_full),
		.almost_empty(o_rd_fifo_almost_empty),
		.empty(o_rd_fifo_empty),
		.data_count(o_rd_fifo_count)
	);
	
	// Result FIFO
	result_fifo rslt_fifo (
		.clk(i_clk),
		.srst(i_rst),
		.din(i_rslt_fifo_data),
		.wr_en(i_rslt_fifo_we),
		.rd_en(i_rslt_fifo_re),
		.dout(o_rslt_fifo_data),
		.full(o_rslt_fifo_full),
		.empty(o_rslt_fifo_empty)
	);
	
	
endmodule
