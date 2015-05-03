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
// request_sm.v

module request_sm #(
	parameter DRAM_RQST_FIFO_DATA_WIDTH = 45,
	parameter CMD_FIFO_DATA_WIDTH 		= 72,
        parameter CMD_TAG_WIDTH = 6,
	parameter RSLT_FIFO_DATA_WIDTH 		= 26,
        parameter COMPLETE_CMD_WIDTH = 102
)
(
	// System Signals
	input i_clk,
	input i_rst,
	
	// Debug Signals
	output [3:0] o_state,
	output [2:0] o_completed_rqsts,
	output [2:0] o_completed_rslts,
	
	// Slave Register Signals
	input 		[COMPLETE_CMD_WIDTH-1:0]	i_slave_cmd,
	input						i_slave_new_rqst,
	output reg 					o_slave_clr_rqst,
	
	// DRAM Request FIFO Signals
	output reg	[DRAM_RQST_FIFO_DATA_WIDTH-1:0]	o_dram_rqst_fifo_data,
	output reg					o_dram_rqst_fifo_we,
	input						i_dram_rqst_fifo_full,
	
	// Command FIFO Signals
	output reg [CMD_FIFO_DATA_WIDTH-1:0]	o_cmd_fifo_data,
	output reg				o_cmd_fifo_we,
	input					i_cmd_fifo_full,
	
	// Result FIFO Signals
	input 		[RSLT_FIFO_DATA_WIDTH-1:0]	i_rslt_fifo_data,
	output reg					o_rslt_fifo_re,
	input						i_rslt_fifo_empty,
	
	output reg o_new_rslt,
	output reg [CMD_TAG_WIDTH-1:0] o_new_rslt_tag
);

	// Begin Module Architecture
	`include "host_ops.v"
	
        localparam CMD_FLASH_ADDR_WIDTH = 46;
	localparam RQST_DRAM_ADDR_WIDTH	= 32;
	localparam RQST_LENGTH_WIDTH    = 10;
	localparam RQST_OP_WIDTH	= 4;
	
	function [RQST_DRAM_ADDR_WIDTH-1:0] getDRAMAddr;
		input [COMPLETE_CMD_WIDTH-1:0] cmd;
	begin
		getDRAMAddr = cmd[COMPLETE_CMD_WIDTH-1 -: RQST_DRAM_ADDR_WIDTH];
	end
	endfunction
		
	function [CMD_FLASH_ADDR_WIDTH-1:0] getFlashAddr;
		input [COMPLETE_CMD_WIDTH-1:0] cmd;
	begin
		getFlashAddr = cmd[COMPLETE_CMD_WIDTH-RQST_DRAM_ADDR_WIDTH-2-1 -: CMD_FLASH_ADDR_WIDTH];
	end
	endfunction
	
	function [RQST_OP_WIDTH-1:0] getOp;
		input [COMPLETE_CMD_WIDTH-1:0] cmd;
	begin
		getOp = cmd[COMPLETE_CMD_WIDTH-RQST_DRAM_ADDR_WIDTH-2-CMD_FLASH_ADDR_WIDTH-1 -: RQST_OP_WIDTH];
	end
	endfunction
	
	function [RQST_LENGTH_WIDTH-1:0] getLength;
		input [COMPLETE_CMD_WIDTH-1:0] cmd;
	begin
		getLength = cmd[COMPLETE_CMD_WIDTH-RQST_DRAM_ADDR_WIDTH-2-CMD_FLASH_ADDR_WIDTH-RQST_OP_WIDTH-2-1 -: RQST_LENGTH_WIDTH];
	end
	endfunction
	
        function [CMD_TAG_WIDTH-1:0] getTagFromCommand;
		input [COMPLETE_CMD_WIDTH-1:0] cmd;
	begin
		getTagFromCommand = cmd[CMD_TAG_WIDTH-1:0];
	end
	endfunction

	function [CMD_TAG_WIDTH-1:0] getTag;
		input [RSLT_FIFO_DATA_WIDTH-1:0] rslt;
	begin
		getTag = rslt[RSLT_FIFO_DATA_WIDTH-2-1 -: CMD_TAG_WIDTH];
	end
	endfunction
	
	function [9:0] getLengthFromRslt;
		input [RSLT_FIFO_DATA_WIDTH-1:0] rslt;
	begin
		getLengthFromRslt = {rslt[RSLT_FIFO_DATA_WIDTH-8-1 -: 10]};
	end
	endfunction
	
	localparam MAX_DRAM_RQST_SIZE = 4064; // Maximum number of bytes that can be transferred in one DRAM Request (usually 4088, but we have to work in terms of 32 Bytes)
	localparam MAX_DRAM_RQST_CHUNK_SIZE = 10'd127; // Maximum number of chunks (32 bytes) that can be transferred in one DRAM Request (=4064/32)
	localparam MAX_DRAM_RQST_SIZE_BITS = 12'hFE0; // Maximum number of chunks (32 bytes) that can be transferred in one DRAM Request (this is equivalent to 4064 in hex)
	
	
	// State Machine Signals
	localparam STATE_IDLE		= 0;
	localparam STATE_NEW_RQST_0	= 1;
	localparam STATE_NEW_RQST_1	= 2;
	localparam STATE_NEW_RQST_2	= 3;
	localparam STATE_NEW_RSLT_0	= 4;
	localparam STATE_NEW_RSLT_1	= 5;
	localparam STATE_NEW_RSLT_2	= 6;
	localparam STATE_NEW_RSLT_3	= 7;
	localparam STATE_NEW_RSLT_4	= 8;
	reg [3:0] state_reg, state_next;
	
	// Scoreboard Data Signals
	wire [RQST_DRAM_ADDR_WIDTH-1:0]		sb_dram_addr_rd;
	wire [RQST_LENGTH_WIDTH-1:0]		sb_length_rd;
	wire [RQST_OP_WIDTH-1:0]		sb_op_rd;
	reg [RQST_DRAM_ADDR_WIDTH-1: 0]		sb_dram_addr_wr;
	reg [RQST_LENGTH_WIDTH-1:0]		sb_length_wr;
	reg [RQST_OP_WIDTH-1:0]			sb_op_wr;
	reg [CMD_TAG_WIDTH-1:0]			sb_addr;
	reg 				        sb_we;
	
	// Command Register Signals
	reg [RQST_DRAM_ADDR_WIDTH-1:0] 	cmd_dram_addr_reg, cmd_dram_addr_next;
	reg [RQST_LENGTH_WIDTH-1:0] 	cmd_length_reg, cmd_length_next;
	reg [RQST_OP_WIDTH-1:0] 	cmd_op_reg, cmd_op_next;
	reg [CMD_FLASH_ADDR_WIDTH-1:0] 	cmd_flash_addr_reg, cmd_flash_addr_next;
	reg [CMD_TAG_WIDTH-1:0]		cmd_tag_reg, cmd_tag_next;
	
	// Result info from flash bus
	localparam RSLT_DRAM_ADDR_WIDTH	= 32;
	localparam RSLT_TAG_WIDTH 	= CMD_TAG_WIDTH;
	localparam RSLT_LENGTH_WIDTH 	= 10;
	reg [RSLT_DRAM_ADDR_WIDTH-1:0] 	rslt_dram_addr_reg, rslt_dram_addr_next;
	reg [RSLT_TAG_WIDTH-1:0] 	rslt_tag_reg, rslt_tag_next;
	reg [RSLT_LENGTH_WIDTH-1:0] 	rslt_length_reg, rslt_length_next;
	
	reg [2:0] completed_rqsts_reg = 0, completed_rqsts_next = 0;
	reg [2:0] completed_rslts_reg = 0, completed_rslts_next = 0;
	
	// Registers
	always @(posedge i_clk)
	begin
		if (i_rst) begin
			state_reg <= STATE_IDLE;
			cmd_dram_addr_reg <= 0;
			cmd_length_reg <= 0;
			cmd_op_reg <= 0;
			cmd_flash_addr_reg <= 0;
			cmd_tag_reg <= 0;
			rslt_dram_addr_reg <= 0;
			rslt_tag_reg <= 0;
			rslt_length_reg <= 0;
			completed_rqsts_reg <= 0;
			completed_rslts_reg <= 0;
		end else begin
			state_reg <= state_next;
			cmd_dram_addr_reg <= cmd_dram_addr_next;
			cmd_length_reg <= cmd_length_next;
			cmd_op_reg <= cmd_op_next;
			cmd_flash_addr_reg <= cmd_flash_addr_next;
			cmd_tag_reg <= cmd_tag_next;
			rslt_dram_addr_reg <= rslt_dram_addr_next;
			rslt_tag_reg <= rslt_tag_next;
			rslt_length_reg <= rslt_length_next;
			completed_rqsts_reg <= completed_rqsts_next;
			completed_rslts_reg <= completed_rslts_next;
		end
	end
	
	// Next-State and Output Logic
	always @* begin
		// Default Values
		state_next = state_reg;
		cmd_dram_addr_next = cmd_dram_addr_reg;
		cmd_length_next = cmd_length_reg;
		cmd_op_next = cmd_op_reg;
		cmd_flash_addr_next = cmd_flash_addr_reg;
		cmd_tag_next = cmd_tag_reg;
		rslt_dram_addr_next = rslt_dram_addr_reg;
		rslt_tag_next = rslt_tag_reg;
		rslt_length_next = rslt_length_reg;
		
		completed_rqsts_next = completed_rqsts_reg;
		completed_rslts_next = completed_rslts_reg;
		
		sb_addr = rslt_tag_reg;
		sb_dram_addr_wr = sb_dram_addr_rd;
		sb_length_wr = sb_length_rd;
		sb_op_wr = sb_op_rd;		
		sb_we = 0;
		
		o_slave_clr_rqst = 0;
		
		o_cmd_fifo_data = 0;
		o_cmd_fifo_we = 0;
		
		o_dram_rqst_fifo_data = 0;
		o_dram_rqst_fifo_we = 0;
		
		o_rslt_fifo_re = 0;
		o_new_rslt = 0;
		o_new_rslt_tag = rslt_tag_reg;
		
		case (state_reg)
			STATE_IDLE: begin
				// Check for new requests
				if (i_slave_new_rqst) begin
					o_slave_clr_rqst = 1;
					
					// Register the input command
					cmd_dram_addr_next = getDRAMAddr(i_slave_cmd);
					cmd_length_next = getLength(i_slave_cmd);
					cmd_op_next = getOp(i_slave_cmd);
					cmd_flash_addr_next = getFlashAddr(i_slave_cmd);
                                        cmd_tag_next = getTagFromCommand(i_slave_cmd);
					
					state_next = STATE_NEW_RQST_0;
				end else if (!i_rslt_fifo_empty) begin // Check for new results
					// Register the result
					rslt_tag_next = getTag(i_rslt_fifo_data);
					rslt_length_next = getLengthFromRslt(i_rslt_fifo_data);
					
					// Read the value from the Result FIFO
					o_rslt_fifo_re = 1;
					
					state_next = STATE_NEW_RSLT_0;
				end 
			end
			
			STATE_NEW_RQST_0: begin // Write the values to the scoreboard in a new slot
				// Check to see if there is room in the scoreboard
                                sb_addr = cmd_tag_reg;
                                sb_dram_addr_wr = cmd_dram_addr_reg;
                                sb_length_wr = cmd_length_reg;
                                sb_op_wr = cmd_op_reg;
                                sb_we = 1;
                                
                                // Go to the next state
                                state_next = STATE_NEW_RQST_1;
			end
			
			STATE_NEW_RQST_1: begin // Wait for the command FIFO to open up and write the command
				// Check to see if there is room in the command FIFO
				if (!i_cmd_fifo_full) begin
					// Write to the Command FIFO
					// Command FIFO Data = {tag(8),size(10),op(8),addr(46)} - this length is in terms of 32 B chunks
					o_cmd_fifo_data = {2'h0,cmd_tag_reg,cmd_length_reg,4'h0,cmd_op_reg,cmd_flash_addr_reg};
					o_cmd_fifo_we = 1;
					
					// Check to see if the command is a program operation
					if (cmd_op_reg == HOP_PROGRAM)
						state_next = STATE_NEW_RQST_2;
					else begin
						state_next = STATE_IDLE;
						completed_rqsts_next = completed_rqsts_reg + 1;
					end
				end
			end
			
			STATE_NEW_RQST_2: begin // Wait for the DRAM Request FIFO to make some space
				// Check to see if there is space in the DRAM Request FIFO
				if (!i_dram_rqst_fifo_full) begin
					// Check to see if the command length is greater than the Master Controller can handle
					if (cmd_length_reg > MAX_DRAM_RQST_CHUNK_SIZE) begin
						// Create a new DRAM Request
						// DRAM Request FIFO Data = {addr(32),length(12),rnw(1)} - this length is in terms of bytes
						o_dram_rqst_fifo_data = {cmd_dram_addr_reg,MAX_DRAM_RQST_SIZE_BITS,1'b1};
						o_dram_rqst_fifo_we = 1;
						
						// Decrement the length
						cmd_length_next = cmd_length_reg - MAX_DRAM_RQST_CHUNK_SIZE;
						
						// Increment the DRAM Address
						cmd_dram_addr_next = cmd_dram_addr_reg + MAX_DRAM_RQST_SIZE;
					
					end else begin
						// Initiate a new read request to the DRAM Request FIFO
						// DRAM Request FIFO Data = {addr(32),length(12),rnw(1)}
						o_dram_rqst_fifo_data = {cmd_dram_addr_reg,{cmd_length_reg[6:0],5'd0},1'b1};
						o_dram_rqst_fifo_we = 1;
						
						state_next = STATE_IDLE;
						
						completed_rqsts_next = completed_rqsts_reg + 1;
					end
				end
			end

			STATE_NEW_RSLT_0: begin // Find the value in the scoreboard
				// The scoreboard address was just set, now you have to wait 2 more cycles
				state_next = STATE_NEW_RSLT_1;				
			end
			
			STATE_NEW_RSLT_1: begin // Wait for the value from the scoreboard
				state_next = STATE_NEW_RSLT_2;
			end
			
			STATE_NEW_RSLT_2: begin // Wait for the value from the scoreboard
				state_next = STATE_NEW_RSLT_3;
			end
			
			STATE_NEW_RSLT_3: begin // Possibly remove the entry from the scoreboard
				// Check to see if this is the end of the operation
				if (sb_op_rd == HOP_GET_ADC_SAMPLES) begin
                    // Assert that this operation has been completed
					o_new_rslt = 1;
                end else if (sb_length_rd == rslt_length_reg) begin
					// Assert that this operation has been completed
					o_new_rslt = 1;
				end else begin
					// Update the address and the remaining length
					sb_dram_addr_wr = sb_dram_addr_rd + {19'd0,rslt_length_reg,5'd0};
					sb_length_wr = sb_length_rd - rslt_length_reg;
					
					// Write the value back to the scoreboard
					sb_we = 1;
				end
				
				// Check to see if it was a read operation
				if ((sb_op_rd == HOP_READ) || (sb_op_rd == HOP_READID) || (sb_op_rd == HOP_READPARAM) || (sb_op_rd == HOP_GET_ADC_SAMPLES)) begin
					// Register the DRAM Address
					rslt_dram_addr_next = sb_dram_addr_rd;
					
					// Move to the DRAM Request State
					state_next = STATE_NEW_RSLT_4;
				end else begin
					// Update the completed results
					completed_rslts_next = completed_rslts_reg + 1;
					
					// Go back to Idle
					state_next = STATE_IDLE;
				end
			end
			
			STATE_NEW_RSLT_4: begin // If it was a read, write a new DRAM Request
				// Check to see if there is space in the DRAM
				if (!i_dram_rqst_fifo_full) begin
					// Check to see if the command length is greater than the Master Controller can handle
					if (rslt_length_reg > MAX_DRAM_RQST_CHUNK_SIZE) begin
						// Create a new DRAM Request
						// DRAM Request FIFO Data = {addr(32),length(12),rnw(1)}
						o_dram_rqst_fifo_data = {rslt_dram_addr_reg,MAX_DRAM_RQST_SIZE_BITS,1'b0};
						o_dram_rqst_fifo_we = 1;
						
						// Decrement the length
						rslt_length_next = rslt_length_reg - MAX_DRAM_RQST_CHUNK_SIZE;
						
						// Increment the DRAM Address
						rslt_dram_addr_next = rslt_dram_addr_reg + MAX_DRAM_RQST_SIZE;
					end else begin
						// Initiate a new read request to the DRAM Request FIFO
						// DRAM Request FIFO Data = {addr(32),length(12),rnw(1)}
						o_dram_rqst_fifo_data = {rslt_dram_addr_reg,{rslt_length_reg[6:0],5'd0},1'b0};
						o_dram_rqst_fifo_we = 1;

						// Update the completed results
						completed_rslts_next = completed_rslts_reg + 1;
						
						// Go back to Idle
						state_next = STATE_IDLE;	
					end
				end
			end
		endcase
	end
	
	assign o_state = state_reg;
	assign o_completed_rqsts = completed_rqsts_reg;
	assign o_completed_rslts = completed_rslts_reg;
	
	// Tag Scoreboard
	tag_scoreboard tagScoreboard (
		.clka(i_clk),
		.rsta(i_rst),
		.wea(sb_we),
		.addra(sb_addr),
		.dina({sb_dram_addr_wr,sb_length_wr,sb_op_wr}),
		.douta({sb_dram_addr_rd,sb_length_rd,sb_op_rd})
	);
	
endmodule
