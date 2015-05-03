#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

#include "mingii.h"

int main(int argc, char** argv) {

	if (argc != 4) {
		fprintf(stderr,"%s chip channel message{in hex}\n",argv[0]);
		return -1;
	}

	if (gordon_init())
	{
		fprintf(stderr,"Error Opening Gordon Device\n");
		return -1;
	}


	unsigned char chip = atoi(argv[1]);
	unsigned char channel = atoi(argv[2]);
	unsigned int msg = 0;
	sscanf(argv[3], "%x", &msg);
	unsigned short shortMsg = (unsigned short) msg;

	unsigned short returnMsg = gordon_send_adc_command(chip, channel, shortMsg);

	printf("Return Message: 0x%04X\n", returnMsg);

	return 0;
}




