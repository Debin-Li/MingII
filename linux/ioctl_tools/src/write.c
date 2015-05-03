#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

#include "mingii.h"

int main(int argc, char** argv) {

	if (argc != 6) {
		fprintf(stderr,"%s bus chip page offset length\n",argv[0]);
		return -1;
	}

	if (gordon_init())
	{
		fprintf(stderr,"Error Opening Gordon Device\n");
		return -1;
	}


        unsigned short len = atoi(argv[5]);
	unsigned short offset = atoi(argv[4]);
        unsigned int page = atoi(argv[3]);
	unsigned char bus = atoi(argv[1]);
	unsigned char chip = atoi(argv[2]);

        char buf[8192];

	fread(buf,1,len,stdin);	

	gordon_write_wait(bus,chip,page,offset,len,buf);

	return 0;
}




