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
// Chip manufacturer codes
localparam NAND_MFR_TOSHIBA  =      8'h98;
localparam NAND_MFR_TOSHIBA2 = 		8'h94;
localparam NAND_MFR_TOSHIBA3 =      8'h84;
localparam NAND_MFR_SAMSUNG  =      8'hec;
localparam NAND_MFR_FUJITSU  =      8'h04;
localparam NAND_MFR_NATIONAL =      8'h8f;
localparam NAND_MFR_RENESAS  =      8'h07;
localparam NAND_MFR_STMICRO  =      8'h20;
localparam NAND_MFR_HYNIX    =      8'had;
localparam NAND_MFR_MICRON   =      8'h2c;

// NAND Flash Delays
// TODO: Need a parameter for tCS and tCH (CE#)
localparam	DELAY_tADL				= ceil_division(70,PERIOD);	// Address to Data
localparam 	DELAY_tALS 				= ceil_division(10,PERIOD);	// ALE setup time
localparam	DELAY_tALH				= ceil_division(5,PERIOD);	// ALE hold time
localparam 	DELAY_tCLS 				= ceil_division(10,PERIOD);	// CLE setup time
localparam	DELAY_tCLH				= ceil_division(5,PERIOD);	// CLE hold time
localparam	DELAY_tCLR				= ceil_division(10,PERIOD);	// tCLR
localparam	DELAY_tWW				= ceil_division(10,PERIOD);	// TODO: Can't find anywhere
localparam	DELAY_tRR				= ceil_division(20,PERIOD);	// >20ns
localparam	DELAY_tWHR				= ceil_division(60,PERIOD);	// >80ns
localparam	DELAY_tRHW				= ceil_division(100,PERIOD);	// >100ns
localparam	DELAY_tWB				= ceil_division(100,PERIOD);	// <100ns
localparam	DELAY_tWH				= ceil_division(10,PERIOD);	// WE# pulse width high
localparam	DELAY_tWP				= ceil_division(16,PERIOD);	// WE# pulse width low // TODO (TB): Changing this
localparam	DELAY_tWC				= ceil_division(44,PERIOD);	// >25ns // TODO (TB): Made this longer
localparam	DELAY_tRP				= ceil_division(16,PERIOD);	// >12ns // TODO (TB): Changing this
localparam	DELAY_tREH				= ceil_division(10,PERIOD);	// >10ns
localparam	DELAY_tRC				= ceil_division(44,PERIOD);	// >35ns // TODO (TB): Making this larger
localparam	DELAY_CMD_WELOW			= 30;	// 
localparam	DELAY_CMD_WEHIGH		= 30;	//
localparam	DELAY_ADDR_WELOW		= 30;	//
localparam	DELAY_ADDR_WEHIGH		= 30;	//
localparam	DELAY_CMD_CLELOW		= 20;	//
localparam	DELAY_ADDR_ALELOW		= 20;	//
localparam	DELAY_tDBSY				= 200; 	// aakel - This seems wrong....but its from the datasheet
localparam	DELAY_tADL_minus_tWC	= DELAY_tADL-DELAY_tWH-DELAY_tWP;	// Address to Data

// NAND Flash Commands
localparam	CMD_READID						= 8'h90;
localparam	CMD_RESET						= 8'hFF;
localparam	CMD_BLOCKERASE0					= 8'h60;
localparam	CMD_BLOCKERASE1					= 8'hD0;
localparam	CMD_WRITEPAGE0					= 8'h80;
localparam	CMD_WRITEPAGE1					= 8'h10;
localparam  CMD_PROGRAM_PAGE_CACHE_SEQ		= 8'h15;
localparam 	CMD_PROGRAM_PAGE_CACHE_0		= 8'h80;
localparam 	CMD_PROGRAM_PAGE_CACHE_1		= 8'h15;
localparam	CMD_READ_MODE					= 8'h00;
localparam	CMD_READPAGE0					= 8'h00;
localparam	CMD_READPAGE1					= 8'h30;
localparam 	CMD_READ_PAGE_CACHE_SEQUENTIAL	= 8'h31;
localparam 	CMD_READ_PAGE_CACHE_RANDOM_0	= 8'h00;
localparam 	CMD_READ_PAGE_CACHE_RANDOM_1	= 8'h31;
localparam 	CMD_READ_PAGE_CACHE_LAST		= 8'h3F;
localparam 	CMD_READ_PARAMPAGE				= 8'hEC;
localparam 	CMD_TWOPLANEBLOCKERASE0			= 8'h60;
localparam	CMD_TWOPLANEBLOCKERASE1 		= 8'h60;
localparam 	CMD_TWOPLANEBLOCKERASE2 		= 8'hD0;
localparam 	CMD_TWOPLANEWRITEPAGE0			= 8'h80;
localparam 	CMD_TWOPLANEWRITEPAGE1			= 8'h11;
localparam	CMD_TWOPLANEWRITEPAGE2			= 8'h80;
localparam	CMD_TWOPLANEWRITEPAGE3			= 8'h10;
localparam	CMD_TWOPLANEREADPAGE0			= 8'h00;
localparam	CMD_TWOPLANEREADPAGE1			= 8'h00;
localparam	CMD_TWOPLANEREADPAGE2			= 8'h30;
localparam	CMD_TWOPLANEREADPAGE3			= 8'h06;
localparam	CMD_TWOPLANEREADPAGE4			= 8'hE0;
localparam 	CMD_STATUS						= 8'h70;
localparam 	CMD_STATUS_ENHANCED				= 8'h78;
localparam 	CMD_SETFEATURES					= 8'hEF;

localparam	CMD_READPAGE_TOSH0				= 8'h00;
localparam 	CMD_READPAGE_TOSH1				= 8'h01;
