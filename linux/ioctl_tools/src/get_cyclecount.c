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

	unsigned sum = gordon_get_cyclecount(bus);

	printf("Cycle Count Sum for Bus %d: %d\n", bus, sum);
	return 0;
}




