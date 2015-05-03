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
// rd_fifo_bus_interposer
module rd_fifo_bus_interposer #(
	parameter RD_FIFO_DATA_WIDTH = 136,
	parameter ERROR_CODE_WIDTH = 8
)
(
	// System Signals
	input i_clk,
	input i_rst,
	
	// Read FIFO Signals
	input [RD_FIFO_DATA_WIDTH-1:0] 	i_rd_fifo_data,
	output reg						o_rd_fifo_re,
	input 							i_rd_fifo_empty,
	
	// Bus Master Signals
	output [63:0]					o_bus_master_data,
	input							i_bus_master_re,
	output							o_bus_master_empty,
	
	input							i_start
);

	// Begin Module Architecture
	`include "functions.v"
	
	// Support Signals
	localparam JUST_DATA_WIDTH = RD_FIFO_DATA_WIDTH-ERROR_CODE_WIDTH;
	reg 						index_reg, index_next;
	reg [JUST_DATA_WIDTH-1:0]	buffer_reg, buffer_next;
    reg loaded_reg, loaded_next;
	
	// Registers
	always @(posedge i_clk) begin
		if (i_rst) begin
			buffer_reg <= 0;
			index_reg <= 0;
            loaded_reg <= 0;
		end else begin
			buffer_reg <= buffer_next;
			index_reg <= index_next;
            loaded_reg <= loaded_next;
		end
	end
	
	always @* begin
		index_next = i_bus_master_re ? ~index_reg : index_reg;
        
        if (!loaded_reg && !i_rd_fifo_empty) begin
            loaded_next = 1'b1;
            buffer_next = i_rd_fifo_data[127:0];
            o_rd_fifo_re = 1'b1;
        end else if (index_reg && i_bus_master_re) begin
            if (i_rd_fifo_empty) begin
                loaded_next = 1'b0;
                buffer_next = buffer_reg;
                o_rd_fifo_re = 1'b0;
            end else begin
                loaded_next = 1'b1;
                buffer_next = i_rd_fifo_data[127:0];
                o_rd_fifo_re = 1'b1;
            end
        end else begin
            loaded_next = loaded_reg;
            buffer_next = buffer_reg;
            o_rd_fifo_re = 1'b0;
        end

	end
	
	// Assign Outputs
	assign o_bus_master_data = (index_reg) ? buffer_reg[63:0] : buffer_reg[127:64];
	assign o_bus_master_empty = !loaded_reg;
	
endmodule
