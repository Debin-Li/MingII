 `timescale 1ns / 1ps

module adc_master_tb;

    // Begin Testbench Architecture
    parameter PERIOD = 40;
    parameter HALF_PERIOD = PERIOD/2;

    // Wires
    reg clk;
    reg rst;

    reg [13:0] adc_read_value_0;
    reg [13:0] adc_read_value_1;
    reg [13:0] adc_read_value_2;
    reg [13:0] adc_read_value_3;
    wire [15:0] adc_write_value[1:0];

    wire [1:0] fpga2adc_chip_select_n;
    wire fpga2adc_data;
    wire [3:0] adc2fpga_data;
        
    reg [3:0] gain;

    reg [17:0] adc_cmd_fifo_data_in;
    reg        adc_cmd_fifo_empty;
    wire       adc_cmd_fifo_re;

    // Response Interface
    wire     [17:0] adc_rsp_fifo_data_out;
    reg             adc_rsp_fifo_full;
    wire            adc_rsp_fifo_we;

    // Flash Bus Signals
    wire            adc_busy;
    reg       [3:0] flash_bus_record;
    wire     [15:0] sample_fifo_data_out[3:0];
    wire            sample_fifo_we[3:0];
	
    // Generate clock
    initial begin
        clk = 1;
        forever begin
            #HALF_PERIOD clk = ~clk;
        end
    end

    // ADC Slave Module 0 Instantiation
    adc_slave slave_inst_0(
        // System Inputs
        .i_clk(clk), // This clock is the clock sent to the ADC chip
        .i_rst(rst),

        // Inputs
        .i_read_value_0(adc_read_value_0),
        .i_read_value_1(adc_read_value_1),

        // Outputs
        .o_write_value(adc_write_value[0]),

        // Chip Signals
        .i_fpga_chip_select_n(fpga2adc_chip_select_n[0]),
        .i_fpga_data(fpga2adc_data),
        .o_fpga_data(adc2fpga_data[1:0])

    );

    // ADC Slave Module 1 Instantiation
    adc_slave slave_inst_1(
        // System Inputs
        .i_clk(clk), // This clock is the clock sent to the ADC chip
        .i_rst(rst),

        // Inputs
        .i_read_value_0(adc_read_value_2),
        .i_read_value_1(adc_read_value_3),

        // Outputs
        .o_write_value(adc_write_value[1]),

        // Chip Signals
        .i_fpga_chip_select_n(fpga2adc_chip_select_n[1]),
        .i_fpga_data(fpga2adc_data),
        .o_fpga_data(adc2fpga_data[3:2])

    );

    // ADC Master Module Instantiation
    adc_master master_inst(
        // System Inputs
        .i_clk(clk), // This clock is the clock sent to the ADC chip
        .i_rst(rst),

        .i_gain(gain),

        // Command Interface
        .i_adc_cmd_fifo_data(adc_cmd_fifo_data_in),
        .i_adc_cmd_fifo_empty(adc_cmd_fifo_empty),
        .o_adc_cmd_fifo_re(adc_cmd_fifo_re),

        // Response Interface
        .o_adc_rsp_fifo_data(adc_rsp_fifo_data_out),
        .i_adc_rsp_fifo_full(adc_rsp_fifo_full),
        .o_adc_rsp_fifo_we(adc_rsp_fifo_we),

        // Flash Bus Signals
        .o_adc_busy(adc_busy),
        .i_flash_bus_record(flash_bus_record),
        .o_sample_fifo_0_data(sample_fifo_data_out[0]),
        .o_sample_fifo_0_we(sample_fifo_we[0]),
        .o_sample_fifo_1_data(sample_fifo_data_out[1]),
        .o_sample_fifo_1_we(sample_fifo_we[1]),
        .o_sample_fifo_2_data(sample_fifo_data_out[2]),
        .o_sample_fifo_2_we(sample_fifo_we[2]),
        .o_sample_fifo_3_data(sample_fifo_data_out[3]),
        .o_sample_fifo_3_we(sample_fifo_we[3]),

        // Chip Signals
        .o_adc_chip_select_n(fpga2adc_chip_select_n),
        .o_adc_chip_data(fpga2adc_data),
        .i_adc_chip_data(adc2fpga_data)
    );
    
    // Test ADC Write
    task test_adc_write;
    begin
        wait (adc_busy === 0);
        @(negedge clk);
        adc_cmd_fifo_data_in = 18'h27654;
        adc_cmd_fifo_empty = 1'b0;
        wait (adc_cmd_fifo_re === 1);
        @(posedge clk);
        adc_cmd_fifo_data_in = 18'h00000;
        adc_cmd_fifo_empty = 1'b1;
        wait (adc_busy === 0);
        @(negedge clk);
        adc_cmd_fifo_data_in = 18'h2ABCD;
        adc_cmd_fifo_empty = 1'b0;
        wait (adc_cmd_fifo_re === 1);
        @(posedge clk);
        adc_cmd_fifo_data_in = 18'h00000;
        adc_cmd_fifo_empty = 1'b1;
    end
    endtask
	
    // Test ADC Read
    task test_adc_read;
    begin
        wait (adc_busy === 0);
        @(negedge clk);
        adc_cmd_fifo_data_in = 18'h10123;
        adc_cmd_fifo_empty = 1'b0;
        wait (adc_cmd_fifo_re === 1);
        @(posedge clk);
        adc_cmd_fifo_data_in = 18'h00000;
        adc_cmd_fifo_empty = 1'b1;
        wait (adc_busy === 0);
        @(negedge clk);
        adc_cmd_fifo_data_in = 18'h1589A;
        adc_cmd_fifo_empty = 1'b0;
        wait (adc_cmd_fifo_re === 1);
        @(posedge clk);
        adc_cmd_fifo_data_in = 18'h00000;
        adc_cmd_fifo_empty = 1'b1;
    end
    endtask
    
    // Test Dual-Channel Recording
    task test_2chan_recording;
    begin
        wait (adc_busy === 0);
        @(negedge clk);
        flash_bus_record = 4'b1010;

        #100000;
        flash_bus_record = 4'b0000;
    end
    endtask
	
    // Test Quad-Channel Recording
    task test_4chan_recording;
    begin
        wait (adc_busy === 0);
        @(negedge clk);
        flash_bus_record = 4'b1111;

        #100000;
        flash_bus_record = 4'b1111;
    end
    endtask
	
	
    initial begin : main_test
        // Default Values
        adc_read_value_0 = 14'h1ABC;
        adc_read_value_1 = 14'h2DEF;
        adc_read_value_2 = 14'h2321;
        adc_read_value_3 = 14'h0381;

        gain = 4'd1;

        adc_cmd_fifo_data_in = 18'h00000;
        adc_cmd_fifo_empty = 1'b1;

        adc_rsp_fifo_full = 1'b0;

        flash_bus_record = 4'b0000;
    
        rst = 1;
        #(PERIOD*2) rst = 0;

        #1000;

        test_adc_write;
        //test_adc_read;
        //test_2chan_recording;
        //test_4chan_recording;

        #10000;

        $stop(0);
        $finish;
    end
	
endmodule
