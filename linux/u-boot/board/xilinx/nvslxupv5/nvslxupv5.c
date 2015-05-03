/*
 * (C) Copyright 2007 Michal Simek
 *
 * Michal  SIMEK <monstr@monstr.eu>
 *
 * See file CREDITS for list of people who contributed to this
 * project.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 * MA 02111-1307 USA
 */

/* This is a board specific file.  It's OK to include board specific
 * header files */

#include <common.h>
#include <config.h>
#include <netdev.h>
#include <asm/microblaze_intc.h>
#include <asm/asm.h>
#include <i2c.h>

/*-----------------------------------------------------------------------------
 * aschex_to_byte --
 *-----------------------------------------------------------------------------
 */
static unsigned char aschex_to_byte (unsigned char *cp)
{
	u_char byte, c;

	c = *cp++;

	if ((c >= 'A') && (c <= 'F')) {
		c -= 'A';
		c += 10;
	} else if ((c >= 'a') && (c <= 'f')) {
		c -= 'a';
		c += 10;
	} else {
		c -= '0';
	}

	byte = c * 16;

	c = *cp;

	if ((c >= 'A') && (c <= 'F')) {
		c -= 'A';
		c += 10;
	} else if ((c >= 'a') && (c <= 'f')) {
		c -= 'a';
		c += 10;
	} else {
		c -= '0';
	}

	byte += c;

	return (byte);
}


void do_reset (void)
{
#ifdef CONFIG_SYS_GPIO_0
	*((unsigned long *)(CONFIG_SYS_GPIO_0_ADDR)) =
	    ++(*((unsigned long *)(CONFIG_SYS_GPIO_0_ADDR)));
#endif
#ifdef CONFIG_SYS_RESET_ADDRESS
	puts ("Reseting board\n");
	asm ("bra r0");
#endif
}

int gpio_init (void)
{
#ifdef CONFIG_SYS_GPIO_0
	*((unsigned long *)(CONFIG_SYS_GPIO_0_ADDR)) = 0xFFFFFFFF;
#endif
	return 0;
}

#ifdef CONFIG_SYS_FSL_2
void fsl_isr2 (void *arg) {
	volatile int num;
	*((unsigned int *)(CONFIG_SYS_GPIO_0_ADDR + 0x4)) =
	    ++(*((unsigned int *)(CONFIG_SYS_GPIO_0_ADDR + 0x4)));
	GET (num, 2);
	NGET (num, 2);
	puts("*");
}

int fsl_init2 (void) {
	puts("fsl_init2\n");
	install_interrupt_handler (FSL_INTR_2, fsl_isr2, NULL);
	return 0;
}
#endif

int board_eth_init(bd_t *bis)
{
	int ret = 0;

#ifdef CONFIG_XILINX_AXIEMAC
	ret |= xilinx_axiemac_initialize(bis, XILINX_AXIEMAC_BASEADDR);
#endif
#ifdef CONFIG_XILINX_EMACLITE
	ret |= xilinx_emaclite_initialize(bis, XILINX_EMACLITE_BASEADDR);
#endif
#ifdef CONFIG_XILINX_LL_TEMAC
	ret |= xilinx_ll_temac_initialize(bis, XILINX_LLTEMAC_BASEADDR);
#endif
	return ret;
}

/*-----------------------------------------------------------------------------
 * board_get_enetaddr -- Read the MAC Address in the I2C EEPROM
 *-----------------------------------------------------------------------------
 */
void board_get_enetaddr (uchar * enet)
{
	int i;
	char buff[12];

	/* read the mac address from the i2c eeprom, the address 0x37
	   appears to be off by 1 according to factory documentation,
	   but not according to contents read?
	*/

	i2c_read(0x50, 0x37, 1, buff, 12);

	/* if the emac address in the i2c eeprom is not valid, then
	   then initialize it to a valid address, all xilinx addresses
	   have a known 1st several digits
	*/
	if ((buff[0] != 0x30) || (buff[1] != 0x30) || (buff[2] != 0x30) ||
	    (buff[3] != 0x41) || (buff[4] != 0x33) || (buff[5] != 0x35))
	{
		enet[0] = 0x00;
		enet[1] = 0x0A;
		enet[2] = 0x35;
		enet[3] = 0x01;
		enet[4] = 0x02;		
		enet[5] = 0x03;
		printf("MAC address not valid from I2C EEPROM, set to default\n");
	}
	else
	{
		/* convert the mac address from i2c eeprom from ascii hex to 
		   binary */

		for (i = 0; i < 6; i++) {
			enet[i] = aschex_to_byte ((unsigned char *)&buff[i*2]);
		}
		printf("MAC address valid from I2C EEPROM\n");
	}

	printf ("MAC address: %02x:%02x:%02x:%02x:%02x:%02x\n",
		enet[0], enet[1], enet[2], enet[3], enet[4], enet[5]);

	return;
}