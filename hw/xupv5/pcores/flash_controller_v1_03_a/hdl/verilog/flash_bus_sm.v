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
 * flash_bus_sm.v - Flash Bus State Machine
 *
 * Responsible for keeping the bus controller busy, and handling any requests that need this bus
 **/
 
module flash_bus_sm #(
	parameter NUM_OF_CHIPS 		= 4,
	parameter CMD_FIFO_DATA_WIDTH	= 72,
	parameter RSLT_FIFO_DATA_WIDTH	= 26,
	parameter BUS_ADDR_WIDTH	= 40,
	parameter PAGE_SIZE_WIDTH	= 15
)
(
	// System signals
	input 	i_clk,
	input 	i_rst,

        // User logic (host interface) signals
        input i_recording_en,
        output o_top_bus_active,

	// Dispatch signals
        input i_disp_cmd_req,
        output o_disp_cmd_ack,
        input [CMD_FIFO_DATA_WIDTH-1:0] i_disp_cmd_data,
        output o_disp_rsp_req,
        input i_disp_rsp_ack,
        input i_disp_rsp_listening,
        output [RSLT_FIFO_DATA_WIDTH-1:0] o_disp_rsp_data,
        output [NUM_OF_CHIPS-1:0] o_disp_chip_active, // This is a one-hot encoding to the dispatch telling it if there is already an active operation for this chip 
        output o_disp_wr_buffer_rsvd,
        output o_disp_rd_buffer_rsvd,

	// Cycle Count Signals
	output	[31:0]	o_cyclecount_sum,		//
	input	    	i_cyclecount_reset,		//
	input	[7:0]	i_cyclecount_start,		//
	input	[7:0]	i_cyclecount_end,		//
	
        // ADC Master signals
        output o_adc_master_record,

        // Bus controller signals
	input 			    			i_ctrl_busy,		//
	output reg 	[0:4] 				o_ctrl_operation,	// The new operation to start
	output reg	[log2(NUM_OF_CHIPS)-1:0]	o_ctrl_chip,		//
	output reg	[BUS_ADDR_WIDTH-1:0]		o_ctrl_addr,	        // 
	output reg	[PAGE_SIZE_WIDTH-1:0]		o_ctrl_length,		//
	output reg			        	o_ctrl_start,	    	// Start signal for the new operation
	input           [PAGE_SIZE_WIDTH-1:0]           i_sample_count,
        
        input [NUM_OF_CHIPS-1:0] i_ctrl_chip_ready,	// This a one-hot encoding of the R/B# lines coming from the flash bus 
	input [NUM_OF_CHIPS-1:0] i_ctrl_chip_result
);
	
	// Begin Module Architecture
	`include "functions.v"
	
	// Include Bus Operations
	`include "bus_ops.v"
	
	// Include Host Operations
	`include "host_ops.v"
	
	// Define command address width for functions
	localparam CMD_BUS_ADDR_WIDTH 	= 46;
	localparam CMD_TAG_WIDTH	= 8;
	localparam CMD_SIZE_WIDTH 	= 10;
	localparam CMD_OP_WIDTH 	= 8;
	
	function [CMD_TAG_WIDTH-1:0] getTagFromCommand;
		input [CMD_FIFO_DATA_WIDTH-1:0] addr;
		getTagFromCommand = addr[CMD_FIFO_DATA_WIDTH-1 -: CMD_TAG_WIDTH];
	endfunction
	
	function [CMD_SIZE_WIDTH-1:0] getSizeFromCommand;
		input [CMD_FIFO_DATA_WIDTH-1:0] addr;
		getSizeFromCommand = addr[CMD_FIFO_DATA_WIDTH-CMD_TAG_WIDTH-1 -: CMD_SIZE_WIDTH];
	endfunction
	
	function [CMD_OP_WIDTH-1:0] getOpFromCommand;
		input [CMD_FIFO_DATA_WIDTH-1:0] addr;
		getOpFromCommand = addr[CMD_FIFO_DATA_WIDTH-CMD_TAG_WIDTH-CMD_SIZE_WIDTH-1 -: CMD_OP_WIDTH];
	endfunction
	
	function [CMD_BUS_ADDR_WIDTH-1:0] getBusAddrFromCommand;
		input [CMD_FIFO_DATA_WIDTH-1:0] addr;
		getBusAddrFromCommand = addr[CMD_BUS_ADDR_WIDTH-1 : 0];
	endfunction
	
	function [1:0] getChipNum;
		input [CMD_BUS_ADDR_WIDTH-1:0] addr;
		getChipNum = addr[CMD_BUS_ADDR_WIDTH-2-2-1 : CMD_BUS_ADDR_WIDTH-2-2-2];
	endfunction
	
	function [39:0] getRemainingAddress;
		input [CMD_BUS_ADDR_WIDTH-1:0] addr;
		getRemainingAddress = addr[CMD_BUS_ADDR_WIDTH-2-4-1 : 0];
	endfunction
	
	// Command Registers
	// Command Data = {tag(8),size(10),op(8),addr(46)}
	reg [CMD_TAG_WIDTH-1:0]		cmd_tag_reg, cmd_tag_next;
	reg [CMD_SIZE_WIDTH-1:0]	cmd_size_reg, cmd_size_next;
	reg [CMD_OP_WIDTH-1:0]		cmd_op_reg, cmd_op_next;
	reg [CMD_BUS_ADDR_WIDTH-1:0]	cmd_addr_reg, cmd_addr_next;
	
	// Scoreboard Data Signals
	localparam CHIP_STATE_WIDTH	= 5;
	localparam CYCLE_COUNT_WIDTH	= 36;
	localparam TOTAL_SB_WIDTH	= CMD_TAG_WIDTH+CMD_OP_WIDTH+CHIP_STATE_WIDTH+CMD_SIZE_WIDTH+1+CMD_BUS_ADDR_WIDTH+CYCLE_COUNT_WIDTH; // This is the total width of the data that is stored in the scoreboard
	wire [CMD_TAG_WIDTH-1:0]	sb_tag_rd;
	wire [CMD_OP_WIDTH-1:0] 	sb_op_rd;
	wire [CHIP_STATE_WIDTH-1:0]	sb_chip_state_rd;
	wire [CMD_SIZE_WIDTH-1:0]	sb_length_rd;
	wire [CMD_BUS_ADDR_WIDTH-1:0]	sb_bus_addr_rd;
	wire [CYCLE_COUNT_WIDTH-1:0]	sb_cycle_count_rd;	// The operation cycle count when this operation started
	wire	                        sb_sent_read_status_rd;
	reg [CMD_TAG_WIDTH-1:0]	        sb_tag_wr;
	reg [CMD_OP_WIDTH-1:0]	        sb_op_wr;
	reg [CHIP_STATE_WIDTH-1:0]	sb_chip_state_wr;
	reg [CMD_SIZE_WIDTH-1:0]	sb_length_wr;
	reg [CMD_BUS_ADDR_WIDTH-1:0]	sb_bus_addr_wr;
	reg [CYCLE_COUNT_WIDTH-1:0]	sb_cycle_count_wr;
	reg	                        sb_sent_read_status_wr;
	reg sb_fifo_we = 0;
        reg [1:0] sb_addr;

	reg [35:0]	sys_cycle_count_reg, sys_cycle_count_next; 	// Keeps track of number of cycles since starting
	reg [0:31]	op_cycle_count_reg, op_cycle_count_next; 	// Keeps track of the number of cycles of operations indicated by i_cyclecount_start & i_cyclecount_end

        reg recording_reg, recording_next;

        reg new_cmd_ack_reg, new_cmd_ack_next;
        reg new_rsp_req_reg, new_rsp_req_next;
        reg [RSLT_FIFO_DATA_WIDTH-1:0] new_rsp_data_reg, new_rsp_data_next;
        reg [NUM_OF_CHIPS-1:0] chip_active_reg, chip_active_next;
        reg wr_buffer_rsvd_reg, wr_buffer_rsvd_next;
        reg rd_buffer_rsvd_reg, rd_buffer_rsvd_next;
        reg [log2(NUM_OF_CHIPS)-1:0] curr_chip_reg, curr_chip_next;
    
        wire [NUM_OF_CHIPS-1:0] new_cmd_chip_decode = {{NUM_OF_CHIPS-1{1'b0}},1'b1} << getChipNum(cmd_addr_reg);
        
	// local chip states
	localparam CS_IDLE 		 = 0; // Chip has no assigned request
        localparam CS_READ_START_PENDING = 1; //chip has a pending read operation
	localparam CS_READ_DATA_PENDING  = 2; //waiting for bus to be free
	localparam CS_READ_DATA_DONE	 = 3; //waiting for bus to be free
	localparam CS_WRITE_DATA_PENDING = 4; // Send the write command and data
	localparam CS_WRITE_DATA_ONBUS   = 5; // Finished sending the data
	localparam CS_WRITE_DATA_DONE    = 6; // Chip has written everything back
	localparam CS_ERASE_PENDING      = 7;
	localparam CS_ERASE_ONBUS        = 8;
	localparam CS_ERASE_DONE         = 9;
	localparam CS_READID_0           = 10;
	localparam CS_READID_1           = 11;
	localparam CS_READPARAM_0        = 12;
	localparam CS_READPARAM_1        = 13;
	localparam CS_READPARAM_2        = 14;
	localparam CS_SETTIMINGMODE_0    = 15;
	localparam CS_SETTIMINGMODE_1    = 16;
	localparam CS_RESET_0            = 17;
	localparam CS_RESET_1            = 18;
        localparam CS_GET_ADC_SAMPLES_0  = 19;
        localparam CS_GET_ADC_SAMPLES_1  = 20;
        localparam CS_UNKNOWN            = 21;	
	
        // State machine signals
	localparam STATE_IDLE 		      = 0;
	localparam STATE_NEW_RQST_0	      = 1;
	localparam STATE_GET_NEXT_OP_0 	      = 2;
	localparam STATE_GET_NEXT_OP_1 	      = 3;
	localparam STATE_GET_NEXT_OP_2 	      = 4;
        localparam STATE_WAIT_FOR_CONTROLLER  = 5;
        localparam STATE_CHECK_FOR_CHIP_READY = 6;
	localparam STATE_DO_BUS_OP	      = 7;
	localparam STATE_NEW_RSLT_0	      = 8;
	localparam STATE_NEW_RSLT_1	      = 9;
	localparam STATE_SWITCH_CHIPS	      = 10;
	reg [3:0] state_reg, state_next;
	
	// Registers
	always @(posedge i_clk or posedge i_rst) begin
            if (i_rst) begin
                state_reg <= STATE_IDLE;
                sys_cycle_count_reg <= 0;
                op_cycle_count_reg <= 0;
                recording_reg <= 0;
                cmd_tag_reg <= 0;
                cmd_size_reg <= 0;
                cmd_op_reg <= 0;
                cmd_addr_reg <= 0;
                new_cmd_ack_reg <= 0;
                new_rsp_req_reg <= 0;
                new_rsp_data_reg <= 0;
                chip_active_reg <= 0;
                wr_buffer_rsvd_reg <= 0;
                rd_buffer_rsvd_reg <= 0;
                curr_chip_reg <= 0;
            end else begin
                state_reg <= state_next;
                sys_cycle_count_reg <= sys_cycle_count_next;
                op_cycle_count_reg <= op_cycle_count_next;
                recording_reg <= recording_next;
                cmd_tag_reg <= cmd_tag_next;
                cmd_size_reg <= cmd_size_next;
                cmd_op_reg <= cmd_op_next;
                cmd_addr_reg <= cmd_addr_next;
                new_cmd_ack_reg <= new_cmd_ack_next;
                new_rsp_req_reg <= new_rsp_req_next;
                new_rsp_data_reg <= new_rsp_data_next;
                chip_active_reg <= chip_active_next;
                wr_buffer_rsvd_reg <= wr_buffer_rsvd_next;
                rd_buffer_rsvd_reg <= rd_buffer_rsvd_next;
                curr_chip_reg <= curr_chip_next;
            end
	end
	
	// Next-state and output logic
	always @* begin
            // Set default signal values
            state_next = state_reg;
            sys_cycle_count_next = sys_cycle_count_reg + 1;
            op_cycle_count_next = i_cyclecount_reset ? 0 : op_cycle_count_reg;
            cmd_tag_next = cmd_tag_reg;
            cmd_size_next = cmd_size_reg;
            cmd_op_next = cmd_op_reg;
            cmd_addr_next = cmd_addr_reg;
                    
            new_cmd_ack_next = 0;
            new_rsp_req_next = new_rsp_req_reg;
            new_rsp_data_next = new_rsp_data_reg;
            chip_active_next = chip_active_reg;
            wr_buffer_rsvd_next = wr_buffer_rsvd_reg;
            rd_buffer_rsvd_next = rd_buffer_rsvd_reg;
            curr_chip_next = curr_chip_reg;

            sb_tag_wr = sb_tag_rd;
            sb_op_wr = sb_op_rd;
            sb_chip_state_wr = sb_chip_state_rd;
            sb_length_wr = sb_length_rd;
            sb_bus_addr_wr = sb_bus_addr_rd;
            sb_cycle_count_wr = sb_cycle_count_rd;
            sb_sent_read_status_wr = sb_sent_read_status_rd;
            sb_addr = curr_chip_reg;
            sb_fifo_we = 0;
    
            recording_next = (!i_recording_en) ? 0 : recording_reg;
            
            o_ctrl_operation = 0;
            o_ctrl_chip = getChipNum(sb_bus_addr_rd);
            o_ctrl_addr = getRemainingAddress(sb_bus_addr_rd);
            o_ctrl_length = {sb_length_rd,5'd0};
            o_ctrl_start = 0;
            
            case(state_reg)
                STATE_IDLE: begin
                    cmd_tag_next = getTagFromCommand(i_disp_cmd_data);
                    cmd_size_next = getSizeFromCommand(i_disp_cmd_data);
                    cmd_op_next = getOpFromCommand(i_disp_cmd_data);
                    cmd_addr_next = getBusAddrFromCommand(i_disp_cmd_data);
                    
                    // Check for new requests and if there is room in the queue
                    if (i_disp_cmd_req) begin
                        // Ack the request
                        new_cmd_ack_next = 1;
                
                        state_next = STATE_NEW_RQST_0;
                    end else if (chip_active_reg[curr_chip_reg]) begin
                        state_next = STATE_GET_NEXT_OP_0;
                    end else begin
                        curr_chip_next = curr_chip_reg + 1;
                    end
                end
                
                STATE_NEW_RQST_0: begin // Write the new request to the scoreboard
                    // Write the values to the scoreboard
                    sb_tag_wr = cmd_tag_reg;
                    sb_op_wr = cmd_op_reg;
                    sb_length_wr = cmd_size_reg; // This is a 5 bit shift because the cmd_size_reg is in terms of 32 byte chunks instead of bytes
                    sb_bus_addr_wr = cmd_addr_reg;
                    sb_sent_read_status_wr = 0;
                    sb_addr = getChipNum(cmd_addr_reg);
                    sb_fifo_we = 1;
    
                    // Mark the chip as active
                    chip_active_next = chip_active_reg | new_cmd_chip_decode;

                    // Assign correct Chip State
                    if (cmd_op_reg == HOP_READ) begin
                        sb_chip_state_wr = CS_READ_START_PENDING;
                        rd_buffer_rsvd_next = 1;
                    end else if (cmd_op_reg == HOP_PROGRAM) begin
                        sb_chip_state_wr = CS_WRITE_DATA_PENDING;
                        wr_buffer_rsvd_next = 1;
                    end else if (cmd_op_reg == HOP_ERASE) begin
                        sb_chip_state_wr = CS_ERASE_PENDING;					
                    end else if (cmd_op_reg == HOP_READID) begin
                        sb_chip_state_wr = CS_READID_0;
                        rd_buffer_rsvd_next = 1;
                    end else if (cmd_op_reg == HOP_READPARAM) begin
                        sb_chip_state_wr = CS_READPARAM_0;
                        rd_buffer_rsvd_next = 1;
                    end else if (cmd_op_reg == HOP_SET_TIMING_MODE) begin
                        sb_chip_state_wr = CS_SETTIMINGMODE_0;
                    end else if (cmd_op_reg == HOP_RESET) begin
                        sb_chip_state_wr = CS_RESET_0;
                    end else if (cmd_op_reg == HOP_GET_ADC_SAMPLES) begin
                        sb_chip_state_wr = CS_GET_ADC_SAMPLES_0;
                        rd_buffer_rsvd_next = 1;
                    end
                    
                    state_next = STATE_IDLE;
                end
                
                STATE_GET_NEXT_OP_0: begin // Wait a cycle
                    state_next = STATE_GET_NEXT_OP_1;
                end
                
                STATE_GET_NEXT_OP_1: begin // Wait a cycle
                    state_next = STATE_WAIT_FOR_CONTROLLER;
                end

                STATE_WAIT_FOR_CONTROLLER: begin
                    if (!i_ctrl_busy) begin
                        // If you are just reading the ADC samples, you don't care if the chip is ready or not
                        if (sb_op_rd == HOP_GET_ADC_SAMPLES) begin
                            state_next = STATE_DO_BUS_OP;
                        end else begin
                            state_next = STATE_CHECK_FOR_CHIP_READY;
                        end
                    end
                end

                STATE_CHECK_FOR_CHIP_READY: begin
                    // If the chip isn't ready, give another chip a chance to go
                    if (!i_ctrl_chip_ready[getChipNum(sb_bus_addr_rd)]) begin        
                        o_ctrl_operation = (sb_sent_read_status_rd) ? OP_JUSTREADSTATUS : OP_READSTATUS;
                        o_ctrl_start = 1;

                        sb_sent_read_status_wr = 1;
                        sb_fifo_we = 1;

                        state_next = STATE_SWITCH_CHIPS;
                    end else begin
                        state_next = STATE_DO_BUS_OP;
                    end
                end
                STATE_DO_BUS_OP: begin
                    if (i_cyclecount_start[CHIP_STATE_WIDTH-1:0] == CS_IDLE) begin
                        recording_next = 0;
                    end else if (i_cyclecount_start[CHIP_STATE_WIDTH-1:0] == sb_chip_state_rd) begin
                        sb_cycle_count_wr = sys_cycle_count_reg; 
                        if (i_recording_en) begin
                            recording_next = 1;
                        end
                    end 
                    
                    if (i_cyclecount_end[CHIP_STATE_WIDTH-1:0] == CS_IDLE) begin
                        recording_next = 0;
                    end else if (i_cyclecount_end[CHIP_STATE_WIDTH-1:0] == sb_chip_state_rd) begin
                        op_cycle_count_next = op_cycle_count_reg + (sys_cycle_count_reg - sb_cycle_count_rd);
                        recording_next = 0;
                    end
                    
                    case (sb_chip_state_rd)
                        // Send an operation to the controller, switch on chip_state
                        CS_READ_START_PENDING, CS_READ_DATA_PENDING,
                        CS_WRITE_DATA_PENDING,
                        CS_ERASE_PENDING,
                        CS_READID_0,
                        CS_READPARAM_0, CS_READPARAM_1,
                        CS_SETTIMINGMODE_0,
                        CS_RESET_0,
                        CS_GET_ADC_SAMPLES_0: begin
                            // Send operation to controller
                            case (sb_chip_state_rd)
                                CS_READ_START_PENDING: o_ctrl_operation = OP_STARTREAD;
                                CS_READ_DATA_PENDING:  o_ctrl_operation = OP_COMPLETEREAD;
                                CS_WRITE_DATA_PENDING: o_ctrl_operation = OP_PROGRAM;
                                CS_ERASE_PENDING:      o_ctrl_operation = OP_ERASE;
                                CS_READID_0:           o_ctrl_operation = OP_READID;
                                CS_READPARAM_0:        o_ctrl_operation = OP_READPARAM;
                                CS_READPARAM_1:        o_ctrl_operation = OP_COMPLETEREAD;
                                CS_SETTIMINGMODE_0:    o_ctrl_operation = OP_SET_TIMING_MODE;
                                CS_RESET_0:            o_ctrl_operation = OP_RESET;
                                CS_GET_ADC_SAMPLES_0:  o_ctrl_operation = OP_READ_ADC_SAMPLES;
                            endcase
                            o_ctrl_start = 1;
                            
                            case (sb_chip_state_rd)
                                CS_READ_START_PENDING: sb_chip_state_wr = CS_READ_DATA_PENDING;
                                CS_READ_DATA_PENDING:  sb_chip_state_wr = CS_READ_DATA_DONE;
                                CS_WRITE_DATA_PENDING: sb_chip_state_wr = CS_WRITE_DATA_ONBUS;
                                CS_ERASE_PENDING:      sb_chip_state_wr = CS_ERASE_ONBUS;
                                CS_READID_0:           sb_chip_state_wr = CS_READID_1;
                                CS_READPARAM_0:        sb_chip_state_wr = CS_READPARAM_1;
                                CS_READPARAM_1:        sb_chip_state_wr = CS_READPARAM_2;
                                CS_SETTIMINGMODE_0:    sb_chip_state_wr = CS_SETTIMINGMODE_1;
                                CS_RESET_0:            sb_chip_state_wr = CS_RESET_1;
                                CS_GET_ADC_SAMPLES_0:  sb_chip_state_wr = CS_GET_ADC_SAMPLES_1;
                            endcase
                            sb_fifo_we = 1;
                            state_next = STATE_SWITCH_CHIPS;
                        end
                       
                        // Intermediate chip states that don't send operations to the controller and don't send a result
                        CS_WRITE_DATA_ONBUS, CS_ERASE_ONBUS: begin
                            case (sb_chip_state_rd)
                                CS_WRITE_DATA_ONBUS: sb_chip_state_wr = CS_WRITE_DATA_DONE;
                                CS_ERASE_ONBUS:      sb_chip_state_wr = CS_ERASE_DONE;
                            endcase
                            sb_fifo_we = 1;
                            state_next = STATE_SWITCH_CHIPS;
                        end

                        // The request is over so send a result	
                        CS_READ_DATA_DONE,
                        CS_WRITE_DATA_DONE,
                        CS_ERASE_DONE,
                        CS_READID_1,
                        CS_READPARAM_2,
                        CS_SETTIMINGMODE_1,
                        CS_RESET_1,
                        CS_GET_ADC_SAMPLES_1: begin 
                            state_next = STATE_NEW_RSLT_0;
                        end
                    endcase
                end

                STATE_SWITCH_CHIPS: begin
                    curr_chip_next = curr_chip_reg + 1;
                    state_next = STATE_IDLE;
                end

                STATE_NEW_RSLT_0: begin
                    new_rsp_req_next = 1;
                    // If this was a GET_ADC_SAMPLES request, the length that should be in the result comes from the controller through i_sample_count
                    if (sb_op_rd == HOP_GET_ADC_SAMPLES) begin
                        if (i_sample_count[3:0] == 0) begin
                            new_rsp_data_next = {sb_tag_rd,i_sample_count[4+CMD_SIZE_WIDTH-1:4],8'd0};
                        end else begin
                            new_rsp_data_next = {sb_tag_rd,i_sample_count[4+CMD_SIZE_WIDTH-1:4] + {{CMD_SIZE_WIDTH-1{1'b0}},1'b1},8'd0};
                        end
                    end else begin
                        new_rsp_data_next = {sb_tag_rd,sb_length_rd,8'd0};
                    end

                    state_next = STATE_NEW_RSLT_1;
                end

                STATE_NEW_RSLT_1: begin
                    if (i_disp_rsp_ack) begin
                        chip_active_next[curr_chip_reg] = 0;
                        rd_buffer_rsvd_next = ((sb_op_rd == HOP_READ) || (sb_op_rd == HOP_READID) || (sb_op_rd == HOP_READPARAM) || (sb_op_rd == HOP_GET_ADC_SAMPLES)) ? 0 : rd_buffer_rsvd_reg;
                        wr_buffer_rsvd_next = (sb_op_rd == HOP_PROGRAM) ? 0 : wr_buffer_rsvd_reg;
                       
                        new_rsp_req_next = 0;
                        
                        state_next = STATE_SWITCH_CHIPS;
                    end
                end
            endcase
	end

	// Assign outputs
	assign o_cyclecount_sum = op_cycle_count_reg;
        assign o_disp_cmd_ack = new_cmd_ack_reg;
        assign o_disp_rsp_req = new_rsp_req_reg;
        assign o_disp_rsp_data = (i_disp_rsp_listening) ? new_rsp_data_reg : {RSLT_FIFO_DATA_WIDTH{1'bZ}};
        assign o_disp_chip_active = chip_active_reg;
        assign o_disp_wr_buffer_rsvd = wr_buffer_rsvd_reg;
        assign o_disp_rd_buffer_rsvd = rd_buffer_rsvd_reg;
        assign o_top_bus_active = |chip_active_reg;
        assign o_adc_master_record = recording_reg;
    
	// Scoreboard
	chip_scoreboard chip_scoreboard_inst (
            .clka(i_clk),
            .rsta(i_rst),
            .addra(sb_addr),
            .dina({sb_tag_wr,sb_op_wr,sb_chip_state_wr,sb_length_wr,sb_bus_addr_wr,sb_sent_read_status_wr,sb_cycle_count_wr}),
            .wea(sb_fifo_we),
            .douta({sb_tag_rd,sb_op_rd,sb_chip_state_rd,sb_length_rd,sb_bus_addr_rd,sb_sent_read_status_rd,sb_cycle_count_rd}) 
	);
	
endmodule
