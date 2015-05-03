/**
 *
 *
 *
 *
 **/
 
 `timescale 1ns / 1ps
 
 module flash_bus_controller_tb;
 
	function integer log2;
		input integer value;
	begin
		value = value-1;
		for (log2=0; value>0; log2=log2+1)
			value = value>>1;
	end
	endfunction
 
	// Parameters
	localparam NUM_OF_BLOCKS = 4096;
	localparam NUM_OF_PAGES = 64;
	localparam NUM_OF_BYTES = 2048;
	localparam PERIOD = 14;
	localparam HALF_PERIOD = PERIOD/2;
	localparam MAX_CHIPS = 4;
	localparam MAX_CHIPS_LOG2 = 2;

 
	// Wires
	wire	[7:0]   Io;
        wire         	Cle;
        wire		Ale;
        wire [MAX_CHIPS-1:0] Ce_n;
	wire		Re_n;
        wire		We_n;
        wire		Wp_n = 1'b1;
        tri1		Rb_n[MAX_CHIPS-1:0];
	wire            Dqs;

	reg clk;
	reg reset;
	
	// Generate clock
	 initial begin
		clk = 0;
		forever begin
			#HALF_PERIOD clk = ~clk;
		end
	end
	
	wire [7:0] bus_i_data;
	wire [7:0] bus_o_data;
	wire bus_data_tri;
	
	assign Io = (bus_data_tri == 1'b0) ? bus_o_data : 8'bz;
	assign bus_i_data = Io;
        assign Dqs = 1'bz;

	wire 				busy;		// Signal to bus state machine that the bus is busy
	reg 	[0:4] 			operation;	// i_operation from bus state machine
	reg 	[MAX_CHIPS_LOG2-1:0] 	chip;		// 
	reg 	[0:39] 			addr;		// 
	reg 	[0:14] 			length;		// The number of bytes of the new i_operation
	reg 				start;		// i_start the i_operation
	
        wire 	[MAX_CHIPS-1:0] 	chip_ready;	// Ready bit for each chip
	wire 	[MAX_CHIPS-1:0] 	statusbits;	// Result status bit for each chip
	wire 	[MAX_CHIPS-1:0] 	chip_exists;	// Exists bit for each chip
	
	// Write Buffer Signals
	wire [12:0]	wr_buffer_addr;
	reg  [15:0]	wr_buffer_data;
	
	// Read Buffer Signals
	wire [12:0]	rd_buffer_addr;
	wire [15:0]	rd_buffer_data;
	wire		rd_buffer_we;
	
	// Include Bus Operations
	`include "../hdl/verilog/bus_ops.v"
	
	flash_bus_controller #(
		.PERIOD(PERIOD),
		.NUM_OF_CHIPS(MAX_CHIPS)
	) controller (
		// System signals
		.i_clk(clk),
		.i_rst(reset),		// System i_reset
		
		// State machine signals
		.o_busy(busy),		// Signal to bus state machine that the bus is busy
		.i_operation(operation),	// i_operation from bus state machine
		.i_chip(chip),		// 
		.i_addr(addr),		// 
		.i_length(length),	// The number of bytes of the new i_operation
		.i_start(start),		// i_start the i_operation
                .o_sample_count(),      // The number of ADC samples of the last OP_READ_ADC_SAMPLES operation
		
                .o_chip_ready(chip_ready),// Ready bit for each i_chip
		.o_chip_result(statusbits),// Result status bit for each i_chip
		.o_chip_exists(chip_exists),

                // ADC Sample FIFO Signals
                .i_adc_sample_fifo_data(16'h00),
                .i_adc_sample_fifo_almost_empty(1'b1),
                .i_adc_sample_fifo_empty(1'b1),
                .o_adc_sample_fifo_re(),
                .i_adc_sample_fifo_valid(1'b0),

                // Write Buffer Signals
		.o_wr_buffer_addr(wr_buffer_addr),
		.i_wr_buffer_data(wr_buffer_data),
		
		// Read Buffer Signals
		.o_rd_buffer_addr(rd_buffer_addr),
		.o_rd_buffer_data(rd_buffer_data),
		.o_rd_buffer_we(rd_buffer_we),
		
		// Flash bus signals
		.i_bus_data(bus_i_data),
		.o_bus_data(bus_o_data),
		.o_bus_data_tri_n(bus_data_tri),
		.o_bus_we_n(We_n),
		.o_bus_re_n(Re_n),
		.o_bus_ces_n(Ce_n),
                .o_bus_cle(Cle),
		.o_bus_ale(Ale)
	);
	
        genvar j;
        generate
            for (j = 0; j < MAX_CHIPS; j = j + 1) begin
                nand_model flash (
                    .Dq_Io(Io), 
                    .Cle(Cle),
                    .Ale(Ale), 
                    .Clk_We_n(We_n), 
                    .Wr_Re_n(Re_n), 
                    .Ce_n(Ce_n[j]), 
                    .Wp_n(1'b1), 
                    .Rb_n(Rb_n[j]),
                    .Dqs(Dqs)
                );
            end
        endgenerate
	
	function [0:39] make_address;
		input [0:log2(NUM_OF_BLOCKS)-1] block_number;
		input [0:log2(NUM_OF_PAGES)-1] page_number;
		input [0:log2(NUM_OF_BYTES)] byte_number;
	begin
		// TODO: Make modular
		make_address = {6'b0,block_number,page_number,4'b0,byte_number};
		//$display("log2(BLOCKS) = %d log2(PAGES) = %d log2(BYTES) = %d Address: %b",log2(NUM_OF_BLOCKS),log2(NUM_OF_PAGES),log2(NUM_OF_BYTES),make_address);
	end
	endfunction
	
	// Reset the chip
	task reset_chip;
	begin
		wait_for_chip_ready(1'b0);
                issue_operation(OP_RESET);
		wait_for_chip_ready(1'b0);
		issue_operation(OP_SET_TIMING_MODE);
	end
	endtask
	
	// Wait for power-up
	task wait_power_up;
	begin
	    #1000000;
	end
	endtask
	
	// Issue Command
	task issue_operation;
		input [4:0] new_operation;
	begin
                wait(busy === 0);
                operation = new_operation;
		start = 1;
		if ((new_operation != 0) && (new_operation != 1)) begin
                    $display("Issuing operation %d: %t", new_operation, $realtime);
                end
		#PERIOD;
                start = 0;
                wait (busy === 1);
                wait (busy === 0);
	end
	endtask


        // Wait until chip is ready
        task wait_for_chip_ready;
	    input [MAX_CHIPS_LOG2-1:0] 	chip;
        begin
            wait (busy === 0);

            if (!chip_ready[chip]) begin
                issue_operation(OP_READSTATUS);
                
                wait (busy === 0);
                
                while (!chip_ready[chip]) begin
                    issue_operation(OP_JUSTREADSTATUS);
                    wait (busy === 0);
                end
            end
        end
        endtask

	// Erase a block
	task erase_block;
		input [0:log2(NUM_OF_BLOCKS)-1] block_number;
	begin
		addr = make_address(block_number,0,0);
		wait_for_chip_ready(2'd0);
		issue_operation(OP_ERASE);
	end
	endtask
	
	// Read status register
	task read_status;
	begin
		issue_operation(OP_READSTATUS);
		wait (Re_n === 0);
		wait (Re_n === 1);
		//$display ("Current Status: %hh", Io);
	end
	endtask

	// Program page
	task program_page;
		input [0:log2(NUM_OF_BLOCKS)-1] block_number;
		input [0:log2(NUM_OF_PAGES)-1] page_number;
		input [0:log2(NUM_OF_BYTES)] byte_number;
		input [15:0] program_data;
	begin
		addr = make_address(block_number,page_number,byte_number);
		length = 2048-byte_number;
		wr_buffer_data = program_data;
		wait_for_chip_ready(2'd0);
                issue_operation(OP_PROGRAM);
	end
	endtask
	
	// Read a page
	task read_page;
		input [0:log2(NUM_OF_BLOCKS)-1] block_number;
		input [0:log2(NUM_OF_PAGES)-1] page_number;
		input [0:log2(NUM_OF_BYTES)] byte_number;
	begin
		addr = make_address(block_number,page_number,byte_number);
		length = 2048-byte_number;
		wait_for_chip_ready(1'b0);
		issue_operation(OP_STARTREAD);
		wait_for_chip_ready(1'b0);
		issue_operation(OP_COMPLETEREAD);
	end
	endtask
	
	task test_erase_block;
	begin
                erase_block(120);
                program_page(120,0,0,16'h5b3a);
		erase_block(120);
		read_page(120,0,0);
	end
	endtask
	
	task test_program_page;
	begin
		erase_block(120);
		program_page(120,0,0,16'h5b3a);
	        read_page(120,0,0);
	end
	endtask
	
	initial begin : main_test
        operation = 0;
	chip = 0;
	addr = 0;
	length = 0;
	start = 0;
	wr_buffer_data = 0;
	reset = 1;
	#50 reset = 0;
	wait_power_up;

	// Perform a test
        //erase_block(120);
	//read_page(120,0,0);
	//test_erase_block;
	test_program_page;
	
	#1000000 $stop(0);
	$finish;
	end
	
endmodule
