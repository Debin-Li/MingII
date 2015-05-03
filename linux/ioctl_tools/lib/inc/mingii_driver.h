#ifndef MINGII_DRIVER_H
#define MINGII_DRIVER_H

#include <linux/ioctl.h>

#ifdef GORDON_INCLUDE_US_DEFS

typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;
typedef unsigned long long int u64;

#endif

#define FTL_CHAR_MAJOR_NUM	121

#define FTL_OP_WRITE	       0
#define FTL_OP_READ	       1
#define FTL_OP_ERASE	       2
#define FTL_OP_READID	       3
#define FTL_OP_READPARAM       4
#define FTL_OP_CHIP_RESET      5
#define FTL_OP_SETTIMINGMODE   6
#define FTL_OP_GET_ADC_SAMPLES 7
#define FTL_OP_TWOPLANEREAD    8
#define FTL_OP_TWOPLANEWRITE   9
#define FTL_OP_TWOPLANEERASE   10
#define FTL_OP_CTRL_RESET      11

#define FTL_IOCTL_DO_OPERATION 		   _IOR(FTL_CHAR_MAJOR_NUM, 0, char*)
#define FTL_IOCTL_SET_ACTIVE_TAG	   _IOR(FTL_CHAR_MAJOR_NUM, 1, int)
#define FTL_IOCTL_TAGS			   _IOR(FTL_CHAR_MAJOR_NUM, 2, char*)
#define FTL_IOCTL_GET_CHIP_EXISTS	   _IOR(FTL_CHAR_MAJOR_NUM, 3, char*)
#define FTL_IOCTL_SET_CYCLECOUNT_PARAMS	   _IOR(FTL_CHAR_MAJOR_NUM, 4, char*)
#define FTL_IOCTL_GET_CYCLECOUNT	   _IOR(FTL_CHAR_MAJOR_NUM, 5, char*)
#define FTL_IOCTL_SET_TIMINGS		   _IOR(FTL_CHAR_MAJOR_NUM, 6, char*)
#define FTL_IOCTL_SET_DRAM_TRANSFER_ENABLE _IOR(FTL_CHAR_MAJOR_NUM, 7, int)
#define FTL_IOCTL_RESET_CYCLECOUNT	   _IOR(FTL_CHAR_MAJOR_NUM, 8, char*)
#define FTL_IOCTL_PRINT_REGISTERS	   _IOR(FTL_CHAR_MAJOR_NUM, 9, char*)
#define FTL_IOCTL_SEND_ADC_COMMAND         _IOR(FTL_CHAR_MAJOR_NUM, 10, char*)
#define FTL_IOCTL_SET_ADC_GAIN             _IOR(FTL_CHAR_MAJOR_NUM, 11, char*)
#define FTL_IOCTL_GET_ADC_GAIN             _IOR(FTL_CHAR_MAJOR_NUM, 12, char*)
#define FTL_IOCTL_ENABLE_ADC_RECORDING     _IOR(FTL_CHAR_MAJOR_NUM, 13, char*)
#define FTL_IOCTL_DISABLE_ADC_RECORDING    _IOR(FTL_CHAR_MAJOR_NUM, 14, char*)

struct ftl_char_message {
        u8 bus;
        u8 chip;
        u8 operation;
        u8 chipaddr[5];
	u8 chipaddr2[5];
        u16 length;
        u8 priority;
};

struct ftl_adc_command {
        u8 chip;
        u8 channel;
        u16 message;
        u16 response;
};

#endif
