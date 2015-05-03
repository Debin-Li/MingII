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
 * rd_fifo_interface.v - Read FIFO Interface
 *
 * Responsible for combining 8 bit values from the controller and sending
 * them as 136-bit values to the Read FIFO
 **/
module rd_fifo_interface #(
	parameter RD_FIFO_DATA_WIDTH = 136,
	parameter ERROR_CODE_WIDTH = 8
)
(
	// System Signals
	input i_clk,
	input i_rst,
	
	// Read FIFO Signals
	output [RD_FIFO_DATA_WIDTH-1:0] o_rd_fifo_data,
	output reg						o_rd_fifo_we,
	input 							i_rd_fifo_full,
	
	// Controller Signals
	input [7:0]						i_ctrl_data,
	input [ERROR_CODE_WIDTH-1:0]	i_ctrl_error_code,
	input							i_ctrl_we,
	input							i_ctrl_flush,	// Used to flush the data even if the buffer is not full
	output reg						o_ctrl_full
);

	// Begin Module Architecture
	`include "functions.v"
	
	// State Signals
	localparam STATE_WRITE_TO_FIFO 	= 0;
	localparam STATE_INPUT			= 1;
	reg state_reg, state_next;
	
	// Index Signals
	localparam JUST_DATA_WIDTH = RD_FIFO_DATA_WIDTH-ERROR_CODE_WIDTH;
	localparam NUM_OF_BYTES = ceil_division(JUST_DATA_WIDTH,8);
	reg [log2(NUM_OF_BYTES)-1:0] index_reg, index_next;
	reg [JUST_DATA_WIDTH-1:0] buffer_data_reg, buffer_data_next;
	reg [ERROR_CODE_WIDTH-1:0] buffer_error_reg, buffer_error_next;
	
	// Registers
	always @(posedge i_clk) begin
		if (i_rst) begin
			state_reg <= STATE_INPUT;
			buffer_data_reg <= 0;
			buffer_error_reg <= 0;
			index_reg <= 0;
		end else begin
			state_reg <= state_next;
			buffer_data_reg <= buffer_data_next;
			buffer_error_reg <= buffer_error_next;
			index_reg <= index_next;
		end
	end
	
	//always @(state_reg,buffer_data_reg,buffer_error_reg,index_reg,i_rd_fifo_full,i_ctrl_we,i_ctrl_data,i_ctrl_error_code,i_ctrl_flush) begin
	always @* begin
		// Default Values
		state_next = state_reg;
		buffer_data_next = buffer_data_reg;
		buffer_error_next = buffer_error_reg;
		index_next = index_reg;
			
		o_ctrl_full = 0;
		o_rd_fifo_we = 0;
		
		case (state_reg)
			STATE_WRITE_TO_FIFO: begin
				// Assert the full signal
				o_ctrl_full = 1;
				
				// Check to see if the current output buffer is full and if the Read FIFO has room
				if (!i_rd_fifo_full) begin
					o_rd_fifo_we = 1;
					
					// Reset the registers
					index_next = 0;
					buffer_data_next = 0;
					buffer_error_next = 0;
					
					// Go to input state
					state_next = STATE_INPUT;
				end
			end
			
			STATE_INPUT: begin
				// Check to see if the controller sent data and the current input buffer is not full
				if (i_ctrl_we) begin
					// Write the data to the buffer in the correct slot
					/* This is a complete hack because XST does not allow variable indexing in this assignment */
					// The following is valid syntax (per Verliog 2001), but XST will not accept it
					//buffer_data_next[((NUM_OF_BYTES-index_reg)*8)-1 -: 8] = i_ctrl_data;
					if (index_reg == 0)
						buffer_data_next[127:120] = i_ctrl_data;
					else if (index_reg == 1)
						buffer_data_next[119:112] = i_ctrl_data;
					else if (index_reg == 2)
						buffer_data_next[111:104] = i_ctrl_data;
					else if (index_reg == 3)
						buffer_data_next[103:96] = i_ctrl_data;
					else if (index_reg == 4)
						buffer_data_next[95:88] = i_ctrl_data;
					else if (index_reg == 5)
						buffer_data_next[87:80] = i_ctrl_data;
					else if (index_reg == 6)
						buffer_data_next[79:72] = i_ctrl_data;
					else if (index_reg == 7)
						buffer_data_next[71:64] = i_ctrl_data;
					else if (index_reg == 8)
						buffer_data_next[63:56] = i_ctrl_data;
					else if (index_reg == 9)
						buffer_data_next[55:48] = i_ctrl_data;
					else if (index_reg == 10)
						buffer_data_next[47:40] = i_ctrl_data;
					else if (index_reg == 11)
						buffer_data_next[39:32] = i_ctrl_data;
					else if (index_reg == 12)
						buffer_data_next[31:24] = i_ctrl_data;
					else if (index_reg == 13)
						buffer_data_next[23:16] = i_ctrl_data;
					else if (index_reg == 14)
						buffer_data_next[15:8] = i_ctrl_data;
					else if (index_reg == 15)
						buffer_data_next[7:0] = i_ctrl_data;
					/* End of gross hack */
					
					// Register the error code
					buffer_error_next = i_ctrl_error_code;
					
					// Check to see if this buffer is now full
					if (index_reg == NUM_OF_BYTES-1) begin
						// Go to write to fifo state
						state_next = STATE_WRITE_TO_FIFO;
					end else begin
						index_next = index_reg + 1;
					end
				end
				
				// Check to see if the controller request a flush
				if (i_ctrl_flush) begin
					// Go to write to fifo state
					state_next = STATE_WRITE_TO_FIFO;
				end				
			end
		endcase
	end
	
	// Assign Outputs
	assign o_rd_fifo_data = {buffer_error_reg,buffer_data_reg};
	
endmodule
