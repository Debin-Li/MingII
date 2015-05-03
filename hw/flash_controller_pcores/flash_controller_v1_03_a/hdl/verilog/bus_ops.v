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
localparam OP_READSTATUS 			= 0;
localparam OP_JUSTREADSTATUS 			= 1;
localparam OP_RESET 				= 2;
localparam OP_SET_TIMING_MODE			= 3;
localparam OP_STARTREAD 			= 4;
localparam OP_COMPLETEREAD 			= 5;
localparam OP_PROGRAM 				= 6;
localparam OP_ERASE 				= 7;
localparam OP_READID 				= 8;
localparam OP_READPARAM 			= 9;
localparam OP_CHECK_EXISTS      		= 10;
localparam OP_READ_ADC_SAMPLES      		= 11;
