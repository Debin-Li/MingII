LINUXKERNEL=/home/microblaze-vm/devel/microblaze/linux-2.6-microblaze

obj-m += gordon.o

default:
	make ARCH=microblaze CROSS_COMPILE=microblaze-unknown-linux-gnu- -C $(LINUXKERNEL) SUBDIRS=`pwd` modules

clean:
	make ARCH=microblaze CROSS_COMPILE=microblaze-unknown-linux-gnu- -C $(LINUXKERNEL) SUBDIRS=`pwd` clean

