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
 * flash_bus_controller.v - Flash Bus Controller 
 *
 * Responsible for actual interaction with flash chips over a bus
 **/
module flash_bus_controller #(
	parameter PERIOD			= 10,
	parameter NUM_OF_CHIPS 			= 4,
	parameter OP_WIDTH			= 5,
	parameter BUS_ADDR_WIDTH		= 40,
	parameter LENGTH_WIDTH			= 15
)
(
	// System Signals
	input 	i_clk,
	input 	i_rst,
	
        // Debug Signals
	//output [7:0] o_controller_state,
	
	// Bus State Machine Signals
	output reg				o_busy,		// Signal to bus state machine that the bus is busy
	input 	[OP_WIDTH-1:0] 			i_operation,	// operation from bus state machine
	input 	[log2(NUM_OF_CHIPS)-1:0]	i_chip,		// The chip number of the chip we want to talk to
	input 	[BUS_ADDR_WIDTH-1:0] 		i_addr,		// The address
	input 	[LENGTH_WIDTH-1:0]		i_length,	// The number of bytes of the new operation
	input 					i_start,	// start the operation
        output  [LENGTH_WIDTH-1:0]              o_sample_count, // The number of ADC samples (2 byte values) of the last OP_READ_ADC_SAMPLES operation

        output	[NUM_OF_CHIPS-1:0] 		o_chip_ready,	// Ready bit for each chip
	output	[NUM_OF_CHIPS-1:0] 		o_chip_result,	// Result status bit for each chip
	output	[NUM_OF_CHIPS-1:0] 		o_chip_exists,	// Exists bit for each chip

        // ADC Sample FIFO Signals
        input [15:0] i_adc_sample_fifo_data,
        input        i_adc_sample_fifo_almost_empty,
        input        i_adc_sample_fifo_empty,
        output       o_adc_sample_fifo_re,
        input        i_adc_sample_fifo_valid,

	// Write Buffer Signals
	output [12:0] o_wr_buffer_addr,
	input  [15:0] i_wr_buffer_data,
	
	// Read Buffer Signals
	output [12:0] o_rd_buffer_addr,
	output [15:0] o_rd_buffer_data,
	output	      o_rd_buffer_we,
	
	// Flash bus signals
	input 	[7:0] 		  i_bus_data,
	output	[7:0]	 	  o_bus_data,
	output		 	  o_bus_data_tri_n,
	output			  o_bus_we_n,
	output			  o_bus_re_n,
	output [NUM_OF_CHIPS-1:0] o_bus_ces_n,
	output			  o_bus_cle,
	output			  o_bus_ale
);

// Begin module architecture	

	// Include functions
	`include "functions.v"
	
	// Include NAND Flash Parameters
	`include "nand_params.v"
	
	// Include Bus Operations
	`include "bus_ops.v"
	
	// Local Parameters
	localparam DIR_OUT = 0;
	localparam DIR_IN  = 1;
	
	integer i;
	reg [NUM_OF_CHIPS-1:0] chip_ready_reg, chip_ready_next;
	reg [NUM_OF_CHIPS-1:0] chip_result_reg, chip_result_next;
	reg [NUM_OF_CHIPS-1:0] chip_exists_reg, chip_exists_next;
	
	// Bus state_reg machine registers
	reg [OP_WIDTH-1:0]	     op_reg, op_next;
	reg [LENGTH_WIDTH-1:0]	     length_reg, length_next;
	reg [log2(NUM_OF_CHIPS)-1:0] chip_reg, chip_next;
	reg [BUS_ADDR_WIDTH-1:0]     addr_reg, addr_next;
	
	// NAND bus registers
	reg              [7:0] bus_data_in_reg;
	reg	               bus_dir_reg, bus_dir_next;
	reg              [7:0] bus_data_out_reg, bus_data_out_next;
	reg	               bus_we_n_reg, bus_we_n_next;
	reg	               bus_re_n_reg, bus_re_n_next;
	reg [NUM_OF_CHIPS-1:0] bus_ces_n_reg, bus_ces_n_next;
	reg	               bus_cle_reg, bus_cle_next;
	reg	               bus_ale_reg, bus_ale_next;

        reg adc_sample_fifo_re_reg, adc_sample_fifo_re_next;

        reg [13:0] wr_buffer_addr_reg, wr_buffer_addr_next; // This is a byte address, but we are reading two bytes from the write buffer. Use the upper 13 bits.
        wire [7:0] wr_buffer_data_out_byte; // This is to select which byte you want to use from the write buffer
        reg [12:0] rd_buffer_addr_reg, rd_buffer_addr_next; // This is a double byte address
        reg [15:0] rd_buffer_data_reg, rd_buffer_data_next;
        reg        rd_buffer_we_reg, rd_buffer_we_next; // This is the write enable for each byte. We need to produce a new write enable for each 2 byte value.

	// Local controller registers
        localparam STATE_RESET              = 0;
        localparam STATE_STARTUP_0          = 1;
        localparam STATE_STARTUP_1          = 2;
        localparam STATE_IDLE               = 3;
        localparam STATE_SEND_COMMAND_0     = 4;
        localparam STATE_SEND_ADDRESS       = 5;
        localparam STATE_SEND_COMMAND_1     = 6;
        localparam STATE_READ_STATUS        = 7;
        localparam STATE_DELAY_ADL          = 8;
        localparam STATE_DELAY_WHR          = 9;
        localparam STATE_DELAY_RHW          = 10;
        localparam STATE_DELAY_WB           = 11;
        localparam STATE_WRITE_DATA         = 12;
        localparam STATE_READ_DATA          = 13;
        localparam STATE_READ_ADC_SAMPLES_0 = 14;
        localparam STATE_READ_ADC_SAMPLES_1 = 15;
        reg [4:0] state_reg, state_next;
	
        // State delay signals
	localparam DELAY_STATE_CTRL_RESET   = ceil_division(1000000,PERIOD);
        localparam DELAY_STATE_SEND_COMMAND = DELAY_tWC; // The time to hold WE# low while asserting CLE, and then the time to hold WE# high
        localparam DELAY_STATE_SEND_ADDRESS = DELAY_tWC; // The time to hold WE# low while asserting ALE, and then the time to hold WE# high
        localparam DELAY_STATE_READ_DATA = DELAY_tRC; // The time to hold RE# low and then the time to hold RE# high
        localparam DELAY_STATE_WRITE_DATA = DELAY_tWC; // The time to hold WE# low and then the time to hold WE# high
        localparam DELAY_STATE_WHR = DELAY_tWHR; 
        localparam DELAY_STATE_ADL = DELAY_tADL; // The time after sending the address before you can write data
        localparam DELAY_STATE_RHW = DELAY_tRHW; 
        localparam DELAY_STATE_WB = DELAY_tWB; 
        reg [19:0]  state_delay_count_reg;
	
	reg [LENGTH_WIDTH-1:0]	byte_count_reg, byte_count_next;
	reg [LENGTH_WIDTH-1:0]	sample_count_reg, sample_count_next;
	reg [39:0]		addr_out_reg, addr_out_next; // This is the address that should be sent out during the send address states
	reg [2:0]		addr_bytes_reg, addr_bytes_next; // These are the number of bytes that should be sent during the send address states

        reg [log2(NUM_OF_CHIPS)-1:0] chip_counter_reg, chip_counter_next;
        reg [1:0] startup_op_reg, startup_op_next;
        reg  reading_status_reg, reading_status_next;

        wire [NUM_OF_CHIPS-1:0] chip_decode = 4'h1 << chip_reg;
        wire [NUM_OF_CHIPS-1:0] chip_decode_n = ~chip_decode;

	always @(posedge i_clk or posedge i_rst) begin
		if (i_rst) begin
			state_reg <= STATE_RESET;
                        chip_ready_reg <= 0;
                        chip_result_reg <= 0;
                        chip_exists_reg <= 0;
			op_reg <= 0;
			length_reg <= 0;
			chip_reg <= 0;
			addr_reg <= 0;
			byte_count_reg <= 0;
			sample_count_reg <= 0;
			addr_out_reg <= 0;
			addr_bytes_reg <= 0;
			bus_data_in_reg <= 0;
			bus_dir_reg <= DIR_OUT;
			bus_data_out_reg <= 0;
			bus_we_n_reg <= 1;
			bus_re_n_reg <= 1;
			bus_ces_n_reg <= 0;
			bus_cle_reg <= 0;
			bus_ale_reg <= 0;
		        adc_sample_fifo_re_reg <= 0;
                        wr_buffer_addr_reg <= 0;
		        rd_buffer_addr_reg <= 0;
		        rd_buffer_data_reg <= 0;
		        rd_buffer_we_reg <= 0;
                        chip_counter_reg <= 0;
                        startup_op_reg <= 0;
                        reading_status_reg <= 0;
                end else begin
			state_reg <= state_next;
                        chip_ready_reg <= chip_ready_next;
                        chip_result_reg <= chip_result_next;
                        chip_exists_reg <= chip_exists_next;
			op_reg <= op_next;
			length_reg <= length_next;
			chip_reg <= chip_next;
			addr_reg <= addr_next;
			byte_count_reg <= byte_count_next;
			sample_count_reg <= sample_count_next;
			addr_out_reg <= addr_out_next;
			addr_bytes_reg <= addr_bytes_next;
			bus_data_in_reg <= i_bus_data;
			bus_data_out_reg <= bus_data_out_next;
			bus_dir_reg <= bus_dir_next;
			bus_we_n_reg <= bus_we_n_next;
			bus_re_n_reg <= bus_re_n_next;
			bus_ces_n_reg <= bus_ces_n_next;
			bus_cle_reg <= bus_cle_next;
			bus_ale_reg <= bus_ale_next;
		        adc_sample_fifo_re_reg <= adc_sample_fifo_re_next;
		        wr_buffer_addr_reg <= wr_buffer_addr_next;
		        rd_buffer_addr_reg <= rd_buffer_addr_next;
		        rd_buffer_data_reg <= rd_buffer_data_next;
		        rd_buffer_we_reg <= rd_buffer_we_next;
                        chip_counter_reg <= chip_counter_next;
                        startup_op_reg <= startup_op_next;
                        reading_status_reg <= reading_status_next;
                end
	end

	always @* begin
		// Set default Values
		state_next = state_reg;
		
                chip_ready_next = chip_ready_reg;
                chip_result_next = chip_result_reg;
                chip_exists_next = chip_exists_reg;

                op_next = op_reg;
		length_next = length_reg;
		chip_next = chip_reg;
		addr_next = addr_reg;
		
                byte_count_next = byte_count_reg;
                sample_count_next = sample_count_reg;
		addr_out_next = addr_out_reg;
		addr_bytes_next = addr_bytes_reg;
			
		o_busy = 1'b1;
		        
                adc_sample_fifo_re_next = 1'b0;

                wr_buffer_addr_next = wr_buffer_addr_reg;
                rd_buffer_addr_next[2:0] = (rd_buffer_we_reg) ? rd_buffer_addr_reg[2:0] - 3'd1 : rd_buffer_addr_reg[2:0];
                rd_buffer_addr_next[12:3] = (rd_buffer_we_reg && (rd_buffer_addr_reg[2:0] == 3'd0)) ? rd_buffer_addr_reg[12:3] + 10'd1 : rd_buffer_addr_reg[12:3];
		rd_buffer_data_next[15:8] = (!byte_count_reg[0]) ? bus_data_in_reg : rd_buffer_data_reg[15:8];
		rd_buffer_data_next[7:0] = (byte_count_reg[0]) ? bus_data_in_reg : rd_buffer_data_reg[7:0];
		rd_buffer_we_next = 1'b0;

                chip_counter_next = chip_counter_reg;
                startup_op_next = startup_op_reg;
                reading_status_next = reading_status_reg;

		case(state_reg)
                        STATE_RESET: begin // On reset, wait certain amount of time until monitoring r/b# line
                            if (state_delay_count_reg == DELAY_STATE_CTRL_RESET-1) begin
                                chip_ready_next = {NUM_OF_CHIPS{1'b1}};
                                chip_exists_next = 0;
                                chip_counter_next = 0;
                                startup_op_next = 0;
                                state_next = STATE_STARTUP_0;
                            end
			end

                        // On startup, we send three commands: RESET, SET_TIMING_MODE (4), READ ID
                        STATE_STARTUP_0: begin
                            // Check to see if the chip is busy
                            if (startup_op_reg == 2'd3) begin
                                state_next = STATE_IDLE;
                            end else if (chip_ready_reg[chip_counter_reg]) begin
                                reading_status_next = 0;
                                state_next = STATE_STARTUP_1;
                            end else begin
                                // Read the status of the chip to find out when it is ready
                                reading_status_next = 1;
                                chip_next = chip_counter_reg;
                                op_next = (reading_status_reg) ? OP_JUSTREADSTATUS : OP_READSTATUS;
                                state_next = (reading_status_reg) ? STATE_READ_STATUS : STATE_SEND_COMMAND_0;
                            end
                        end
                        
                        STATE_STARTUP_1: begin
                            // Issue all of the three startup operations based on the value of startup_op_reg
                            op_next = (startup_op_reg == 2'd0) ? OP_RESET           :
                                      (startup_op_reg == 2'd1) ? OP_SET_TIMING_MODE : OP_CHECK_EXISTS;
                            chip_next = chip_counter_reg;
                            chip_counter_next = chip_counter_reg + 1;
                            startup_op_next = (chip_counter_reg == NUM_OF_CHIPS-1) ? startup_op_reg + 2'd1 : startup_op_reg;
                            state_next = STATE_SEND_COMMAND_0;
                        end
		
			STATE_IDLE: begin
                            o_busy = 0;
                            
                            op_next = i_operation;
                            chip_next = i_chip;
                            addr_next = i_addr;
                            length_next = i_length;
                           
                            rd_buffer_addr_next = 13'd7;
                            wr_buffer_addr_next = 14'd15;

                            if (i_start) begin
                                state_next = (i_operation == OP_JUSTREADSTATUS)   ? STATE_READ_STATUS        : 
                                             (i_operation == OP_READ_ADC_SAMPLES) ? STATE_READ_ADC_SAMPLES_0 : STATE_SEND_COMMAND_0;
                            end
			end
		    
                        STATE_SEND_COMMAND_0: begin
                            // Set the correct address for operations that will need to send an address
                            addr_bytes_next = (op_reg == OP_SET_TIMING_MODE) ? 3'd1 : 
                                              (op_reg == OP_READID)          ? 3'd1 : 
                                              (op_reg == OP_CHECK_EXISTS)    ? 3'd1 : 
                                              (op_reg == OP_ERASE)           ? 3'd3 : 
                                              (op_reg == OP_READPARAM)       ? 3'd1 : 3'd5;

                            addr_out_next = (op_reg == OP_SET_TIMING_MODE) ? {32'h0, 8'h01}           :
                                            (op_reg == OP_READID)          ? {32'h0, 8'h00}           :
                                            (op_reg == OP_CHECK_EXISTS)    ? {32'h0, 8'h00}           :
                                            (op_reg == OP_READPARAM)       ? {32'h0, 8'h00}           :
                                            (op_reg == OP_ERASE)           ? {16'h0, addr_reg[39:16]} : addr_reg;

                            // Reset the chip ready signal so that a READ_STATUS is sent next time
                            chip_ready_next[chip_reg] = (op_reg == OP_RESET) ? 0 : chip_ready_reg[chip_reg];
                            
                            if (state_delay_count_reg == DELAY_STATE_SEND_COMMAND-1) begin                      
                                state_next = (op_reg == OP_READSTATUS)   ? STATE_DELAY_WHR    : 
                                             (op_reg == OP_RESET)        ? STATE_DELAY_WB     :
                                             (op_reg == OP_COMPLETEREAD) ? STATE_DELAY_WHR    : STATE_SEND_ADDRESS;
                            end
                        end
                        
                        STATE_SEND_ADDRESS: begin
                            // Reset the chip ready signal so that a READ_STATUS is sent next time
                            chip_ready_next[chip_reg] = (op_reg == OP_READPARAM) ? 1'b0 : chip_ready_reg[chip_reg];

                            if (state_delay_count_reg == DELAY_STATE_SEND_ADDRESS-1) begin
				if (addr_bytes_reg == 1) begin
                                    state_next = (op_reg == OP_PROGRAM)         ? STATE_DELAY_ADL :
                                                 (op_reg == OP_SET_TIMING_MODE) ? STATE_DELAY_ADL :
                                                 (op_reg == OP_READPARAM)       ? STATE_DELAY_WB  :
                                                 (op_reg == OP_READID)          ? STATE_DELAY_WHR : 
                                                 (op_reg == OP_CHECK_EXISTS)    ? STATE_DELAY_WHR : STATE_SEND_COMMAND_1;
				end else begin
                                    addr_bytes_next = addr_bytes_reg - 1;
                                    addr_out_next = {8'h0, addr_out_reg[39:8]};
				end
                            end
			end
                        
                        STATE_SEND_COMMAND_1: begin
                            // Reset the chip ready signal so that a READ_STATUS is sent next time
                            chip_ready_next[chip_reg] = (op_reg == OP_ERASE)     ? 1'b0 : 
                                                        (op_reg == OP_STARTREAD) ? 1'b0 : chip_ready_reg[chip_reg];
                            
                            if (state_delay_count_reg == DELAY_STATE_SEND_COMMAND-1) begin
                               state_next = (op_reg == OP_ERASE)     ? STATE_DELAY_WB : 
                                            (op_reg == OP_PROGRAM)   ? STATE_DELAY_WB : 
                                            (op_reg == OP_STARTREAD) ? STATE_DELAY_WB : STATE_IDLE;
                            end
                        end

                        STATE_DELAY_WHR: begin
			    // Because we use a 2 byte interface to the read buffer, the byte count has to be a multiple of 2 bytes
                            byte_count_next = (op_reg == OP_READID)       ? 3'd6 :
			                      (op_reg == OP_CHECK_EXISTS) ? 3'd6 : length_reg;
                            
                            if (state_delay_count_reg == DELAY_STATE_WHR-1) begin
                                state_next = (op_reg == OP_READSTATUS)   ? STATE_READ_STATUS : 
                                             (op_reg == OP_READID)       ? STATE_READ_DATA   :
                                             (op_reg == OP_CHECK_EXISTS) ? STATE_READ_DATA   :
                                             (op_reg == OP_COMPLETEREAD) ? STATE_READ_DATA   : STATE_IDLE;
                            end
                        end
			
			STATE_READ_STATUS: begin
                            if (state_delay_count_reg == DELAY_STATE_READ_DATA-1) begin
                                chip_ready_next[chip_reg] = bus_data_in_reg[6];
                                chip_result_next[chip_reg] = bus_data_in_reg[0];
                                state_next = STATE_DELAY_RHW;
                            end
			end		
		
                        STATE_DELAY_ADL: begin
                            if (state_delay_count_reg == DELAY_STATE_ADL-1) begin
                                wr_buffer_addr_next[3:0] = wr_buffer_addr_reg[3:0] - 4'd1;
                                wr_buffer_addr_next[13:4] = (wr_buffer_addr_reg[3:0] == 4'd0) ? wr_buffer_addr_reg[13:4] +10'd1 : wr_buffer_addr_reg[13:4];
                                
                                state_next = STATE_WRITE_DATA;

                                byte_count_next = (op_reg == OP_SET_TIMING_MODE) ? 4 : length_reg;
                            end
                        end
                        
                        STATE_DELAY_RHW: begin
                            if (state_delay_count_reg == DELAY_STATE_RHW-1) begin
                                state_next = (startup_op_reg != 2'd3) ? STATE_STARTUP_0 : STATE_IDLE;
                            end
                        end
			
                        STATE_DELAY_WB: begin
                            if (state_delay_count_reg == DELAY_STATE_WB-1) begin
                                state_next = (startup_op_reg != 2'd3) ? STATE_STARTUP_0 : STATE_IDLE;
                            end
                        end
			
                        STATE_WRITE_DATA: begin
                            chip_ready_next[chip_reg] = 0;
                            
                            if (state_delay_count_reg == DELAY_STATE_WRITE_DATA-1) begin
                                wr_buffer_addr_next[3:0] = wr_buffer_addr_reg[3:0] - 4'd1;
                                wr_buffer_addr_next[13:4] = (wr_buffer_addr_reg[3:0] == 4'd0) ? wr_buffer_addr_reg[13:4] +10'd1 : wr_buffer_addr_reg[13:4];
                                byte_count_next = byte_count_reg - 1;
                                
                                if (byte_count_reg == 1) begin
                                    state_next = (op_reg == OP_PROGRAM)         ? STATE_SEND_COMMAND_1 :
                                                 (op_reg == OP_SET_TIMING_MODE) ? STATE_DELAY_WB       : STATE_IDLE;
                                end
                            end
                        end
			
			// Read Data States
			STATE_READ_DATA: begin
                            if (state_delay_count_reg == DELAY_STATE_READ_DATA-1) begin
                                rd_buffer_we_next = (op_reg == OP_CHECK_EXISTS) ? 1'b0 : (byte_count_reg[0]) ? 1'b1 : 1'b0;
                    
                                if (((op_reg == OP_READID) || (op_reg == OP_CHECK_EXISTS)) && (byte_count_reg == 5) && (bus_data_in_reg != 0)) begin 
                                    chip_exists_next[chip_reg] = 1;
                                end
                                
                                byte_count_next = byte_count_reg - 1;
                               
                                if (byte_count_reg == 1) begin
                                    state_next = STATE_DELAY_RHW;
                                end
                            end
                        end
			
                        // Read ADC Samples
			STATE_READ_ADC_SAMPLES_0: begin
                            if (i_adc_sample_fifo_empty) begin
                                sample_count_next = 0;
                                state_next = STATE_READ_ADC_SAMPLES_1;
                            end else if (adc_sample_fifo_re_reg && i_adc_sample_fifo_valid) begin
                                rd_buffer_data_next = i_adc_sample_fifo_data;
                                rd_buffer_we_next = 1'b1;
                            
                                sample_count_next = sample_count_reg + 1;

                                if (i_adc_sample_fifo_almost_empty) begin
                                    state_next = STATE_READ_ADC_SAMPLES_1;
                                end else begin
                                    adc_sample_fifo_re_next = 1'b1;
                                end
                            end else begin
                                sample_count_next = 0;
                                adc_sample_fifo_re_next = 1'b1;
                            end
                        end

                        // Write a special code to indicate that you're at the end of the samples
			STATE_READ_ADC_SAMPLES_1: begin
                            rd_buffer_data_next = 16'hFFFF;
                            rd_buffer_we_next = 1'b1;
                        
                            sample_count_next = sample_count_reg + 1;
                            
                            state_next = STATE_IDLE;
                        end

		endcase
	end

        assign wr_buffer_data_out_byte = (byte_count_reg[0]) ? i_wr_buffer_data[7:0] : i_wr_buffer_data[15:8]; // Select the correct byte to use based on the byte_count_reg

        always @* begin
	    case (state_reg)
                STATE_RESET, STATE_STARTUP_0, STATE_STARTUP_1, STATE_IDLE, STATE_DELAY_WB, STATE_DELAY_RHW, STATE_READ_ADC_SAMPLES_0, STATE_READ_ADC_SAMPLES_1: begin
                    bus_dir_next = DIR_IN;
                    bus_data_out_next = 8'h0;
                    bus_we_n_next = 1;
                    bus_re_n_next = 1;
                    bus_ces_n_next = {NUM_OF_CHIPS{1'b1}};
                    bus_cle_next = 0;
                    bus_ale_next = 0;
                end
                
                STATE_SEND_COMMAND_0: begin 
                    bus_dir_next = DIR_OUT;
                    bus_data_out_next = (op_reg == OP_READSTATUS)      ? CMD_STATUS         :
                                        (op_reg == OP_RESET)           ? CMD_RESET          : 
                                        (op_reg == OP_READID)          ? CMD_READID         : 
                                        (op_reg == OP_CHECK_EXISTS)    ? CMD_READID         : 
                                        (op_reg == OP_READPARAM)       ? CMD_READ_PARAMPAGE : 
                                        (op_reg == OP_PROGRAM)         ? CMD_WRITEPAGE0     : 
                                        (op_reg == OP_STARTREAD)       ? CMD_READPAGE0      : 
                                        (op_reg == OP_COMPLETEREAD)    ? CMD_READ_MODE      : 
                                        (op_reg == OP_ERASE)           ? CMD_BLOCKERASE0    : 
                                        (op_reg == OP_SET_TIMING_MODE) ? CMD_SETFEATURES    : 8'h00;
                    bus_we_n_next = (state_delay_count_reg < DELAY_tWP) ? 0 : 1;
                    bus_re_n_next = 1;
                    bus_ces_n_next = chip_decode_n;
                    bus_cle_next = 1;
                    bus_ale_next = 0;
                end
                
                STATE_SEND_COMMAND_1: begin 
                    bus_dir_next = DIR_OUT;
                    bus_data_out_next = (op_reg == OP_STARTREAD)    ? CMD_READPAGE1   :
                                        (op_reg == OP_PROGRAM)      ? CMD_WRITEPAGE1  : 
                                        (op_reg == OP_ERASE)        ? CMD_BLOCKERASE1 : 8'h00;
                    bus_we_n_next = (state_delay_count_reg < DELAY_tWP) ? 0 : 1;
                    bus_re_n_next = 1;
                    bus_ces_n_next = chip_decode_n;
                    bus_cle_next = 1;
                    bus_ale_next = 0;
                end

                STATE_SEND_ADDRESS: begin
                    bus_dir_next = DIR_OUT;
                    bus_data_out_next = addr_out_reg[7:0];
                    bus_we_n_next = (state_delay_count_reg < DELAY_tWP) ? 0 : 1;
                    bus_re_n_next = 1;
                    bus_ces_n_next = chip_decode_n;
                    bus_cle_next = 0;
                    bus_ale_next = 1;
                end
                
                STATE_READ_STATUS, STATE_READ_DATA: begin
                    bus_dir_next = DIR_IN;
                    bus_data_out_next = 8'h00;
                    bus_we_n_next = 1;
                    bus_re_n_next = (state_delay_count_reg < DELAY_tRP) ? 0 : 1;
                    bus_ces_n_next = chip_decode_n;
                    bus_cle_next = 0;
                    bus_ale_next = 0;
                end
                
                STATE_WRITE_DATA: begin
                    bus_dir_next = DIR_OUT;
                    bus_data_out_next = (op_reg == OP_SET_TIMING_MODE) ? ((byte_count_reg == 4) ? 8'h04 : 8'h00) : wr_buffer_data_out_byte;
                    bus_we_n_next = (state_delay_count_reg < DELAY_tWP) ? 0 : 1;
                    bus_re_n_next = 1;
                    bus_ces_n_next = chip_decode_n;
                    bus_cle_next = 0;
                    bus_ale_next = 0;
                end
                
                default: begin
                    bus_dir_next = DIR_IN;
                    bus_data_out_next = 8'h0;
                    bus_we_n_next = 1;
                    bus_re_n_next = 1;
                    bus_ces_n_next = chip_decode_n;
                    bus_cle_next = 0;
                    bus_ale_next = 0;
                end
            endcase
        end

        always @(posedge i_clk or posedge i_rst) begin
            if (i_rst) begin
                state_delay_count_reg <= 0;
            end else begin
                // Default Value
                state_delay_count_reg <= state_delay_count_reg + 1;
                
                case (state_reg)
                    STATE_RESET: begin
                        if (state_delay_count_reg == DELAY_STATE_CTRL_RESET-1) begin
                            state_delay_count_reg <= 0;
                        end
                    end

                    STATE_SEND_COMMAND_0, STATE_SEND_COMMAND_1: begin
                        if (state_delay_count_reg == DELAY_STATE_SEND_COMMAND-1) begin
                            state_delay_count_reg <= 0;
                        end
                    end

                    STATE_SEND_ADDRESS: begin
                        if (state_delay_count_reg == DELAY_STATE_SEND_ADDRESS-1) begin
                            state_delay_count_reg <= 0;
                        end
                    end
                    
                    STATE_READ_STATUS, STATE_READ_DATA: begin
                        if (state_delay_count_reg == DELAY_STATE_READ_DATA-1) begin
                            state_delay_count_reg <= 0;
                        end
                    end

                    STATE_DELAY_WHR: begin
                        if (state_delay_count_reg == DELAY_STATE_WHR-1) begin
                            state_delay_count_reg <= 0;
                        end
                    end

                    STATE_DELAY_ADL: begin
                        if (state_delay_count_reg == DELAY_STATE_ADL-1) begin
                            state_delay_count_reg <= 0;
                        end
                    end
                   
                    STATE_DELAY_RHW: begin
                        if (state_delay_count_reg == DELAY_STATE_RHW-1) begin
                            state_delay_count_reg <= 0;
                        end
                    end
                    
                    STATE_DELAY_WB: begin
                        if (state_delay_count_reg == DELAY_STATE_WB-1) begin
                            state_delay_count_reg <= 0;
                        end
                    end
                    
                    STATE_WRITE_DATA: begin
                        if (state_delay_count_reg == DELAY_STATE_WRITE_DATA-1) begin
                            state_delay_count_reg <= 0;
                        end
                    end

                    default: begin
                        state_delay_count_reg <= 0;
                    end
                endcase
            end
        end

	// Assign outputs
	assign o_sample_count = sample_count_reg;
       
        assign o_adc_sample_fifo_re = adc_sample_fifo_re_reg;

        assign o_bus_data 	= bus_data_out_reg;
	assign o_bus_data_tri_n = bus_dir_reg;
	assign o_bus_we_n 	= bus_we_n_reg;
	assign o_bus_re_n 	= bus_re_n_reg;
	assign o_bus_ces_n 	= bus_ces_n_reg;
	assign o_bus_cle 	= bus_cle_reg;
	assign o_bus_ale 	= bus_ale_reg;
	
        assign o_chip_ready = chip_ready_reg;
        assign o_chip_result = chip_result_reg;
        assign o_chip_exists = chip_exists_reg;

        assign o_wr_buffer_addr = wr_buffer_addr_reg[13:1];
        assign o_rd_buffer_addr = rd_buffer_addr_reg;
        assign o_rd_buffer_data = rd_buffer_data_reg;
        assign o_rd_buffer_we = rd_buffer_we_reg;

	//assign o_controller_state = {state_reg};
endmodule
