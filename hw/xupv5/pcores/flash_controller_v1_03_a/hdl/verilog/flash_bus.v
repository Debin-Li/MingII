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
 * flash_bus.v - The top level module for a NAND flash bus
 *
 * This module instantiates the bus controller, bus state machine
 * and a buffer for bus operations.
 *
 **/
 module flash_bus #(
	parameter NUM_OF_CHIPS 			= 32,
	parameter CMD_FIFO_DATA_WIDTH 	= 72,
	parameter WR_FIFO_DATA_WIDTH 	= 128,
	parameter RD_FIFO_DATA_WIDTH 	= 136,
	parameter RSLT_FIFO_DATA_WIDTH 	= 26,
	parameter PERIOD 				= 8,
	parameter PAGE_SIZE_WIDTH		= 15
 )
 (
	// System signals
	input 	i_clk,		// System clock
	input 	i_rst,	// System reset
        input   i_adc_clk,

        output o_top_bus_active,
        input i_recording_en,
        
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

        // ADC Sample FIFO Signals
        input [15:0] i_adc_sample_fifo_data,
        output       o_adc_sample_fifo_almost_full,
        output       o_adc_sample_fifo_full,
        input        i_adc_sample_fifo_we,
	
        // Write Buffer Signals
	input	[9:0]	i_disp_wr_buffer_addr,
	input	[127:0]	i_disp_wr_buffer_data,
	input		i_disp_wr_buffer_we,
	
	// Read Buffer Signals
	input	[9:0]	i_disp_rd_buffer_addr,
	output	[127:0]	o_disp_rd_buffer_data,

	// Performance Counter Signals
	output	[0:31]						o_cyclecount_sum,		//
	input								i_cyclecount_reset,		//
	input	[0:7]						i_cyclecount_start,		//
	input	[0:7]						i_cyclecount_end,		//

        // ADC Master Signals
        output o_adc_master_record,

	// Flash bus signals
	input 	[7:0] 						i_bus_data,			// The data coming from the flash bus
	output 	[7:0]	 					o_bus_data,			// The data going to the flash chip
	output		 						o_bus_data_tri_n,	// Tri-state enable for output data
	output 								o_bus_we_n,			// Write Enable signal, active low
	output 								o_bus_re_n,			// Read Enable signal, active low
	output [NUM_OF_CHIPS-1:0] 					o_bus_ces_n,			// Chip Enable signal, active low
	output 								o_bus_cle,			// Command Latch Enable signal
	output 								o_bus_ale,			// Address Latch Enable signal

	// Debug Signals
	//output [7:0]	o_controller_state,
	
	// Top Level Signals
        output [NUM_OF_CHIPS-1:0] o_chip_exists
 );
 
 // Begin module architecture
	`include "functions.v"
	
        // ADC Sample FIFO Signals
        wire [15:0] adc_sample_fifo_data_out;
        wire        adc_sample_fifo_almost_empty;
        wire        adc_sample_fifo_empty;
        wire        adc_sample_fifo_re;
        wire        adc_sample_fifo_valid;

	// Write Buffer Intermediate Signals
	wire [12:0] 	ctrl_wr_buffer_addr;
	wire [15:0] 	ctrl_wr_buffer_data_out;
	wire		ctrl_wr_buffer_re;
	
	// Read Buffer Intermediate Signals
	wire [12:0] 	ctrl_rd_buffer_addr;
	wire [15:0] 	ctrl_rd_buffer_data_in;
	wire 		ctrl_rd_buffer_we;
	
        wire [127:0] rd_buffer_data_out;

	// State machine and controller intermediate signals
	localparam BUS_ADDR_WIDTH = 40;
	wire					ctrl_busy; 		// Signal from controller to state machine to indicate that the controller is busy
	wire 	[4:0] 				ctrl_operation;	//
	wire 	[log2(NUM_OF_CHIPS)-1:0]	ctrl_chip;		//
	wire 	[BUS_ADDR_WIDTH-1:0] 		ctrl_addr;		//
	wire	[PAGE_SIZE_WIDTH-1:0]		ctrl_length;	//
	wire 					ctrl_start;		//
        wire    [PAGE_SIZE_WIDTH-1:0]           ctrl_sample_count;

	// Chip status bits
	wire [NUM_OF_CHIPS-1:0] 	chip_ready;			// Chip Ready bit for each chip
	wire [NUM_OF_CHIPS-1:0] 	chip_result;			// Result status bit for each chip
	
	
        // ADC Sample FIFO Instantiation
        adc_sample_fifo adc_sample_fifo_inst (
            .rst(i_rst),
            .wr_clk(i_adc_clk),
            .rd_clk(i_clk),
            .din(i_adc_sample_fifo_data),
            .wr_en(i_adc_sample_fifo_we),
            .rd_en(adc_sample_fifo_re),
            .dout(adc_sample_fifo_data_out),
            .full(o_adc_sample_fifo_full),
            .almost_full(o_adc_sample_fifo_almost_full),
            .empty(adc_sample_fifo_empty),
            .almost_empty(adc_sample_fifo_almost_empty),
            .valid(adc_sample_fifo_valid)
        );
	
	
	flash_bus_sm #(
		.NUM_OF_CHIPS(NUM_OF_CHIPS),
		.CMD_FIFO_DATA_WIDTH(CMD_FIFO_DATA_WIDTH),
		.RSLT_FIFO_DATA_WIDTH(RSLT_FIFO_DATA_WIDTH),
		.BUS_ADDR_WIDTH(BUS_ADDR_WIDTH)
	) busSM (
		// System signals
		.i_clk(i_clk),
		.i_rst(i_rst),
	
                .o_top_bus_active(o_top_bus_active),
                .i_recording_en(i_recording_en),
                
                // Dispatch signals
                .i_disp_cmd_req(i_disp_cmd_req),
                .o_disp_cmd_ack(o_disp_cmd_ack),
                .i_disp_cmd_data(i_disp_cmd_data),
                .o_disp_rsp_req(o_disp_rsp_req),
                .i_disp_rsp_ack(i_disp_rsp_ack),
                .i_disp_rsp_listening(i_disp_rsp_listening),
                .o_disp_rsp_data(o_disp_rsp_data),
                .o_disp_chip_active(o_disp_chip_active), // This is a one-hot encoding to the dispatch telling it if there is already an active operation for this chip 
                .o_disp_wr_buffer_rsvd(o_disp_wr_buffer_rsvd),
                .o_disp_rd_buffer_rsvd(o_disp_rd_buffer_rsvd),
		
		.o_cyclecount_sum(o_cyclecount_sum),
		.i_cyclecount_reset(i_cyclecount_reset),
		.i_cyclecount_start(i_cyclecount_start),
		.i_cyclecount_end(i_cyclecount_end),

                // ADC Master signals
                .o_adc_master_record(o_adc_master_record),

		// State machine and controller intermediate signals
		.i_ctrl_busy(ctrl_busy),
		.o_ctrl_operation(ctrl_operation),
		.o_ctrl_chip(ctrl_chip),
		.o_ctrl_addr(ctrl_addr),
		.o_ctrl_length(ctrl_length),
		.o_ctrl_start(ctrl_start),
                .i_sample_count(ctrl_sample_count),

		.i_ctrl_chip_ready(chip_ready),
		.i_ctrl_chip_result(chip_result)
	);
	
        write_buffer write_buffer_inst (
          .clka(i_clk),
          .clkb(i_clk),
          .addra(i_disp_wr_buffer_addr),
          .dina(i_disp_wr_buffer_data),
          .wea(i_disp_wr_buffer_we),
          .addrb(ctrl_wr_buffer_addr),
          .doutb(ctrl_wr_buffer_data_out)
        );
	
        read_buffer read_buffer_inst (
          .clka(i_clk),
          .clkb(i_clk),
          .addra(ctrl_rd_buffer_addr),
          .dina(ctrl_rd_buffer_data_in),
          .wea(ctrl_rd_buffer_we),
          .addrb(i_disp_rd_buffer_addr),
          .doutb(rd_buffer_data_out)
        );

        assign o_disp_rd_buffer_data = (i_disp_rsp_listening) ? rd_buffer_data_out : {128{1'bZ}};

	flash_bus_controller #(
		.PERIOD(PERIOD),
		.NUM_OF_CHIPS(NUM_OF_CHIPS),
		.OP_WIDTH(5),
		.BUS_ADDR_WIDTH(BUS_ADDR_WIDTH),
		.LENGTH_WIDTH(PAGE_SIZE_WIDTH)
	) busController (
		// System signals
		.i_clk(i_clk),
		.i_rst(i_rst),
		
                //.o_controller_state(o_controller_state),
		
		// State machine and controller intermediate signals
		.o_busy(ctrl_busy),
		.i_operation(ctrl_operation),
		.i_chip(ctrl_chip),
		.i_addr(ctrl_addr),
		.i_length(ctrl_length),
		.i_start(ctrl_start),
		.o_sample_count(ctrl_sample_count),

		.o_chip_ready(chip_ready),
		.o_chip_result(chip_result),
		.o_chip_exists(o_chip_exists),
		
                // ADC Sample FIFO Signals
                .i_adc_sample_fifo_data(adc_sample_fifo_data_out),
                .i_adc_sample_fifo_almost_empty(adc_sample_fifo_almost_empty),
                .i_adc_sample_fifo_empty(adc_sample_fifo_empty),
                .o_adc_sample_fifo_re(adc_sample_fifo_re),
                .i_adc_sample_fifo_valid(adc_sample_fifo_valid),

		// Write Buffer Signals
		.o_wr_buffer_addr(ctrl_wr_buffer_addr),
		.i_wr_buffer_data(ctrl_wr_buffer_data_out),
		
		// Read Buffer Signals
		.o_rd_buffer_addr(ctrl_rd_buffer_addr),
		.o_rd_buffer_data(ctrl_rd_buffer_data_in),
		.o_rd_buffer_we(ctrl_rd_buffer_we),
                
		// Bus signals
		.i_bus_data(i_bus_data),
		.o_bus_data(o_bus_data),
		.o_bus_data_tri_n(o_bus_data_tri_n),
		.o_bus_we_n(o_bus_we_n),
		.o_bus_re_n(o_bus_re_n),
		.o_bus_ces_n(o_bus_ces_n),
		.o_bus_cle(o_bus_cle),
		.o_bus_ale(o_bus_ale)
	);
	
endmodule
