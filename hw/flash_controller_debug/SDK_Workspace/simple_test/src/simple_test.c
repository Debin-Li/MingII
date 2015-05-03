#include <stdio.h>
#include <stdlib.h>
#include "xparameters.h"
#include "xutil.h"
#include "xio.h"

#include "flash_controller.h"

/*
// Read ID Loop
int main()
{
    int num_of_values = 24;
    int bus_number = 1;
    int chip_number = 0;
    int block_number = 0;
    int page_number_offset = 0;
    int pages_per_block = 64;
    int byte_offset = 0;
    int page_number = block_number*pages_per_block + page_number_offset;

    // Get a pointer to DRAM
    int* dram_readid_addr = (int*)malloc(8*sizeof(int));
    int i = 0;
    int tag = 0;

    // Zero out Read ID Addresses
    for (i = 0; i < 8; i++) {
        // Zero out data
        *(int*)(dram_readid_addr + i) = 0;
    }

    // Reset the Flash Controller
    reset();

    while (1) {
		// Issue a Read ID Operation
		xil_printf("Read ID\n");
		readID(bus_number, chip_number, dram_readid_addr, tag++);

		// Reading the ID
		//xil_printf("Read ID Addresses\n");
		for (i = 0; i < 8; i++) {
			// Read the data
			xil_printf("0x%08X: 0x%08X\n", (dram_readid_addr + i), *(int*)(dram_readid_addr + i));
		}
    }

	free(dram_readid_addr);

    return 0;
}
*/

/*
// ADC Command test
int main()
{
    // Reset the Flash Controller
    reset();
	
	// Set up ADC Controller
	setADCGain(0x1);

	while (1) {
		// Send ADC Read Command
		int response = sendADCCommand(0x0, 0x1, (0x1114 << 0));

		xil_printf("ADC Read Response: 0x%08X\n", response);
		xil_printf("Debug Register: 0x%08X\n", *(int*)(XPAR_FLASH_CONTROLLER_0_BASEADDR + READ_ADDR_OFFSET_CC_DEBUG));
		xil_printf("ADC Settings: 0x%08X\n", *(int*)(XPAR_FLASH_CONTROLLER_0_BASEADDR + READ_ADDR_OFFSET_ADC_SETTINGS));
	}

    return 0;
}
*/

// Read Loop of large requests
int main()
{
    int num_of_values = 1032;
    int bus_number = 0;
    int chip_number = 0;
    int block_number = 0;
    int page_number_offset = 0;
    int pages_per_block = 64;
    int byte_offset = 0;
    int page_number = block_number*pages_per_block + page_number_offset;

    // Get a pointer to DRAM
    int* dram_readid_addr = (int*)malloc(8*sizeof(int));
    int* dram_read_addr = (int*)malloc(num_of_values*sizeof(int));
    int* dram_write_addr = (int*)malloc(num_of_values*sizeof(int));
    int i = 0;
    int tag = 0;

    if ((dram_read_addr == 0) || (dram_write_addr == 0)) {
    	printf("error");
    	return -1;
	}

    // Zero out Read ID Addresses
	for (i = 0; i < 8; i++) {
		// Zero out data
		*(int*)(dram_readid_addr + i) = 0;
	}

    for (i = 0; i < num_of_values; i++) {
    	*(int*)(dram_read_addr + i) = i;
    }

    for (i = 0; i < num_of_values; i++) {
    	// Zero out data
    	*(int*)(dram_write_addr + i) = 0xABABABAB;
    }

    // Reset the Flash Controller
    reset();

	// Erase the Flash Chip
	xil_printf("Erasing the block\n");
	erase(bus_number, chip_number, page_number, tag++);

	// Program the Flash Chip
	xil_printf("P %d\n", page_number);
	program(bus_number, chip_number, page_number, byte_offset, num_of_values*4/32, dram_read_addr, tag++);

	//while (1) {

		// Read from the Flash Chip
		xil_printf("R %d\n", page_number);
		read(bus_number, chip_number, page_number, byte_offset, num_of_values*4/32, dram_write_addr, tag++);

		// Issue a Read ID Operation
		xil_printf("Read ID\n");
		readID(bus_number, chip_number, dram_readid_addr, tag++);

		// Reading the data from the Read Address
		xil_printf("Read Data Addresses\n");
		for (i = 0; i < num_of_values; i++) {
			// Read the data
			xil_printf("0x%08X: 0x%08X\n", (dram_write_addr + i), *(int*)(dram_write_addr + i));
		}

		// Reading the ID
		xil_printf("Read ID Addresses\n");
		for (i = 0; i < 8; i++) {
			// Read the data
			xil_printf("0x%08X: 0x%08X\n", (dram_readid_addr + i), *(int*)(dram_readid_addr + i));
		}

		page_number++;
	//}
	free(dram_read_addr);
	free(dram_write_addr);

    return 0;
}

/*
int main()
{
    int num_of_values = 1016;
    int max_num_of_adc_samples = 128;
    int bus_number = 1;
    int chip_number = 0;
    int block_number = 0;
    int page_number_offset = 0;
    int pages_per_block = 64;
    int byte_offset = 0;
    int page_number = block_number*pages_per_block + page_number_offset;

    // Get a pointer to DRAM
    int* dram_read_addr = (int*)malloc(num_of_values*sizeof(int));
    int* dram_write_addr = (int*)malloc(num_of_values*sizeof(int));
    int* dram_readid_addr = (int*)malloc(8*sizeof(int));
    int* dram_readparam_addr = (int*)malloc(64*sizeof(int));
    int* dram_adc_samples_addr = (int*)malloc(max_num_of_adc_samples*sizeof(int));
    int i = 0;
    int tag = 0;

    for (i = 0; i < num_of_values; i++) {
    	*(int*)(dram_read_addr + i) = i;
    }

    for (i = 0; i < num_of_values; i++) {
    	// Zero out data
    	*(int*)(dram_write_addr + i) = 0;
    }

    // Zero out Read ID Addresses
    for (i = 0; i < 8; i++) {
        // Zero out data
        *(int*)(dram_readid_addr + i) = 0;
    }

    // Zero out Read Param Addresses
	for (i = 0; i < 64; i++) {
		// Zero out data
		*(int*)(dram_readparam_addr + i) = 0;
	}

    // Zero out ADC Samples Addresses
	for (i = 0; i < max_num_of_adc_samples; i++) {
		// Zero out data
		*(int*)(dram_adc_samples_addr + i) = 0;
	}

    // Reset the Flash Controller
    reset();

	// Set up ADC Controller
	setADCGain(1);
	xil_printf("ADC Settings: 0x%08X\n", *(int*)(XPAR_FLASH_CONTROLLER_0_BASEADDR + READ_ADDR_OFFSET_ADC_SETTINGS));

	// Issue a Read ID Operation
	xil_printf("Read ID\n");
	readID(bus_number, chip_number, dram_readid_addr, tag++);
	printRegisters();

	xil_printf("Read Parameters\n");
	readParams(bus_number, chip_number, dram_readparam_addr, tag++);
	printRegisters();

	// Erase the Flash Chip
	resetCCSum(bus_number);
	setCCParams(bus_number,PC_ERASE_PENDING_TO_ONBUS,PC_ERASE_FINISHED);
	//xil_printf("CC Params: 0x%08X\n", readCCParams());
	xil_printf("Erasing the block\n");
	erase(bus_number, chip_number, page_number, tag++);
	printRegisters();
	xil_printf("Cycles for Erase: %d\n", readCCSum(bus_number));

    // Program the Flash Chip
	resetCCSum(bus_number);
	setCCParams(bus_number,PC_WRITE_DATA_PENDING_TO_DATA_ONBUS,PC_WRITE_ARRAY_WRITE_FINISHED);
	enableADCRecording(bus_number);
	xil_printf("Programming a page\n");
	program(bus_number, chip_number, page_number, byte_offset, num_of_values*4/32, dram_read_addr, tag++);
	printRegisters();
	xil_printf("Cycles for Program: %d\n", readCCSum(bus_number));
	disableADCRecording(bus_number);

	// Read from the Flash Chip
	resetCCSum(bus_number);
	setCCParams(bus_number,PC_READ_COMMAND_PENDING_TO_COMMAND_ONBUS,PC_READ_DATA_ONBUS_TO_TRANSFER_PENDING);
	//enableADCRecording(bus_number);
	xil_printf("Reading a page\n");
	read(bus_number, chip_number, page_number, byte_offset, num_of_values*4/32, dram_write_addr, tag++);
	printRegisters();
	xil_printf("Cycles for Read: %d\n", readCCSum(bus_number));
	//disableADCRecording(bus_number);

	// Get the ADC Samples
	xil_printf("Getting the ADC Samples\n");
	getADCSamples(bus_number, dram_adc_samples_addr, tag++);
	printRegisters();

	// Reading the ID
	xil_printf("Read ID Addresses\n");
	for (i = 0; i < 8; i++) {
		// Read the data
		xil_printf("0x%08X: 0x%08X\n", (dram_readid_addr + i), *(int*)(dram_readid_addr + i));
	}

	// Reading the data from the Read Address
	xil_printf("Read Data Addresses\n");
	for (i = 0; i < num_of_values; i++) {
		// Read the data
		xil_printf("0x%08X: 0x%08X\n", (dram_write_addr + i), *(int*)(dram_write_addr + i));
	}

	// Reading the Parameters
	xil_printf("Read Parameter Addresses\n");
	for (i = 0; i < 64; i++) {
		// Read the data
		xil_printf("0x%08X (+%d): 0x%08X\n", (dram_readparam_addr + i), i*4, *(int*)(dram_readparam_addr + i));
	}

	// Reading the ADC Samples
	xil_printf("Read ADC Sample Addresses\n");
	int sample, firstSample, secondSample;
	for (i = 0; i < max_num_of_adc_samples; i++) {
		// Read the data
		//xil_printf("0x%08X (+%d): 0x%08X\n", (dram_adc_samples_addr + i), i*4, *(int*)(dram_adc_samples_addr + i));
		sample = *(int*)(dram_adc_samples_addr + i);

		firstSample = (sample & 0xFFFF0000) >> 16;
		secondSample = sample & 0xFFFF;

		if (firstSample == 0xFFFF) {
			xil_printf("Total number of samples is %d\n", i*2);
			break;
		} else {
			xil_printf("Sample %d: 0x%04X\n", i*2, firstSample);
		}

		if (secondSample == 0xFFFF) {
			xil_printf("Total number of samples is %d\n", i*2+1);
			break;
		} else {
			xil_printf("Sample %d: 0x%04X\n", i*2+1, secondSample);
		}
	}

	printRegisters();

	free(dram_read_addr);
	free(dram_write_addr);
	free(dram_readid_addr);
	free(dram_readparam_addr);
	free(dram_adc_samples_addr);
    return 0;
}
*/
