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
 * wr_fifo_interface.v - Write FIFO Interface
 *
 * Responsible for reading 128-bit value from Write FIFO and letting
 * controller read 8 bit increments.
 **/
module wr_fifo_interface #(
	parameter WR_FIFO_DATA_WIDTH = 128
)
(
	// System Signals
	input i_clk,
	input i_rst,
	
	// Write FIFO Signals
	input [WR_FIFO_DATA_WIDTH-1:0] 	i_wr_fifo_data,
	output reg						o_wr_fifo_re,
	input 							i_wr_fifo_empty,
	
	// Controller Signals
	output [7:0]	o_ctrl_data,
	input			i_ctrl_re,
	output reg		o_ctrl_empty
);

	// Begin Module Architecture
	`include "functions.v"
	
	// State Signals
	localparam STATE_READ_FROM_FIFO = 0;
	localparam STATE_OUTPUT			= 1;
	reg state_reg, state_next;
	
	// Index Signals
	localparam NUM_OF_BYTES = ceil_division(WR_FIFO_DATA_WIDTH,8);
	reg [log2(NUM_OF_BYTES)-1:0] index_reg, index_next;
	reg [WR_FIFO_DATA_WIDTH-1:0] buffer_reg, buffer_next;
	
	// Registers
	always @(posedge i_clk) begin
		if (i_rst) begin
			state_reg <= STATE_READ_FROM_FIFO;
			buffer_reg <= 0;
			index_reg <= 0;
		end else begin
			state_reg <= state_next;
			buffer_reg <= buffer_next;
			index_reg <= index_next;
		end
	end
	
	//always @(state_reg,index_reg,buffer_reg,i_wr_fifo_empty,i_wr_fifo_data,i_ctrl_re) begin
	always @* begin
		// Default Values
		state_next = state_reg;
		index_next = index_reg;
		buffer_next = buffer_reg;
		
		o_wr_fifo_re = 0;
		o_ctrl_empty = 0;
		
		case (state_reg)
			STATE_READ_FROM_FIFO: begin
				// Assert the empty signal
				o_ctrl_empty = 1;
				
				// Check to see if there is available data
				if (!i_wr_fifo_empty) begin
					// Read the data from the Write FIFO
					o_wr_fifo_re = 1;
					buffer_next = i_wr_fifo_data;
					
					// Reset the index counter
					index_next = 0;
					
					// Go to output state
					state_next = STATE_OUTPUT;
				end
				
			end
			
			STATE_OUTPUT: begin
				// Check to see if the controller requested data and we have valid data
				if (i_ctrl_re) begin
					// Check to see if this buffer is all done
					if (index_reg == NUM_OF_BYTES-1) begin
						// Go to Read State
						state_next = STATE_READ_FROM_FIFO;
					end else begin
						// Increment Index Counter
						index_next = index_reg + 1;
					end
				end
			end
		endcase
	end
	
	// Assign Outputs
	assign o_ctrl_data = 	(index_reg == 0) ? buffer_reg[127:120] :
							(index_reg == 1) ? buffer_reg[119:112] :	
							(index_reg == 2) ? buffer_reg[111:104] :	
							(index_reg == 3) ? buffer_reg[103:96] :	
							(index_reg == 4) ? buffer_reg[95:88] :	
							(index_reg == 5) ? buffer_reg[87:80] :	
							(index_reg == 6) ? buffer_reg[79:72] :	
							(index_reg == 7) ? buffer_reg[71:64] :	
							(index_reg == 8) ? buffer_reg[63:56] :	
							(index_reg == 9) ? buffer_reg[55:48] :	
							(index_reg == 10) ? buffer_reg[47:40] :	
							(index_reg == 11) ? buffer_reg[39:32] :	
							(index_reg == 12) ? buffer_reg[31:24] :	
							(index_reg == 13) ? buffer_reg[23:16] :	
							(index_reg == 14) ? buffer_reg[15:8] :	
							buffer_reg[7:0];
	//assign o_ctrl_data = buffer_reg[((NUM_OF_BYTES-index_reg)*8)-1 -: 8];
	
endmodule
