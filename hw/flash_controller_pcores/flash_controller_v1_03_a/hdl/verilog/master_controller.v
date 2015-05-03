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
// master_controller.v

module master_controller #(
	parameter C_MST_AWIDTH				= 32,
	parameter C_MST_DWIDTH				= 32,
	parameter RD_FIFO_DATA_WIDTH		= 136,
	parameter WR_FIFO_DATA_WIDTH		= 128,
	parameter DRAM_RQST_FIFO_DATA_WIDTH = 45,
	parameter RD_FIFO_COUNT_WIDTH		= 11,
	parameter WR_FIFO_COUNT_WIDTH		= 11
)
(
	// PLB Bus Signals
	input Bus2IP_Clk,                     // Bus to IP clock
	input Bus2IP_Reset,                   // Bus to IP reset
	
	// Debug Signals
	// output [5:0] 	o_state,
	// output [31:0]	o_dram_addr,
	// output [11:0]	o_length,
	// output			o_rnw,
	// output [11:0]	o_count,
	// output [RD_FIFO_COUNT_WIDTH-1:0] o_init_rd_count,
	
	// PLB Master Signals
	output reg 							IP2Bus_MstRd_Req,           // IP to Bus master read request
	output reg 							IP2Bus_MstWr_Req,           // IP to Bus master write request
	output reg	[0 : C_MST_AWIDTH-1]	IP2Bus_Mst_Addr,            // IP to Bus master address bus
	output reg	[0 : C_MST_DWIDTH/8-1] 	IP2Bus_Mst_BE,              // IP to Bus master byte enables
	output reg	[0 : 11] 				IP2Bus_Mst_Length,          // IP to Bus master transfer length
	output reg							IP2Bus_Mst_Type,            // IP to Bus master transfer type (0 = single, 1 = burst)
	output 								IP2Bus_Mst_Lock,            // IP to Bus master lock (reserved, assign low)
	output reg							IP2Bus_Mst_Reset,           // IP to Bus master reset
	input 								Bus2IP_Mst_CmdAck,          // Bus to IP master command acknowledgement
	input 								Bus2IP_Mst_Cmplt,           // Bus to IP master transfer completion
	input 								Bus2IP_Mst_Error,           // Bus to IP master error response
	input 								Bus2IP_Mst_Rearbitrate,     // Bus to IP master re-arbitrate
	input 								Bus2IP_Mst_Cmd_Timeout,     // Bus to IP master command timeout
	input		[0 : C_MST_DWIDTH-1] 	Bus2IP_MstRd_d,             // Bus to IP master read data bus
	input		[0 : C_MST_DWIDTH/8-1] 	Bus2IP_MstRd_rem,           // Bus to IP master read remainder
	input 								Bus2IP_MstRd_sof_n,         // Bus to IP master read start of frame
	input 								Bus2IP_MstRd_eof_n,         // Bus to IP master read end of frame
	input 								Bus2IP_MstRd_src_rdy_n,     // Bus to IP master read source ready
	input 								Bus2IP_MstRd_src_dsc_n,     // Bus to IP master read source discontinue
	output reg 							IP2Bus_MstRd_dst_rdy_n,     // IP to Bus master read destination ready
	output								IP2Bus_MstRd_dst_dsc_n,     // IP to Bus master read destination discontinue
	output reg	[0 : C_MST_DWIDTH-1] 	IP2Bus_MstWr_d,             // IP to Bus master write data bus
	output reg	[0 : C_MST_DWIDTH/8-1] 	IP2Bus_MstWr_rem,           // IP to Bus master write remainder
	output reg 							IP2Bus_MstWr_sof_n,         // IP to Bus master write start of frame
	output reg							IP2Bus_MstWr_eof_n,         // IP to Bus master write end of frame
	output reg							IP2Bus_MstWr_src_rdy_n,     // IP to Bus master write source ready
	output								IP2Bus_MstWr_src_dsc_n,     // IP to Bus master write source discontinue
	input 								Bus2IP_MstWr_dst_rdy_n,     // Bus to IP master write destination ready
	input 								Bus2IP_MstWr_dst_dsc_n,		// Bus to IP master write destination discontinue
	
	// Request State Machine Signals
	input [DRAM_RQST_FIFO_DATA_WIDTH-1:0]	i_dram_rqst_fifo_data,
	output reg								o_dram_rqst_fifo_re,
	input									i_dram_rqst_fifo_empty,
	
	// Read FIFO Signals
	input	[RD_FIFO_DATA_WIDTH-1:0]	i_rd_fifo_data,
	output reg							o_rd_fifo_re,
	input								i_rd_fifo_empty,
	input	[RD_FIFO_COUNT_WIDTH-1:0]	i_rd_fifo_count,
	
	// Write FIFO Signals
	output reg	[WR_FIFO_DATA_WIDTH-1:0]	o_wr_fifo_data,
	output reg								o_wr_fifo_we,
	input									i_wr_fifo_full,
	input		[WR_FIFO_COUNT_WIDTH-1:0]	i_wr_fifo_count,
	
	output reg	o_rd_fifo_bus_interposer_start, // This is to tell the Read FIFO Bus Interposer to read the first element in the Read FIFO
	
	output reg	o_rqst_complete // This is to alert the user_logic that a DRAM request was completed, used for interrupt signal
);

	// Begin Module Architecture
	function integer getDRAMAddr;
		input [DRAM_RQST_FIFO_DATA_WIDTH-1:0] data;
	begin
		getDRAMAddr = data[DRAM_RQST_FIFO_DATA_WIDTH-1 -: 32];
	end
	endfunction
	
	function integer getLength;
		input [DRAM_RQST_FIFO_DATA_WIDTH-1:0] data;
	begin
		getLength = data[DRAM_RQST_FIFO_DATA_WIDTH-32-1 -: 12];
	end
	endfunction
	
	// Size parameters
	localparam WR_FIFO_MAX_SIZE = 2**(WR_FIFO_COUNT_WIDTH-1);
	
	// Transfer State Machine Signals
	localparam STATE_XFER_IDLE		= 0;
	localparam STATE_XFER_WAIT		= 1;
	localparam STATE_XFER_READ		= 2;
	localparam STATE_XFER_WRITE		= 3;
	localparam STATE_XFER_FAILURE	= 4;
	reg [2:0] xfer_state_reg, xfer_state_next;
	reg xfer_sm_busy;
	
	// Request State Machine Signals
	localparam STATE_RQST_IDLE		= 0;
	localparam STATE_RQST_WAIT		= 1;
	localparam STATE_RQST_START		= 2;
	localparam STATE_RQST_PENDING	= 3;
	localparam STATE_RQST_RESET		= 4;
	localparam STATE_RQST_FAILURE	= 5;
	reg [2:0] rqst_state_reg, rqst_state_next;
	reg rqst_sm_busy;
	
	// Registers
	reg [11:0]	xfer_count_reg, xfer_count_next;
	reg [31:0]	rqst_addr_reg, rqst_addr_next;
	reg			rqst_rnw_reg, rqst_rnw_next;
	reg [11:0]	rqst_length_reg, rqst_length_next;
	
	//reg [RD_FIFO_COUNT_WIDTH-1:0]	initial_rd_fifo_count_reg, initial_rd_fifo_count_next;
		
	// Registers
	always @(posedge Bus2IP_Clk)
	begin
		if (Bus2IP_Reset) begin
			rqst_state_reg <= STATE_RQST_IDLE;
			rqst_addr_reg <= 0;
			rqst_rnw_reg <= 0;
			rqst_length_reg <= 0;
			xfer_state_reg <= STATE_XFER_IDLE;
			xfer_count_reg <= 0;
			//initial_rd_fifo_count_reg <= 0;
		end else begin
			rqst_state_reg <= rqst_state_next;
			rqst_addr_reg <= rqst_addr_next;
			rqst_rnw_reg <= rqst_rnw_next;
			rqst_length_reg <= rqst_length_next;
			xfer_state_reg <= xfer_state_next;			
			xfer_count_reg <= xfer_count_next;
			//initial_rd_fifo_count_reg <= initial_rd_fifo_count_next;
		end
	end
	
	// Request State Machine
	always @* begin
		// Default Values
		rqst_state_next = rqst_state_reg;
		rqst_rnw_next = rqst_rnw_reg;
		rqst_addr_next = rqst_addr_reg;
		rqst_length_next = rqst_length_reg;
		
		rqst_sm_busy = 1;
		
		o_dram_rqst_fifo_re = 0;
		
		IP2Bus_MstRd_Req = 0;
		IP2Bus_MstWr_Req = 0;
		IP2Bus_Mst_Addr = 0;
		IP2Bus_Mst_BE = {C_MST_DWIDTH/8{1'b1}};
		IP2Bus_Mst_Length = 0;
		IP2Bus_Mst_Type = 0;
		IP2Bus_Mst_Reset = 0;
		
		o_rqst_complete = 0;
		
		case (rqst_state_reg)
			STATE_RQST_IDLE: begin // Wait for a new request
				rqst_sm_busy = 0;
				if (!i_dram_rqst_fifo_empty && !xfer_sm_busy) begin
					// Read the value from the request FIFO
					o_dram_rqst_fifo_re = 1;
				
					// Register the inputs
					rqst_addr_next = getDRAMAddr(i_dram_rqst_fifo_data);
					rqst_length_next = getLength(i_dram_rqst_fifo_data);
					rqst_rnw_next = i_dram_rqst_fifo_data[0];
					
					// Begin the request
					rqst_state_next = STATE_RQST_WAIT;
				end			
			end
			
			STATE_RQST_WAIT: begin // Wait until the Read and Write FIFOs are ready
				// Check to see if you are doing a read request
				if (rqst_rnw_reg) begin
					// Check to see if there is room in the Write FIFO
					if (rqst_length_reg[11:4] <= (WR_FIFO_MAX_SIZE - i_wr_fifo_count)) begin
						// Begin the request
						rqst_state_next = STATE_RQST_START;
					end
				end else begin // You are doing a DRAM write request
					// Check to see if there is enough data in the Read FIFO
					//if (rqst_length_reg[11:4] <= i_rd_fifo_count) begin
						// Begin the request
						rqst_state_next = STATE_RQST_START;
					//end
				end	
			end
			
			STATE_RQST_START: begin // Make the request and wait for command acknowledgement
				IP2Bus_MstRd_Req = rqst_rnw_reg;
				IP2Bus_MstWr_Req = !rqst_rnw_reg;
				IP2Bus_Mst_Type = 1;
				IP2Bus_Mst_Addr = rqst_addr_reg;
				IP2Bus_Mst_Length = rqst_length_reg;
				
				if (Bus2IP_Mst_Error)
					rqst_state_next = STATE_RQST_RESET;
				else if (Bus2IP_Mst_CmdAck)
					rqst_state_next = STATE_RQST_PENDING;
			end
			
			STATE_RQST_PENDING: begin // Wait for completion acknowledgement
				if (Bus2IP_Mst_Error)
					rqst_state_next = STATE_RQST_RESET;
				else if (Bus2IP_Mst_Cmplt) begin
					// Assert request complete for one cycle
					o_rqst_complete = 1;
					
					rqst_state_next = STATE_RQST_IDLE;
				end
			end
			
			STATE_RQST_RESET: begin // Reset the Bus
				IP2Bus_Mst_Reset = 1;
				rqst_state_next = STATE_RQST_FAILURE;
			end
			
			// TODO: May want to get rid of this state in the future because it just stays here and doesn't send any information back
			STATE_RQST_FAILURE: begin
			
			end
		endcase
	
	end
	
	// Transfer State Machine
	always @* begin
		// Default Values
		xfer_state_next = xfer_state_reg;
		xfer_count_next = xfer_count_reg;
		
		xfer_sm_busy = 1;
		
		IP2Bus_MstRd_dst_rdy_n = 1;
		IP2Bus_MstWr_rem = {C_MST_DWIDTH/8{1'b0}}; // This is active low
		IP2Bus_MstWr_sof_n = 1;
		IP2Bus_MstWr_eof_n = 1;
		IP2Bus_MstWr_src_rdy_n = 1;
		
		o_wr_fifo_data = Bus2IP_MstRd_d;
		IP2Bus_MstWr_d = i_rd_fifo_data[RD_FIFO_DATA_WIDTH-8-1:0];
		
		o_rd_fifo_re = 0;
		o_wr_fifo_we = 0;
		
		//initial_rd_fifo_count_next = initial_rd_fifo_count_reg;
		
		o_rd_fifo_bus_interposer_start = 0;
		
		case (xfer_state_reg)
			STATE_XFER_IDLE: begin
				xfer_sm_busy = 0;
				if (!i_dram_rqst_fifo_empty && !rqst_sm_busy) begin
					// Reset the counter
					xfer_count_next = 0;
				
					// Go to wait state
					xfer_state_next = STATE_XFER_WAIT;
				end
			end
			
			STATE_XFER_WAIT: begin // Wait until the Read and Write FIFOs are ready
				// Check to see if you are doing a read request
				if (rqst_rnw_reg) begin
					// Check to see if there is room in the Write FIFO
					if (rqst_length_reg[11:4] <= (WR_FIFO_MAX_SIZE - i_wr_fifo_count)) begin
						// Begin the request
						xfer_state_next = STATE_XFER_READ;
					end
				end else begin // You are doing a DRAM write request
					// Check to see if there is enough data in the Read FIFO
					//if (rqst_length_reg[11:4] <= i_rd_fifo_count) begin
						// Begin the request
						xfer_state_next = STATE_XFER_WRITE;
						
						// Register the Read FIFO Count at the time of moving to the Write State
						//initial_rd_fifo_count_next = i_rd_fifo_count;
						
						// Send a signal to the Read FIFO Bus Interposer to grab the first element in the Read FIFO
						//o_rd_fifo_bus_interposer_start = 1;
					//end
				end	
			end
			
			STATE_XFER_READ: begin
				// Check for any bus errors
				if (Bus2IP_Mst_Error)
					xfer_state_next = STATE_XFER_FAILURE;
				else begin
					// Assert the ready signal
					IP2Bus_MstRd_dst_rdy_n = 0;
					
					// Check to see if the interface is ready to send data
					if (!Bus2IP_MstRd_src_rdy_n) begin
						// Write the data to the FIFO
						o_wr_fifo_we = 1;
						
						// Increment the count
						xfer_count_next = xfer_count_reg + (C_MST_DWIDTH/8);
						
						// Check to see if you are all done
						if (xfer_count_reg == (rqst_length_reg - (C_MST_DWIDTH/8)))
							xfer_state_next = STATE_XFER_IDLE;
						else if (!Bus2IP_MstRd_eof_n) // Check for assertion of eof_n
							xfer_state_next = STATE_XFER_IDLE;
					end
				end
			end
			
			STATE_XFER_WRITE: begin
				// Check for any bus errors
				if (Bus2IP_Mst_Error)
					xfer_state_next = STATE_XFER_FAILURE;
				else begin
					// Assert the ready signal
					IP2Bus_MstWr_src_rdy_n = 0;
					
					// Check for frame signal qualifications
					if (xfer_count_reg == 0)
						IP2Bus_MstWr_sof_n = 0;
					else if (xfer_count_reg == (rqst_length_reg - (C_MST_DWIDTH/8)))
						IP2Bus_MstWr_eof_n = 0;
					
					// Check to see if the interface is ready to receive data
					if (!Bus2IP_MstWr_dst_rdy_n) begin
						// Read the data from the FIFO (we already checked to make sure there was data)
						o_rd_fifo_re = 1;
						
						// Increment the count
						xfer_count_next = xfer_count_reg + (C_MST_DWIDTH/8);
						
						// Check to see if you are all done
						if (xfer_count_reg == (rqst_length_reg - (C_MST_DWIDTH/8)))
							xfer_state_next = STATE_XFER_IDLE;
					end
				end
			end
			
			STATE_XFER_FAILURE: begin
			
			end
			
		endcase
	end
	
	// Assign Output Values
	assign IP2Bus_Mst_Lock = 0; // Datasheet says this signal is reserved and should be tied to zero
	assign IP2Bus_MstRd_dst_dsc_n = 1; // This is currently unsupported in PLB46 Master v1.01a (12-14-2010)
	assign IP2Bus_MstWr_src_dsc_n = 1; // This is currently unsupported in PLB46 Master v1.01a (12-14-2010)
	
	//assign o_state = {rqst_state_reg,xfer_state_reg};
	// assign o_dram_addr = rqst_addr_reg;
	// assign o_length = rqst_length_reg;
	// assign o_rnw = rqst_rnw_reg;
	// assign o_count = xfer_count_reg;
	// assign o_init_rd_count = initial_rd_fifo_count_reg;
	
endmodule
