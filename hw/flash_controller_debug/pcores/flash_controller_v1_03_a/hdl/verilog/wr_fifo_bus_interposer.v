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
// wr_fifo_bus_interposer.v
module wr_fifo_bus_interposer #(
	parameter WR_FIFO_DATA_WIDTH = 128
)
(
	// System Signals
	input i_clk,
	input i_rst,
	
	// Write FIFO Signals
	output [WR_FIFO_DATA_WIDTH-1:0] o_wr_fifo_data,
	output							o_wr_fifo_we,
	input 							i_wr_fifo_full,
	
	// Bus Master Signals
	input [63:0]	i_bus_master_data,
	input			i_bus_master_we,
	output 			o_bus_master_full
);

	// Begin Module Architecture
	`include "functions.v"
	
	// Support Signals
	reg 						 	index_reg, index_next;
	reg [WR_FIFO_DATA_WIDTH-1:0] 	buffer_reg, buffer_next;
	reg 							valid_reg, valid_next;
	
	// Registers
	always @(posedge i_clk) begin
		if (i_rst) begin
			buffer_reg <= 0;
			index_reg <= 0;
			valid_reg <= 0;
		end else begin
			buffer_reg <= buffer_next;
			index_reg <= index_next;
			valid_reg <= valid_next;
		end
	end
	
	always @* begin
		index_next = i_bus_master_we ? ~index_reg : index_reg;
		buffer_next[127:64] = (~index_reg && i_bus_master_we) ? i_bus_master_data : buffer_reg[127:64];
		buffer_next[63:0] = (index_reg && i_bus_master_we) ? i_bus_master_data : buffer_reg[63:0];
		valid_next = (valid_reg && i_wr_fifo_full) || (index_reg && i_bus_master_we);
	end
	
	// Assign Outputs
	assign o_wr_fifo_data = buffer_reg;
	assign o_wr_fifo_we = valid_reg && ~i_wr_fifo_full;
	assign o_bus_master_full = i_wr_fifo_full;
	
endmodule
