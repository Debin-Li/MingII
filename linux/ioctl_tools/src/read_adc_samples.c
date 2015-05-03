#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

#include "mingii.h"

int main(int argc, char** argv) {

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
	unsigned int samples = 0;

        float buf[8192];
	unsigned int i;

	samples = gordon_read_adc_samples(bus,buf);

	for (i = 0; i < samples; i++) {
		//printf("Sample %d: 0x%04X\n", i, short_buf[i]);
		printf("%f\n", buf[i]);
	}

	return 0;
}




