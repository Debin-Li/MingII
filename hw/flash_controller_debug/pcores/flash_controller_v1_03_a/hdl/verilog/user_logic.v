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
//----------------------------------------------------------------------------
// Filename:          user_logic.vhd
// Version:           1.01.a
// Description:       User logic module.
// Date:              Wed Mar 09 10:11:37 2011 (by Create and Import Peripheral Wizard)
// Verilog Standard:  Verilog-2001
//----------------------------------------------------------------------------

module user_logic # (
	parameter C_SLV_DWIDTH	= 32,
	parameter C_MST_AWIDTH	= 32,
	parameter C_MST_DWIDTH	= 32,
	parameter C_NUM_REG		= 20,
	parameter C_NUM_INTR    = 1,
    parameter C_NUM_BUSES = 4,
    parameter C_NUM_CHIPS_PER_BUS = 4,
	parameter C_PERIOD = 8
)
(
	// PLB Bus Signals
	input 					Bus2IP_Clk,                 // Bus to IP clock
	input 					Bus2IP_Reset,               // Bus to IP reset
	
	// PLB Slave Signals
	input	[0 : C_SLV_DWIDTH-1]		Bus2IP_Data, 				// Bus to IP data bus
	input	[0 : C_SLV_DWIDTH/8-1]		Bus2IP_BE, 					// Bus to IP byte enables
	input	[0 : C_NUM_REG-1]		Bus2IP_RdCE, 				// Bus to IP read chip enable
	input	[0 : C_NUM_REG-1]		Bus2IP_WrCE,				// Bus to IP write chip enable
	output	[0 : C_SLV_DWIDTH-1]		IP2Bus_Data,				// IP to Bus data bus
	output					IP2Bus_RdAck, 				// IP to Bus read transfer acknowledgement
	output					IP2Bus_WrAck, 				// IP to Bus write transfer acknowledgement
	output					IP2Bus_Error, 				// IP to Bus error response
	
	// PLB Master Signals
	output  				IP2Bus_MstRd_Req,           // IP to Bus master read request
	output  				IP2Bus_MstWr_Req,           // IP to Bus master write request
	output 	[0 : C_MST_AWIDTH-1]		IP2Bus_Mst_Addr,            // IP to Bus master address bus
	output 	[0 : C_MST_DWIDTH/8-1] 		IP2Bus_Mst_BE,              // IP to Bus master byte enables
	output 	[0 : 11] 			IP2Bus_Mst_Length,          // IP to Bus master transfer length
	output 					IP2Bus_Mst_Type,            // IP to Bus master transfer type (0 = single, 1 = burst)
	output 					IP2Bus_Mst_Lock,            // IP to Bus master lock (reserved, assign low)
	output 					IP2Bus_Mst_Reset,           // IP to Bus master reset
	input 					Bus2IP_Mst_CmdAck,          // Bus to IP master command acknowledgement
	input 					Bus2IP_Mst_Cmplt,           // Bus to IP master transfer completion
	input 				        Bus2IP_Mst_Error,           // Bus to IP master error response
	input 					Bus2IP_Mst_Rearbitrate,     // Bus to IP master re-arbitrate
	input 				        Bus2IP_Mst_Cmd_Timeout,     // Bus to IP master command timeout
	input	[0 : C_MST_DWIDTH-1] 		Bus2IP_MstRd_d,             // Bus to IP master read data bus
	input	[0 : C_MST_DWIDTH/8-1] 		Bus2IP_MstRd_rem,           // Bus to IP master read remainder
	input 					Bus2IP_MstRd_sof_n,         // Bus to IP master read start of frame
	input 					Bus2IP_MstRd_eof_n,         // Bus to IP master read end of frame
	input 					Bus2IP_MstRd_src_rdy_n,     // Bus to IP master read source ready
	input 					Bus2IP_MstRd_src_dsc_n,     // Bus to IP master read source discontinue
	output  				IP2Bus_MstRd_dst_rdy_n,     // IP to Bus master read destination ready
	output					IP2Bus_MstRd_dst_dsc_n,     // IP to Bus master read destination discontinue
	output 	[0 : C_MST_DWIDTH-1] 		IP2Bus_MstWr_d,             // IP to Bus master write data bus
	output 	[0 : C_MST_DWIDTH/8-1] 		IP2Bus_MstWr_rem,           // IP to Bus master write remainder
	output  				IP2Bus_MstWr_sof_n,         // IP to Bus master write start of frame
	output 					IP2Bus_MstWr_eof_n,         // IP to Bus master write end of frame
	output 					IP2Bus_MstWr_src_rdy_n,     // IP to Bus master write source ready
	output					IP2Bus_MstWr_src_dsc_n,     // IP to Bus master write source discontinue
	input 					Bus2IP_MstWr_dst_rdy_n,     // Bus to IP master write destination ready
	input 					Bus2IP_MstWr_dst_dsc_n,		// Bus to IP master write destination discontinue
	output 	[0 : C_NUM_INTR-1]		IP2Bus_IntrEvent,			// IP to Bus interrupt event
	
	// ADC Clock
        input i_adc_clk,
        
        // Flash Bus Signals
	input 	[7:0] 				i_bus0_data,		// The data coming from the flash bus
	output 	[7:0]	 		        o_bus0_data,		// The data going to the flash chip
	output		 			o_bus0_data_tri_n,	// Tri-state enable for output data
	output 					o_bus0_we_n,		// Write Enable signal, active low
	output 					o_bus0_re_n,		// Read Enable signal, active low
	output [C_NUM_CHIPS_PER_BUS-1:0]	o_bus0_ces_n,		// Chip Enable signal, active low
	output 					o_bus0_cle,		// Command Latch Enable signal
	output 					o_bus0_ale,		// Address Latch Enable signal
	input 	[7:0] 				i_bus1_data,		// The data coming from the flash bus
	output 	[7:0]	 		        o_bus1_data,		// The data going to the flash chip
	output		 			o_bus1_data_tri_n,	// Tri-state enable for output data
	output 					o_bus1_we_n,		// Write Enable signal, active low
	output 					o_bus1_re_n,		// Read Enable signal, active low
	output [C_NUM_CHIPS_PER_BUS-1:0]	o_bus1_ces_n,		// Chip Enable signal, active low
	output 					o_bus1_cle,		// Command Latch Enable signal
	output 					o_bus1_ale,		// Address Latch Enable signal
	input 	[7:0] 				i_bus2_data,		// The data coming from the flash bus
	output 	[7:0]	 		        o_bus2_data,		// The data going to the flash chip
	output		 			o_bus2_data_tri_n,	// Tri-state enable for output data
	output 					o_bus2_we_n,		// Write Enable signal, active low
	output 					o_bus2_re_n,		// Read Enable signal, active low
	output [C_NUM_CHIPS_PER_BUS-1:0]	o_bus2_ces_n,		// Chip Enable signal, active low
	output 					o_bus2_cle,		// Command Latch Enable signal
	output 					o_bus2_ale,		// Address Latch Enable signal
	input 	[7:0] 				i_bus3_data,		// The data coming from the flash bus
	output 	[7:0]	 		        o_bus3_data,		// The data going to the flash chip
	output		 			o_bus3_data_tri_n,	// Tri-state enable for output data
	output 					o_bus3_we_n,		// Write Enable signal, active low
	output 					o_bus3_re_n,		// Read Enable signal, active low
	output [C_NUM_CHIPS_PER_BUS-1:0]	o_bus3_ces_n,		// Chip Enable signal, active low
	output 					o_bus3_cle,		// Command Latch Enable signal
	output 					o_bus3_ale,		// Address Latch Enable signal
        
        output [1:0] o_adc_chip_select_n,
        output       o_adc_data,
        input  [3:0] i_adc_data,

        output o_bus0_active,
        output o_bus1_active,
        output o_bus2_active,
        output o_bus3_active
);

	// Begin Module Architecture
	
	`include "functions.v"
	
	localparam NUM_OF_BUSES = C_NUM_BUSES;
	localparam NUM_OF_CHIPS_PER_BUS = C_NUM_CHIPS_PER_BUS;
	localparam NUM_OF_CHIPS = (NUM_OF_CHIPS_PER_BUS * NUM_OF_BUSES);
    localparam CTRL_VERSION = 4'd4;

	// Flash Controller Parameters
	localparam CMD_FIFO_DATA_WIDTH 		= 72;
	localparam WR_FIFO_DATA_WIDTH 		= 128;
	localparam RD_FIFO_DATA_WIDTH 		= 136;
	localparam RSLT_FIFO_DATA_WIDTH 	= 26;
	localparam ERROR_CODE_WIDTH		= 8;
	localparam RD_FIFO_COUNT_WIDTH	 	= 11;
	localparam WR_FIFO_COUNT_WIDTH	 	= 11;
	localparam PERIOD 			= C_PERIOD;

        localparam TAG_WIDTH = 6;
    
	// Nets for user logic slave model s/w accessible register example
	reg 	[0 : C_SLV_DWIDTH-1] 	slv_0_reg, slv_0_next; // Command 0 Register (BASE_ADDR+0)
	reg 	[0 : C_SLV_DWIDTH-1] 	slv_1_reg, slv_1_next; // Command 1 Register (BASE_ADDR+4)
	reg 	[0 : C_SLV_DWIDTH-1] 	slv_2_reg, slv_2_next; // Command 2 Register (BASE_ADDR+8)
	reg 	[0 : C_SLV_DWIDTH-1] 	slv_3_reg, slv_3_next; // Command 3 Register (BASE_ADDR+12)
	reg				slv_4_reg, slv_4_next; // Issue Command (BASE_ADDR+16)
	reg				slv_5_reg, slv_5_next; // Reset Register (BASE_ADDR+20)
	reg 	[0 : C_SLV_DWIDTH-1] 	slv_6_reg, slv_6_next; // Tag Status Register 0-31 (BASE_ADDR+24)
	reg 	[0 : C_SLV_DWIDTH-1] 	slv_7_reg, slv_7_next; // Tag Status Register 32-64 (BASE_ADDR+28)
	reg 	[0 : C_SLV_DWIDTH-1] 	slv_8_reg, slv_8_next; // Controller Status Register (BASE_ADDR+32)
	reg 	[0 : C_SLV_DWIDTH-1] 	slv_9_reg, slv_9_next; // Cycle Count Parameters (BASE_ADDR+36)
	reg 	[0 : C_SLV_DWIDTH-1] 	slv_10_reg, slv_10_next; // Cycle Count Reset (BASE_ADDR+40)
	reg 	[0 : C_SLV_DWIDTH-1] 	slv_11_reg, slv_11_next; // Cycle Count Value Bus 0 (BASE_ADDR+44)
	reg 	[0 : C_SLV_DWIDTH-1] 	slv_12_reg, slv_12_next; // Cycle Count Value Bus 1 (BASE_ADDR+48) 
	reg 	[0 : C_SLV_DWIDTH-1] 	slv_13_reg, slv_13_next; // Cycle Count Value Bus 2 (BASE_ADDR+52) 
	reg 	[0 : C_SLV_DWIDTH-1] 	slv_14_reg, slv_14_next; // Cycle Count Value Bus 3 (BASE_ADDR+56) 
	reg 	[0 : C_SLV_DWIDTH-1] 	slv_15_reg, slv_15_next;
	wire	[0 : 15]                slv_reg_write_sel;
	wire	[0 : 15]		slv_reg_read_sel;
	reg		[0 : C_SLV_DWIDTH-1]	slv_ip2bus_data;
	wire				slv_read_ack;
	wire				slv_write_ack;
	integer				byte_index, bit_index;

	// Command FIFO Signals
	wire [CMD_FIFO_DATA_WIDTH-1:0]	cmd_fifo_data_in;
	wire [CMD_FIFO_DATA_WIDTH-1:0]	cmd_fifo_data_out;
	wire 				cmd_fifo_re;
	wire 				cmd_fifo_we;
	wire 				cmd_fifo_empty;
	wire 				cmd_fifo_full;

	// Write FIFO Signals
	wire [WR_FIFO_DATA_WIDTH-1:0]	wr_fifo_data_in;
	wire [WR_FIFO_DATA_WIDTH-1:0]	wr_fifo_data_out;
	wire 				wr_fifo_re;
	wire 				wr_fifo_we;
	wire 				wr_fifo_almost_empty;
	wire 				wr_fifo_empty;
	wire 				wr_fifo_almost_full;
	wire 				wr_fifo_full;
	wire [WR_FIFO_COUNT_WIDTH-1:0]	wr_fifo_count;

	// Read FIFO Signals
	wire [RD_FIFO_DATA_WIDTH-1:0] 	rd_fifo_data_in;
	wire [RD_FIFO_DATA_WIDTH-1:0] 	rd_fifo_data_out;
	wire 				rd_fifo_re;
	wire 				rd_fifo_we;
	wire 				rd_fifo_almost_empty;
	wire 				rd_fifo_empty;
	wire 				rd_fifo_almost_full;
	wire 				rd_fifo_full;
	wire [RD_FIFO_COUNT_WIDTH-1:0]	rd_fifo_count;

	// Result FIFO Signals
	wire [RSLT_FIFO_DATA_WIDTH-1:0] rslt_fifo_data_in;
	wire [RSLT_FIFO_DATA_WIDTH-1:0] rslt_fifo_data_out;
	wire 				rslt_fifo_re;
	wire 				rslt_fifo_we;
	wire 				rslt_fifo_empty;
	wire 				rslt_fifo_full;

	// Write FIFO Bus Interposer Signals
	wire [63:0] wr_fifo_bus_interposer_data_in;
	wire		wr_fifo_bus_interposer_we;
	wire		wr_fifo_bus_interposer_full;
	
	// Read FIFO Bus Interposer Signals
	wire [63:0] rd_fifo_bus_interposer_data_out;
	wire		rd_fifo_bus_interposer_re;
	wire		rd_fifo_bus_interposer_empty;
	wire		rd_fifo_bus_interposer_start;
	
	// Performance Counter Signals
	wire	[0:31]	cyclecount_sum[NUM_OF_BUSES-1:0];
	wire		cyclecount_reset[NUM_OF_BUSES-1:0];
	wire	[0:7]	cyclecount_start[NUM_OF_BUSES-1:0];
	wire	[0:7]	cyclecount_end[NUM_OF_BUSES-1:0];

        assign cyclecount_reset[3] = slv_11_reg[28];
        assign cyclecount_start[3] = slv_10_reg[0:7];
        assign cyclecount_end[3] = slv_10_reg[8:15];
        assign cyclecount_reset[2] = slv_11_reg[29];
        assign cyclecount_start[2] = slv_10_reg[16:23];
        assign cyclecount_end[2] = slv_10_reg[24:31];
        assign cyclecount_reset[1] = slv_11_reg[30];
        assign cyclecount_start[1] = slv_9_reg[0:7];
        assign cyclecount_end[1] = slv_9_reg[8:15];
        assign cyclecount_reset[0] = slv_11_reg[31];
        assign cyclecount_start[0] = slv_9_reg[16:23];
        assign cyclecount_end[0] = slv_9_reg[24:31];

	// DRAM Request FIFO Signals
	localparam DRAM_RQST_FIFO_DATA_WIDTH = 45;
	wire [DRAM_RQST_FIFO_DATA_WIDTH-1:0]	dram_rqst_fifo_data_in;
	wire [DRAM_RQST_FIFO_DATA_WIDTH-1:0]	dram_rqst_fifo_data_out;
	wire					dram_rqst_fifo_re;
	wire					dram_rqst_fifo_we;
	wire					dram_rqst_fifo_empty;
	wire					dram_rqst_fifo_full;
	wire					dram_rqst_complete;
	
	// Request State Machine Signals
	reg [2**TAG_WIDTH-1:0] tag_status_reg;
        wire new_rqst = slv_4_reg;
        wire clr_rqst;
	wire new_rslt;
	wire [TAG_WIDTH-1:0] new_rslt_tag;
	
        // Dispatch signals
        wire [3:0] d2c_cmd_req;
        wire [3:0] c2d_cmd_ack;
        wire [CMD_FIFO_DATA_WIDTH-1:0] d2c_cmd_data;
        wire [3:0] c2d_rsp_req;
        wire [3:0] d2c_rsp_ack;
        wire [3:0] d2c_rsp_listening;
        wire [RSLT_FIFO_DATA_WIDTH-1:0] c2d_rsp_data;
        wire [NUM_OF_BUSES*NUM_OF_CHIPS_PER_BUS-1:0] chip_active; 
        wire [3:0] wr_buffer_rsvd;
        wire [3:0] rd_buffer_rsvd;
        wire [9:0] wr_buffer_addr;
        wire [127:0] wr_buffer_data;
        wire [3:0] wr_buffer_we;
        wire [9:0] rd_buffer_addr;
        wire [127:0] rd_buffer_data;
	
        // Flash Bus Signals
        wire [NUM_OF_BUSES-1:0] bus_active;
        wire [NUM_OF_CHIPS-1:0] chip_exists;

        assign o_bus0_active = bus_active[0];
        assign o_bus1_active = bus_active[1];
        assign o_bus2_active = bus_active[2];
        assign o_bus3_active = bus_active[3];

        // ADC Command FIFO Signals
        wire [17:0] adc_cmd_fifo_data_out;
        wire        adc_cmd_fifo_empty;
        wire        adc_cmd_fifo_re;
        reg         adc_cmd_fifo_we_reg, adc_cmd_fifo_we_next;

        // ADC Response FIFO Signals
        wire [17:0] adc_rsp_fifo_data_in;
        wire [17:0] adc_rsp_fifo_data_out;
        wire        adc_rsp_fifo_full;
        wire        adc_rsp_fifo_almost_full;
        wire        adc_rsp_fifo_empty;
        wire        adc_rsp_fifo_almost_empty;
        wire        adc_rsp_fifo_we;
        reg         adc_rsp_fifo_re;

        // Other ADC Signals
        wire      [2:0] adc_state;
		wire     [17:0] adc_last_cmd;
        wire            adc_busy;
        wire      [3:0] flash_bus_record;
        wire     [13:0] sample_fifo_data_in[3:0];
        wire            sample_fifo_we[3:0];

        // Debug Signals
	wire [7:0] controller_state;
	wire [3:0] rqst_sm_state;
	wire [2:0] sm_rqsts;
	wire [2:0] sm_rslts;
	wire [5:0] master_state;
	wire [31:0] master_dram_addr;
	wire [11:0] master_length;
	wire		master_rnw;
	wire [11:0] master_count;
	wire [RD_FIFO_COUNT_WIDTH-1:0] init_rd_fifo_count;
    
    wire [25:0] last_rsp;
  
	// Master Module
	master_controller #(
		.C_MST_AWIDTH(C_MST_AWIDTH),
		.C_MST_DWIDTH(C_MST_DWIDTH),
		.RD_FIFO_DATA_WIDTH(RD_FIFO_DATA_WIDTH),
		.DRAM_RQST_FIFO_DATA_WIDTH(DRAM_RQST_FIFO_DATA_WIDTH),
		.RD_FIFO_COUNT_WIDTH(RD_FIFO_COUNT_WIDTH),
		.WR_FIFO_COUNT_WIDTH(WR_FIFO_COUNT_WIDTH)
	) master_logic (
		// PLB Bus Signals
		.Bus2IP_Clk(Bus2IP_Clk),
		.Bus2IP_Reset(Bus2IP_Reset),
		
		// Debug Signals
		//.o_state(master_state),
		// .o_dram_addr(master_dram_addr),
		// .o_length(master_length),
		// .o_rnw(master_rnw),
		// .o_count(master_count),
		// .o_init_rd_count(init_rd_fifo_count),
		
		// PLB Master Signals
		.IP2Bus_MstRd_Req(IP2Bus_MstRd_Req),
		.IP2Bus_MstWr_Req(IP2Bus_MstWr_Req),
		.IP2Bus_Mst_Addr(IP2Bus_Mst_Addr),
		.IP2Bus_Mst_BE(IP2Bus_Mst_BE),
		.IP2Bus_Mst_Length(IP2Bus_Mst_Length),
		.IP2Bus_Mst_Type(IP2Bus_Mst_Type),
		.IP2Bus_Mst_Lock(IP2Bus_Mst_Lock),
		.IP2Bus_Mst_Reset(IP2Bus_Mst_Reset),
		.Bus2IP_Mst_CmdAck(Bus2IP_Mst_CmdAck),
		.Bus2IP_Mst_Cmplt(Bus2IP_Mst_Cmplt),
		.Bus2IP_Mst_Error(Bus2IP_Mst_Error),
		.Bus2IP_Mst_Rearbitrate(Bus2IP_Mst_Rearbitrate),
		.Bus2IP_Mst_Cmd_Timeout(Bus2IP_Mst_Cmd_Timeout),
		.Bus2IP_MstRd_d(Bus2IP_MstRd_d),
		.Bus2IP_MstRd_rem(Bus2IP_MstRd_rem),
		.Bus2IP_MstRd_sof_n(Bus2IP_MstRd_sof_n),
		.Bus2IP_MstRd_eof_n(Bus2IP_MstRd_eof_n),
		.Bus2IP_MstRd_src_rdy_n(Bus2IP_MstRd_src_rdy_n),
		.Bus2IP_MstRd_src_dsc_n(Bus2IP_MstRd_src_dsc_n),
		.IP2Bus_MstRd_dst_rdy_n(IP2Bus_MstRd_dst_rdy_n),
		.IP2Bus_MstRd_dst_dsc_n(IP2Bus_MstRd_dst_dsc_n),
		.IP2Bus_MstWr_d(IP2Bus_MstWr_d),
		.IP2Bus_MstWr_rem(IP2Bus_MstWr_rem),
		.IP2Bus_MstWr_sof_n(IP2Bus_MstWr_sof_n),
		.IP2Bus_MstWr_eof_n(IP2Bus_MstWr_eof_n),
		.IP2Bus_MstWr_src_rdy_n(IP2Bus_MstWr_src_rdy_n),
		.IP2Bus_MstWr_src_dsc_n(IP2Bus_MstWr_src_dsc_n),
		.Bus2IP_MstWr_dst_rdy_n(Bus2IP_MstWr_dst_rdy_n),
		.Bus2IP_MstWr_dst_dsc_n(Bus2IP_MstWr_dst_dsc_n),
		
		// DRAM Request FIFO Signals
		.i_dram_rqst_fifo_data(dram_rqst_fifo_data_out),
		.o_dram_rqst_fifo_re(dram_rqst_fifo_re),
		.i_dram_rqst_fifo_empty(dram_rqst_fifo_empty),
		
		// Read FIFO Signals
		.i_rd_fifo_data(rd_fifo_bus_interposer_data_out),
		.o_rd_fifo_re(rd_fifo_bus_interposer_re),
		.i_rd_fifo_empty(rd_fifo_bus_interposer_empty),
		.i_rd_fifo_count(rd_fifo_count),
		
		// Write FIFO Signals
		.o_wr_fifo_data(wr_fifo_bus_interposer_data_in),
		.o_wr_fifo_we(wr_fifo_bus_interposer_we),
		.i_wr_fifo_full(wr_fifo_bus_interposer_full),
		.i_wr_fifo_count(wr_fifo_count),
		
		.o_rd_fifo_bus_interposer_start(rd_fifo_bus_interposer_start),
		
		.o_rqst_complete(dram_rqst_complete)
	);
	
	// Write FIFO Bus Interposer
	wr_fifo_bus_interposer #(
		.WR_FIFO_DATA_WIDTH(WR_FIFO_DATA_WIDTH)
	) wrFIFOInterposer (
		// System Signals
		.i_clk(Bus2IP_Clk),
		.i_rst(Bus2IP_Reset),
		
		// Write FIFO Signals
		.o_wr_fifo_data(wr_fifo_data_in),
		.o_wr_fifo_we(wr_fifo_we),
		.i_wr_fifo_full(wr_fifo_full),
		
		// Bus Master Signals
		.i_bus_master_data(wr_fifo_bus_interposer_data_in),
		.i_bus_master_we(wr_fifo_bus_interposer_we),
		.o_bus_master_full(wr_fifo_bus_interposer_full)
	);
	
	// Read FIFO Bus Interposer
	rd_fifo_bus_interposer #(
		.RD_FIFO_DATA_WIDTH(RD_FIFO_DATA_WIDTH),
		.ERROR_CODE_WIDTH(ERROR_CODE_WIDTH)
	) rdFIFOInterposer (
		// System Signals
		.i_clk(Bus2IP_Clk),
		.i_rst(Bus2IP_Reset),
		
		// Read FIFO Signals
		.i_rd_fifo_data(rd_fifo_data_out),
		.o_rd_fifo_re(rd_fifo_re),
		.i_rd_fifo_empty(rd_fifo_empty),
		
		// Bus Master Signals
		.o_bus_master_data(rd_fifo_bus_interposer_data_out),
		.i_bus_master_re(rd_fifo_bus_interposer_re),
		.o_bus_master_empty(rd_fifo_bus_interposer_empty),
		
		.i_start(rd_fifo_bus_interposer_start)
	);
	
	// DRAM Request FIFO
	dram_rqst_fifo dramRqstFifo (
		.clk(Bus2IP_Clk),
		.srst(Bus2IP_Reset),
		.din(dram_rqst_fifo_data_in),
		.wr_en(dram_rqst_fifo_we),
		.rd_en(dram_rqst_fifo_re),
		.dout(dram_rqst_fifo_data_out),
		.full(dram_rqst_fifo_full),
		.empty(dram_rqst_fifo_empty)
	);
	
	// Request State Machine
	request_sm #(
		.DRAM_RQST_FIFO_DATA_WIDTH(DRAM_RQST_FIFO_DATA_WIDTH),
		.CMD_FIFO_DATA_WIDTH(CMD_FIFO_DATA_WIDTH),
		.CMD_TAG_WIDTH(TAG_WIDTH),
                .RSLT_FIFO_DATA_WIDTH(RSLT_FIFO_DATA_WIDTH),
                .COMPLETE_CMD_WIDTH(C_SLV_DWIDTH*3+TAG_WIDTH)   
	) requestSM	(
		// System Signals
		.i_clk(Bus2IP_Clk),
		.i_rst(Bus2IP_Reset),
		
		// Debug Signals
		.o_state(rqst_sm_state),
		.o_completed_rqsts(sm_rqsts),
		.o_completed_rslts(sm_rslts),
		
		// Slave Register Signals
		.i_slave_cmd({slv_0_reg,slv_1_reg,slv_2_reg,slv_3_reg[0:TAG_WIDTH-1]}),
		.i_slave_new_rqst(new_rqst),
		.o_slave_clr_rqst(clr_rqst),
		
		// DRAM Request FIFO Signals
		.o_dram_rqst_fifo_data(dram_rqst_fifo_data_in),
		.o_dram_rqst_fifo_we(dram_rqst_fifo_we),
		.i_dram_rqst_fifo_full(dram_rqst_fifo_full),
		
		// Command FIFO Signals
		.o_cmd_fifo_data(cmd_fifo_data_in),
		.o_cmd_fifo_we(cmd_fifo_we),
		.i_cmd_fifo_full(cmd_fifo_full),
		
		// Result FIFO Signals
		.i_rslt_fifo_data(rslt_fifo_data_out),
		.o_rslt_fifo_re(rslt_fifo_re),
		.i_rslt_fifo_empty(rslt_fifo_empty),
		
		.o_new_rslt(new_rslt),
                .o_new_rslt_tag(new_rslt_tag)
	);
	
	// Flash Bus Interface
	flash_bus_interface #(
		.CMD_FIFO_DATA_WIDTH(CMD_FIFO_DATA_WIDTH),
		.WR_FIFO_DATA_WIDTH(WR_FIFO_DATA_WIDTH),
		.RD_FIFO_DATA_WIDTH(RD_FIFO_DATA_WIDTH),
		.RSLT_FIFO_DATA_WIDTH(RSLT_FIFO_DATA_WIDTH),
		.RD_FIFO_COUNT_WIDTH(RD_FIFO_COUNT_WIDTH),
		.WR_FIFO_COUNT_WIDTH(WR_FIFO_COUNT_WIDTH)
	) interface (
		// System signals
		.i_clk(Bus2IP_Clk),
		.i_rst(Bus2IP_Reset),
		
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
		.WR_FIFO_COUNT_WIDTH(WR_FIFO_COUNT_WIDTH),
		.RD_FIFO_COUNT_WIDTH(RD_FIFO_COUNT_WIDTH)
	 ) flash_bus_dispatch_inst (
		// System signals
		.i_clk(Bus2IP_Clk),
		.i_rst(Bus2IP_Reset),
		
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

	// Flash Bus Controller
	flash_bus #(
		.NUM_OF_CHIPS(NUM_OF_CHIPS_PER_BUS),
		.CMD_FIFO_DATA_WIDTH(CMD_FIFO_DATA_WIDTH),
		.WR_FIFO_DATA_WIDTH(WR_FIFO_DATA_WIDTH),
		.RD_FIFO_DATA_WIDTH(RD_FIFO_DATA_WIDTH),
		.RSLT_FIFO_DATA_WIDTH(RSLT_FIFO_DATA_WIDTH),
		.PERIOD(PERIOD)
	 ) flash_bus0_inst (
		// System signals
		.i_clk(Bus2IP_Clk),
		.i_rst(Bus2IP_Reset),
                .i_adc_clk(i_adc_clk),

                .o_top_bus_active(bus_active[0]),
                .i_recording_en(slv_8_reg[31]),

                // Dispatch signals
                .i_disp_cmd_req(d2c_cmd_req[0]),
                .o_disp_cmd_ack(c2d_cmd_ack[0]),
                .i_disp_cmd_data(d2c_cmd_data),
                .o_disp_rsp_req(c2d_rsp_req[0]),
                .i_disp_rsp_ack(d2c_rsp_ack[0]),
                .i_disp_rsp_listening(d2c_rsp_listening[0]),
                .o_disp_rsp_data(c2d_rsp_data),
                .o_disp_chip_active(chip_active[3:0]), 
                .o_disp_wr_buffer_rsvd(wr_buffer_rsvd[0]),
                .o_disp_rd_buffer_rsvd(rd_buffer_rsvd[0]),

                // ADC Sample FIFO Signals
                .i_adc_sample_fifo_data(sample_fifo_data_in[0]),
                .o_adc_sample_fifo_almost_full(),
                .o_adc_sample_fifo_full(),
                .i_adc_sample_fifo_we(sample_fifo_we[0]),
	
                // Write Buffer Signals
                .i_disp_wr_buffer_addr(wr_buffer_addr),
                .i_disp_wr_buffer_data(wr_buffer_data),
                .i_disp_wr_buffer_we(wr_buffer_we[0]),
                
                // Read Buffer Signals
                .i_disp_rd_buffer_addr(rd_buffer_addr),
                .o_disp_rd_buffer_data(rd_buffer_data),
		
                // State machine to top level signals
		.o_cyclecount_sum(cyclecount_sum[0]),
		.i_cyclecount_reset(cyclecount_reset[0]),
		.i_cyclecount_start(cyclecount_start[0]),
		.i_cyclecount_end(cyclecount_end[0]),
		
                // ADC Master Signals
                .o_adc_master_record(flash_bus_record[0]),

		// Flash bus signals
		.i_bus_data(i_bus0_data),
		.o_bus_data(o_bus0_data),
		.o_bus_data_tri_n(o_bus0_data_tri_n),
		.o_bus_we_n(o_bus0_we_n),
		.o_bus_re_n(o_bus0_re_n),
		.o_bus_ces_n(o_bus0_ces_n),
		.o_bus_cle(o_bus0_cle),
		.o_bus_ale(o_bus0_ale),
		
		// Debug Signals
		//.o_controller_state(controller_state),
			
		// Top Level Signals
		.o_chip_exists(chip_exists[(1+0)*NUM_OF_CHIPS_PER_BUS-1:0*NUM_OF_CHIPS_PER_BUS])
	);

	flash_bus #(
		.NUM_OF_CHIPS(NUM_OF_CHIPS_PER_BUS),
		.CMD_FIFO_DATA_WIDTH(CMD_FIFO_DATA_WIDTH),
		.WR_FIFO_DATA_WIDTH(WR_FIFO_DATA_WIDTH),
		.RD_FIFO_DATA_WIDTH(RD_FIFO_DATA_WIDTH),
		.RSLT_FIFO_DATA_WIDTH(RSLT_FIFO_DATA_WIDTH),
		.PERIOD(PERIOD)
	 ) flash_bus1_inst (
		// System signals
		.i_clk(Bus2IP_Clk),
		.i_rst(Bus2IP_Reset),
                .i_adc_clk(i_adc_clk),
		
                .o_top_bus_active(bus_active[1]),
                .i_recording_en(slv_8_reg[30]),
                
                // Dispatch signals
                .i_disp_cmd_req(d2c_cmd_req[1]),
                .o_disp_cmd_ack(c2d_cmd_ack[1]),
                .i_disp_cmd_data(d2c_cmd_data),
                .o_disp_rsp_req(c2d_rsp_req[1]),
                .i_disp_rsp_ack(d2c_rsp_ack[1]),
                .i_disp_rsp_listening(d2c_rsp_listening[1]),
                .o_disp_rsp_data(c2d_rsp_data),
                .o_disp_chip_active(chip_active[7:4]), 
                .o_disp_wr_buffer_rsvd(wr_buffer_rsvd[1]),
                .o_disp_rd_buffer_rsvd(rd_buffer_rsvd[1]),

                // ADC Sample FIFO Signals
                .i_adc_sample_fifo_data(sample_fifo_data_in[1]),
                .o_adc_sample_fifo_almost_full(),
                .o_adc_sample_fifo_full(),
                .i_adc_sample_fifo_we(sample_fifo_we[1]),
	
                // Write Buffer Signals
                .i_disp_wr_buffer_addr(wr_buffer_addr),
                .i_disp_wr_buffer_data(wr_buffer_data),
                .i_disp_wr_buffer_we(wr_buffer_we[1]),
                
                // Read Buffer Signals
                .i_disp_rd_buffer_addr(rd_buffer_addr),
                .o_disp_rd_buffer_data(rd_buffer_data),
		
                // State machine to top level signals
		.o_cyclecount_sum(cyclecount_sum[1]),
		.i_cyclecount_reset(cyclecount_reset[1]),
		.i_cyclecount_start(cyclecount_start[1]),
		.i_cyclecount_end(cyclecount_end[1]),
		
                // ADC Master Signals
                .o_adc_master_record(flash_bus_record[1]),

		// Flash bus signals
		.i_bus_data(i_bus1_data),
		.o_bus_data(o_bus1_data),
		.o_bus_data_tri_n(o_bus1_data_tri_n),
		.o_bus_we_n(o_bus1_we_n),
		.o_bus_re_n(o_bus1_re_n),
		.o_bus_ces_n(o_bus1_ces_n),
		.o_bus_cle(o_bus1_cle),
		.o_bus_ale(o_bus1_ale),
		
		// Debug Signals
		//.o_controller_state(controller_state),
			
		// Top Level Signals
		.o_chip_exists(chip_exists[(1+1)*NUM_OF_CHIPS_PER_BUS-1:1*NUM_OF_CHIPS_PER_BUS])
	);

	flash_bus #(
		.NUM_OF_CHIPS(NUM_OF_CHIPS_PER_BUS),
		.CMD_FIFO_DATA_WIDTH(CMD_FIFO_DATA_WIDTH),
		.WR_FIFO_DATA_WIDTH(WR_FIFO_DATA_WIDTH),
		.RD_FIFO_DATA_WIDTH(RD_FIFO_DATA_WIDTH),
		.RSLT_FIFO_DATA_WIDTH(RSLT_FIFO_DATA_WIDTH),
		.PERIOD(PERIOD)
	 ) flash_bus2_inst (
		// System signals
		.i_clk(Bus2IP_Clk),
		.i_rst(Bus2IP_Reset),
                .i_adc_clk(i_adc_clk),
		
                .o_top_bus_active(bus_active[2]),
                .i_recording_en(slv_8_reg[29]),

                // Dispatch signals
                .i_disp_cmd_req(d2c_cmd_req[2]),
                .o_disp_cmd_ack(c2d_cmd_ack[2]),
                .i_disp_cmd_data(d2c_cmd_data),
                .o_disp_rsp_req(c2d_rsp_req[2]),
                .i_disp_rsp_ack(d2c_rsp_ack[2]),
                .i_disp_rsp_listening(d2c_rsp_listening[2]),
                .o_disp_rsp_data(c2d_rsp_data),
                .o_disp_chip_active(chip_active[11:8]), 
                .o_disp_wr_buffer_rsvd(wr_buffer_rsvd[2]),
                .o_disp_rd_buffer_rsvd(rd_buffer_rsvd[2]),

                // ADC Sample FIFO Signals
                .i_adc_sample_fifo_data(sample_fifo_data_in[2]),
                .o_adc_sample_fifo_almost_full(),
                .o_adc_sample_fifo_full(),
                .i_adc_sample_fifo_we(sample_fifo_we[2]),
	
                // Write Buffer Signals
                .i_disp_wr_buffer_addr(wr_buffer_addr),
                .i_disp_wr_buffer_data(wr_buffer_data),
                .i_disp_wr_buffer_we(wr_buffer_we[2]),
                
                // Read Buffer Signals
                .i_disp_rd_buffer_addr(rd_buffer_addr),
                .o_disp_rd_buffer_data(rd_buffer_data),
		
                // State machine to top level signals
		.o_cyclecount_sum(cyclecount_sum[2]),
		.i_cyclecount_reset(cyclecount_reset[2]),
		.i_cyclecount_start(cyclecount_start[2]),
		.i_cyclecount_end(cyclecount_end[2]),
		
                // ADC Master Signals
                .o_adc_master_record(flash_bus_record[2]),

		// Flash bus signals
		.i_bus_data(i_bus2_data),
		.o_bus_data(o_bus2_data),
		.o_bus_data_tri_n(o_bus2_data_tri_n),
		.o_bus_we_n(o_bus2_we_n),
		.o_bus_re_n(o_bus2_re_n),
		.o_bus_ces_n(o_bus2_ces_n),
		.o_bus_cle(o_bus2_cle),
		.o_bus_ale(o_bus2_ale),
		
		// Debug Signals
		//.o_controller_state(controller_state),
			
		// Top Level Signals
		.o_chip_exists(chip_exists[(1+2)*NUM_OF_CHIPS_PER_BUS-1:2*NUM_OF_CHIPS_PER_BUS])
	);

	flash_bus #(
		.NUM_OF_CHIPS(NUM_OF_CHIPS_PER_BUS),
		.CMD_FIFO_DATA_WIDTH(CMD_FIFO_DATA_WIDTH),
		.WR_FIFO_DATA_WIDTH(WR_FIFO_DATA_WIDTH),
		.RD_FIFO_DATA_WIDTH(RD_FIFO_DATA_WIDTH),
		.RSLT_FIFO_DATA_WIDTH(RSLT_FIFO_DATA_WIDTH),
		.PERIOD(PERIOD)
	 ) flash_bus3_inst (
		// System signals
		.i_clk(Bus2IP_Clk),
		.i_rst(Bus2IP_Reset),
                .i_adc_clk(i_adc_clk),
		
                .o_top_bus_active(bus_active[3]),
                .i_recording_en(slv_8_reg[28]),

                // Dispatch signals
                .i_disp_cmd_req(d2c_cmd_req[3]),
                .o_disp_cmd_ack(c2d_cmd_ack[3]),
                .i_disp_cmd_data(d2c_cmd_data),
                .o_disp_rsp_req(c2d_rsp_req[3]),
                .i_disp_rsp_ack(d2c_rsp_ack[3]),
                .i_disp_rsp_listening(d2c_rsp_listening[3]),
                .o_disp_rsp_data(c2d_rsp_data),
                .o_disp_chip_active(chip_active[15:12]), 
                .o_disp_wr_buffer_rsvd(wr_buffer_rsvd[3]),
                .o_disp_rd_buffer_rsvd(rd_buffer_rsvd[3]),

                // ADC Sample FIFO Signals
                .i_adc_sample_fifo_data(sample_fifo_data_in[3]),
                .o_adc_sample_fifo_almost_full(),
                .o_adc_sample_fifo_full(),
                .i_adc_sample_fifo_we(sample_fifo_we[3]),
	
                // Write Buffer Signals
                .i_disp_wr_buffer_addr(wr_buffer_addr),
                .i_disp_wr_buffer_data(wr_buffer_data),
                .i_disp_wr_buffer_we(wr_buffer_we[3]),
                
                // Read Buffer Signals
                .i_disp_rd_buffer_addr(rd_buffer_addr),
                .o_disp_rd_buffer_data(rd_buffer_data),
		
                // State machine to top level signals
		.o_cyclecount_sum(cyclecount_sum[3]),
		.i_cyclecount_reset(cyclecount_reset[3]),
		.i_cyclecount_start(cyclecount_start[3]),
		.i_cyclecount_end(cyclecount_end[3]),
		
                // ADC Master Signals
                .o_adc_master_record(flash_bus_record[3]),

		// Flash bus signals
		.i_bus_data(i_bus3_data),
		.o_bus_data(o_bus3_data),
		.o_bus_data_tri_n(o_bus3_data_tri_n),
		.o_bus_we_n(o_bus3_we_n),
		.o_bus_re_n(o_bus3_re_n),
		.o_bus_ces_n(o_bus3_ces_n),
		.o_bus_cle(o_bus3_cle),
		.o_bus_ale(o_bus3_ale),
		
		// Debug Signals
		//.o_controller_state(controller_state),
			
		// Top Level Signals
		.o_chip_exists(chip_exists[(1+3)*NUM_OF_CHIPS_PER_BUS-1:3*NUM_OF_CHIPS_PER_BUS])
	);

        // ADC Command FIFO
        adc_comm_fifo adc_cmd_fifo_inst(
            .rst(Bus2IP_Reset),
            .wr_clk(Bus2IP_Clk),
            .rd_clk(i_adc_clk),
            .din(slv_6_reg[14:31]),
            .wr_en(adc_cmd_fifo_we_reg),
            .rd_en(adc_cmd_fifo_re),
            .dout(adc_cmd_fifo_data_out),
            .full(adc_cmd_fifo_full),
            .almost_full(adc_cmd_fifo_almost_full),
            .empty(adc_cmd_fifo_empty),
            .almost_empty(adc_cmd_fifo_almost_empty)
        );

        // ADC Response FIFO
        adc_comm_fifo adc_rsp_fifo_inst(
            .rst(Bus2IP_Reset),
            .wr_clk(i_adc_clk),
            .rd_clk(Bus2IP_Clk),
            .din(adc_rsp_fifo_data_in),
            .wr_en(adc_rsp_fifo_we),
            .rd_en(adc_rsp_fifo_re),
            .dout(adc_rsp_fifo_data_out),
            .full(adc_rsp_fifo_full),
            .almost_full(adc_rsp_fifo_almost_full),
            .empty(adc_rsp_fifo_empty),
            .almost_empty(adc_rsp_fifo_almost_empty)
        );

        wire [7:0] adc_sample_count;
        
        // ADC Master Instantiation
        adc_master master_inst(
            // System Inputs
            .i_clk(i_adc_clk), // This clock is the clock sent to the ADC chip
            .i_rst(Bus2IP_Reset),

            // User Logic Signals
            .i_gain(slv_8_reg[24:27]),

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
            .o_sample_fifo_0_data(sample_fifo_data_in[0]),
            .o_sample_fifo_0_we(sample_fifo_we[0]),
            .o_sample_fifo_1_data(sample_fifo_data_in[1]),
            .o_sample_fifo_1_we(sample_fifo_we[1]),
            .o_sample_fifo_2_data(sample_fifo_data_in[2]),
            .o_sample_fifo_2_we(sample_fifo_we[2]),
            .o_sample_fifo_3_data(sample_fifo_data_in[3]),
            .o_sample_fifo_3_we(sample_fifo_we[3]),

            // Chip Signals
            .o_adc_chip_select_n(o_adc_chip_select_n),
            .o_adc_chip_data(o_adc_data),
            .i_adc_chip_data(i_adc_data)
        );

  assign
    slv_reg_write_sel = Bus2IP_WrCE[0:15],
    slv_reg_read_sel  = Bus2IP_RdCE[0:15],
    slv_write_ack     = Bus2IP_WrCE[0] || Bus2IP_WrCE[1] || Bus2IP_WrCE[2] || Bus2IP_WrCE[3] || Bus2IP_WrCE[4] || Bus2IP_WrCE[5] || Bus2IP_WrCE[6] || Bus2IP_WrCE[7] || Bus2IP_WrCE[8] || Bus2IP_WrCE[9] || Bus2IP_WrCE[10] || Bus2IP_WrCE[11] || Bus2IP_WrCE[12] || Bus2IP_WrCE[13] || Bus2IP_WrCE[14] || Bus2IP_WrCE[15],
    slv_read_ack      = Bus2IP_RdCE[0] || Bus2IP_RdCE[1] || Bus2IP_RdCE[2] || Bus2IP_RdCE[3] || Bus2IP_RdCE[4] || Bus2IP_RdCE[5] || Bus2IP_RdCE[6] || Bus2IP_RdCE[7] || Bus2IP_RdCE[8] || Bus2IP_RdCE[9] || Bus2IP_RdCE[10] || Bus2IP_RdCE[11] || Bus2IP_RdCE[12] || Bus2IP_RdCE[13] || Bus2IP_RdCE[14] || Bus2IP_RdCE[15];
	
        // Tag Status Registers
	integer tag_num;
        always @(posedge Bus2IP_Clk) begin
            if (Bus2IP_Reset) begin
                tag_status_reg <= 0;
            end else begin
                for (tag_num = 0; tag_num < 2**TAG_WIDTH; tag_num = tag_num + 1) begin
                    if (clr_rqst && (tag_num == slv_3_reg[0:TAG_WIDTH-1])) begin
                        tag_status_reg[tag_num] <= 1'b1;
                    end else if (new_rslt && (tag_num == new_rslt_tag)) begin
                        tag_status_reg[tag_num] <= 1'b0;
                    end
                end
            end
        end

        // Count ADC Commands (Debug)
	reg [3:0] new_adc_commands_reg;
	reg [3:0] new_adc_responses_reg;
        always @(posedge Bus2IP_Clk) begin
            if (Bus2IP_Reset) begin
                new_adc_commands_reg <= 0;
				new_adc_responses_reg <= 0;
            end else begin
                if (adc_cmd_fifo_we_reg) begin
                    new_adc_commands_reg <= new_adc_commands_reg + 1;
                end
				
				if (adc_rsp_fifo_we) begin
                    new_adc_responses_reg <= new_adc_responses_reg + 1;
                end
            end
        end

	// Registers
	always @(posedge Bus2IP_Clk)
	begin
		if (Bus2IP_Reset) begin
			slv_0_reg <= 0;
			slv_1_reg <= 0;
			slv_2_reg <= 0;
			slv_3_reg <= 0;
			slv_4_reg <= 0;
			slv_5_reg <= 0;
			slv_6_reg <= 0;
                        adc_cmd_fifo_we_reg <= 0;
			slv_7_reg <= 0;
			slv_8_reg <= 0;
			slv_9_reg <= 0;
			slv_10_reg <= 0;
			slv_11_reg <= 0;
			slv_12_reg <= 0;
			slv_13_reg <= 0;
			slv_14_reg <= 0;
			slv_15_reg <= 0;
        end else begin
			slv_0_reg <= slv_0_next;
			slv_1_reg <= slv_1_next;
			slv_2_reg <= slv_2_next;
			slv_3_reg <= slv_3_next;
			slv_4_reg <= slv_4_next;
			slv_5_reg <= slv_5_next;
			slv_6_reg <= slv_6_next;
                        adc_cmd_fifo_we_reg <= adc_cmd_fifo_we_next;
			slv_7_reg <= slv_7_next;
			slv_8_reg <= slv_8_next;
			slv_9_reg <= slv_9_next;
			slv_10_reg <= slv_10_next;
                        slv_11_reg <= slv_11_next;
                        slv_12_reg <= slv_12_next;
                        slv_13_reg <= slv_13_next;
                        slv_14_reg <= slv_14_next;
			slv_15_reg <= slv_15_next;
		end
	end
	
	// Slave Write Logic
	always @* begin
		// Default Values
		slv_0_next = slv_0_reg;
		slv_1_next = slv_1_reg;
		slv_2_next = slv_2_reg;
		slv_3_next = slv_3_reg;
		slv_4_next = (clr_rqst) ? 0 : slv_4_reg; // Command Pending
		slv_5_next = 0;
		slv_6_next = slv_6_reg;
                adc_cmd_fifo_we_next = 1'b0;
                slv_7_next = slv_7_reg;
		slv_8_next = slv_8_reg;
		slv_9_next = slv_9_reg;
		slv_10_next = slv_10_reg;
		slv_11_next = 0; // Cycle Count Reset (one-shot)
		slv_12_next = slv_12_reg;
		slv_13_next = slv_13_reg;
		slv_14_next = slv_14_reg;
		slv_15_next = slv_15_reg;
		
		case ( slv_reg_write_sel )
			16'b1000000000000000 : // Command 0 Register (BASE_ADDRESS+0)
				for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
					if ( Bus2IP_BE[byte_index] == 1 )
						for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
							slv_0_next[bit_index] = Bus2IP_Data[bit_index];
							
			16'b0100000000000000 : // Command 1 Register (BASE_ADDRESS+4)
				for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
					if ( Bus2IP_BE[byte_index] == 1 )
						for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
							slv_1_next[bit_index] = Bus2IP_Data[bit_index];
				  
			16'b0010000000000000 : // Command 2 Register (BASE_ADDRESS+8)
				for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
					if ( Bus2IP_BE[byte_index] == 1 )
						for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
							slv_2_next[bit_index] = Bus2IP_Data[bit_index];
				  
			16'b0001000000000000 : // Command 3 Register (BASE_ADDRESS+12)
				for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
					if ( Bus2IP_BE[byte_index] == 1 )
						for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
							slv_3_next[bit_index] = Bus2IP_Data[bit_index];
			
                        16'b0000100000000000 : // Issue Command (BASE_ADDRESS+16)
				slv_4_next = 1;
				  
			16'b0000010000000000 : // Unused 
				slv_5_next = 0;
			
			16'b0000001000000000 : begin // ADC 0 Command
                                adc_cmd_fifo_we_next = 1'b1;
				
                                for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
					if ( Bus2IP_BE[byte_index] == 1 )
						for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
							slv_6_next[bit_index] = Bus2IP_Data[bit_index];
                        end
				
			16'b0000000100000000 : begin // Unused
                        end

			16'b0000000010000000 : begin // ADC Gain and Recording Enabled Signals
				for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
					if ( Bus2IP_BE[byte_index] == 1 )
						for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
							slv_8_next[bit_index] = Bus2IP_Data[bit_index];
			end
				  
			16'b0000000001000000 : // Cycle Count Parameters Buses 0-1 (BASE_ADDRESS+36)
				for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
					if ( Bus2IP_BE[byte_index] == 1 )
						for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
							slv_9_next[bit_index] = Bus2IP_Data[bit_index];
				  
			16'b0000000000100000 : // Cycle Count Parameters Buses 2-3 (BASE_ADDRESS+40)
				for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
					if ( Bus2IP_BE[byte_index] == 1 )
						for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
							slv_10_next[bit_index] = Bus2IP_Data[bit_index];
				  
			16'b0000000000010000 : begin // Cycle Count Reset (BASE_ADDRESS+44)
				for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
					if ( Bus2IP_BE[byte_index] == 1 )
						for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
							slv_11_next[bit_index] = Bus2IP_Data[bit_index];
			end
			
                        16'b0000000000001000 : begin // Unused (BASE_ADDRESS+48) 
		        end

                        16'b0000000000000100 : begin // Unused (BASE_ADDRESS+52) 
			end
                        
                        16'b0000000000000010 : begin // Unused (BASE_ADDRESS+56) 
			end
			
                        16'b0000000000000001 : begin // Unused (BASE_ADDRESS+60)
			end 
		endcase
	end
	
	// Slave Read Logic

        // Dumb wires to fix Xilinx warning
        wire [31:0] cyclecount_sum_0 = cyclecount_sum[0];
        wire [31:0] cyclecount_sum_1 = cyclecount_sum[1];
        wire [31:0] cyclecount_sum_2 = cyclecount_sum[2];
        wire [31:0] cyclecount_sum_3 = cyclecount_sum[3];

	always @*
	begin
            // Default Values
            adc_rsp_fifo_re = 1'b0;

            case ( slv_reg_read_sel )
                16'b1000000000000000 : slv_ip2bus_data = slv_0_reg;
                16'b0100000000000000 : slv_ip2bus_data = slv_1_reg;
                16'b0010000000000000 : slv_ip2bus_data = slv_2_reg;
                16'b0001000000000000 : slv_ip2bus_data = slv_3_reg;
                16'b0000100000000000 : begin
                    slv_ip2bus_data = {14'h0, adc_rsp_fifo_data_out};
                    adc_rsp_fifo_re = 1'b1;
                end
                16'b0000010000000000 : slv_ip2bus_data = {CTRL_VERSION, bus_active, chip_exists, {32-4-4-NUM_OF_CHIPS{1'b0}}};
                16'b0000001000000000 : slv_ip2bus_data = tag_status_reg[31:0];
                16'b0000000100000000 : slv_ip2bus_data = tag_status_reg[63:32];
                16'b0000000010000000 : slv_ip2bus_data = slv_8_reg;
                16'b0000000001000000 : slv_ip2bus_data = slv_9_reg;  // Cycle Count Parameters Buses 0-1
                16'b0000000000100000 : slv_ip2bus_data = slv_10_reg; // Cycle Count Parameters Buses 2-3
                16'b0000000000010000 : slv_ip2bus_data = cyclecount_sum_0;
                16'b0000000000001000 : slv_ip2bus_data = cyclecount_sum_1;
                16'b0000000000000100 : slv_ip2bus_data = cyclecount_sum_2;
                16'b0000000000000010 : slv_ip2bus_data = cyclecount_sum_3;
                16'b0000000000000001 : slv_ip2bus_data = 32'h0;
                //16'b0000000000000001 : slv_ip2bus_data = {12'h0, 2'h0, master_state, 1'h0, dram_rqst_fifo_empty, rd_fifo_empty, wr_fifo_empty, 1'b0, sm_rqsts, 1'b0, sm_rslts};
                //16'b0000000000000001 : slv_ip2bus_data = {20'h0, 1'b0, adc_state, adc_rsp_fifo_full, adc_rsp_fifo_empty, adc_cmd_fifo_full, adc_cmd_fifo_empty, new_adc_commands_reg};
                //16'b0000000000000001 : slv_ip2bus_data = {6'h0, last_rsp};
                default : begin
                    slv_ip2bus_data = 0;
                end
            endcase
        end


	// Assign Outputs
	assign IP2Bus_Data    	= slv_ip2bus_data;
	assign IP2Bus_WrAck   	= slv_write_ack;
	assign IP2Bus_RdAck   	= slv_read_ack;
	assign IP2Bus_Error   	= 0;
	assign IP2Bus_IntrEvent = new_rslt;

endmodule
