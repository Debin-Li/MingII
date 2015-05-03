#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

#include "mingii.h"

int main(int argc, char** argv) {
	unsigned int status;
	
	if (argc != 2) {
		fprintf(stderr,"%s bus\n",argv[0]);
		return -1;
	}

	if (gordon_init())
	{
		fprintf(stderr,"Error Opening Gordon Device\n");
		return -1;
	}


	unsigned char bus = atoi(argv[1]);

	status = gordon_bus_busy(bus);

	printf("Status: %d\n", status);
	printf("Chip 0: %d\n", (status >> 31) & 0x1);

	return 0;
}




