##############################################################################
## Filename:          C:\EDK\flash_controller_debug/drivers/flash_controller_v1_01_a/data/flash_controller_v2_1_0.tcl
## Description:       Microprocess Driver Command (tcl)
## Date:              Wed Mar 09 10:11:38 2011 (by Create and Import Peripheral Wizard)
##############################################################################

#uses "xillib.tcl"

proc generate {drv_handle} {
  xdefine_include_file $drv_handle "xparameters.h" "flash_controller" "NUM_INSTANCES" "DEVICE_ID" "C_BASEADDR" "C_HIGHADDR" 
}
