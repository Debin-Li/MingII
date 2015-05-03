#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include "mingii.h"

int main(int argc, char** argv) {

	if (argc != 1) {
		fprintf(stderr,"%s\n",argv[0]);
		return -1;
	}

	if (gordon_init())
	{
		fprintf(stderr,"Error Opening Gordon Device\n");
		return -1;
	}


	gordon_calib_adc();

	return 0;
}




