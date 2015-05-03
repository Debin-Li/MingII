##############################################################################
## Filename:          C:\Development\EDK\IP\MyProcessorIPLib/drivers/flash_controller_v1_00_a/data/flash_controller_v2_1_0.tcl
## Description:       Microprocess Driver Command (tcl)
## Date:              Tue Jan 25 13:08:38 2011 (by Create and Import Peripheral Wizard)
##############################################################################

#uses "xillib.tcl"

proc generate {drv_handle} {
  xdefine_include_file $drv_handle "xparameters.h" "flash_controller" "NUM_INSTANCES" "DEVICE_ID" "C_BASEADDR" "C_HIGHADDR" 
}
