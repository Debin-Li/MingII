# Ming II Project Files

This repository contains the files needed to setup Ming II.

Ming II is a flexible platform for NAND flash-based research. It is
described in [UCSD CSE Technical Report CS2012-0978](http://cseweb.ucsd.edu/~swanson/papers/2012MingIITechReport.pdf), and
runs on the [XUPv5](http://www.xilinx.com/univ/xupv5-lx110t.htm) FPGA prototyping platform.

To use Ming II, you will need to purchase an XUPv5 prototyping platform and
you will need to fabricate the Ming II daughter board. The PCB files needed to
fabricate the board are located in the ```pcb``` directory.

In addition to the hardware components, you will need the software components in this library.
They include the verilog files for the FPGA, and the Linux kernel and drivers for the
Microblaze embedded soft processor, and the userspace tools used for interfacing with
the NAND flash chip.

Assuming you have fabricated the Ming II board files located in the ```pcb/MingII``` directory,
to get started use the genace tool to generate an ace image to put in the CF card slot. The
FPGA hardware (.bit) files are already pregenerated for you.

To modify the logic on the FPGA, you’ll need to use Xilinx ISE to open and build the files
in the ```hw``` directory.

## Support

This repository and the source files within are provided to you for free, without support or warranty
of any kind.

