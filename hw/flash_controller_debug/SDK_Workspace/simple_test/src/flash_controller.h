#ifndef FLASH_CONTROLLER_H_
#define FLASH_CONTROLLER_H_

#define NUM_OF_BUSES          4
#define NUM_OF_CHIPS_PER_BUS  4
#define NUM_OF_CHIPS          NUM_OF_BUSES*NUM_OF_CHIPS_PER_BUS

#define CMD_FLASH_LOWER_ADDR_MASK	0xFFFF
#define CMD_FLASH_LOWER_LEFT_SHIFT	16
#define CMD_OP_CODE_MASK			0xF
#define CMD_OP_CODE_LEFT_SHIFT		12
#define CMD_LENGTH_MASK				0x2FF

// Operations
#define OP_PROGRAM		    0
#define OP_READ			    1
#define OP_ERASE		    2
#define OP_READ_ID		    3
#define OP_READ_PARAMS	    4
#define OP_RESET		    5
#define OP_SET_TIMING_MODE	6
#define OP_GET_ADC_SAMPLES  7

// Performance Counter Values
// Performance Counter Start and End Point Options
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

// Default Page Sizes
#define PAGE_SIZE_2112 0x00000840 // 2048 + 64
#define PAGE_SIZE_4200 0x000010E0 // 4096 + 224
#define PAGE_SIZE_9152 0x000023C0 // 8192 + 960

// Write Addresses
#define WRITE_ADDR_OFFSET_CMD_0 		0
#define WRITE_ADDR_OFFSET_CMD_1 		4
#define WRITE_ADDR_OFFSET_CMD_2 		8
#define WRITE_ADDR_OFFSET_CMD_3 		12
#define WRITE_ADDR_OFFSET_ISSUE_CMD 	16
#define WRITE_ADDR_OFFSET_ADC_CMD 	    24
#define WRITE_ADDR_OFFSET_ADC_SETTINGS  32
#define WRITE_ADDR_OFFSET_CC_PARAMS		36
#define WRITE_ADDR_OFFSET_CC_RESET		40
#define WRITE_ADDR_OFFSET_RESET			0x200

// Read Addresses
#define READ_ADDR_OFFSET_CMD_0 		  0
#define READ_ADDR_OFFSET_CMD_1 		  4
#define READ_ADDR_OFFSET_CMD_2 		  8
#define READ_ADDR_OFFSET_CMD_3 		  12
#define READ_ADDR_OFFSET_ADC_RESP	  16
#define READ_ADDR_OFFSET_CTRL_STATUS  20
#define READ_ADDR_OFFSET_TAG_STATUS	  24
#define READ_ADDR_OFFSET_ADC_SETTINGS 32
#define READ_ADDR_OFFSET_CC_PARAMS	  36
#define READ_ADDR_OFFSET_CC_RESET	  40
#define READ_ADDR_OFFSET_CC_BUS0	  44
#define READ_ADDR_OFFSET_CC_BUS1	  48
#define READ_ADDR_OFFSET_CC_BUS2	  52
#define READ_ADDR_OFFSET_CC_BUS3	  56
#define READ_ADDR_OFFSET_CC_DEBUG	  60


void writeToRegister(int registerOffset, int data);
int readFromRegister(int registerOffset);
void writeCommand(int* dramAddress, int busNumber, int chipNumber, int pageNumber, int offset, int operationCode, int length, int tag);
void issueCommand();
int sendCommand(int* dramAddress, int busNumber, int chipNumber, int pageNumber, int offset, int operationCode, int length, int tag);
void reset();
int initChips(int tag);
int chipReset(int busNumber, int chipNumber, int tag);
int setTimingMode(int busNumber, int chipNumber, int tag);
int read(int busNumber, int chipNumber, int pageNumber, int offset, int length, int* buffer, int tag);
int program(int busNumber, int chipNumber, int pageNumber, int offset, int length, int* buffer, int tag);
int readID(int busNumber, int chipNumber, int* buffer, int tag);
int erase(int busNumber, int chipNumber, int pageNumber, int tag);
int readParams(int busNumber, int chipNumber, int* buffer, int tag);
int getADCSamples(int busNumber, int* buffer, int tag);
int readCCParams();
int setCCParams(int bus, int startParam, int endParam);
int readCCSum(int bus);
int resetCCSum(int bus);
int setADCGain(int gain);
int enableADCRecording(int bus);
int disableADCRecording(int bus);
int sendADCCommand(int chip, int rnw, int command);
void printOperation(int operation);
void printCommands();
void printRegisters();


#endif
