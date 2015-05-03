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
module adc_master #(
    parameter NUM_OF_BUSES = 4,
    parameter NUM_OF_ADC_CS = 2
) (
    // System Inputs
    input i_clk, // This clock is the clock sent to the ADC chip
    input i_rst,

    // User Logic Signals
    input  [3:0] i_gain,
    
    // Command Interface
    input [17:0] i_adc_cmd_fifo_data,
    input        i_adc_cmd_fifo_empty,
    output reg   o_adc_cmd_fifo_re,

    // Response Interface
    output     [17:0] o_adc_rsp_fifo_data,
    input             i_adc_rsp_fifo_full,
    output            o_adc_rsp_fifo_we,

    // Flash Bus Signals
    output reg                     o_adc_busy,
    input       [NUM_OF_BUSES-1:0] i_flash_bus_record,
    output                  [15:0] o_sample_fifo_0_data,
    output                         o_sample_fifo_0_we,
    output                  [15:0] o_sample_fifo_1_data,
    output                         o_sample_fifo_1_we,
    output                  [15:0] o_sample_fifo_2_data,
    output                         o_sample_fifo_2_we,
    output                  [15:0] o_sample_fifo_3_data,
    output                         o_sample_fifo_3_we,

    // Chip Signals
    output [NUM_OF_ADC_CS-1:0] o_adc_chip_select_n,
    output                     o_adc_chip_data,
    input   [NUM_OF_BUSES-1:0] i_adc_chip_data
);

    // Begin module definition

    // Reset synchronization signals
    reg rst_sync_1, rst_sync_2;

    // Signals for flash bus interface
    reg [NUM_OF_BUSES-1:0] flash_bus_record_sync_1, flash_bus_record_sync_2;
    reg [NUM_OF_BUSES-1:0] sample_fifo_we_reg, sample_fifo_we_next;
	reg [NUM_OF_BUSES-1:0] adc_rsp_fifo_we_reg, adc_rsp_fifo_we_next;
	
    // Signals for ADC chip interface
    reg [NUM_OF_ADC_CS-1:0] adc_chip_select_n_reg, adc_chip_select_n_next;
    reg [15:0] adc_chip_data_out_staged_reg, adc_chip_data_out_staged_next;
    reg [15:0] adc_chip_data_out_reg, adc_chip_data_out_next;
    reg [15:0] adc_chip_data_in_reg[NUM_OF_BUSES-1:0]; // One extra bit because we don't read anything useful on that last cycle

    integer i;

    // State machine signals
    localparam STATE_RESET = 0;
    localparam STATE_IDLE = 1;
    localparam STATE_START_XFER = 2;
    localparam STATE_XFER = 3;
    localparam STATE_END_XFER = 4;
    reg [2:0] state_reg, state_next;
    reg [5:0] cycle_counter_reg, cycle_counter_next;
    reg curr_cmd_cs_reg, curr_cmd_cs_next;
    reg curr_cmd_cs_reg_d1;
    reg curr_cmd_chan_reg, curr_cmd_chan_next;
    reg curr_cmd_chan_reg_d1;
    reg [NUM_OF_BUSES-1:0] recording_reg, recording_next;
    reg [NUM_OF_BUSES-1:0] recording_reg_d1;

    // Synchronize the reset signal
    always @(posedge i_clk) begin
        rst_sync_1 <= i_rst;
        rst_sync_2 <= rst_sync_1;
    end

    // Synchronize the input signals from the flash buses
    always @(posedge i_clk) begin
        if (rst_sync_2) begin
           flash_bus_record_sync_1 <= 0;
            flash_bus_record_sync_2 <= 0;
        end else begin
            flash_bus_record_sync_1 <= i_flash_bus_record;
            flash_bus_record_sync_2 <= flash_bus_record_sync_1;
        end
    end

    // Registers
    always @(posedge i_clk) begin
        if (rst_sync_2) begin
            state_reg <= STATE_RESET;
            cycle_counter_reg <= 0;
            curr_cmd_cs_reg <= 0;
            curr_cmd_cs_reg_d1 <= 0;
            curr_cmd_chan_reg <= 0;
            curr_cmd_chan_reg_d1 <= 0;
            recording_reg <= 0;
            recording_reg_d1 <= 0;
            sample_fifo_we_reg <= 0;
            adc_rsp_fifo_we_reg <= 0;
            adc_chip_select_n_reg <= {NUM_OF_ADC_CS{1'b1}};
            adc_chip_data_out_reg <= 0;
            adc_chip_data_out_staged_reg <= 0;
        end else begin
            state_reg <= state_next;
            cycle_counter_reg <= cycle_counter_next;
            curr_cmd_cs_reg <= curr_cmd_cs_next;
            curr_cmd_cs_reg_d1 <= curr_cmd_cs_reg;
            curr_cmd_chan_reg <= curr_cmd_chan_next;
            curr_cmd_chan_reg_d1 <= curr_cmd_chan_reg;
            recording_reg <= recording_next;
            recording_reg_d1 <= recording_reg;
            sample_fifo_we_reg <= sample_fifo_we_next;
            adc_rsp_fifo_we_reg <= adc_rsp_fifo_we_next;
            adc_chip_select_n_reg <= adc_chip_select_n_next;
            adc_chip_data_out_reg <= adc_chip_data_out_next;
            adc_chip_data_out_staged_reg <= adc_chip_data_out_staged_next;
        end
    end

    // State Machine
    always @(*) begin
        // Default Values
        state_next = state_reg;
        cycle_counter_next = cycle_counter_reg;
        recording_next = recording_reg;
        curr_cmd_cs_next = curr_cmd_cs_reg;
        curr_cmd_chan_next = curr_cmd_chan_reg;
        adc_chip_data_out_staged_next = adc_chip_data_out_staged_reg;

        o_adc_busy = 1'b1;
        o_adc_cmd_fifo_re = 1'b0;

        case (state_reg)
            STATE_RESET: begin
                // TODO: Do something on reset?
                state_next = STATE_IDLE;
            end

            STATE_IDLE: begin
                o_adc_busy = 1'b0;

                if (|flash_bus_record_sync_2) begin
                    adc_chip_data_out_staged_next = {4'b0001, 4'b0000, 1'b0, 3'b001, i_gain};
                    recording_next = flash_bus_record_sync_2;
                    state_next = STATE_START_XFER;
                end else if (!i_adc_cmd_fifo_empty) begin
                    curr_cmd_cs_next = i_adc_cmd_fifo_data[17];
                    curr_cmd_chan_next = i_adc_cmd_fifo_data[16];
                    adc_chip_data_out_staged_next = i_adc_cmd_fifo_data[15:0];
                    o_adc_cmd_fifo_re = 1'b1;
                    state_next = STATE_START_XFER;
                end
            end

            STATE_START_XFER: begin
                state_next = STATE_XFER;
                // We are in STATE_START_XFER for one cycle, and 
                // This will keep us in STATE_XFER for 32 cycles, so
                // a total of 33 cycles, which is what the chip wants
                cycle_counter_next = 6'd31;
            end

            STATE_XFER: begin
                if (cycle_counter_reg == 6'd0) begin
                    state_next = STATE_END_XFER;
                end else begin
                    cycle_counter_next = cycle_counter_reg - 6'd1;
                end
            end

            STATE_END_XFER: begin
                recording_next = {NUM_OF_BUSES{1'b0}};
                if (|flash_bus_record_sync_2) begin
                    adc_chip_data_out_staged_next = {4'b0001, 4'b0000, 1'b0, 3'b001, i_gain};
                    recording_next = flash_bus_record_sync_2;
                    state_next = STATE_START_XFER;
                end else begin
                    state_next = STATE_IDLE;
                end
            end
        endcase
    end

    // ADC Data Output
    always @(*) begin
        // ADC Chip Select Signal
        case (state_reg)
            STATE_START_XFER, STATE_XFER: begin
                // Check to see if you are recording or if you are doing a request
                if (|recording_reg) begin
                    if (|recording_reg[1:0]) begin
                        adc_chip_select_n_next[0] = 1'b0;
                    end else begin
                        adc_chip_select_n_next[0] = 1'b1;
                    end
                    
                    if (|recording_reg[3:2]) begin
                        adc_chip_select_n_next[1] = 1'b0;
                    end else begin
                        adc_chip_select_n_next[1] = 1'b1;
                    end
                end else begin
                    if (curr_cmd_cs_reg) begin
                        adc_chip_select_n_next = 2'b01;
                    end else begin
                        adc_chip_select_n_next = 2'b10;
                    end
                end
            end
			
            default: 
                adc_chip_select_n_next = {NUM_OF_ADC_CS{1'b1}};
        endcase

        // ADC MOSI Signals
        if (state_reg == STATE_START_XFER) begin
            adc_chip_data_out_next = adc_chip_data_out_staged_reg;
        end else if (state_reg == STATE_XFER) begin
            adc_chip_data_out_next = {adc_chip_data_out_reg[14:0],1'b0};
        end else begin
            adc_chip_data_out_next = adc_chip_data_out_reg;
        end
    end
	
	// Negative-edge Triggered Register for data coming from chip
    always @(negedge i_clk) begin
        if (rst_sync_2) begin
            for (i = 0; i < NUM_OF_BUSES; i = i + 1) begin
                adc_chip_data_in_reg[i] <= 0;
            end
        end else begin
            for (i = 0; i < NUM_OF_BUSES; i = i + 1) begin
                if ((state_reg == STATE_XFER) || (state_reg == STATE_END_XFER)) begin
                    adc_chip_data_in_reg[i] <= {adc_chip_data_in_reg[i][14:0], i_adc_chip_data[i]};
                end
            end
        end
    end

    always @(*) begin
        // Write to the Sample FIFO if you are recording that bus
        if (state_reg == STATE_END_XFER) begin
            sample_fifo_we_next = recording_reg;
        end else begin
            sample_fifo_we_next = 0;
        end
    end

    always @(*) begin        
        if ((recording_reg == 0) && (state_reg == STATE_END_XFER)) begin
            adc_rsp_fifo_we_next = 1'b1;
        end else begin
            adc_rsp_fifo_we_next = 1'b0;
        end
    end
    
    // Assign outputs
    assign o_adc_rsp_fifo_data = {2'b00, adc_chip_data_in_reg[{curr_cmd_cs_reg_d1, curr_cmd_chan_reg_d1}]};
    assign o_adc_rsp_fifo_we = adc_rsp_fifo_we_reg;
    assign o_sample_fifo_0_data = {2'b00, adc_chip_data_in_reg[0][13:0]};
    assign o_sample_fifo_0_we = sample_fifo_we_reg[0];
    assign o_sample_fifo_1_data = {2'b00, adc_chip_data_in_reg[1][13:0]};
    assign o_sample_fifo_1_we = sample_fifo_we_reg[1];
    assign o_sample_fifo_2_data = {2'b00, adc_chip_data_in_reg[2][13:0]};
    assign o_sample_fifo_2_we = sample_fifo_we_reg[2];
    assign o_sample_fifo_3_data = {2'b00, adc_chip_data_in_reg[3][13:0]};
    assign o_sample_fifo_3_we = sample_fifo_we_reg[3];
    assign o_adc_chip_select_n = adc_chip_select_n_reg;
    assign o_adc_chip_data = adc_chip_data_out_reg[15];

endmodule

