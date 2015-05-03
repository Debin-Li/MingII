module adc_slave (
    // System Inputs
    input i_clk, // This clock is the clock sent to the ADC chip
    input i_rst,

    // Inputs
    input [13:0] i_read_value_0,
    input [13:0] i_read_value_1,

    // Outputs
    output [15:0] o_write_value,

    // Chip Signals
    input        i_fpga_chip_select_n,
    input        i_fpga_data,
    output [1:0] o_fpga_data
);

    // Begin module definition

    // Signals for FPGA interface
    reg        fpga_chip_select_n_sync_1, fpga_chip_select_n_sync_2;
    // These next 4 signals have 2 fewer bits because of the 2 FF synchronizer
    reg [30:0] fpga_data_out_0_staged_reg, fpga_data_out_0_staged_next;
    reg [30:0] fpga_data_out_1_staged_reg, fpga_data_out_1_staged_next;
    reg [30:0] fpga_data_out_0_reg, fpga_data_out_0_next;
    reg [30:0] fpga_data_out_1_reg, fpga_data_out_1_next;
    reg        fpga_data_sync_1, fpga_data_sync_2;
    reg [32:0] fpga_data_in_reg, fpga_data_in_next;

    // State machine signals
    localparam STATE_RESET = 0;
    localparam STATE_IDLE = 1;
    localparam STATE_START_XFER = 2;
    localparam STATE_XFER = 3;
    localparam STATE_END_XFER = 4;
    reg [2:0] state_reg, state_next;
    reg [2:0] state_reg_d1, state_reg_d2; // These are used because the inputs are synchronized with a 2 FF synchronizer
    reg [5:0] cycle_counter_reg, cycle_counter_next;

    // Synchronize the input signals from the chip
    always @(posedge i_clk) begin
        if (i_rst) begin
            fpga_chip_select_n_sync_1 <= 1'b1;
            fpga_chip_select_n_sync_2 <= 1'b1;
            fpga_data_sync_1 <= 0;
            fpga_data_sync_2 <= 0;
        end else begin
            fpga_chip_select_n_sync_1 <= i_fpga_chip_select_n;
            fpga_chip_select_n_sync_2 <= fpga_chip_select_n_sync_1;
            fpga_data_sync_1 <= i_fpga_data;
            fpga_data_sync_2 <= fpga_data_sync_1;
        end
    end

    // Registers
    always @(posedge i_clk) begin
        if (i_rst) begin
            state_reg <= STATE_RESET;
            state_reg_d1 <= STATE_RESET;
            state_reg_d2 <= STATE_RESET;
            cycle_counter_reg <= 0;
            fpga_data_out_0_staged_reg <= 0;
            fpga_data_out_1_staged_reg <= 0;
            fpga_data_out_0_reg <= 0;
            fpga_data_out_1_reg <= 0;
            fpga_data_in_reg <= 0;
        end else begin
            state_reg <= state_next;
            state_reg_d1 <= state_reg;
            state_reg_d2 <= state_reg_d1;
            cycle_counter_reg <= cycle_counter_next;
            fpga_data_out_0_staged_reg <= fpga_data_out_0_staged_next;
            fpga_data_out_1_staged_reg <= fpga_data_out_1_staged_next;
            fpga_data_out_0_reg <= fpga_data_out_0_next;
            fpga_data_out_1_reg <= fpga_data_out_1_next;
            fpga_data_in_reg <= fpga_data_in_next;
        end
    end

    // State Machine
    always @(*) begin
        // Default Values
        state_next = state_reg;
        cycle_counter_next = cycle_counter_reg;
        fpga_data_in_next = fpga_data_in_reg;
        fpga_data_out_0_next = fpga_data_out_0_reg;
        fpga_data_out_1_next = fpga_data_out_1_reg;

        case (state_reg)
            STATE_RESET: begin
                // TODO: Do something on reset?
                state_next = STATE_IDLE;
            end

            STATE_IDLE: begin

                if (!fpga_chip_select_n_sync_2) begin
                    fpga_data_out_0_next = {17'h0, i_read_value_0};
                    fpga_data_out_1_next = {17'h0, i_read_value_1};
                    cycle_counter_next = 6'd32;
                    state_next = STATE_XFER;
                end
            end

            STATE_XFER: begin
                fpga_data_in_next = {fpga_data_in_reg[31:0], fpga_data_sync_2};
                fpga_data_out_0_next = {fpga_data_out_0_reg[29:0],1'b0};
                fpga_data_out_1_next = {fpga_data_out_1_reg[29:0],1'b0};
                
                if (cycle_counter_reg == 6'd0) begin
                    state_next = STATE_END_XFER;
                end else begin
                    cycle_counter_next = cycle_counter_reg - 6'd1;
                end
            end

            STATE_END_XFER: begin
                if (fpga_chip_select_n_sync_2) begin
                    state_next = STATE_IDLE;
                end
            end
        endcase
    end

    // Assign outputs
    assign o_write_value = fpga_data_in_reg[32:17];
    assign o_fpga_data[0] = fpga_data_out_0_reg[30];
    assign o_fpga_data[1] = fpga_data_out_1_reg[30];

endmodule

