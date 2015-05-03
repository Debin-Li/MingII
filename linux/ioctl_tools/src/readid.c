#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

#include "mingii.h"

int main(int argc, char** argv) {

	if (argc != 3) {
		fprintf(stderr,"%s bus chip\n",argv[0]);
		return -1;
	}

	if (gordon_init())
	{
		fprintf(stderr,"Error Opening Gordon Device\n");
		return -1;
	}


	unsigned char bus = atoi(argv[1]);
	unsigned char chip = atoi(argv[2]);

        unsigned char buf[5];

	gordon_readid(bus,chip,buf);

	printf("Bus %d Chip %d ID: 0x%.2x 0x%.2x 0x%.2x 0x%.2x 0x%.2x\n",bus,chip,buf[0],buf[1],buf[2],buf[3],buf[4]);

	//fwrite(buf,1,4,stdout);

	return 0;
}




