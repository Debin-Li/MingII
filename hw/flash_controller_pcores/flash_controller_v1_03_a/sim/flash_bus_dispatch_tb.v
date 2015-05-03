 `timescale 1ns / 1ps

module flash_bus_dispatch_tb;

	// Begin Testbench Architecture
	
        // Include Host Operations
	`include "host_ops.v"

	`include "functions.v"
	
	// Parameters
	localparam NUM_OF_BLOCKS = 4096;
	localparam NUM_OF_PAGES = 64;
	localparam NUM_OF_BYTES = 2048;
	localparam PERIOD = 14;
	localparam HALF_PERIOD = PERIOD/2;
	localparam ADC_PERIOD = 33.3;
        localparam ADC_HALF_PERIOD = ADC_PERIOD/2;
        localparam NUM_OF_BUSES = 4;
	localparam NUM_OF_CHIPS_PER_BUS = 4;
        localparam NUM_OF_CHIPS = (NUM_OF_BUSES * NUM_OF_CHIPS_PER_BUS);
        localparam NUM_OF_ADCS = NUM_OF_BUSES/2;
	
	localparam CMD_FIFO_DATA_WIDTH 	= 72;
	localparam WR_FIFO_DATA_WIDTH 	= 128;
	localparam RD_FIFO_DATA_WIDTH 	= 136;
	localparam RSLT_FIFO_DATA_WIDTH = 26;
	localparam RD_FIFO_COUNT_WIDTH	 	= 11;
	localparam WR_FIFO_COUNT_WIDTH	 	= 11;
 
	// Wires
	wire [7:0]                      Io[NUM_OF_BUSES-1:0];
        wire         	                Cle[NUM_OF_BUSES-1:0];
        wire		                Ale[NUM_OF_BUSES-1:0];
        wire [NUM_OF_CHIPS_PER_BUS-1:0]	Ce_n[NUM_OF_BUSES-1:0];
	wire		                Re_n[NUM_OF_BUSES-1:0];
        wire		                We_n[NUM_OF_BUSES-1:0];
        wire [NUM_OF_CHIPS_PER_BUS-1:0] Rb_n[NUM_OF_BUSES-1:0]; 
        wire		                Dqs[NUM_OF_BUSES-1:0];
	
        // ADC I/O Pins
        wire [NUM_OF_ADCS-1:0] fpga2adc_chip_select_n;
        wire                   fpga2adc_data;
        wire [1:0]             adc2fpga_data[NUM_OF_ADCS-1:0];

	reg clk;
        reg adc_clk;
	reg rst;
	
	// Generate clock
	 initial begin
            clk = 1;
            forever begin
                #HALF_PERIOD clk = ~clk;
            end
	end

	 // Generate ADC clock
	 initial begin
            adc_clk = 1;
            forever begin
                #ADC_HALF_PERIOD adc_clk = ~adc_clk;
            end
	end

	wire [7:0] bus_i_data[NUM_OF_BUSES-1:0];
	wire [7:0] bus_o_data[NUM_OF_BUSES-1:0];
	wire bus_data_tri[NUM_OF_BUSES-1:0];
	
        genvar i, j;
        
        generate
            for (i = 0; i < NUM_OF_BUSES; i = i + 1) begin
                assign Io[i] = (bus_data_tri[i] == 8'b0) ? bus_o_data[i] : {8{1'bz}};
                assign bus_i_data[i] = Io[i];
                assign Dqs[i] = 1'bz;
            end
	endgenerate

        // ADC Slave Model Signals
        reg [13:0] adc_read_value_0[NUM_OF_ADCS-1:0];
        reg [13:0] adc_read_value_1[NUM_OF_ADCS-1:0];
        wire [15:0] adc_write_value[NUM_OF_ADCS-1:0];

        // Host Signals
        wire [NUM_OF_CHIPS-1:0] chip_exists;
        wire                    bus_active[NUM_OF_BUSES-1:0];
        reg                     recording_en[NUM_OF_BUSES-1:0];
        reg  [3:0]              adc_gain;

	// Command FIFO Signals
	reg [CMD_FIFO_DATA_WIDTH-1:0]	cmd_fifo_data_in;
	wire [CMD_FIFO_DATA_WIDTH-1:0]	cmd_fifo_data_out;
	reg 				cmd_fifo_we;
	wire 				cmd_fifo_re;
	wire 				cmd_fifo_full;
	wire 				cmd_fifo_empty;
	
	// Write FIFO Signals
	reg [WR_FIFO_DATA_WIDTH-1:0]	wr_fifo_data_in;
	wire [WR_FIFO_DATA_WIDTH-1:0]	wr_fifo_data_out;
	reg 				wr_fifo_we;
	wire 				wr_fifo_re;
	wire 				wr_fifo_almost_full;
	wire 				wr_fifo_full;
	wire 				wr_fifo_almost_empty;
	wire 				wr_fifo_empty;
	wire [WR_FIFO_COUNT_WIDTH-1:0]	wr_fifo_count;
	
	// Read FIFO Signals
	wire [RD_FIFO_DATA_WIDTH-1:0]	rd_fifo_data_in;
	wire [RD_FIFO_DATA_WIDTH-1:0]	rd_fifo_data_out;
	wire				rd_fifo_we;
	reg				rd_fifo_re;
	wire	        		rd_fifo_almost_full;
	wire	        		rd_fifo_full;
	wire	        		rd_fifo_almost_empty;
	wire	        		rd_fifo_empty;
	wire [RD_FIFO_COUNT_WIDTH-1:0]	rd_fifo_count;
	
	// Result FIFO Signals
	wire [RSLT_FIFO_DATA_WIDTH-1:0]	rslt_fifo_data_in;
	wire [RSLT_FIFO_DATA_WIDTH-1:0]	rslt_fifo_data_out;
	wire				rslt_fifo_we;
	reg				rslt_fifo_re;
	wire				rslt_fifo_full;
	wire				rslt_fifo_empty;
        
        // Dispatch signals
        wire [NUM_OF_BUSES-1:0] d2c_cmd_req;
        wire [NUM_OF_BUSES-1:0] c2d_cmd_ack;
        wire [CMD_FIFO_DATA_WIDTH-1:0] d2c_cmd_data;
        wire [NUM_OF_BUSES-1:0] c2d_rsp_req;
        wire [NUM_OF_BUSES-1:0] d2c_rsp_ack;
        wire [NUM_OF_BUSES-1:0] d2c_rsp_listening;
        wire [RSLT_FIFO_DATA_WIDTH-1:0] c2d_rsp_data;
        wire [NUM_OF_BUSES*NUM_OF_CHIPS_PER_BUS-1:0] chip_active; 
        wire [NUM_OF_BUSES-1:0] wr_buffer_rsvd;
        wire [NUM_OF_BUSES-1:0] rd_buffer_rsvd;

        // ADC Command FIFO Signals
        reg  [17:0] adc_cmd_fifo_data_in;
        wire [17:0] adc_cmd_fifo_data_out;
        wire        adc_cmd_fifo_full;
        wire        adc_cmd_fifo_almost_full;
        wire        adc_cmd_fifo_empty;
        wire        adc_cmd_fifo_almost_empty;
        reg         adc_cmd_fifo_we;
        wire        adc_cmd_fifo_re;

        // ADC Response FIFO Signals
        wire [17:0] adc_rsp_fifo_data_in;
        wire [17:0] adc_rsp_fifo_data_out;
        wire        adc_rsp_fifo_full;
        wire        adc_rsp_fifo_almost_full;
        wire        adc_rsp_fifo_empty;
        wire        adc_rsp_fifo_almost_empty;
        wire        adc_rsp_fifo_we;
        reg         adc_rsp_fifo_re;

        // ADC Sample FIFO Signals
        wire [15:0] adc_sample_fifo_data_in[NUM_OF_BUSES-1:0];
        wire        adc_sample_fifo_almost_full[NUM_OF_BUSES-1:0];
        wire        adc_sample_fifo_full[NUM_OF_BUSES-1:0];
        wire        adc_sample_fifo_we[NUM_OF_BUSES-1:0];

        // Other ADC Signals
        wire adc_busy;
        wire [NUM_OF_BUSES-1:0] flash_bus_record;

        // Write Buffer Signals
        wire [9:0] wr_buffer_addr;
        wire [127:0] wr_buffer_data;
        wire [NUM_OF_BUSES-1:0] wr_buffer_we;
        
        // Read Buffer Signals
        wire [9:0] rd_buffer_addr;
        wire [127:0] rd_buffer_data;

        // Cycle Counter Signals
        reg   [7:0] cyclecount_start[NUM_OF_BUSES-1:0];
        reg   [7:0] cyclecount_end[NUM_OF_BUSES-1:0];
        wire [31:0] cyclecount_sum[NUM_OF_BUSES-1:0];
        reg         cyclecount_reset[NUM_OF_BUSES-1:0];

        reg [7:0] curr_cmd_tag;
	integer sent_requests, received_responses;
        integer done_sending_requests;

        // Begin Behavioral Models for Simulation
        // Flash Chip Models
        generate
            for (i = 0; i < NUM_OF_BUSES; i = i + 1) begin
                for (j = 0; j < NUM_OF_CHIPS_PER_BUS; j = j + 1) begin
                    nand_model flash (
                        .Dq_Io(Io[i]), 
                        .Cle(Cle[i]),
                        .Ale(Ale[i]), 
                        .Clk_We_n(We_n[i]), 
                        .Wr_Re_n(Re_n[i]), 
                        .Ce_n(Ce_n[i][j]), 
                        .Wp_n(1'b1), 
                        .Rb_n(Rb_n[i][j]),
                        .Dqs(Dqs[i])
                    );
                end
            end
        endgenerate

        // ADC Slave Models
        generate
            for (i = 0; i < NUM_OF_ADCS; i = i + 1) begin
                adc_slave slave_inst(
                    // System Inputs
                    .i_clk(adc_clk), // This clock is the clock sent to the ADC chip
                    .i_rst(rst),

                    // Inputs
                    .i_read_value_0(adc_read_value_0[i]),
                    .i_read_value_1(adc_read_value_1[i]),

                    // Outputs
                    .o_write_value(adc_write_value[i]),

                    // Chip Signals
                    .i_fpga_chip_select_n(fpga2adc_chip_select_n[i]),
                    .i_fpga_data(fpga2adc_data),
                    .o_fpga_data(adc2fpga_data[i])

                );
            end
        endgenerate

        // End Behavioral Models for Simulation
 
	// Device Under Test
	flash_bus_interface #(
		.CMD_FIFO_DATA_WIDTH(CMD_FIFO_DATA_WIDTH),
		.WR_FIFO_DATA_WIDTH(WR_FIFO_DATA_WIDTH),
		.RD_FIFO_DATA_WIDTH(RD_FIFO_DATA_WIDTH),
		.RSLT_FIFO_DATA_WIDTH(RSLT_FIFO_DATA_WIDTH),
		.RD_FIFO_COUNT_WIDTH(RD_FIFO_COUNT_WIDTH),
		.WR_FIFO_COUNT_WIDTH(WR_FIFO_COUNT_WIDTH)
	) interface (
		// System signals
		.i_clk(clk),
		.i_rst(rst),
		
		// Command FIFO Signals
		.i_cmd_fifo_data(cmd_fifo_data_in),
		.o_cmd_fifo_data(cmd_fifo_data_out),
		.i_cmd_fifo_re(cmd_fifo_re),
		.i_cmd_fifo_we(cmd_fifo_we),
		.o_cmd_fifo_empty(cmd_fifo_empty),
		.o_cmd_fifo_full(cmd_fifo_full),

		// Write FIFO Signals
		.i_wr_fifo_data(wr_fifo_data_in),
		.o_wr_fifo_data(wr_fifo_data_out),
		.i_wr_fifo_re(wr_fifo_re),
		.i_wr_fifo_we(wr_fifo_we),
		.o_wr_fifo_almost_empty(wr_fifo_almost_empty),
		.o_wr_fifo_empty(wr_fifo_empty),
		.o_wr_fifo_almost_full(wr_fifo_almost_full),
		.o_wr_fifo_full(wr_fifo_full),
		.o_wr_fifo_count(wr_fifo_count),
		
		// Read FIFO Signals
		.i_rd_fifo_data(rd_fifo_data_in),
		.o_rd_fifo_data(rd_fifo_data_out),
		.i_rd_fifo_re(rd_fifo_re),
		.i_rd_fifo_we(rd_fifo_we),
		.o_rd_fifo_almost_empty(rd_fifo_almost_empty),
		.o_rd_fifo_empty(rd_fifo_empty),
		.o_rd_fifo_almost_full(rd_fifo_almost_full),
		.o_rd_fifo_full(rd_fifo_full),
		.o_rd_fifo_count(rd_fifo_count),
		
		// Result FIFO Signals
		.i_rslt_fifo_data(rslt_fifo_data_in),
		.o_rslt_fifo_data(rslt_fifo_data_out),
		.i_rslt_fifo_re(rslt_fifo_re),
		.i_rslt_fifo_we(rslt_fifo_we),
		.o_rslt_fifo_empty(rslt_fifo_empty),
		.o_rslt_fifo_full(rslt_fifo_full)
	);
	flash_bus_dispatch #(
		.NUM_OF_BUSES(NUM_OF_BUSES),
		.NUM_OF_CHIPS_PER_BUS(NUM_OF_CHIPS_PER_BUS),
		.CMD_FIFO_DATA_WIDTH(CMD_FIFO_DATA_WIDTH),
		.WR_FIFO_DATA_WIDTH(WR_FIFO_DATA_WIDTH),
		.RD_FIFO_DATA_WIDTH(RD_FIFO_DATA_WIDTH),
		.RSLT_FIFO_DATA_WIDTH(RSLT_FIFO_DATA_WIDTH),
		.RD_FIFO_COUNT_WIDTH(RD_FIFO_COUNT_WIDTH)
	 ) flash_bus_dispatch_inst (
		// System signals
		.i_clk(clk),
		.i_rst(rst),
		
		// Command FIFO Signals
		.i_cmd_fifo_data(cmd_fifo_data_out),
		.o_cmd_fifo_re(cmd_fifo_re),
		.i_cmd_fifo_empty(cmd_fifo_empty),

		// Write FIFO Signals
		.i_wr_fifo_data(wr_fifo_data_out),
		.o_wr_fifo_re(wr_fifo_re),
		.i_wr_fifo_almost_empty(wr_fifo_almost_empty),
		.i_wr_fifo_empty(wr_fifo_empty),
	        .i_wr_fifo_count(wr_fifo_count),

		// Read FIFO Signals
		.o_rd_fifo_data(rd_fifo_data_in),
		.o_rd_fifo_we(rd_fifo_we),
		.i_rd_fifo_almost_full(rd_fifo_almost_full),
		.i_rd_fifo_full(rd_fifo_full),
		.i_rd_fifo_count(rd_fifo_count),

		// Result FIFO Signals
		.o_rslt_fifo_data(rslt_fifo_data_in),
		.o_rslt_fifo_we(rslt_fifo_we),
		.i_rslt_fifo_full(rslt_fifo_full),

                // Flash Bus signals
                .o_bus_cmd_req(d2c_cmd_req),
                .i_bus_cmd_ack(c2d_cmd_ack),
                .o_bus_cmd_data(d2c_cmd_data),
                .i_bus_rsp_req(c2d_rsp_req),
                .o_bus_rsp_ack(d2c_rsp_ack),
                .o_bus_rsp_listening(d2c_rsp_listening),
                .i_bus_rsp_data(c2d_rsp_data),
                .i_bus_chip_active(chip_active), 
                .i_bus_wr_buffer_rsvd(wr_buffer_rsvd),
                .i_bus_rd_buffer_rsvd(rd_buffer_rsvd),

                // Write Buffer Signals
                .o_bus_wr_buffer_addr(wr_buffer_addr),
                .o_bus_wr_buffer_data(wr_buffer_data),
                .o_bus_wr_buffer_we(wr_buffer_we),
                
                // Read Buffer Signals
                .o_bus_rd_buffer_addr(rd_buffer_addr),
                .i_bus_rd_buffer_data(rd_buffer_data)
        );

	generate
            for (i = 0; i < NUM_OF_BUSES; i = i + 1) begin
                flash_bus #(
                    .NUM_OF_CHIPS(NUM_OF_CHIPS_PER_BUS),
                    .CMD_FIFO_DATA_WIDTH(CMD_FIFO_DATA_WIDTH),
                    .WR_FIFO_DATA_WIDTH(WR_FIFO_DATA_WIDTH),
                    .RD_FIFO_DATA_WIDTH(RD_FIFO_DATA_WIDTH),
                    .RSLT_FIFO_DATA_WIDTH(RSLT_FIFO_DATA_WIDTH),
                    .PERIOD(PERIOD)
                 ) flashBus (
                    // System signals
                    .i_clk(clk),
                    .i_rst(rst),
                    .i_adc_clk(adc_clk),

                    .o_top_bus_active(bus_active[i]),
                    .i_recording_en(recording_en[i]),

                    // Dispatch signals
                    .i_disp_cmd_req(d2c_cmd_req[i]),
                    .o_disp_cmd_ack(c2d_cmd_ack[i]),
                    .i_disp_cmd_data(d2c_cmd_data),
                    .o_disp_rsp_req(c2d_rsp_req[i]),
                    .i_disp_rsp_ack(d2c_rsp_ack[i]),
                    .i_disp_rsp_listening(d2c_rsp_listening[i]),
                    .o_disp_rsp_data(c2d_rsp_data),
                    .o_disp_chip_active(chip_active[4*(i+1)-1:4*i]), 
                    .o_disp_wr_buffer_rsvd(wr_buffer_rsvd[i]),
                    .o_disp_rd_buffer_rsvd(rd_buffer_rsvd[i]),

                    // ADC Sample FIFO Signals
                    .i_adc_sample_fifo_data(adc_sample_fifo_data_in[i]),
                    .o_adc_sample_fifo_almost_full(adc_sample_fifo_almost_full[i]),
                    .o_adc_sample_fifo_full(adc_sample_fifo_full[i]),
                    .i_adc_sample_fifo_we(adc_sample_fifo_we[i]),
	
                    // Write Buffer Signals
                    .i_disp_wr_buffer_addr(wr_buffer_addr),
                    .i_disp_wr_buffer_data(wr_buffer_data),
                    .i_disp_wr_buffer_we(wr_buffer_we[i]),
                    
                    // Read Buffer Signals
                    .i_disp_rd_buffer_addr(rd_buffer_addr),
                    .o_disp_rd_buffer_data(rd_buffer_data),

                    // Performance Counter Signals
                    .o_cyclecount_sum(cyclecount_sum[i]),
                    .i_cyclecount_reset(cyclecount_reset[i]),
                    .i_cyclecount_start(cyclecount_start[i]),
                    .i_cyclecount_end(cyclecount_end[i]),
                    
                    // ADC Master Signals
                    .o_adc_master_record(flash_bus_record[i]),

                    // Flash bus signals
                    .i_bus_data(bus_i_data[i]),
                    .o_bus_data(bus_o_data[i]),
                    .o_bus_data_tri_n(bus_data_tri[i]),
                    .o_bus_we_n(We_n[i]),
                    .o_bus_re_n(Re_n[i]),
                    .o_bus_ces_n(Ce_n[i]),
                    .o_bus_cle(Cle[i]),
                    .o_bus_ale(Ale[i]),
                            
                    // Top Level Signals
                    // TODO: Do I really need these?
                    .o_chip_exists(chip_exists[(1+i)*NUM_OF_CHIPS_PER_BUS-1:i*NUM_OF_CHIPS_PER_BUS])
                );
            end
        endgenerate
        
        // ADC Command FIFO
        adc_comm_fifo adc_cmd_fifo_inst_0(
            .rst(rst),
            .wr_clk(adc_clk),
            .rd_clk(clk),
            .din(adc_cmd_fifo_data_in),
            .wr_en(adc_cmd_fifo_we),
            .rd_en(adc_cmd_fifo_re),
            .dout(adc_cmd_fifo_data_out),
            .full(adc_cmd_fifo_full),
            .almost_full(adc_cmd_fifo_almost_full),
            .empty(adc_cmd_fifo_empty),
            .almost_empty(adc_cmd_fifo_almost_empty)
        );

        // ADC Response FIFO
        adc_comm_fifo adc_rsp_fifo_inst(
            .rst(rst),
            .wr_clk(adc_clk),
            .rd_clk(clk),
            .din(adc_rsp_fifo_data_in),
            .wr_en(adc_rsp_fifo_we),
            .rd_en(adc_rsp_fifo_re),
            .dout(adc_rsp_fifo_data_out),
            .full(adc_rsp_fifo_full),
            .almost_full(adc_rsp_fifo_almost_full),
            .empty(adc_rsp_fifo_empty),
            .almost_empty(adc_rsp_fifo_almost_empty)
        );

        // ADC Master Instantiation
        adc_master master_inst(
            // System Inputs
            .i_clk(adc_clk), // This clock is the clock sent to the ADC chip
            .i_rst(rst),

            .i_gain(adc_gain),

            // Command Interface
            .i_adc_cmd_fifo_data(adc_cmd_fifo_data_out),
            .i_adc_cmd_fifo_empty(adc_cmd_fifo_empty),
            .o_adc_cmd_fifo_re(adc_cmd_fifo_re),

            // Response Interface
            .o_adc_rsp_fifo_data(adc_rsp_fifo_data_in),
            .i_adc_rsp_fifo_full(adc_rsp_fifo_full),
            .o_adc_rsp_fifo_we(adc_rsp_fifo_we),

            // Flash Bus Signals
            .o_adc_busy(adc_busy),
            .i_flash_bus_record(flash_bus_record),
            .o_sample_fifo_0_data(adc_sample_fifo_data_in[0]),
            .o_sample_fifo_0_we(adc_sample_fifo_we[0]),
            .o_sample_fifo_1_data(adc_sample_fifo_data_in[1]),
            .o_sample_fifo_1_we(adc_sample_fifo_we[1]),
            .o_sample_fifo_2_data(adc_sample_fifo_data_in[2]),
            .o_sample_fifo_2_we(adc_sample_fifo_we[2]),
            .o_sample_fifo_3_data(adc_sample_fifo_data_in[3]),
            .o_sample_fifo_3_we(adc_sample_fifo_we[3]),

            // Chip Signals
            .o_adc_chip_select_n(fpga2adc_chip_select_n),
            .o_adc_chip_data(fpga2adc_data),
            .i_adc_chip_data({adc2fpga_data[1],adc2fpga_data[0]})
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
		input [9:0] size;
		input [7:0] op;
		input [45:0] addr;
	begin
		wait (cmd_fifo_full === 0);
		cmd_fifo_data_in = {curr_cmd_tag,size,op,addr};
		cmd_fifo_we = 1;
		#PERIOD;
		cmd_fifo_we = 0;
                #PERIOD;
                curr_cmd_tag = curr_cmd_tag + 1;
                sent_requests = sent_requests + 1;
	end
	endtask

        task read_responses;
            //input integer num_of_responses;
            integer i;
        begin
                while (!done_sending_requests || (done_sending_requests && (received_responses < sent_requests))) begin
                //for (i = 0; i < num_of_responses; i = i + 1) begin
                    wait(!rslt_fifo_empty);
                    received_responses = received_responses + 1;
                    $display("Received response (%3d/%3d)- Tag %d, Length %d, Error %d", received_responses, sent_requests, rslt_fifo_data_out[25:18], rslt_fifo_data_out[17:8], rslt_fifo_data_out[7:0]);
                    rslt_fifo_re = 1;
                    #PERIOD;
                    rslt_fifo_re = 0;
                    #PERIOD;
                end
        end
        endtask
        
        task read_from_rd_fifo;
            integer i;
            reg [7:0] j;
        begin
		j = 8'd0;
                while (!done_sending_requests || (done_sending_requests && (received_responses < sent_requests))) begin
                    wait(!rd_fifo_empty);
                    rd_fifo_re = 1;
                    #PERIOD;
                    
                    // Check that the data matches
                    if (rd_fifo_data_out != {j+8'd15, j+8'd14, j+8'd13, j+8'd12, j+8'd11, j+8'd10, j+8'd9, j+8'd8, j+8'd7, j+8'd6, j+8'd5, j+8'd4, j+8'd3, j+8'd2, j+8'd1, j}) begin
                        $display("Data mismatch in the Read FIFO at j = %d", j);
                    end else begin
                        $display("Data match in the Read FIFO at j = %d", j);
                    end

                    rd_fifo_re = 0;
                    #PERIOD;
                    j = j + 8'd16;
                end
        end
        endtask
        
        //  Reset all chip
	task reset_all_chips;
	    integer i, j;
        begin
            for (i = 0; i < NUM_OF_CHIPS_PER_BUS; i = i + 1) begin
                for (j = 0; j < NUM_OF_BUSES; j = j + 1) begin
		    issue_cmd(0,HOP_RESET,make_address(j,i,0*NUM_OF_BLOCKS + 0,0));
                end
            end
            for (i = 0; i < NUM_OF_CHIPS_PER_BUS; i = i + 1) begin
                for (j = 0; j < NUM_OF_BUSES; j = j + 1) begin
		    issue_cmd(0,HOP_SET_TIMING_MODE,make_address(j,i,0*NUM_OF_BLOCKS + 0,0));
                end
            end
        end
	endtask
	
        // Erase a block
	task erase_block;
		input [0:log2(NUM_OF_BLOCKS)-1] block_number;
	begin
		issue_cmd(0,HOP_ERASE,make_address(0,0,block_number*NUM_OF_BLOCKS+0,0));
	end
	endtask
	
	// Write data to write FIFO
	task write_to_wr_fifo;
		input [9:0] length; // This is in terms of 32 byte chunks, but I only write 16 bytes to the write fifo so double it
		integer i;
                reg [7:0] j;
	begin
		j = 8'd0;
		for (i = 0; i < length*2; i = i + 1) begin
			wait(wr_fifo_full == 0);
			wr_fifo_data_in = {j+8'd15, j+8'd14, j+8'd13, j+8'd12, j+8'd11, j+8'd10, j+8'd9, j+8'd8, j+8'd7, j+8'd6, j+8'd5, j+8'd4, j+8'd3, j+8'd2, j+8'd1, j};
			wr_fifo_we = 1;
			#PERIOD;
			wr_fifo_we = 0;
                        j = j + 8'd16;
		end
	end
	endtask

	//Program page
	task program_page;
		input [9:0] size;
		input [0:log2(NUM_OF_BLOCKS)-1] block_number;
		input [0:log2(NUM_OF_PAGES)-1] page_number;
		input [0:log2(NUM_OF_BYTES)] byte_number;
		input [7:0] program_data;
	begin
		write_to_wr_fifo(size);
		issue_cmd(size,HOP_PROGRAM,make_address(0,0,block_number*NUM_OF_BLOCKS+page_number,byte_number));
	end
	endtask
	
	//Read a page
	task read_page;
		input [7:0] size;
		input [0:log2(NUM_OF_BLOCKS)-1] block_number;
		input [0:log2(NUM_OF_PAGES)-1] page_number;
		input [0:log2(NUM_OF_BYTES)] byte_number;
	begin
		issue_cmd(size,HOP_READ,make_address(0,0,block_number*NUM_OF_BLOCKS+page_number,byte_number));
	end
	endtask
	
	// Read Chip ID
	task read_id;
            input [1:0] bus_number;
            input [3:0] chip_number;
	begin
		issue_cmd(1,HOP_READID,make_address(bus_number,chip_number,0,0));
	end
	endtask
	
	// Read All Chips IDs
	task read_all_ids;
	    integer i, j;
        begin
            for (i = 0; i < NUM_OF_CHIPS_PER_BUS; i = i + 1) begin
                for (j = 0; j < NUM_OF_BUSES; j = j + 1) begin
		    read_id(j,i);
                end
            end
	end
	endtask
	
        // Read Parameter Page
	task read_params;
            input [1:0] bus_number;
            input [3:0] chip_number;
	begin
		issue_cmd(256/32,HOP_READPARAM,make_address(bus_number,chip_number,0,0));
	end
	endtask
	
        // Get ADC Data
	task get_adc_samples;
            input [1:0] bus_number;
	begin
		issue_cmd(0,HOP_GET_ADC_SAMPLES,make_address(bus_number,0,0,0));
	end
	endtask
	
	// Read All Chips Paramater Pages
	task read_all_params;
	    integer i, j;
        begin
            for (i = 0; i < NUM_OF_CHIPS_PER_BUS; i = i + 1) begin
                for (j = 0; j < NUM_OF_BUSES; j = j + 1) begin
		    read_params(j,i);
                end
            end
	end
	endtask
	
	task test_erase_block;
	begin
		erase_block(120);
		program_page(66,120,0,0,8'h3a);
		erase_block(120);
		read_page(66,120,0,0);
	end
	endtask
	
	task test_program_page;
	begin
		erase_block(120);
		program_page(66,120,0,0,8'h3a);
		read_page(66,120,0,0);
	end
	endtask
	
	task test_random_ops;
	begin
		erase_block(120);
                program_page(66,120,0,0,8'h3a);

                wait (received_responses == sent_requests);
                $display("Program took %d cycles", cyclecount_sum[0]);
                get_adc_samples(0);

                erase_block(155);
		read_page(2,120,0,0);
		program_page(66,155,0,0,8'hb4);
                
                wait (received_responses == sent_requests);
                $display("Program took %d cycles", cyclecount_sum[0]);
                get_adc_samples(0);

		read_page(32,155,0,0);
	end
	endtask
	
	
	initial begin : main_test
            // Default Values
            curr_cmd_tag = 0;
            sent_requests = 0;
            received_responses = 0;
            done_sending_requests = 0;

            cmd_fifo_data_in = 0;
            cmd_fifo_we = 0;
            wr_fifo_data_in = 0;
            wr_fifo_we = 0;
            rd_fifo_re = 0;
            rslt_fifo_re = 0;
        
            adc_gain = 4'd1;
            adc_read_value_0[0] = 14'h1212;
            adc_read_value_1[0] = 14'h3434;
            adc_read_value_0[1] = 14'h5656;
            adc_read_value_1[1] = 14'h7878;
        
            adc_cmd_fifo_data_in = 18'h00000;
            adc_cmd_fifo_we = 1'b0;

            adc_rsp_fifo_re = 1'b0;
            
            cyclecount_start[0] = 8'd4;
            cyclecount_start[1] = 8'd0;
            cyclecount_start[2] = 8'd0;
            cyclecount_start[3] = 8'd0;
            cyclecount_end[0] = 8'd6;
            cyclecount_end[1] = 8'd0;
            cyclecount_end[2] = 8'd0;
            cyclecount_end[3] = 8'd0;
            cyclecount_reset[0] = 1'b0;
            cyclecount_reset[1] = 1'b0;
            cyclecount_reset[2] = 1'b0;
            cyclecount_reset[3] = 1'b0;

            recording_en[0] = 1'b1;
            recording_en[1] = 1'b0;
            recording_en[2] = 1'b0;
            recording_en[3] = 1'b0;
            
            rst = 1;
            #(PERIOD*2) rst = 0;

            #1000000;

            
            fork
               begin
                    //reset_all_chips;

                    #1200000;

                    $display("chip_exists: %x", chip_exists);

                    // Perform a test
                    //read_id;
                    $display("Reading all ids");
                    //read_all_ids;
                    //read_params;
                    $display("Reading all parameters");
                    //read_all_params;
                    //test_erase_block;
                    //test_program_page;
                    $display("Testing random ops");
                    test_random_ops;
                    $display("Done sending ops");
                    done_sending_requests = 1;
                end

                begin
                    read_responses;
                end
               
                //begin
                //    read_from_rd_fifo;
                //end
            join

            #100000;
            $stop(0);
            $finish;
	end
	
endmodule
