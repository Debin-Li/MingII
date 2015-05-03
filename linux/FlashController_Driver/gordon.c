#undef DEBUG

#include <linux/module.h>
#include <linux/ctype.h>
#include <linux/init.h>
#include <linux/interrupt.h>
#include <linux/errno.h>
#include <linux/kernel.h>
#include <linux/delay.h>
#include <linux/slab.h>
//#include <linux/blkdev.h>
//#include <linux/hdreg.h>
#include <linux/platform_device.h>
#include <linux/dma-mapping.h>
//#include <linux/genhd.h>
#include <linux/types.h>

//for char device:
#include <linux/fs.h>
#include <asm/uaccess.h>

#include "gordon.h"

static int ftl_char_open(struct inode*, struct file*);
static int ftl_char_close(struct inode*, struct file*);
static ssize_t ftl_char_read(struct file*, char*, size_t, loff_t*);
static ssize_t ftl_char_write(struct file*, const char*, size_t, loff_t*);
static long ftl_char_ioctl(struct file*, unsigned int ioctl_num, unsigned long ioctl_param);
static struct file_operations fops = {
	.read = ftl_char_read,
	.write = ftl_char_write,
	.open = ftl_char_open,
	.release = ftl_char_close,
	.unlocked_ioctl = ftl_char_ioctl
};

static struct class *ftl_char_class;

struct char_priv_data {
	struct ftl_device* ftl;
	u8 free;
	u16 act_tag;
	u8 buf;
};

static struct char_priv_data chardata[10];

//for block device:
MODULE_AUTHOR("Adrian Caulfield <acaulfie@cs.ucsd.edu> & Trevor Bunker <tbunker@cs.ucsd.edu>");
MODULE_DESCRIPTION("Flash Translation Layer char device driver version 2");
MODULE_LICENSE("GPL");

#define FTL_NUM_BUSES 4
#define FTL_NUM_CHIPS_PER_BUS 4
#define FTL_NUM_CHIPS (FTL_NUM_BUSES * FTL_NUM_CHIPS_PER_BUS)
#define FTL_NUM_TAGS 64
#define FTL_BUFFER_SPACE (16*1024)

/* FTL Registers */
#define FTL_REG_COMMAND	         (0x00)
#define FTL_REG_ADC_RSP          (0x10) // Read address
#define FTL_REG_STATUS		 (0x14)
#define FTL_REG_ADC_CMD          (0x18) // Write address
#define FTL_REG_TAG		 (0x18) // Read address, 2 32-bit registers
#define FTL_REG_ADC_SETTINGS     (0x20)
#define FTL_REG_CYCLECOUNT_SET	 (0x24)
#define FTL_REG_CYCLECOUNT_RESET (0x2C) // Write Address
#define FTL_REG_CYCLECOUNT	 (0x2C) // Read, 4 32-bit registers
#define FTL_REG_DEBUG            (0x3C)

#define FTL_REG_SW_RESET (0x200)

#define FTL_REG_INT_ISR	 (0x320)
#define FTL_REG_INT_IER  (0x328)
#define FTL_REG_INT_GIER (0x31C)

#define FTL_NUM_MINORS 16

struct ftl_request_info {
        //values written to device
        u8 chip;
        u8 bus;
        u8 operation;
        u8 chipaddr[5];
        //u8 chipaddr2[5];
        u32 ramaddr;
        void *cpuaddr;
        u16 length;
        //u8 priority;
	u8 tag;
        //u8 result;
};

struct ftl_device {
	/* driver state data */
	int id;
	struct device *dev;
	int users;
	
	u16 free_list[FTL_NUM_TAGS];        
	u16 free_list_tail_index;
	u16 free_list_head_index;

	/* Details of hardware device */
	unsigned long physaddr;
	void __iomem *baseaddr;
	int irq;

	spinlock_t lock;

	u64 tags_last;
	u64 tags;

	u32 chip_exists;

	struct ftl_request_info chip_request[FTL_NUM_TAGS];

	int char_open_count;

	//u8	timings[16];
	u8	cyclecount_start[4];
	u8	cyclecount_end[4];

	u8 adc_gain;
	u8 adc_recording_en[FTL_NUM_BUSES];
};

//ftl_char variables
static int ftl_char_major = FTL_CHAR_MAJOR_NUM;
static struct ftl_device* ftl_char_blk_dev_struct;

/* Command Read/Write Functions */
static void ftl_write_timings(struct ftl_device* ftl)
{
	printk(KERN_INFO "Writing timings not supported.");
}

static void ftl_set_timing(struct ftl_device* ftl,
u8 bus0WriteLow, u8 bus0WriteHigh, u8 bus0ReadLow, u8 bus0ReadHigh,
u8 bus1WriteLow, u8 bus1WriteHigh, u8 bus1ReadLow, u8 bus1ReadHigh,
u8 bus2WriteLow, u8 bus2WriteHigh, u8 bus2ReadLow, u8 bus2ReadHigh,
u8 bus3WriteLow, u8 bus3WriteHigh, u8 bus3ReadLow, u8 bus3ReadHigh)
{
	printk(KERN_INFO "Setting timings not supported.");
}

static void ftl_write_command(struct ftl_device* ftl, struct ftl_request_info* req)
{
	u32 com0;
        u32 com1;
	u32 com2;
	u32 com3;
	u32 length;
	u32 __iomem *d;
        
        // Requests are in terms of 32 B
	if (req->length & 0x1F) {
		length = (req->length >> 5) + 1;
        } else {
		length = req->length >> 5;
        }

	com0 = (u32)req->ramaddr;
	
	com1 = (req->bus & 0xF) << 28;
	com1 = com1 | ((req->chip & 0xF) << 24);
	com1 = com1 | (req->chipaddr[0] << 16);
	com1 = com1 | (req->chipaddr[1] << 8);
	com1 = com1 | (req->chipaddr[2] << 0);
	
	com2 = req->chipaddr[3] << 24;
	com2 = com2 | (req->chipaddr[4] << 16);
	com2 = com2 | ((req->operation & 0xF) << 12);
        com2 = com2 | (length & 0x3FF);

	com3 = (req->tag & 0x3F) << 26;

	d = ftl->baseaddr + FTL_REG_COMMAND;
	out_be32(d++,com0);//0
	out_be32(d++,com1);//4
	out_be32(d++,com2);//8
	out_be32(d++,com3);//12
	out_be32(d,1);//16
}

//static void ftl_read_command(struct ftl_device* ftl, struct ftl_request_info* req)
//{
//	u32 __iomem *d = ftl->baseaddr + FTL_REG_COMMAND;
//	u32 com0;
//	u32 com1;
//	u32 com2;
//	u32 com3;
//
//	com0 = in_be32(d++);
//	com1 = in_be32(d++);
//	com2 = in_be32(d++);
//	com3 = in_be32(d++);
//
//	req->bus = (com1 >> 28) & 0xf;
//	req->chip = (com1 >> 24) & 0xf;
//	req->operation = (com2 >> 12) & 0xf;
//	req->length = com2 & 0x3ff;
//	req->ramaddr = com0;
//	req->chipaddr[0] = (com1 >> 16) & 0xff;
//	req->chipaddr[1] = (com1 >> 8) & 0xff;
//	req->chipaddr[2] = com1 & 0xff;
//	req->chipaddr[3] = (com2 >> 24) & 0xff;
//	req->chipaddr[4] = (com2 >> 16) & 0xff;
//	req->tag = (com3 >> 26) & 0x3f;
//}

static void ftl_print_registers(struct ftl_device* ftl)
{
	u32 i;
	u32 com;
	u32 __iomem *d;

	d = ftl->baseaddr;
	
	printk(KERN_INFO "Begin Slave Registers\n");
	for (i = 0; i < 16; i++) {
		com = in_be32(d++);
		printk(KERN_INFO "Register[%d]: %08X\n", i, com);
	}
	
	printk(KERN_INFO "Begin Interrupt Controller Registers\n");
	printk(KERN_INFO "ISR: %08X\n", in_be32(ftl->baseaddr + FTL_REG_INT_ISR));
	printk(KERN_INFO "IER: %08X\n", in_be32(ftl->baseaddr + FTL_REG_INT_IER));
	printk(KERN_INFO "GIER: %08X\n", in_be32(ftl->baseaddr + FTL_REG_INT_GIER));
}

static void ftl_reset_cyclecount(struct ftl_device* ftl, u8 bus)
{
	u32 __iomem *d = ftl->baseaddr + FTL_REG_CYCLECOUNT_RESET;
	u32 val = 0x1 << bus;
	out_be32(d, val);	
}

static void ftl_set_cyclecount_params(struct ftl_device* ftl, u8 start, u8 end, u8 bus)
{
	int b;
	u32 __iomem * d;
	u32 params = 0;
	
	d = ftl->baseaddr + FTL_REG_CYCLECOUNT_SET;

	ftl->cyclecount_start[bus] = start;
	ftl->cyclecount_end[bus] = end;

	for(b=1; b>=0; b--) {
		params = params << 8;
		params = params | (ftl->cyclecount_start[b] & 0xff);
		params = params << 8;
		params = params | (ftl->cyclecount_end[b] & 0xff);
	}

	out_be32(d++, params);
	
	for(b=3; b>=2; b--) {
		params = params << 8;
		params = params | (ftl->cyclecount_start[b] & 0xff);
		params = params << 8;
		params = params | (ftl->cyclecount_end[b] & 0xff);
	}
	
	out_be32(d, params);
}

static u32 ftl_get_cyclecount(struct ftl_device* ftl, u8 bus)
{
	u32 __iomem *d = ftl->baseaddr + FTL_REG_CYCLECOUNT;
	d += bus; // Moving in 32-bit increments
	return in_be32(d);	
}


static u8 ftl_get_version(struct ftl_device *ftl)
{
        u32 __iomem *d = ftl->baseaddr + FTL_REG_STATUS;
	return (u8)((in_be32(d) >> 28) & 0x0000000f);
}

static u8 ftl_device_ready(struct ftl_device *ftl)
{
	u32 __iomem *d = ftl->baseaddr + FTL_REG_STATUS;
	dev_info(ftl->dev, "Bus Status: 0x%x\n",((in_be32(d) >> 24) & 0x0000000f));
	return ((u8)((in_be32(d) >> 24) & 0x0000000f)) ;
}

static u64 in_be64(u8* addr)
{
	u32* a = (u32*)addr;
	u64 temp1;
	u64 temp2;
	temp1 = in_be32(a);
	temp2 = in_be32(a + 1);
	return (temp2 << 32) | temp1;
}

//static void ftl_print_tags(struct ftl_device* ftl)
//{
//	printk(KERN_INFO "gordon: tag: 0x%.16llx\n", ftl->tags);
//	printk(KERN_INFO "gordon: last_tag: 0x%.16llx\n", ftl->tags_last);
//}

static void ftl_update_tags(struct ftl_device* ftl)
{
        ftl->tags_last |= ftl->tags;
	ftl->tags = in_be64(ftl->baseaddr + FTL_REG_TAG);
        //ftl_print_tags(ftl);
}

static void ftl_update_chip_exists(struct ftl_device* ftl)
{
	u32 __iomem *d = ftl->baseaddr + FTL_REG_STATUS;
	ftl->chip_exists = (u32)((in_be32(d) >> 8) & 0xffff);
}

static void ftl_do_reset(struct ftl_device* ftl)
{
	out_be32(ftl->baseaddr + FTL_REG_SW_RESET, 0xA);
}

static void ftl_clear_interrupt(struct ftl_device* ftl)
{
	//toggle user interrupt
	out_be32(ftl->baseaddr + FTL_REG_INT_ISR, 0x1);
}

static void ftl_enable_interrupt(struct ftl_device *ftl)
{
	//enable user ip interrupt
	out_be32(ftl->baseaddr + FTL_REG_INT_IER, 0x1);
	
	//global interrupt enable
	out_be32(ftl->baseaddr + FTL_REG_INT_GIER, (0x1 << 31));
	
	dev_info(ftl->dev,"interrupt enabled.\n");
}

static void ftl_disable_interrupt(struct ftl_device *ftl)
{
	out_be32(ftl->baseaddr + FTL_REG_INT_GIER, 0x0);
	out_be32(ftl->baseaddr + FTL_REG_INT_IER, 0x0);
	dev_info(ftl->dev,"interrupt disabled.\n");
}

//static void ftl_print_request_info(struct ftl_request_info* req)
//{
//	
//	printk(KERN_INFO "gordon: Bus: %i, Chip: %i, Operation: %i, Tag: %i\n"
//		         "ChipAddr: 0x%.2x%.2x%.2x%.2x%.2x, RamAddr: 0x%.8x, Length: 0x%.4x, Result: %i\n",
//	req->bus, req->chip, req->operation, req->tag,
//	req->chipaddr[0],req->chipaddr[1],req->chipaddr[2],req->chipaddr[3],req->chipaddr[4], 
//	(u32)req->ramaddr, req->length, req->result);
//}

static void ftl_print_chip_exists(struct ftl_device* ftl)
{
        printk(KERN_INFO "gordon: bus0 chipexists: 0x%.1x  bus1 chipexists: 0x%.1x\n"
                         "        bus2 chipexists: 0x%.1x  bus3 chipexists: 0x%.1x\n",
                        (ftl->chip_exists & 0xF), (ftl->chip_exists >> 4) & 0xF, (ftl->chip_exists >> 8) & 0xF, (ftl->chip_exists >> 12) & 0xF);
}

static void ftl_set_tag(struct ftl_device *ftl, int bus, int tag)
{
	u64 one = 0x1;
	u64 bit = one << tag;
	ftl->tags |= bit;
}

static void ftl_send_adc_command(struct ftl_device *ftl, struct ftl_adc_command *cmd)
{
	u32 data;
        
	data = (u32)(((cmd->chip & 0x1) << 17) | ((cmd->channel & 0x1) << 16) | (cmd->message & 0xFFFF));
	
	// Send the command to the device
	out_be32(ftl->baseaddr + FTL_REG_ADC_CMD,data);

	// Need to wait some time before checking for a response
	udelay(1);

	// Get the response if it was a read
	cmd->response = in_be32(ftl->baseaddr + FTL_REG_ADC_RSP);
}

static void ftl_write_adc_settings(struct ftl_device *ftl)
{
	u32 data;
       	u32 i;
 
	data = (u32)((ftl->adc_gain & 0xF) << 4);

	for (i = 0; i < FTL_NUM_BUSES; i++) {
		data = data | ((ftl->adc_recording_en[i] & 0x1) << i);
	}
	
	out_be32(ftl->baseaddr + FTL_REG_ADC_SETTINGS,data);
}

static void ftl_set_adc_gain(struct ftl_device *ftl, u8 gain)
{
	ftl->adc_gain = gain;
	ftl_write_adc_settings(ftl);
}

static void ftl_enable_adc_recording(struct ftl_device *ftl, u8 bus)
{
	ftl->adc_recording_en[bus] = 1;
	ftl_write_adc_settings(ftl);
} 

static void ftl_disable_adc_recording(struct ftl_device *ftl, u8 bus)
{
	ftl->adc_recording_en[bus] = 0;
	ftl_write_adc_settings(ftl);
} 

static void ftl_fsm_dostate(struct ftl_device *ftl)
{
	int tag;
	int bit;
	//struct ftl_request_info* creq;
	u64 changed;
	u64 one = 0x1;
	
	//get chip busy registers
	ftl_update_tags(ftl);

        //find all chips which changed from busy to not busy
        changed = (ftl->tags ^ ftl->tags_last) & ftl->tags_last;
        
        if (changed != 0) {
            for (tag = 0; tag < 64; tag++) {
                // Check to see if this tag just finished
                bit = changed & 0x1;
                if (bit) {
                    //unset busy bit when we've processed this chip
                    ftl->tags_last = ftl->tags_last ^ (one << tag);

		    // Add the tag back to the free list
                    ftl->free_list[(ftl->free_list_tail_index++ % FTL_NUM_TAGS)] = tag;
                    
	            //creq = &ftl->chip_request[tag];
                }				
                
                // Shift to check the next tag
                changed = changed >> 1;
            }
        }
}

/* ---------------------------------------------------------------------
 * Interrupt handling routines
 */
static irqreturn_t ftl_interrupt(int irq, void *dev_id)
{
	struct ftl_device *ftl = dev_id;

	/* be safe and get the lock */
	spin_lock(&ftl->lock);

	ftl_clear_interrupt(ftl);

	/* Loop over state machine until told to stop */
        ftl_fsm_dostate(ftl);

	/* done with interrupt; drop the lock */
	spin_unlock(&ftl->lock);

	return IRQ_HANDLED;
}

static int __devinit ftl_setup(struct ftl_device *ftl)
{
	u16 version;
	int rc;
	int cr;
	int j;

	printk(KERN_INFO "ftl_setup(ftl=0x%p)\n", ftl);
	printk(KERN_INFO "physaddr=0x%lx irq=%i\n", ftl->physaddr, ftl->irq);

	spin_lock_init(&ftl->lock);

	/*
	 * Map the device
	 */
	ftl->baseaddr = ioremap_nocache(ftl->physaddr, 0x400);
	if (!ftl->baseaddr)
		goto err_ioremap;

	for (cr = 0; cr < FTL_NUM_TAGS; cr++) {
		ftl->chip_request[cr].chip = 0;
	}
	
	// Reset the flash controller
	ftl_do_reset(ftl);

	/* Make sure version register is sane */
	version = ftl_get_version(ftl);
	if (version == 0) {
		printk(KERN_INFO "Gordon Version Reported: %d -- Erroring\n",version);
		goto err_read;
	}

	// Set default ADC settings
	ftl_set_adc_gain(ftl,1);
	for (j = 0; j < FTL_NUM_BUSES; j++) {
		ftl_disable_adc_recording(ftl,j);
	}

	/* Now we can hook up the irq handler */
        rc = request_irq(ftl->irq, ftl_interrupt, 0, "gordon", ftl);
        if (rc) {
                /* Failure */
                dev_err(ftl->dev, "request_irq failed\n");
                goto err_read;
        }
	
        /* Enable interrupts */
        ftl_enable_interrupt(ftl);
	
	/* Print the identification */
	dev_info(ftl->dev, "hardware FTL revision %i at physaddr 0x%lx, mapped to 0x%p, irq=%i\n", version,ftl->physaddr,ftl->baseaddr,ftl->irq);

	while (ftl_device_ready(ftl) != 0);
	
        dev_info(ftl->dev, "controller initialization complete\n");

	ftl_update_chip_exists(ftl);
	ftl_update_tags(ftl);

	if (ftl->chip_exists == 0) {
		dev_info(ftl->dev, "No flash chips detected.\n");
	}
	
	ftl_print_chip_exists(ftl);

	for (j = 0; j < FTL_NUM_TAGS; j++)
	{
		ftl->chip_request[j].cpuaddr = dma_alloc_coherent(ftl->dev,FTL_BUFFER_SPACE,&ftl->chip_request[j].ramaddr,GFP_KERNEL);	
		if (ftl->chip_request[j].cpuaddr == 0) 
			dev_warn(ftl->dev, "unable to allocate DMA memory for tag %d\n", j);
	}
        
        // Setup the free tag list after allocating some memory for it
        for (j = 0; j < FTL_NUM_TAGS; j++) {
            ftl->free_list[j] = j;  
        }
        ftl->free_list_head_index = 0;
        ftl->free_list_tail_index = FTL_NUM_TAGS;

	//set variable so char device can access device structure
	ftl_char_blk_dev_struct = ftl;

	for(j=0; j<10; j++)
		chardata[j].free = 1;

	return 0;

err_read:
	printk("err_read\n");
	iounmap(ftl->baseaddr);
err_ioremap:
	dev_info(ftl->dev, "error initializing device at 0x%lx\n",ftl->physaddr);
	return -ENOMEM;
}

static void __devexit ftl_teardown(struct ftl_device *ftl)
{
	int j;
	
        ftl_disable_interrupt(ftl);
        free_irq(ftl->irq, ftl);

	for (j = 0; j < FTL_NUM_TAGS; j++) {
            dma_free_coherent(ftl->dev, FTL_BUFFER_SPACE, ftl->chip_request[j].cpuaddr, ftl->chip_request[j].ramaddr);	
	}

	iounmap(ftl->baseaddr);
}

static int __devinit ftl_alloc(struct device *dev, int id, unsigned long physaddr, int irq)
{
	struct ftl_device *ftl;
	int rc;
	dev_dbg(dev, "ftl_alloc(%p)\n", dev);

	if (!physaddr) {
		rc = -ENODEV;
		goto err_noreg;
	}

	/* Allocate and initialize the ftl device structure */
	ftl = kzalloc(sizeof(struct ftl_device), GFP_KERNEL);
	if (!ftl) {
		rc = -ENOMEM;
		goto err_alloc;
	}

	ftl->dev = dev;
	ftl->id = id;
	ftl->physaddr = physaddr;
	ftl->irq = irq;

	/* Call the setup code */
	rc = ftl_setup(ftl);
	if (rc)
		goto err_setup;

	dev_set_drvdata(dev, ftl);
	return 0;

err_setup:
	dev_err(dev, "err_setup\n");
	dev_set_drvdata(dev, NULL);
	kfree(ftl);
err_alloc:
	dev_err(dev, "err_alloc\n");
err_noreg:
	dev_err(dev, "could not initialize device, err=%i\n", rc);
	return rc;
}

static void __devexit ftl_free(struct device *dev)
{
	struct ftl_device *ftl = dev_get_drvdata(dev);
	dev_dbg(dev, "ftl_free(%p)\n", dev);

	if (ftl) {
		ftl_teardown(ftl);
		dev_set_drvdata(dev, NULL);
		kfree(ftl);
	}
}

/* ---------------------------------------------------------------------
 * Platform Bus Support
 */

static int __devinit ftl_probe(struct platform_device *dev)
{
	unsigned long physaddr = 0;
	int id = dev->id;
	int irq = 0;
	int i = 0;
	struct resource *rsc;

	dev_dbg(&dev->dev, "ftl_probe(%p)\n", dev);

	printk(KERN_INFO "Matched %d devices\n", dev->num_resources);	

	// Get the physical address of the device
	rsc = platform_get_resource(dev, IORESOURCE_MEM, 0);
	if (!rsc) {
	    printk(KERN_INFO "FAILURE! Didn't find a base address for device %d.\n", i);
	} else {
		// You can use the commented line to hard code the physical address
		//physaddr = 0x85E00000;
		physaddr = rsc->start;
	}

	// Check for an interrupt number
	rsc = platform_get_resource(dev, IORESOURCE_IRQ, 0);
	if (!rsc) {
	    printk(KERN_INFO "FAILURE! Didn't find an interrupt for device %d.\n", i);
	} else {
	    irq = rsc->start;
	}

	/* Call the bus-independant setup code */
	return ftl_alloc(&dev->dev, id, physaddr, irq);
}

/*
 * Platform bus remove() method
 */
static int __devexit ftl_remove(struct platform_device *dev)
{
	ftl_free(&dev->dev);
	return 0;
}

static struct of_device_id ftl_of_match[] __devinitdata = {
        { .compatible = "xlnx,flash-controller-1.03.a", },
        {}
};

MODULE_DEVICE_TABLE(of, ftl_of_match);

static struct platform_driver ftl_platform_driver = {
	.probe = ftl_probe,
	.remove = __devexit_p(ftl_remove),
	.driver = {
		.owner = THIS_MODULE,
		.name = "gordon",
                .of_match_table = ftl_of_match,
	},
};


//--------------------------------------------------------------------
//char device code

static int ftl_char_open(struct inode *inode, struct file *file)
{
	int i;
	struct ftl_device* ftl = ftl_char_blk_dev_struct;
	
	if (ftl->char_open_count == 10) return -1;
	ftl->char_open_count++;
	
	for (i = 0; i < 10; i++)
	{
		if (chardata[i].free == 1) {
			chardata[i].free = 0;
			chardata[i].ftl = ftl_char_blk_dev_struct;
			file->private_data = &chardata[i];
			break;
		}
	}

	return 0;
}

static int ftl_char_close(struct inode *inode, struct file *file)
{
	struct char_priv_data* cpd = file->private_data;
	struct ftl_device* ftl = cpd->ftl;
	
	ftl->char_open_count--;
	cpd->free = 1;
	
	return 0;
}

static ssize_t ftl_char_read(struct file *filp, char* buffer, size_t len, loff_t *offset)
{
	struct char_priv_data* cpd = filp->private_data;
	struct ftl_device* ftl = cpd->ftl;
	u16 tag = cpd->act_tag;
	struct ftl_request_info* devreq = &ftl->chip_request[tag];

	len = len > FTL_BUFFER_SPACE ? FTL_BUFFER_SPACE : len;
	
	copy_to_user(buffer,devreq->cpuaddr,len);
	return len;
}

static ssize_t ftl_char_write(struct file *filp, const char* buff, size_t len, loff_t *off)
{
	unsigned long flags;
	struct char_priv_data* cpd = filp->private_data;
	struct ftl_device* ftl = cpd->ftl;
	u16 tag = cpd->act_tag;
	struct ftl_request_info* devreq = &ftl->chip_request[tag];

	len = len > FTL_BUFFER_SPACE ? FTL_BUFFER_SPACE : len;
	
	copy_from_user(devreq->cpuaddr,buff,len);

	//get lock and issue request
	spin_lock_irqsave(&ftl->lock, flags);
	ftl_set_tag(ftl,devreq->bus,devreq->chip);
	ftl_write_command(ftl,devreq);
	spin_unlock_irqrestore(&ftl->lock, flags);

	return len;

}

static long ftl_char_ioctl(struct file *file, unsigned int ioctl_num, unsigned long ioctl_param)
{
	unsigned long flags;
	struct char_priv_data* cpd = file->private_data;
	struct ftl_device* ftl = cpd->ftl;

	struct ftl_char_message msgd;
	struct ftl_char_message* msg = &msgd;
	
	struct ftl_adc_command adcCommand;
	
	char buf[24];
	u32 temp32;
	u8 chip;
        u16 tag = FTL_NUM_TAGS; // This is outside of the range (0-FTL_NUM_TAGS-1) so it indicates that it didn't need a tag

	u64 tags;

	struct ftl_request_info* devreq;

	switch(ioctl_num) {
	case FTL_IOCTL_DO_OPERATION:
		//message from userspace to device
		copy_from_user(msg,(char*)ioctl_param,sizeof(struct ftl_char_message));
	
		chip = (msg->bus * FTL_NUM_CHIPS_PER_BUS) + msg->chip;
        	//check that chip is idle

	        spin_lock_irqsave(&ftl->lock, flags);
		
                // Find a free tag
                tag = ftl->free_list[(ftl->free_list_head_index++ % FTL_NUM_TAGS)];
		
		//printk(KERN_INFO "Received a DO OPERATION ioctl for bus %d, chip %d, op %d and it was assigned tag %d.", msg->bus, msg->chip, msg->operation, tag);
	        
                devreq = &ftl->chip_request[tag];
        	devreq->chip = msg->chip;
	        devreq->bus = msg->bus;
        	devreq->operation = msg->operation;
	        devreq->chipaddr[0] = msg->chipaddr[0];
        	devreq->chipaddr[1] = msg->chipaddr[1];
	        devreq->chipaddr[2] = msg->chipaddr[2];
        	devreq->chipaddr[3] = msg->chipaddr[3];
	        devreq->chipaddr[4] = msg->chipaddr[4];
	        //devreq->chipaddr2[0] = msg->chipaddr2[0];
        	//devreq->chipaddr2[1] = msg->chipaddr2[1];
	        //devreq->chipaddr2[2] = msg->chipaddr2[2];
        	//devreq->chipaddr2[3] = msg->chipaddr2[3];
	        //devreq->chipaddr2[4] = msg->chipaddr2[4];
        	devreq->length = msg->length;
	        //devreq->priority = msg->priority;
		devreq->tag = tag;
        	//devreq->result = 0;

		if (msg->operation == FTL_OP_READ 
		  || msg->operation == FTL_OP_WRITE
		  || msg->operation == FTL_OP_GET_ADC_SAMPLES
		  || msg->operation == FTL_OP_TWOPLANEREAD
		  || msg->operation == FTL_OP_TWOPLANEWRITE) {
			if (devreq->cpuaddr == 0)
				dev_warn(ftl->dev, "dma memory not allocated...\n");
		}
		
		if (msg->operation == FTL_OP_READ 
		|| msg->operation == FTL_OP_READID
		|| msg->operation == FTL_OP_READPARAM
		|| msg->operation == FTL_OP_GET_ADC_SAMPLES
		|| msg->operation == FTL_OP_TWOPLANEREAD)
		{
		        ftl_set_tag(ftl,devreq->bus,devreq->tag);
		        ftl_write_command(ftl,devreq);
		} else if (msg->operation == FTL_OP_WRITE
				|| msg->operation == FTL_OP_TWOPLANEWRITE) {
			cpd->act_tag = tag;
		} else if (msg->operation == FTL_OP_ERASE
				|| msg->operation == FTL_OP_TWOPLANEERASE) {
			ftl_set_tag(ftl,devreq->bus,devreq->tag);
			ftl_write_command(ftl,devreq);
		} else if (msg->operation == FTL_OP_CHIP_RESET) {
			ftl_set_tag(ftl,devreq->bus,devreq->tag);
			ftl_write_command(ftl,devreq);
		} else if (msg->operation == FTL_OP_CTRL_RESET) {
			// Reset the flash controller
			ftl_do_reset(ftl);
			// Turn interrupts back on
			ftl_enable_interrupt(ftl);
		}

	        spin_unlock_irqrestore(&ftl->lock, flags);		
		break;
	case FTL_IOCTL_TAGS:
		spin_lock_irqsave(&ftl->lock,flags);
		//ftl_update_tags(ftl);
		tags = ftl->tags;
		copy_to_user((char*)ioctl_param,(char*)&tags,8);
		spin_unlock_irqrestore(&ftl->lock,flags);
		break;
	case FTL_IOCTL_SET_ACTIVE_TAG:
		spin_lock_irqsave(&ftl->lock,flags);
		cpd->act_tag = ioctl_param;
		spin_unlock_irqrestore(&ftl->lock, flags);
		break;
	case FTL_IOCTL_GET_CHIP_EXISTS:
		spin_lock_irqsave(&ftl->lock,flags);
		ftl_update_chip_exists(ftl);
		copy_to_user((char*)ioctl_param,(char*)(&ftl->chip_exists),16);
		spin_unlock_irqrestore(&ftl->lock, flags);
		break;
	case FTL_IOCTL_GET_CYCLECOUNT:
		copy_from_user(buf,(char*)ioctl_param,1);
		spin_lock_irqsave(&ftl->lock, flags);
		temp32 = ftl_get_cyclecount(ftl,buf[0]);
		spin_unlock_irqrestore(&ftl->lock, flags);
		copy_to_user((char*)ioctl_param,&temp32,4);
		break;
	case FTL_IOCTL_SET_CYCLECOUNT_PARAMS:
		copy_from_user(buf,(char*)ioctl_param,3);
		spin_lock_irqsave(&ftl->lock, flags);
		ftl_set_cyclecount_params(ftl,buf[0],buf[1],buf[2]);
		spin_unlock_irqrestore(&ftl->lock, flags);
		break;
	case FTL_IOCTL_RESET_CYCLECOUNT:
		copy_from_user(buf,(char*)ioctl_param,1);
		spin_lock_irqsave(&ftl->lock, flags);
		ftl_reset_cyclecount(ftl,buf[0]);
		spin_unlock_irqrestore(&ftl->lock, flags);
		break;
	case FTL_IOCTL_SET_TIMINGS:
		copy_from_user(buf,(char*)ioctl_param,16);
		spin_lock_irqsave(&ftl->lock, flags);
		ftl_set_timing(ftl,buf[0],buf[1],buf[2],buf[3],buf[4],buf[5],buf[6],buf[7],buf[8],buf[9],buf[10],buf[11],buf[12],buf[13],buf[14],buf[15]);
		ftl_write_timings(ftl);
		spin_unlock_irqrestore(&ftl->lock, flags);
		break;
	case FTL_IOCTL_PRINT_REGISTERS:
		spin_lock_irqsave(&ftl->lock, flags);
		ftl_print_registers(ftl);
		spin_unlock_irqrestore(&ftl->lock, flags);
		break;
	case FTL_IOCTL_SEND_ADC_COMMAND:
		copy_from_user(&adcCommand,(char*)ioctl_param,sizeof(struct ftl_adc_command));
		spin_lock_irqsave(&ftl->lock, flags);
		ftl_send_adc_command(ftl,&adcCommand);
		copy_to_user((char*)ioctl_param,&adcCommand,sizeof(struct ftl_adc_command));
		spin_unlock_irqrestore(&ftl->lock, flags);
		break;
	case FTL_IOCTL_SET_ADC_GAIN:
		copy_from_user(buf,(char*)ioctl_param,1);
		spin_lock_irqsave(&ftl->lock, flags);
		ftl_set_adc_gain(ftl,buf[0]);
		spin_unlock_irqrestore(&ftl->lock, flags);
		break;
	case FTL_IOCTL_GET_ADC_GAIN:
		spin_lock_irqsave(&ftl->lock, flags);
		copy_to_user((char*)ioctl_param,(char*)(&ftl->adc_gain),1);
		spin_unlock_irqrestore(&ftl->lock, flags);
		break;
	case FTL_IOCTL_ENABLE_ADC_RECORDING:
		copy_from_user(buf,(char*)ioctl_param,1);
		spin_lock_irqsave(&ftl->lock, flags);
		ftl_enable_adc_recording(ftl,buf[0]);
		spin_unlock_irqrestore(&ftl->lock, flags);
		break;
	case FTL_IOCTL_DISABLE_ADC_RECORDING:
		copy_from_user(buf,(char*)ioctl_param,1);
		spin_lock_irqsave(&ftl->lock, flags);
		ftl_disable_adc_recording(ftl,buf[0]);
		spin_unlock_irqrestore(&ftl->lock, flags);
		break;
	}

        // Return the tag if it was assigned one
	return tag;

}



/* ---------------------------------------------------------------------
 * Module init/exit routines
 */
static int __init ftl_init(void)
{
	int rc;

	pr_debug("gordon: registering platform binding\n");
	rc = platform_driver_register(&ftl_platform_driver);
	if (rc)
		goto err_plat;

	if(register_chrdev(ftl_char_major, "gordonchar", &fops)){
		rc = -ENOMEM;
		goto err_char;
	}
	pr_info("gordon FTL char device, major=%i\n", ftl_char_major);

	ftl_char_class = class_create(THIS_MODULE, "gordonchar");

        if (IS_ERR(ftl_char_class)) {
		goto err_charclass;
        }

	device_create(ftl_char_class, NULL, MKDEV(ftl_char_major, 0),
                            NULL, "gordonchar%d", 0);


	return 0;
err_charclass:
	printk(KERN_ERR "Error creating ftl char class.\n");
        unregister_chrdev(ftl_char_major, "gordonchar");
err_char:
	printk(KERN_ERR "gordon: char register failed; err=%i\n", rc);
err_plat:
	printk(KERN_ERR "gordon: platform register failed; err=%i\n", rc);
	return rc;
}

static void __exit ftl_exit(void)
{
	device_destroy(ftl_char_class, MKDEV(ftl_char_major, 0));
	class_destroy(ftl_char_class);
	pr_debug("Unregistering gordon FTL char driver\n");
	unregister_chrdev(ftl_char_major, "gordonchar");
	platform_driver_unregister(&ftl_platform_driver);
}

module_init(ftl_init);
module_exit(ftl_exit);
