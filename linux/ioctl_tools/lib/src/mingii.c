
#include <stdlib.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

#define GORDON_INCLUDE_US_DEFS
#include "mingii_driver.h"
#include "mingii.h"
#include <sys/ioctl.h>

int gordon;

struct ftl_tag_status {
	u64 tags;
};

unsigned short gain_array[16] = {0, 1, 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 64, 96, 128, 0};

u16 send_message(struct ftl_char_message* msg)
{
	return ioctl(gordon, FTL_IOCTL_DO_OPERATION, msg);
}

void get_status(struct ftl_tag_status* stat)
{
	ioctl(gordon, FTL_IOCTL_TAGS, stat);
}

void print_registers()
{
	ioctl(gordon, FTL_IOCTL_PRINT_REGISTERS, NULL);
}

void set_active_tag(u16 tag)
{
	ioctl(gordon, FTL_IOCTL_SET_ACTIVE_TAG, tag);
}

int wait_done(u16 tag)
{
	int loops = 0;
        struct ftl_tag_status stat;
        while(1) {
                get_status(&stat);
		//printf("Tags: 0x%16llu\n",stat.tags);
                if (!((stat.tags >> tag) & 0x1))
                        break;
                loops++;
        }
	return loops;
}

u32 get_chip_exists(u8 bus)
{
	u16 exists;
	ioctl(gordon, FTL_IOCTL_GET_CHIP_EXISTS, &exists);

	return exists;	
}

void set_cyclecount_points(u8 start, u8 end, u8 bus)
{
	char buf[3];
	buf[0] = start;
	buf[1] = end;
	buf[2] = bus;
	ioctl(gordon, FTL_IOCTL_SET_CYCLECOUNT_PARAMS, buf);
}

void reset_cyclecount(u8 bus)
{
	char buf[1];
	buf[0] = bus;
	ioctl(gordon, FTL_IOCTL_RESET_CYCLECOUNT, buf);
}

u32 get_cyclecount(u8 bus)
{
	char* buf;
	u32 ret;
	buf = (char*)(&ret);
	buf[0] = bus;
	buf[1] = bus;
	buf[2] = bus;
	buf[3] = bus;
	ioctl(gordon, FTL_IOCTL_GET_CYCLECOUNT, buf);
	
	return ret;
}

void set_timings(u8 WriteLow, u8 WriteHigh, u8 ReadLow, u8 ReadHigh)
{
	char buf[16];
	buf[0] = WriteLow;
	buf[1] = WriteHigh;
	buf[2] = ReadLow;
	buf[3] = ReadHigh;
	buf[4] = WriteLow;
	buf[5] = WriteHigh;
	buf[6] = ReadLow;
	buf[7] = ReadHigh;
	buf[8] = WriteLow;
	buf[9] = WriteHigh;
	buf[10] = ReadLow;
	buf[11] = ReadHigh;
	buf[12] = WriteLow;
	buf[13] = WriteHigh;
	buf[14] = ReadLow;
	buf[15] = ReadHigh;
	ioctl(gordon, FTL_IOCTL_SET_TIMINGS, buf);
}

u16 gordon_send_adc_command(u8 chip, u8 channel, u16 message)
{
	struct ftl_adc_command cmd;
	cmd.chip = chip;
	cmd.channel = channel;
	cmd.message = message;
	ioctl(gordon, FTL_IOCTL_SEND_ADC_COMMAND, &cmd);
	return cmd.response; 
}

void gordon_calib_adc()
{
	u16 gain;
	u8 gain_index;
	u8 cal_iterations = 10;
	u8 i, j;

	// Convert the gain to an index
	gain = gordon_get_adc_gain();	
	for (gain_index = 0; gain_index < 16; gain_index++) {
		if (gain_array[gain_index] == gain) break;	
	}

	for (i = 0; i < 2; i++) {
		for (j = 0; j < cal_iterations; j++) {
			// Turn on calibration
			gordon_send_adc_command(i, 0, 0x1190|(gain_index&0xF));
		}

		// Turn off calibration
		gordon_send_adc_command(i, 0, 0x1110|(gain_index&0xF));
		
		// Do one more conversion to clear out old samples
		gordon_send_adc_command(i, 0, 0x1110|(gain_index&0xF));
	}
}

void gordon_set_adc_gain(u8 gain)
{
	char buf[1];
	buf[0] = gain;
	ioctl(gordon, FTL_IOCTL_SET_ADC_GAIN, buf);
}

u16 gordon_get_adc_gain()
{
	u8 gain_index;
	ioctl(gordon, FTL_IOCTL_GET_ADC_GAIN, &gain_index);
	return gain_array[gain_index];
}

void gordon_enable_adc_recording(u8 bus)
{
	char buf[1];
	buf[0] = bus;
	ioctl(gordon, FTL_IOCTL_ENABLE_ADC_RECORDING, buf);
}

void gordon_disable_adc_recording(u8 bus)
{
	char buf[1];
	buf[0] = bus;
	ioctl(gordon, FTL_IOCTL_DISABLE_ADC_RECORDING, buf);
}

u32 gordon_bus_chips(u8 bus)
{
	return get_chip_exists(bus);
}

u32 gordon_get_cyclecount(u8 bus)
{
	return get_cyclecount(bus);
}

void gordon_reset_cyclecount(u8 bus)
{
	reset_cyclecount(bus);
}

void gordon_set_cyclecount_points(u8 start, u8 end, u8 bus)
{
	set_cyclecount_points(start,end, bus);
}

void gordon_set_timings(u8 WriteLow, u8 WriteHigh, u8 ReadLow, u8 ReadHigh)
{
	set_timings(WriteLow, WriteHigh, ReadLow, ReadHigh);
}

int gordon_chip_exists(u8 bus, u8 chip)
{
	u32 chips = get_chip_exists(bus);
	return ((chips >> (31-chip)) & 0x1);
}

int gordon_wait(u16 tag)
{
	int loops;
	loops = wait_done(tag);
	return loops;
}

int gordon_tag_busy(u16 tag)
{
	struct ftl_tag_status stat;
	get_status(&stat);
	return (((stat.tags >> tag) & 0x1));
}

u32 gordon_bus_busy(u8 bus)
{
	// TODO (TB): Modify this to use the bus busy signal from the version/status register
	struct ftl_tag_status stat;
	get_status(&stat);
	return stat.tags;
}

void gordon_reset()
{
	struct ftl_char_message msg;
	msg.operation = FTL_OP_CTRL_RESET;
	send_message(&msg);
	sleep(10);
}

u16 gordon_chip_reset(u8 bus, u8 chip)
{	
	struct ftl_char_message msg;
	msg.bus = bus;
	msg.chip = chip;
	msg.operation = FTL_OP_CHIP_RESET;
	msg.chipaddr[0] = 0;
	msg.chipaddr[1] = 0;
	msg.chipaddr[2] = 0;
	msg.chipaddr[3] = 0;
	msg.chipaddr[4] = 0;
	msg.length = 0;
	msg.priority = 0;
	return send_message(&msg);
}

void gordon_chip_reset_wait(u8 bus, u8 chip)
{
	u16 tag = gordon_chip_reset(bus,chip);
	gordon_wait(tag);
}

u16 gordon_erase(u8 bus, u8 chip, u32 page)
{	
	struct ftl_char_message msg;
	msg.bus = bus;
	msg.chip = chip;
	msg.operation = FTL_OP_ERASE;
	msg.chipaddr[0] = (page >> 16) & 0xff;
	msg.chipaddr[1] = (page >> 8) & 0xff;
	msg.chipaddr[2] = (page) & 0xff;
	msg.chipaddr[3] = 0;
	msg.chipaddr[4] = 0;
	msg.length = 0;
	msg.priority = 0;
	return send_message(&msg);
}

void gordon_erase_wait(u8 bus, u8 chip, u32 page)
{
	//int loops;
	u16 tag = gordon_erase(bus,chip,page);
	
	//loops = gordon_wait(tag);
	gordon_wait(tag);
	//printf("Erase took %d loops\n",loops);
}

u16 gordon_read_start(u8 bus, u8 chip, u32 page, u16 offset, u16 length)
{
	struct ftl_char_message msg;
	msg.bus = bus;
	msg.chip = chip;
	msg.operation = FTL_OP_READ;
	msg.chipaddr[0] = (page >> 16) & 0xff;
        msg.chipaddr[1] = (page >> 8) & 0xff;
        msg.chipaddr[2] = (page) & 0xff;
        msg.chipaddr[3] = (offset >> 8) & 0xff;
        msg.chipaddr[4] = (offset) & 0xff;
        msg.length = length;
        msg.priority = 0;
        return send_message(&msg);
}

void gordon_read_complete(u16 tag, u16 length, char* dest)
{
	set_active_tag(tag);
	read(gordon, dest, length);
}

unsigned int gordon_read_adc_samples(u8 bus, float* dest)
{
	u16 tag;
	u16 gain;
	struct ftl_char_message msg;
	u32 i;
	short sample; 
	char char_buf[16384];
	short *samples = (short*)char_buf;
	float lsb;

	// Send the request to read the samples	
	msg.bus = bus;
	msg.chip = 0;
	msg.operation = FTL_OP_GET_ADC_SAMPLES;
	msg.length = 0;
	tag = send_message(&msg);

	// Get the gain that the driver is using
	gain = gordon_get_adc_gain();	

	// Calculate the lsb
	lsb = 2*((2*(2.5/(2*gain)))/16384); // This is the LSB in volts
	lsb = lsb / (0.05); // This will give us amps, dividing by sense resistor of 50 mOhms

	// Wait for the read request to finish
	gordon_wait(tag);

	// Read the samples from the driver's buffer
	gordon_read_complete(tag,4*4096,char_buf);

	// Find out how many samples there are and then return that value
	for (i = 0; i < 8192; i++) {
		// Read the data
		sample = *(samples + i);
		
		if (sample == -1) {
			return i;
		//} else {
		//	printf("Sample %d: 0x%04X\n", i*2, firstSample);
		}

		// Check to see if the sample should be negative, and then make it negative
		sample = (sample & 0x200) ? sample|0xC000 : sample;
		
		// Convert samples to mA
		dest[i] = sample * lsb;
	}

	// Couldn't find the closing marker
	return -1;
}

void gordon_read_parampage(u8 bus, u8 chip, u16 length, char* dest)
{
	u16 tag;
	struct ftl_char_message msg;
	
	msg.bus = bus;
	msg.chip = chip;
	msg.operation = FTL_OP_READPARAM;
	msg.length = length;
	tag = send_message(&msg);
	gordon_wait(tag);
	gordon_read_complete(tag,length,dest);
}

void gordon_readid(u8 bus, u8 chip, unsigned char* dest)
{
	unsigned char buf[8];
	u16 tag;
	struct ftl_char_message msg;

	msg.bus = bus;
	msg.chip = chip;
	msg.operation = FTL_OP_READID;
	msg.length = 8;
	msg.priority = 0;
	tag = send_message(&msg);
	gordon_wait(tag);
	set_active_tag(tag);
	read(gordon,buf,8);
	dest[0] = buf[0];
	dest[1] = buf[1];
	dest[2] = buf[2];
	dest[3] = buf[3];
	dest[4] = buf[4];
}

void gordon_read_wait(u8 bus, u8 chip, u32 page, u16 offset, u16 length, char* dest)
{
	//int loops;
	u16 tag = gordon_read_start(bus,chip,page,offset,length);
	
	//loops = gordon_wait(tag);
	gordon_wait(tag);
	//printf("Read took %d loops\n",loops);
	
	gordon_read_complete(tag,length,dest);
}


u16 gordon_write(u8 bus, u8 chip, u32 page, u16 offset, u16 length, const char* src)
{
	u16 tag;
	struct ftl_char_message msg;
	msg.bus = bus;
        msg.chip = chip;
        msg.operation = FTL_OP_WRITE;
        msg.chipaddr[0] = (page >> 16) & 0xff;
        msg.chipaddr[1] = (page >> 8) & 0xff;
        msg.chipaddr[2] = (page) & 0xff;
        msg.chipaddr[3] = (offset >> 8) & 0xff;
        msg.chipaddr[4] = (offset) & 0xff;
        msg.length = length;
        msg.priority = 0;
        tag = send_message(&msg);

	write(gordon, src, length);

	return tag;
}
void gordon_write_wait(u8 bus, u8 chip, u32 page, u16 offset, u16 length, const char* src)
{
	u16 tag = gordon_write(bus,chip,page,offset,length,src);
	int loops;
	loops = gordon_wait(tag);
	//printf("Write took %d loops\n",loops);		
}

u16 gordon_twoplane_erase(u8 bus, u8 chip, u32 page, u32 page2)
{	
	struct ftl_char_message msg;
	msg.bus = bus;
	msg.chip = chip;
	msg.operation = FTL_OP_TWOPLANEERASE;
	msg.chipaddr[0] = (page >> 16) & 0xff;
	msg.chipaddr[1] = (page >> 8) & 0xff;
	msg.chipaddr[2] = (page) & 0xff;
	msg.chipaddr[3] = 0;
	msg.chipaddr[4] = 0;
	msg.chipaddr2[0] = (page2 >> 16) & 0xff;
	msg.chipaddr2[1] = (page2 >> 8) & 0xff;
	msg.chipaddr2[2] = (page2) & 0xff;
	msg.chipaddr2[3] = 0;
	msg.chipaddr2[4] = 0;
	msg.length = 0;
	msg.priority = 0;
	return send_message(&msg);
}

void gordon_twoplane_erase_wait(u8 bus, u8 chip, u32 page, u32 page2)
{
	u16 tag = gordon_twoplane_erase(bus,chip,page, page2);
	int loops;
	loops = gordon_wait(tag);
	//printf("Erase took %d loops\n",loops);
}

u16 gordon_twoplane_read_start(u8 bus, u8 chip, u32 page, u16 offset, u32 page2, u16 offset2, u16 length)
{
	struct ftl_char_message msg;
	msg.bus = bus;
	msg.chip = chip;
	msg.operation = FTL_OP_TWOPLANEREAD;
	msg.chipaddr[0] = (page >> 16) & 0xff;
	msg.chipaddr[1] = (page >> 8) & 0xff;
	msg.chipaddr[2] = (page) & 0xff;
	msg.chipaddr[3] = (offset >> 8) & 0xff;
	msg.chipaddr[4] = (offset) & 0xff;
	msg.chipaddr2[0] = (page2 >> 16) & 0xff;
	msg.chipaddr2[1] = (page2 >> 8) & 0xff;
	msg.chipaddr2[2] = (page2) & 0xff;
	msg.chipaddr2[3] = (offset2 >> 8) & 0xff;
	msg.chipaddr2[4] = (offset2) & 0xff;
	msg.length = length;
	msg.priority = 0;
	return send_message(&msg);
	
}

void gordon_twoplane_read_complete(u16 tag, u16 length, char* dest)
{
	set_active_tag(tag);
	read(gordon, dest, length * 2);
}

void gordon_twoplane_read_wait(u8 bus, u8 chip, u32 page, u16 offset, u32 page2, u16 offset2, u16 length, char* dest)
{
	u16 tag = gordon_twoplane_read_start(bus,chip,page,offset,page2,offset2,length);
	int loops;
	loops = gordon_wait(tag);
	gordon_twoplane_read_complete(tag,length,dest);
	//printf("Read took %d loops\n",loops);
}


u16 gordon_twoplane_write(u8 bus, u8 chip, u32 page, u16 offset, u32 page2, u16 offset2, u16 length, const char* src)
{
	u16 tag;
	struct ftl_char_message msg;
	msg.bus = bus;
        msg.chip = chip;
        msg.operation = FTL_OP_TWOPLANEWRITE;
        msg.chipaddr[0] = (page >> 16) & 0xff;
        msg.chipaddr[1] = (page >> 8) & 0xff;
        msg.chipaddr[2] = (page) & 0xff;
        msg.chipaddr[3] = (offset >> 8) & 0xff;
        msg.chipaddr[4] = (offset) & 0xff;
        msg.chipaddr2[0] = (page2 >> 16) & 0xff;
        msg.chipaddr2[1] = (page2 >> 8) & 0xff;
        msg.chipaddr2[2] = (page2) & 0xff;
        msg.chipaddr2[3] = (offset2 >> 8) & 0xff;
        msg.chipaddr2[4] = (offset2) & 0xff;
        msg.length = length;
        msg.priority = 0;
        tag = send_message(&msg);

	write(gordon, src, length * 2);

	return tag;
}
void gordon_twoplane_write_wait(u8 bus, u8 chip, u32 page, u16 offset, u32 page2, u16 offset2, u16 length, const char* src)
{
	u16 tag = gordon_twoplane_write(bus,chip,page,offset,page2,offset2,length,src);
	int loops;
	loops = gordon_wait(tag);
	//printf("Write took %d loops\n",loops);		
}


int gordon_init()
{
	gordon = open("/dev/gordonchar0", O_RDWR);
	if (gordon==-1) return 1;
	return 0;
}

void gordon_close()
{
	if (gordon >= 0)
		close(gordon);
}


