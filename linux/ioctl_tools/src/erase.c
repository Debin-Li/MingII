#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

#include "mingii.h"

int main(int argc, char** argv) {

	if (argc != 4) {
		fprintf(stderr,"%s bus chip page\n",argv[0]);
		return -1;
	}

	if (gordon_init())
	{
		fprintf(stderr,"Error Opening Gordon Device\n");
		return -1;
	}


	unsigned char bus = atoi(argv[1]);
	unsigned char chip = atoi(argv[2]);
	unsigned int page = atoi(argv[3]);

	gordon_erase_wait(bus,chip,page);

	return 0;
}




