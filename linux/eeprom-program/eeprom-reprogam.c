/* eeprom-reprogram: program to restore eeprom on XUPv5 boards */
/* revision history
   3/4/2011	mwei	first release
*/

#include <stdio.h>
#include <errno.h>

int main()
{
	//load hex into memory
	FILE* pFile = fopen("xupv5.hex", "r");
	if (pFile == NULL)
	{
		fprintf(stderr, "Couldn't open EEPROM hex xupv5.hex: please make sure it is in the same directory!\n");
		return ENOENT;
	}
	
	char buffer[256];
	fread(buffer, 256, 1, pFile); 
	fclose(pFile);
	
	char macaddress[12];
	char docontinue[2];
	docontinue[0] = 0;
	do
	{
		//ask for what the new mac address should be
		printf("Please enter the MAC address of this board in ABCDEF123456 format.");
		scanf("%12s", macaddress);
	
		printf("You entered MAC address: %s, is this correct?");
		fgets(docontinue, 2, stdin);
	}
	while (docontinue[0] != 'y' && docontinue[0] != 'Y');
}