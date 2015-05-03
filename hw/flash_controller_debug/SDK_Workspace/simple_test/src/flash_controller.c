#include "flash_controller.h"
#include "xparameters.h"
#include <stdio.h>

void writeToRegister(int registerOffset, int data)
{
	*(int*)(XPAR_FLASH_CONTROLLER_0_BASEADDR + registerOffset) = data;
}

int readFromRegister(int registerOffset)
{
	return *(int*)(XPAR_FLASH_CONTROLLER_0_BASEADDR + registerOffset);
}

void writeCommand(int* dramAddress, int busNumber, int chipNumber, int pageNumber, int offset, int operationCode, int length, int tag)
{
	writeToRegister(WRITE_ADDR_OFFSET_CMD_0, (int)dramAddress);
	writeToRegister(WRITE_ADDR_OFFSET_CMD_1, (int)(((busNumber & 0xF) << 28) | ((chipNumber & 0xF) << 24) | (pageNumber & 0xFFFFFF)));
	writeToRegister(WRITE_ADDR_OFFSET_CMD_2, (int)(((offset & 0xFFFF) << 16) | ((operationCode & CMD_OP_CODE_MASK) << CMD_OP_CODE_LEFT_SHIFT) | (length & CMD_LENGTH_MASK)));
	writeToRegister(WRITE_ADDR_OFFSET_CMD_3, (int)((tag & 0x3F) << 26));
}

void issueCommand()
{
	writeToRegister(WRITE_ADDR_OFFSET_ISSUE_CMD, 0x1);
}

int sendCommand(int* dramAddress, int busNumber, int chipNumber, int pageNumber, int offset, int operationCode, int length, int tag)
{
	writeCommand(dramAddress, busNumber, chipNumber, pageNumber, offset, operationCode, length, tag);
	issueCommand();
	return 0;
}

void reset()
{
	xil_printf("Reseting the Flash Controller\n");
	writeToRegister(WRITE_ADDR_OFFSET_RESET, 0xA);
}

int initChips(int tag)
{
	int i, j;

	for (i = 0; i < NUM_OF_CHIPS_PER_BUS; i++) {
		for (j = 0; j < NUM_OF_BUSES; j++) {
			chipReset(j,i, tag);
		}
	}
	return 0;
}

int chipReset(int busNumber, int chipNumber, int tag)
{
	sendCommand(0, busNumber, chipNumber, 0, 0, OP_RESET, 0, tag);
	return 0;
}

int setTimingMode(int busNumber, int chipNumber, int tag)
{
	sendCommand(0, busNumber, chipNumber, 0, 0, OP_SET_TIMING_MODE, 0, tag);
	return 0;
}

int read(int busNumber, int chipNumber, int pageNumber, int offset, int length, int* buffer, int tag)
{
	sendCommand(buffer, busNumber, chipNumber, pageNumber, offset, OP_READ, length, tag);
	return 0;
}

int program(int busNumber, int chipNumber, int pageNumber, int offset, int length, int* buffer, int tag)
{
	sendCommand(buffer, busNumber, chipNumber, pageNumber, offset, OP_PROGRAM, length, tag);
	return 0;
}

int readID(int busNumber, int chipNumber, int* buffer, int tag)
{
	xil_printf("Issued Read ID\n");
	sendCommand(buffer, busNumber, chipNumber, 0, 0, OP_READ_ID, 1, tag);
	return 0;
}

int erase(int busNumber, int chipNumber, int pageNumber, int tag)
{
	sendCommand(0, busNumber, chipNumber, pageNumber, 0, OP_ERASE, 0, tag);
	return 0;
}

int readParams(int busNumber, int chipNumber, int* buffer, int tag)
{
	sendCommand(buffer, busNumber, chipNumber, 0, 0, OP_READ_PARAMS, 8, tag);
	return 0;
}

int getADCSamples(int busNumber, int* buffer, int tag)
{
	sendCommand(buffer, busNumber, 0, 0, 0, OP_GET_ADC_SAMPLES, 0, tag);
	return 0;
}

int readCCParams()
{
	return readFromRegister(READ_ADDR_OFFSET_CC_PARAMS);
}

int setCCParams(int bus, int startParam, int endParam)
{
	int oldParams = readFromRegister(READ_ADDR_OFFSET_CC_PARAMS);
	int clearMask = 0xFFFFFFFF ^ (0xFF << (bus * 8));
	int clearedOldParams = oldParams & clearMask;
	int newParams = clearedOldParams | ((startParam & 0xF) << ((bus*8)+4)) | ((endParam & 0xF) << (bus*8));
	xil_printf("Setting CC Params: 0x%08X\n", newParams);
	writeToRegister(WRITE_ADDR_OFFSET_CC_PARAMS, newParams);
	return 0;
}

int readCCSum(int bus)
{
	return readFromRegister(READ_ADDR_OFFSET_CC_BUS0 + (4 * bus));
}

int resetCCSum(int bus)
{
	writeToRegister(WRITE_ADDR_OFFSET_CC_RESET,(0x1 << bus));
	return 0;
}

int setADCGain(int gain)
{
	int oldParams = readFromRegister(READ_ADDR_OFFSET_ADC_SETTINGS);
	int clearedOldParams = oldParams & 0xFFFFFF0F;
	int newParams = clearedOldParams | ((gain & 0xF) << 4);
	writeToRegister(WRITE_ADDR_OFFSET_ADC_SETTINGS, newParams);
	return 0;
}

int enableADCRecording(int bus)
{
	int oldParams = readFromRegister(READ_ADDR_OFFSET_ADC_SETTINGS);
	int clearMask = 0xFFFFFFFF ^ (0x1 << bus);
	int clearedOldParams = oldParams & clearMask;
	int newParams = clearedOldParams | (0x1 << bus);
	writeToRegister(WRITE_ADDR_OFFSET_ADC_SETTINGS, newParams);
	return 0;
}

int disableADCRecording(int bus)
{
	int oldParams = readFromRegister(READ_ADDR_OFFSET_ADC_SETTINGS);
	int clearMask = 0xFFFFFFFF ^ (0x1 << bus);
	int clearedOldParams = oldParams & clearMask;
	writeToRegister(WRITE_ADDR_OFFSET_ADC_SETTINGS, clearedOldParams);
	return 0;
}

int sendADCCommand(int chip, int rnw, int command)
{
	int adcCommand = ((chip & 0x1) << 17) | ((rnw & 0x1) << 16) | (command & 0xFFFF);
	xil_printf("Sending ADC Command: 0x%08X\n", adcCommand);
	writeToRegister(WRITE_ADDR_OFFSET_ADC_CMD, adcCommand);
	if (rnw) {
		return readFromRegister(READ_ADDR_OFFSET_ADC_RESP);
	} else {
		return 0;
	}
}

void printOperation(int operation)
{
	switch (operation) {
		case OP_PROGRAM:
			printf("OP_PROGRAM");
			break;

		case OP_READ:
			printf("OP_READ");
			break;

		case OP_ERASE:
			printf("OP_ERASE");
			break;

		case OP_READ_ID:
			printf("OP_READ_ID");
			break;

		case OP_READ_PARAMS:
			printf("OP_READ_PARAMS");
			break;

		default:
			printf("Unrecognized operation");
			break;
	}
}

void printCommands()
{
	int cmd_0 = readFromRegister(READ_ADDR_OFFSET_CMD_0);
	int cmd_1 = readFromRegister(READ_ADDR_OFFSET_CMD_1);
	int cmd_2 = readFromRegister(READ_ADDR_OFFSET_CMD_2);
	int cmd_3 = readFromRegister(READ_ADDR_OFFSET_CMD_3);

	printf("DRAM Address: 0x%08X\n", cmd_0);
	printf("Bus Number: %d\n", (cmd_1 & 0xF000000) >> 28);
	printf("Chip Number: %d\n", (cmd_1 & 0x0F000000) >> 24);
	printf("Page Number: %d\n", cmd_1 & 0xFFFFFF);
	printf("Offset: %d\n", (cmd_2 & 0xFFFF0000) >> 16);
	printf("Operation: %d\n", (cmd_2 & 0xF000) >> 12);
	printf("Length(x32 bytes): %d\n", cmd_2 & 0xFFF);
	printf("Tag: %d\n", (cmd_3 & 0xFC000000) >> 26);
}

void printRegisters()
{
	xil_printf("Command 0: 0x%08X\n", *(int*)(XPAR_FLASH_CONTROLLER_0_BASEADDR + 0));
	xil_printf("Command 1: 0x%08X\n", *(int*)(XPAR_FLASH_CONTROLLER_0_BASEADDR + 4));
	xil_printf("Command 2: 0x%08X\n", *(int*)(XPAR_FLASH_CONTROLLER_0_BASEADDR + 8));
	xil_printf("Command 3: 0x%08X\n", *(int*)(XPAR_FLASH_CONTROLLER_0_BASEADDR + 12));
	xil_printf("Tag Status [31:0]: 0x%08X\n", *(int*)(XPAR_FLASH_CONTROLLER_0_BASEADDR + 24));
	xil_printf("Tag Status [63:32]: 0x%08X\n", *(int*)(XPAR_FLASH_CONTROLLER_0_BASEADDR + 28));
	xil_printf("Debug Register: 0x%08X\n", *(int*)(XPAR_FLASH_CONTROLLER_0_BASEADDR + READ_ADDR_OFFSET_CC_DEBUG));
	//xil_printf("Reading at address 0x%08X value: 0x%08X\n", (XPAR_FLASH_CONTROLLER_0_BASEADDR + 32), *(int*)(XPAR_FLASH_CONTROLLER_0_BASEADDR + 32));
	//xil_printf("Reading at address 0x%08X value: 0x%08X\n", (XPAR_FLASH_CONTROLLER_0_BASEADDR + 36), *(int*)(XPAR_FLASH_CONTROLLER_0_BASEADDR + 36));
	//xil_printf("Reading at address 0x%08X value: 0x%08X\n", (XPAR_FLASH_CONTROLLER_0_BASEADDR + 36), *(int*)(XPAR_FLASH_CONTROLLER_0_BASEADDR + 40));
}
