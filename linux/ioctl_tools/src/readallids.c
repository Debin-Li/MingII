#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

#include "mingii.h"

int main(int argc, char** argv) {

	if (argc != 3) {
		fprintf(stderr,"%s num_of_buses num_of_chips\n",argv[0]);
		return -1;
	}

	if (gordon_init())
	{
		fprintf(stderr,"Error Opening Gordon Device\n");
		return -1;
	}

	unsigned short num_of_buses = atoi(argv[1]);
	unsigned short num_of_chips = atoi(argv[2]);

        unsigned char buf[5];
	unsigned short bus, chip;

	for (bus = 0; bus < num_of_buses; bus++) {
		for (chip = 0; chip < num_of_chips; chip++) {
			gordon_readid(bus,chip,buf);
			
			printf("Bus %d Chip %d ID: 0x%.2x 0x%.2x 0x%.2x 0x%.2x 0x%.2x\n",bus,chip,buf[0],buf[1],buf[2],buf[3],buf[4]);

		}
	}

	return 0;
}




