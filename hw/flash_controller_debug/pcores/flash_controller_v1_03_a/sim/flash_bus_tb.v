 `timescale 1ns / 1ps

module flash_bus_tb;

	// Begin Testbench Architecture

	`include "functions.v"
	
	// Parameters
	localparam NUM_OF_BLOCKS = 4096;
	localparam NUM_OF_PAGES = 64;
	localparam NUM_OF_BYTES = 2048;
	localparam PERIOD = 14;
	localparam HALF_PERIOD = PERIOD/2;
	localparam NUM_OF_CHIPS = 4;
	
	localparam CMD_FIFO_DATA_WIDTH 	= 72;
	localparam WR_FIFO_DATA_WIDTH 	= 128;
	localparam RD_FIFO_DATA_WIDTH 	= 136;
	localparam RSLT_FIFO_DATA_WIDTH = 24;

 
	// Wires
	wire	[7:0]   Io;
        wire         	Cle;
        wire		Ale;
        wire	[NUM_OF_CHIPS-1:0]	Ce_n;
	wire		Re_n;
        wire		We_n;
        wire		Wp_n = 1'b1;
        tri1		Rb_n;
	
	reg clk;
	reg rst;
	
	// Generate clock
	 initial begin
            clk = 1;
            forever begin
                    #HALF_PERIOD clk = ~clk;
            end
	end
	
	wire [7:0] bus_i_data;
	wire [7:0] bus_o_data;
	wire bus_data_tri;
	
	assign Io = (bus_data_tri == 8'b0) ? bus_o_data : 8'bz;
	assign bus_i_data = Io;
	
        // Dispatch signals
        reg d2c_cmd_req;
        wire c2d_cmd_ack;
        reg [CMD_FIFO_DATA_WIDTH-1:0] d2c_cmd_data;
        wire c2d_rsp_req;
        reg d2c_rsp_ack;
        reg d2c_rsp_listening;
        wire [RSLT_FIFO_DATA_WIDTH-1:0] c2d_rsp_data;
        wire [NUM_OF_CHIPS-1:0] chip_active; 
        wire wr_buffer_rsvd;
        wire rd_buffer_rsvd;

        // Write Buffer Signals
        reg [9:0] wr_buffer_addr;
        reg [127:0] wr_buffer_data;
        reg wr_buffer_we;
        
        // Read Buffer Signals
        reg [9:0] rd_buffer_addr;
        wire [127:0] rd_buffer_data;

        wire [NUM_OF_CHIPS-1:0] chip_exists;

	// Include Host Operations
	`include "host_ops.v"
	
	nand_model flash (
		.Dq_Io(Io), 
		.Cle(Cle),
		.Ale(Ale), 
		.Clk_We_n(We_n), 
		.Wr_Re_n(Re_n), 
		.Ce_n(Ce_n[0]), 
		.Wp_n(Wp_n), 
		.Rb_n(Rb_n)
	);
 
	// Device Under Test
	flash_bus #(
		.NUM_OF_CHIPS(NUM_OF_CHIPS),
		.CMD_FIFO_DATA_WIDTH(CMD_FIFO_DATA_WIDTH),
		.WR_FIFO_DATA_WIDTH(WR_FIFO_DATA_WIDTH),
		.RD_FIFO_DATA_WIDTH(RD_FIFO_DATA_WIDTH),
		.RSLT_FIFO_DATA_WIDTH(RSLT_FIFO_DATA_WIDTH),
		.PERIOD(PERIOD)
	 ) flashBus (
		// System signals
		.i_clk(clk),
		.i_rst(rst),
		
                // Dispatch signals
                .i_disp_cmd_req(d2c_cmd_req),
                .o_disp_cmd_ack(c2d_cmd_ack),
                .i_disp_cmd_data(d2c_cmd_data),
                .o_disp_rsp_req(c2d_rsp_req),
                .i_disp_rsp_ack(d2c_rsp_ack),
                .i_disp_rsp_listening(d2c_rsp_listening),
                .o_disp_rsp_data(c2d_rsp_data),
                .o_disp_chip_active(chip_active), 
                .o_disp_wr_buffer_rsvd(wr_buffer_rsvd),
                .o_disp_rd_buffer_rsvd(rd_buffer_rsvd),

                // Write Buffer Signals
                .i_disp_wr_buffer_addr(wr_buffer_addr),
                .i_disp_wr_buffer_data(wr_buffer_data),
                .i_disp_wr_buffer_we(wr_buffer_we),
                
                // Read Buffer Signals
                .i_disp_rd_buffer_addr(rd_buffer_addr),
                .o_disp_rd_buffer_data(rd_buffer_data),

		// Performance Counter Signals
		.o_cyclecount_sum(),
		.i_cyclecount_reset(),
		.i_cyclecount_start(),
		.i_cyclecount_end(),
		
		// Flash bus signals
		.i_bus_data(bus_i_data),
		.o_bus_data(bus_o_data),
		.o_bus_data_tri_n(bus_data_tri),
		.o_bus_we_n(We_n),
		.o_bus_re_n(Re_n),
		.o_bus_ces_n(Ce_n),
		.o_bus_cle(Cle),
		.o_bus_ale(Ale),
			
		// Top Level Signals
		// TODO: Do I really need these?
		.o_chip_exists(chip_exists),
                .i_write_low_count(4'd2),
		.i_write_high_count(4'd1),
		.i_read_low_count(4'd3),
		.i_read_high_count(4'd1)
	);
	
	function [45:0] make_address;
		input [1:0] bus_number;
		input [3:0] chip_number;
		input [23:0] page_number;
		input [15:0] byte_number;
	begin
		// TODO: Make modular
		make_address = {bus_number,chip_number,page_number,byte_number};
		//$display("log2(BLOCKS) = %d log2(PAGES) = %d log2(BYTES) = %d Address: %b",log2(NUM_OF_BLOCKS),log2(NUM_OF_PAGES),log2(NUM_OF_BYTES),make_address);
	end
	endfunction
	
	// Issue Command
	// Command Data = {tag,size,op,addr}
	task issue_cmd;
		input [7:0] tag;
		input [9:0] size;
		input [7:0] op;
		input [45:0] addr;
	begin
		if (op == HOP_PROGRAM) begin
                    wait(!wr_buffer_rsvd);
                end else if ((op == HOP_READID) || (op == HOP_READ)) begin
                    wait(!rd_buffer_rsvd);
                end
        
                wait(!chip_active);
                
		d2c_cmd_data = {tag,size,op,addr};
		d2c_cmd_req = 1;
                wait(c2d_cmd_ack)
		#PERIOD;
		d2c_cmd_req = 0;

                wait(c2d_rsp_req);
                #PERIOD;
                d2c_rsp_ack = 1;
                #PERIOD;
                d2c_rsp_ack = 0;
	end
	endtask
	
	//  Reset a chip
	task reset_chip;
		input [3:0] chip_number;
	begin
		issue_cmd(0,0,HOP_RESET,make_address(0,chip_number,0*NUM_OF_BLOCKS + 0,0));
		issue_cmd(1,0,HOP_SET_TIMING_MODE,make_address(0,chip_number,0*NUM_OF_BLOCKS + 0,0));
	end
	endtask
	
        // Erase a block
	task erase_block;
		input [7:0] tag;
		input [0:log2(NUM_OF_BLOCKS)-1] block_number;
	begin
		issue_cmd(tag,0,HOP_ERASE,make_address(0,0,block_number*NUM_OF_BLOCKS+0,0));
	end
	endtask
	
	// Write data to write FIFO
	task write_to_wr_buffer;
		input [9:0] length; // This is in terms of 32 byte chunks, but I only write 16 bytes to the write fifo so double it
		integer i;
                reg [7:0] j;
	begin
		j = 8'd0;
                for (i = 0; i < length*2; i = i + 1) begin
                        wr_buffer_addr = i;
			wr_buffer_data = {j+8'd15, j+8'd14, j+8'd13, j+8'd12, j+8'd11, j+8'd10, j+8'd9, j+8'd8, j+8'd7, j+8'd6, j+8'd5, j+8'd4, j+8'd3, j+8'd2, j+8'd1, j};
			wr_buffer_we = 1;
			#PERIOD;
			wr_buffer_we = 0;
                        j = j + 8'd16;
		end
	end
	endtask

	//Program page
	task program_page;
		input [7:0] tag;
		input [9:0] size;
		input [0:log2(NUM_OF_BLOCKS)-1] block_number;
		input [0:log2(NUM_OF_PAGES)-1] page_number;
		input [0:log2(NUM_OF_BYTES)] byte_number;
		input [7:0] program_data;
	begin
		write_to_wr_buffer(size);
		issue_cmd(tag,size,HOP_PROGRAM,make_address(0,0,block_number*NUM_OF_BLOCKS+page_number,byte_number));
	end
	endtask
	
	//Read a page
	task read_page;
		input [7:0] tag;
		input [7:0] size;
		input [0:log2(NUM_OF_BLOCKS)-1] block_number;
		input [0:log2(NUM_OF_PAGES)-1] page_number;
		input [0:log2(NUM_OF_BYTES)] byte_number;
	begin
		issue_cmd(tag,size,HOP_READ,make_address(0,0,block_number*NUM_OF_BLOCKS+page_number,byte_number));
	end
	endtask
	
	// Read Chip ID
	task read_id;
	begin
		issue_cmd(3,0,HOP_READID,make_address(0,0,0*NUM_OF_BLOCKS+0,0));
	end
	endtask
	
	// Read Parameter Page
	task read_params;
	begin
		issue_cmd(4,256/32,HOP_READPARAM,make_address(0,0,0*NUM_OF_BLOCKS+0,0));
	end
	endtask
	
	task test_erase_block;
	begin
		erase_block(0,120);
		program_page(1,66,120,0,0,8'h3a);
		erase_block(2,120);
		read_page(3,66,120,0,0);
	end
	endtask
	
	task test_program_page;
	begin
		erase_block(0,120);
		program_page(1,66,120,0,0,8'h3a);
		read_page(2,66,120,0,0);
	end
	endtask
	
	task test_random_ops;
	begin
		erase_block(0,120);
		program_page(1,66,120,0,0,8'h3a);
		erase_block(2,155);
		read_page(3,2,120,0,0);
		program_page(4,66,155,0,0,8'hb4);
		read_page(5,32,155,0,0);
	end
	endtask
	
    initial begin : main_test
	d2c_cmd_data = 0;
        d2c_cmd_req = 0;
        d2c_rsp_ack = 0;
        d2c_rsp_listening = 1;
        wr_buffer_data = 0;
        wr_buffer_addr = 0;
        wr_buffer_we = 0;
        rd_buffer_addr = 0;
	
        rst = 1;
	#(PERIOD*2) rst = 0;

	#1000000;

        //reset_chip(0);

        #1000000;
        #1000000;

        $display("chip_exists: %x", chip_exists);

	// Perform a test
	read_id;
	read_params;
	//test_erase_block;
	//test_program_page;
	test_random_ops;
	
	#1000000 $stop(0);
	$finish;
    end
	
endmodule
