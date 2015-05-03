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
module flash_bus_dispatch #(
    parameter NUM_OF_BUSES 		= 4,
    parameter NUM_OF_CHIPS_PER_BUS 		= 4,
    parameter CMD_FIFO_DATA_WIDTH 	= 72,
    parameter WR_FIFO_DATA_WIDTH 	= 128,
    parameter RD_FIFO_DATA_WIDTH 	= 136,
    parameter RSLT_FIFO_DATA_WIDTH 	= 26,
    parameter WR_FIFO_COUNT_WIDTH	= 11,
    parameter RD_FIFO_COUNT_WIDTH	= 11
)
(
    // System signals
    input 	i_clk,		// System clock
    input 	i_rst,	// System reset
    
    // Command FIFO Signals
    input	[CMD_FIFO_DATA_WIDTH-1:0]	i_cmd_fifo_data,
    output					o_cmd_fifo_re,
    input	 				i_cmd_fifo_empty,

    // Write FIFO Signals
    input	[WR_FIFO_DATA_WIDTH-1:0]	i_wr_fifo_data,
    output					o_wr_fifo_re,
    input					i_wr_fifo_almost_empty,
    input					i_wr_fifo_empty,
    input	[WR_FIFO_COUNT_WIDTH-1:0]	i_wr_fifo_count,
    
    // Read FIFO Signals
    output	[RD_FIFO_DATA_WIDTH-1:0]	o_rd_fifo_data,
    output					o_rd_fifo_we,
    input					i_rd_fifo_almost_full,
    input					i_rd_fifo_full,
    input	[RD_FIFO_COUNT_WIDTH-1:0]	i_rd_fifo_count,
    
    // Result FIFO Signals
    output	[RSLT_FIFO_DATA_WIDTH-1:0]	o_rslt_fifo_data,
    output					o_rslt_fifo_we,
    input					i_rslt_fifo_full,
    
    // Dispatch signals
    output [NUM_OF_BUSES-1:0]                           o_bus_cmd_req,
    input  [NUM_OF_BUSES-1:0]                           i_bus_cmd_ack,
    output [CMD_FIFO_DATA_WIDTH-1:0]                    o_bus_cmd_data,
    input  [NUM_OF_BUSES-1:0]                           i_bus_rsp_req,
    output [NUM_OF_BUSES-1:0]                           o_bus_rsp_ack,
    output [NUM_OF_BUSES-1:0]                           o_bus_rsp_listening,
    input  [RSLT_FIFO_DATA_WIDTH-1:0]                   i_bus_rsp_data,
    input  [(NUM_OF_BUSES*NUM_OF_CHIPS_PER_BUS)-1:0]    i_bus_chip_active, // This is a one-hot encoding to the dispatch telling it if there is already an active operation for this chip 
    input  [NUM_OF_BUSES-1:0]                           i_bus_wr_buffer_rsvd,
    input  [NUM_OF_BUSES-1:0]                           i_bus_rd_buffer_rsvd,

    // Write Buffer Signals
    output [9:0]	          o_bus_wr_buffer_addr,
    output [127:0]      	  o_bus_wr_buffer_data,
    output reg [NUM_OF_BUSES-1:0] o_bus_wr_buffer_we,
    
    // Read Buffer Signals
    output [9:0]	o_bus_rd_buffer_addr,
    input  [127:0]	i_bus_rd_buffer_data
);

    // Begin Module Architecture
    `include "functions.v"
    
    // Include Host Operations
    `include "host_ops.v"
    
    // Define command address width for functions
    localparam CMD_BUS_ADDR_WIDTH = 46;
    localparam CMD_TAG_WIDTH	  = 8;
    localparam CMD_SIZE_WIDTH 	  = 10;
    localparam CMD_OP_WIDTH 	  = 8;
    localparam RSLT_TAG_WIDTH	  = 8;
    localparam RSLT_SIZE_WIDTH 	  = 10;
    localparam RSLT_ERROR_WIDTH   = 8;
    localparam RD_FIFO_MAX_SIZE = 2**(RD_FIFO_COUNT_WIDTH-1);
    
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
    
    function [1:0] getBusNum;
            input [CMD_BUS_ADDR_WIDTH-1:0] addr;
            getBusNum = addr[CMD_BUS_ADDR_WIDTH-1 : CMD_BUS_ADDR_WIDTH-2];
    endfunction
    
    function [1:0] getChipNum;
            input [CMD_BUS_ADDR_WIDTH-1:0] addr;
            getChipNum = addr[CMD_BUS_ADDR_WIDTH-2-2-1 : CMD_BUS_ADDR_WIDTH-2-2-2];
    endfunction
    
    function [RSLT_TAG_WIDTH-1:0] getTagFromResult;
            input [RSLT_FIFO_DATA_WIDTH-1:0] rslt;
            getTagFromResult = rslt[RSLT_FIFO_DATA_WIDTH-1 : RSLT_FIFO_DATA_WIDTH-RSLT_TAG_WIDTH];
    endfunction
    
    function [RSLT_SIZE_WIDTH-1:0] getSizeFromResult;
            input [RSLT_FIFO_DATA_WIDTH-1:0] rslt;
            getSizeFromResult = rslt[RSLT_FIFO_DATA_WIDTH-RSLT_TAG_WIDTH-1 : RSLT_FIFO_DATA_WIDTH-RSLT_TAG_WIDTH-RSLT_SIZE_WIDTH];
    endfunction
    
    function [RSLT_ERROR_WIDTH-1:0] getErrorFromResult;
            input [RSLT_FIFO_DATA_WIDTH-1:0] rslt;
            getErrorFromResult = rslt[RSLT_ERROR_WIDTH-1 : 0];
    endfunction
    
    // FIFO Registers
    reg cmd_fifo_re_reg, cmd_fifo_re_next;
    reg wr_fifo_re_reg, wr_fifo_re_next;
    reg [127:0] rd_fifo_data_reg, rd_fifo_data_next;
    reg rd_fifo_we_reg, rd_fifo_we_next;
    reg [RSLT_FIFO_DATA_WIDTH-1:0] rslt_fifo_data_reg, rslt_fifo_data_next;
    reg rslt_fifo_we_reg, rslt_fifo_we_next;

    // Command Data = {tag(8),size(10),op(8),addr(46)}
    reg [CMD_TAG_WIDTH-1:0]	    cmd_tag_reg, cmd_tag_next;
    reg [CMD_SIZE_WIDTH-1:0]	    cmd_size_reg, cmd_size_next;
    reg [CMD_OP_WIDTH-1:0]	    cmd_op_reg, cmd_op_next;
    reg [CMD_BUS_ADDR_WIDTH-1:0]    cmd_addr_reg, cmd_addr_next;

    // Result Data = {tag(8), size(10), error(8)}
    reg [RSLT_TAG_WIDTH-1:0]	  rslt_tag_reg, rslt_tag_next;
    reg [RSLT_SIZE_WIDTH-1:0]	  rslt_size_reg, rslt_size_next;
    reg [RSLT_ERROR_WIDTH-1:0]    rslt_error_reg, rslt_error_next;

    reg [NUM_OF_BUSES-1:0] new_cmd_req_reg, new_cmd_req_next;
    reg [CMD_FIFO_DATA_WIDTH-1:0] new_cmd_data_reg, new_cmd_data_next;
    reg [NUM_OF_BUSES-1:0] new_rsp_ack_reg, new_rsp_ack_next;

    reg [9:0] wr_buffer_addr_reg, wr_buffer_addr_next;
    reg [9:0] rd_buffer_addr_reg, rd_buffer_addr_next;

    reg [CMD_SIZE_WIDTH:0] wr_size_reg, wr_size_next;
    reg [RSLT_SIZE_WIDTH:0] rd_size_reg, rd_size_next;
    
    reg [2**CMD_TAG_WIDTH-1:0] tag_rnw_reg;    

    // State Machine Signals
    localparam CMD_STATE_IDLE                 = 0;
    localparam CMD_STATE_WAIT_FOR_CHIP_ACTIVE = 1;
    localparam CMD_STATE_WAIT_FOR_WR_BUFFER   = 2;
    localparam CMD_STATE_WAIT_FOR_RD_BUFFER   = 3;
    localparam CMD_STATE_WRITE_TO_WR_BUFFER_0 = 4;
    localparam CMD_STATE_WRITE_TO_WR_BUFFER_1 = 5;
    localparam CMD_STATE_SEND_REQUEST         = 6;
    reg [2:0] cmd_state_reg, cmd_state_next;
    
    wire [(NUM_OF_BUSES*NUM_OF_CHIPS_PER_BUS)-1:0] new_cmd_chip_decode = (20'h1 << (4*getBusNum(cmd_addr_reg))) << getChipNum(cmd_addr_reg);
    wire [NUM_OF_BUSES-1:0] new_cmd_bus_decode = (4'h1 << getBusNum(cmd_addr_reg));

    // Registers
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            cmd_state_reg <= CMD_STATE_IDLE;
            cmd_fifo_re_reg <= 0;
            wr_fifo_re_reg <= 0;
            cmd_tag_reg <= 0;
            cmd_size_reg <= 0;
            cmd_op_reg <= 0;
            cmd_addr_reg <= 0;
            new_cmd_req_reg <= 0;
            new_cmd_data_reg <= 0;
            wr_size_reg <= 0;
            wr_buffer_addr_reg <= 0;
        end else begin
            cmd_state_reg <= cmd_state_next;
            cmd_fifo_re_reg <= cmd_fifo_re_next;
            wr_fifo_re_reg <= wr_fifo_re_next;
            cmd_tag_reg <= cmd_tag_next;
            cmd_size_reg <= cmd_size_next;
            cmd_op_reg <= cmd_op_next;
            cmd_addr_reg <= cmd_addr_next;
            new_cmd_req_reg <= new_cmd_req_next;
            new_cmd_data_reg <= new_cmd_data_next;
            wr_buffer_addr_reg <= wr_buffer_addr_next;
            wr_size_reg <= wr_size_next;
        end
    end

    // Command State Machine Logic
    always @* begin
        // Default Values
        cmd_state_next = cmd_state_reg;
        cmd_fifo_re_next = 0;
        wr_fifo_re_next = 0;
        cmd_tag_next = cmd_tag_reg;
        cmd_size_next = cmd_size_reg;
        cmd_op_next = cmd_op_reg;
        cmd_addr_next = cmd_addr_reg;
        new_cmd_req_next = new_cmd_req_reg;
        new_cmd_data_next = {cmd_tag_reg, cmd_size_reg, cmd_op_reg, cmd_addr_reg};

        wr_buffer_addr_next = wr_buffer_addr_reg;
        o_bus_wr_buffer_we = 0;
        wr_size_next = wr_size_reg;

        case (cmd_state_reg)
            CMD_STATE_IDLE: begin
                cmd_tag_next = getTagFromCommand(i_cmd_fifo_data);
                cmd_size_next = getSizeFromCommand(i_cmd_fifo_data);
                cmd_op_next = getOpFromCommand(i_cmd_fifo_data);
                cmd_addr_next = getBusAddrFromCommand(i_cmd_fifo_data);

                if (!i_cmd_fifo_empty) begin
                    cmd_fifo_re_next = 1;

                    cmd_state_next = CMD_STATE_WAIT_FOR_CHIP_ACTIVE;
                end
            end
            
            // Depending on the operation, you may need to check for availability for the read and write buffers. However, you definitely need to make sure the chip isn't active
            CMD_STATE_WAIT_FOR_CHIP_ACTIVE: begin
                if ((i_bus_chip_active & new_cmd_chip_decode) == 20'h0) begin
                    cmd_state_next = (cmd_op_reg == HOP_PROGRAM) ? CMD_STATE_WAIT_FOR_WR_BUFFER :
                                     ((cmd_op_reg == HOP_READID) || (cmd_op_reg == HOP_READ) || (cmd_op_reg == HOP_READPARAM) || (cmd_op_reg == HOP_GET_ADC_SAMPLES)) ? CMD_STATE_WAIT_FOR_RD_BUFFER : CMD_STATE_SEND_REQUEST;
                end
            end
            
            CMD_STATE_WAIT_FOR_WR_BUFFER: begin
                wr_size_next = {cmd_size_reg, 1'b0};
                wr_buffer_addr_next = 10'd0;
                
                if (!i_bus_wr_buffer_rsvd[getBusNum(cmd_addr_reg)]) begin
                    cmd_state_next = CMD_STATE_WRITE_TO_WR_BUFFER_0;
                end
            end
            
            CMD_STATE_WAIT_FOR_RD_BUFFER: begin
                if (!i_bus_rd_buffer_rsvd[getBusNum(cmd_addr_reg)]) begin
                    cmd_state_next = CMD_STATE_SEND_REQUEST;
                end
            end

            CMD_STATE_WRITE_TO_WR_BUFFER_0: begin
                if (i_wr_fifo_count >= {{WR_FIFO_COUNT_WIDTH-CMD_SIZE_WIDTH{1'b0}}, wr_size_reg}) begin
                    wr_fifo_re_next = 1;

                    cmd_state_next = CMD_STATE_WRITE_TO_WR_BUFFER_1;
                end
            end

            CMD_STATE_WRITE_TO_WR_BUFFER_1: begin
                wr_size_next = wr_size_reg - 1;
                o_bus_wr_buffer_we = new_cmd_bus_decode;
                wr_buffer_addr_next = wr_buffer_addr_reg + 10'd1;

                if (wr_size_reg == 1) begin
                    cmd_state_next = CMD_STATE_SEND_REQUEST;
                end else begin
                    wr_fifo_re_next = 1;
                end
            end

            CMD_STATE_SEND_REQUEST: begin
                new_cmd_req_next = new_cmd_bus_decode;

                if (i_bus_cmd_ack) begin
                    new_cmd_req_next = 0;

                    cmd_state_next = CMD_STATE_IDLE;
                end
            end
        endcase
    end
    
    // Result State Machine signals
    localparam RSLT_STATE_IDLE                  = 0;
    localparam RSLT_STATE_CHECK_RESPONSE        = 1;
    localparam RSLT_STATE_READ_FROM_RD_BUFFER_0 = 2;
    localparam RSLT_STATE_READ_FROM_RD_BUFFER_1 = 3;
    localparam RSLT_STATE_READ_FROM_RD_BUFFER_2 = 4;
    localparam RSLT_STATE_SEND_RESPONSE         = 5;
    localparam RSLT_STATE_SWITCH_CHIPS          = 6;
    reg [2:0] rslt_state_reg, rslt_state_next;

    reg [NUM_OF_BUSES-1:0] curr_rslt_bus_reg, curr_rslt_bus_next;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            rslt_state_reg <= RSLT_STATE_IDLE;
            curr_rslt_bus_reg <={{NUM_OF_BUSES-1{1'b0}},1'b1};
            rslt_fifo_data_reg <= 0;
            rslt_fifo_we_reg <= 0;
            rd_fifo_data_reg <= 0;
            rd_fifo_we_reg <= 0;
            rslt_tag_reg <= 0;
            rslt_size_reg <= 0;
            rslt_error_reg <= 0;
            new_rsp_ack_reg <= 0;
            rd_size_reg <= 0;
            rd_buffer_addr_reg <= 0;
        end else begin
            rslt_state_reg <= rslt_state_next;
            curr_rslt_bus_reg <= curr_rslt_bus_next;
            rslt_fifo_data_reg <= rslt_fifo_data_next;
            rslt_fifo_we_reg <= rslt_fifo_we_next;
            rd_fifo_data_reg <= rd_fifo_data_next;
            rd_fifo_we_reg <= rd_fifo_we_next;
            rslt_tag_reg <= rslt_tag_next;
            rslt_size_reg <= rslt_size_next;
            rslt_error_reg <= rslt_error_next;
            new_rsp_ack_reg <= new_rsp_ack_next;
            rd_buffer_addr_reg <= rd_buffer_addr_next;
            rd_size_reg <= rd_size_next;
        end
    end

    // Result State Machine Logic
    always @* begin
        // Default Values
        rslt_state_next = rslt_state_reg;
        curr_rslt_bus_next = curr_rslt_bus_reg;
        rslt_fifo_data_next = {rslt_tag_reg, rslt_size_reg, rslt_error_reg};
        rslt_fifo_we_next = 0;
        rd_fifo_data_next = i_bus_rd_buffer_data;
        rd_fifo_we_next = 0;
        rslt_tag_next = rslt_tag_reg;
        rslt_size_next = rslt_size_reg;
        rslt_error_next = rslt_error_reg;
        new_rsp_ack_next = 0;

        rd_buffer_addr_next = rd_buffer_addr_reg;
        rd_size_next = rd_size_reg;

        case (rslt_state_reg)
            RSLT_STATE_IDLE: begin
                rslt_tag_next = getTagFromResult(i_bus_rsp_data);
                rslt_size_next = getSizeFromResult(i_bus_rsp_data);
                rslt_error_next = getErrorFromResult(i_bus_rsp_data);

                if (|(i_bus_rsp_req & curr_rslt_bus_reg)) begin
                    new_rsp_ack_next = curr_rslt_bus_reg;

                    rslt_state_next = RSLT_STATE_CHECK_RESPONSE;
                end else begin
                    curr_rslt_bus_next = {curr_rslt_bus_reg[NUM_OF_BUSES-2:0], curr_rslt_bus_reg[NUM_OF_BUSES-1]};
                end
            end
            
            RSLT_STATE_CHECK_RESPONSE: begin
                if (tag_rnw_reg[rslt_tag_reg]) begin
                    rslt_state_next = RSLT_STATE_READ_FROM_RD_BUFFER_0;
                end else begin
                    rslt_state_next = RSLT_STATE_SEND_RESPONSE;
                end
            end

            RSLT_STATE_READ_FROM_RD_BUFFER_0: begin 
                rd_buffer_addr_next = 0;
                rd_size_next = {rslt_size_reg, 1'b0};

                // Wait for there to be sufficient room in the Read FIFO
                if ({rslt_size_reg, 1'b0} <= (RD_FIFO_MAX_SIZE - i_rd_fifo_count)) begin
                        rslt_state_next = RSLT_STATE_READ_FROM_RD_BUFFER_1;
                end
            end

            RSLT_STATE_READ_FROM_RD_BUFFER_1: begin 
                // Start incrementing the rd_buffer_addr signal early
                rd_buffer_addr_next = rd_buffer_addr_reg + 1;

                if (rd_buffer_addr_reg == 2'd2) begin
                    rslt_state_next = RSLT_STATE_READ_FROM_RD_BUFFER_2;
                end
            end

            RSLT_STATE_READ_FROM_RD_BUFFER_2: begin 
                rd_buffer_addr_next = rd_buffer_addr_reg + 1;
                rd_fifo_we_next = 1;
                rd_size_next = rd_size_reg - 1;

                if (rd_size_reg == 1) begin
                    rslt_state_next = RSLT_STATE_SEND_RESPONSE;
                end
            end

            RSLT_STATE_SEND_RESPONSE: begin        
                if (!i_rslt_fifo_full) begin
                    rslt_fifo_we_next = 1;
                 
                    curr_rslt_bus_next = {curr_rslt_bus_reg[NUM_OF_BUSES-2:0], curr_rslt_bus_reg[NUM_OF_BUSES-1]};
                    
                    rslt_state_next = RSLT_STATE_IDLE;
                end
            end
        endcase
    end
    
    // Track if a tag was for a read or a write
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            tag_rnw_reg <= 0;
        end else begin
            if (cmd_state_reg == CMD_STATE_SEND_REQUEST) begin
                if ((cmd_op_reg == HOP_READ) || (cmd_op_reg == HOP_READID) || (cmd_op_reg == HOP_READPARAM) || (cmd_op_reg == HOP_GET_ADC_SAMPLES)) begin 
                    tag_rnw_reg[cmd_tag_reg] <= 1;
                end else begin
                    tag_rnw_reg[cmd_tag_reg] <= 0;
                end
            end
        end
    end

    // Assign outputs
    assign o_cmd_fifo_re = cmd_fifo_re_reg;
    assign o_wr_fifo_re = wr_fifo_re_reg;
    assign o_rd_fifo_data = {8'h00, rd_fifo_data_reg};
    assign o_rd_fifo_we = rd_fifo_we_reg;
    assign o_rslt_fifo_data = rslt_fifo_data_reg;
    assign o_rslt_fifo_we = rslt_fifo_we_reg;

    assign o_bus_cmd_req = new_cmd_req_reg;
    assign o_bus_cmd_data = new_cmd_data_reg;
    assign o_bus_wr_buffer_addr = wr_buffer_addr_reg;
    assign o_bus_wr_buffer_data = i_wr_fifo_data;
    
    assign o_bus_rsp_ack = new_rsp_ack_reg;
    assign o_bus_rsp_listening = curr_rslt_bus_reg;
    assign o_bus_rd_buffer_addr = rd_buffer_addr_reg;
endmodule
