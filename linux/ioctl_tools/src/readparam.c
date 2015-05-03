#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

#include "mingii.h"

unsigned int ToInt(char* buf, int pos)
{
	unsigned int b0 = (buf[pos] & 0xFF);
	unsigned int b1 = (buf[pos+1] & 0xFF);
	unsigned int b2 = (buf[pos+2] & 0xFF);
	unsigned int b3 = (buf[pos+3] & 0xFF);

	return b0 + (b1<<8) + (b2<<16) + (b3<<24);
}

unsigned short ToUnsignedShort(char* buf, int pos)
{
	unsigned int b0 = (buf[pos] & 0xFF);
	unsigned int b1 = (buf[pos+1] & 0xFF);
	return b0 + (b1<<8);
}

short ToShort(char* buf, int pos)
{
	unsigned int b0 = (buf[pos] & 0xFF);
	unsigned int b1 = (buf[pos+1] & 0xFF);
	return b0 + (b1<<8);
}

char ToYN(unsigned short input)
{
	if (input) return 'Y';
	else return 'N';
}

void PrintRevisionNumber(unsigned short rev) 
{
	int atLeastOne = 0;
	
	printf("Supported Revision Numbers: ");
	
	if ((rev >> 1) & 0x1) {
		printf("1.0");
		atLeastOne = 1;
	}
	if ((rev >> 2) & 0x1) {
		if (atLeastOne) printf(", ");
		printf("2.0");
		atLeastOne = 1;
	} 
	if ((rev >> 3) & 0x1) {
		if (atLeastOne) printf(", ");
		printf("2.1");
		atLeastOne = 1;
	} 
	if ((rev >> 4) & 0x1) {
		if (atLeastOne) printf(", ");
		printf("2.2");
		atLeastOne = 1;
	} 
	if ((rev >> 5) & 0x1) {
		if (atLeastOne) printf(", ");
		printf("2.3");
		atLeastOne = 1;
	}
	if ((rev >> 6) & 0x1) {
		if (atLeastOne) printf(", ");
		printf("3.0");
		atLeastOne = 1;
	}
	printf("\n"); 
}

void PrintSupportedFeatures(unsigned short features)
{
	printf("Supports 16-bit data bus width: %c\n", ToYN(features & 0x1));
	printf("Supports multiple LUN operations: %c\n", ToYN((features >> 1) & 0x1));
	printf("Supports non-sequential page programming: %c\n", ToYN((features >> 2) & 0x1));
	printf("Supports multi-plane program and erase operations: %c\n", ToYN((features >> 3) & 0x1));
	printf("Supports odd to even page copyback: %c\n", ToYN((features >> 4) & 0x1));
	printf("Supports NV-DDR: %c\n", ToYN((features >> 5) & 0x1));
	printf("Supports multi-plane read operations: %c\n", ToYN((features >> 6) & 0x1));
	printf("Supports extended parameter page: %c\n", ToYN((features >> 7) & 0x1));
	printf("Supports program page register clear enhancement: %c\n", ToYN((features >> 8) & 0x1));
	printf("Supports EX NAND: %c\n", ToYN((features >> 9) & 0x1));
	printf("Supports NV-DDR2: %c\n", ToYN((features >> 10) & 0x1));
	printf("Supports volume addressing: %c\n", ToYN((features >> 11) & 0x1));
	printf("Supports external Vpp: %c\n", ToYN((features >> 12) & 0x1));
}

void PrintDeviceManufacturer(char *buf)
{
	int i;	

	printf("Device Manufacturer: ");
	for (i = 0; i < 12; i++) {
		printf("%c", buf[32+i]);
	}
	printf("\n");
}

void PrintDeviceModel(char *buf)
{
	int i;	

	printf("Device Model: ");
	for (i = 0; i < 20; i++) {
		printf("%c", buf[43+i]);
	}
	printf("\n");
}

void PrintPECycles(char *buf)
{
	int i = 0;
	int value = buf[105];	

	for (i = 0; i < buf[106]; i++) {
		value = value * 10;
	}

	printf("# P/E Cycles: %d\n", value);

}

int main(int argc, char** argv) {

	if (argc != 4) {
		fprintf(stderr,"%s bus chip verbosity{0=default - 3=all}\n",argv[0]);
		return -1;
	}
	if (atoi(argv[1]) < 0 || atoi(argv[1]) > 3) {
		fprintf(stderr,"Only 0,1,2,3 acceptable as bus options.\n");
		return -1;
	}

	if (gordon_init())
	{
		fprintf(stderr,"Error Opening Gordon Device\n");
		return -1;
	}

	unsigned char bus, chip;
	unsigned int verbosity;
	bus = atoi(argv[1]);
	chip = atoi(argv[2]);
	char buf[4096];
	verbosity = atoi(argv[3]);

	gordon_read_parampage(bus,chip,256,buf);

	printf("ONFI Marker: %c %c %c %c\n", buf[0], buf[1], buf[2], buf[3]);
	if (verbosity > 0) PrintRevisionNumber(ToUnsignedShort(buf,4));
	if (verbosity > 1) PrintSupportedFeatures(ToUnsignedShort(buf,6));
	PrintDeviceManufacturer(buf);
	PrintDeviceModel(buf);
	printf("JEDEC Manufacturer ID: 0x%02X\n", buf[64]);
	printf("Bytes Per Page: %d\n",ToInt(buf,80));
	printf("OOB Bytes/Page: %d\n",ToShort(buf,84));
	//fprintf(stderr,"Bytes Per Partial Page: %d\n",ToInt(buf,86));
	//fprintf(stderr,"OOB Bytes/Partial Page: %d\n",ToShort(buf,90));
	printf("Pages/Block: %d\n",ToInt(buf,92));
	printf("Blocks/LUN: %d\n",ToInt(buf,96));
	printf("# LUNs: %d\n",buf[100]);
	printf("# Bits/Cell: %d\n",buf[102]);
	PrintPECycles(buf);	
	
	//fwrite(buf,1,256,stdout);	

	return 0;
}




