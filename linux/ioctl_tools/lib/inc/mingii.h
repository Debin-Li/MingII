
#ifndef MINGII_H
#define MINGII_H

//Performance Counter Start and End Point Options
#define PC_REQUEST_SUBMIT                        0 //start only
#define PC_READ_COMMAND_PENDING_TO_COMMAND_ONBUS 1 // Send the read command and wait for the chip to move the data from the array to the registers
#define PC_READ_DATA_PENDING_TO_DATA_ONBUS       2 // Read the data from the chip
#define PC_READ_DATA_ONBUS_TO_TRANSFER_PENDING   3 // Finished reading the data off the chip
#define PC_WRITE_DATA_PENDING_TO_DATA_ONBUS      4 // Send the write command and the data
#define PC_WRITE_REQUEST_COMPLETE                5 // Finished writing the data to the chip
#define PC_WRITE_ARRAY_WRITE_FINISHED            6 // The chip finished writing the data back to the array
#define PC_ERASE_PENDING_TO_ONBUS                7 // Send the erase command
#define PC_ERASE_REQUEST_COMPLETE                8 // Wait for the chip to finish erasing
#define PC_ERASE_FINISHED                        9 //end only

// THESE ARE ALL OF THE OLD PC VALUES, BUT THEY WONT WORK ANYMORE
//#define FTL_PC_REQUEST_SUBMIT  				0  
//#define FTL_PC_READ_COMMAND_PENDING_TO_COMMAND_ONBUS	1
//#define	FTL_PC_READ_COMMAND_ONBUS_TO_COMMAND_DONE	2
//#define FTL_PC_READ_COMMAND_DONE_TO_BUFFER_WAIT		3
//#define FTL_PC_READ_BUFFER_WAIT_TO_DATA_PENDING		4
//#define FTL_PC_READ_DATA_PENDING_TO_DATA_ONBUS		5
//#define FTL_PC_READ_DATA_ONBUS_TO_TRANSFER_PENDING	6
//#define FTL_PC_READ_TRANSFER_PENDING_TO_TRANSFER_ACTIVE	7
//#define FTL_PC_READ_REQUEST_COMPLETE			8
//#define FTL_PC_WRITE_BUFFER_WAIT_TO_TRANSFER_PENDING	9
//#define FTL_PC_WRITE_TRANSFER_PENDING_TO_TRANSFER_ACTIVE 10
//#define FTL_PC_WRITE_TRANSFER_ACTIVE_TO_DATA_PENDING	11
//#define FTL_PC_WRITE_DATA_PENDING_TO_DATA_ONBUS		12
//#define FTL_PC_WRITE_DATA_ONBUS_TO_WAIT_OP 		13
//#define FTL_PC_WRITE_REQUEST_COMPLETE			14
//#define FTL_PC_ERASE_PENDING_TO_ONBUS			15
//#define FTL_PC_ERASE_ONBUS_TO_WAIT_OP			16
//#define FTL_PC_ERASE_REQUEST_COMPLETE			17
//
//#define FTL_PC_TWOPLANE_READ_COMMAND_PENDING_TO_COMMAND_ONBUS		18
//#define FTL_PC_TWOPLANE_READ_COMMAND_ONBUS_TO_COMMAND_DONE			19
//#define FTL_PC_TWOPLANE_READ_COMMAND_DONE_TO_BUFFER_WAIT			20
//#define FTL_PC_TWOPLANE_READ_BUFFER_WAIT_TO_DATA_PENDING			21
//#define FTL_PC_TWOPLANE_READ_DATA_PENDING_TO_DATA_ONBUS				22
//#define FTL_PC_TWOPLANE_READ_DATA_ONBUS_TO_TRANSFER_PENDING			23
//#define FTL_PC_TWOPLANE_READ_TRANSFER_PENDING_TO_TRANSFER_ACTIVE	24
//#define FTL_PC_TWOPLANE_READ_REQUEST_COMPLETE						25
//
//#define FTL_PC_TWOPLANE_WRITE_BUFFER_WAIT_TO_TRANSFER_PENDING		26
//#define FTL_PC_TWOPLANE_WRITE_TRANSFER_PENDING_TO_TRANSFER_ACTIVE	27
//#define FTL_PC_TWOPLANE_WRITE_TRANSFER_ACTIVE_TO_DATA_PENDING		28
//#define FTL_PC_TWOPLANE_WRITE_DATA_PENDING_TO_DATA_ONBUS			29
//#define FTL_PC_TWOPLANE_WRITE_DATA_ONBUS_TO_WAIT_OP					30
//#define FTL_PC_TWOPLANE_WRITE_REQUEST_COMPLETE						31
//
//#define FTL_PC_TWOPLANE_ERASE_PENDING_TO_ONBUS	32
//#define FTL_PC_TWOPLANE_ERASE_ONBUS_TO_WAIT_OP	33
//#define FTL_PC_TWOPLANE_ERASE_REQUEST_COMPLETE	34

int gordon_init();
void gordon_close();

void gordon_set_timings(unsigned char WriteLow, unsigned char WriteHigh, unsigned char ReadLow, unsigned char ReadHigh);

unsigned short gordon_send_adc_command (unsigned char readNotWrite, unsigned char chip, unsigned short message);
void gordon_calib_adc();

void print_registers();

unsigned int gordon_bus_chips(unsigned char bus);
int gordon_chip_exists(unsigned char bus, unsigned char chip);
int gordon_wait(unsigned short tag);

unsigned int gordon_get_cyclecount(unsigned char bus);
void gordon_set_cyclecount_points(unsigned char start, unsigned char end, unsigned char bus);
void gordon_reset_cyclecount(unsigned char bus);

int gordon_chip_busy(unsigned char bus, unsigned char chip);
unsigned int gordon_bus_busy(unsigned char bus);

unsigned short gordon_chip_reset(unsigned char bus, unsigned char chip);
void gordon_chip_reset_wait(unsigned char bus, unsigned char chip);

unsigned short gordon_erase(unsigned char bus, unsigned char chip, unsigned int page);
void gordon_erase_wait(unsigned char bus, unsigned char chip, unsigned int page);

unsigned int gordon_read_adc_samples(unsigned char bus, float* dest);
void gordon_read_parampage(unsigned char bus, unsigned char chip, unsigned short length, char* dest);
void gordon_readid(unsigned char bus, unsigned char chip, unsigned char* dest);
unsigned short gordon_read_start(unsigned char bus, unsigned char chip, unsigned int page,
	unsigned short offset, unsigned short length);
void gordon_read_complete(unsigned short tag, unsigned short length, char* dest);
void gordon_read_wait(unsigned char bus, unsigned char chip, unsigned int page,
	unsigned short offset, unsigned short length, char* dest);

unsigned short gordon_write(unsigned char bus, unsigned char chip, unsigned int page,
	unsigned short offset, unsigned short length, const char* src);
void gordon_write_wait(unsigned char bus, unsigned char chip, unsigned int page,
	unsigned short offset, unsigned short length, const char* src);

unsigned short gordon_twoplane_erase(unsigned char bus, unsigned char chip, unsigned int page, unsigned int page2);
void gordon_twoplane_erase_wait(unsigned char bus, unsigned char chip, unsigned int page, unsigned int page2);

unsigned short gordon_twoplane_read_start(unsigned char bus, unsigned char chip, unsigned int page,
	unsigned short offset, unsigned int page2, unsigned short offset2, unsigned short length);
void gordon_twoplane_read_complete(unsigned short tag, unsigned short length, char* dest);
void gordon_twoplane_read_wait(unsigned char bus, unsigned char chip, unsigned int page,
	unsigned short offset, unsigned int page2, unsigned short offset2, unsigned short length, char* dest);

unsigned short gordon_twoplane_write(unsigned char bus, unsigned char chip, unsigned int page,
	unsigned short offset, unsigned int page2, unsigned short offset2, unsigned short length, const char* src);
void gordon_twoplane_write_wait(unsigned char bus, unsigned char chip, unsigned int page,
	unsigned short offset, unsigned int page2, unsigned short offset2, unsigned short length, const char* src);

void gordon_set_adc_gain(unsigned char gain);
unsigned short gordon_get_adc_gain();
void gordon_enable_adc_recording(unsigned char bus);
void gordon_disable_adc_recording(unsigned char bus);

void gordon_reset();

#endif

