#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

#include "mingii.h"

int main(int argc, char** argv) {

	if (argc != 1) {
		printf("%s\n",argv[0]);
		return -1;
	}

	if (gordon_init())
	{
		printf("Error Opening Gordon Device\n");
		return -1;
	}


	gordon_reset();

	return 0;
}




