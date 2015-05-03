/*****************************************************************************
* Filename:          C:\Development\EDK\IP\MyProcessorIPLib/drivers/flash_controller_v1_00_a/src/flash_controller.h
* Version:           1.00.a
* Description:       flash_controller Driver Header File
* Date:              Tue Jan 25 13:08:38 2011 (by Create and Import Peripheral Wizard)
*****************************************************************************/

#ifndef FLASH_CONTROLLER_H
#define FLASH_CONTROLLER_H

/***************************** Include Files *******************************/

#include "xbasic_types.h"
#include "xstatus.h"
#include "xil_io.h"

/************************** Constant Definitions ***************************/


/**
 * User Logic Slave Space Offsets
 * -- SLV_REG0 : user logic slave module register 0
 * -- SLV_REG1 : user logic slave module register 1
 * -- SLV_REG2 : user logic slave module register 2
 * -- SLV_REG3 : user logic slave module register 3
 * -- SLV_REG4 : user logic slave module register 4
 * -- SLV_REG5 : user logic slave module register 5
 * -- SLV_REG6 : user logic slave module register 6
 * -- SLV_REG7 : user logic slave module register 7
 * -- SLV_REG8 : user logic slave module register 8
 * -- SLV_REG9 : user logic slave module register 9
 * -- SLV_REG10 : user logic slave module register 10
 * -- SLV_REG11 : user logic slave module register 11
 */
#define FLASH_CONTROLLER_USER_SLV_SPACE_OFFSET (0x00000000)
#define FLASH_CONTROLLER_SLV_REG0_OFFSET (FLASH_CONTROLLER_USER_SLV_SPACE_OFFSET + 0x00000000)
#define FLASH_CONTROLLER_SLV_REG1_OFFSET (FLASH_CONTROLLER_USER_SLV_SPACE_OFFSET + 0x00000004)
#define FLASH_CONTROLLER_SLV_REG2_OFFSET (FLASH_CONTROLLER_USER_SLV_SPACE_OFFSET + 0x00000008)
#define FLASH_CONTROLLER_SLV_REG3_OFFSET (FLASH_CONTROLLER_USER_SLV_SPACE_OFFSET + 0x0000000C)
#define FLASH_CONTROLLER_SLV_REG4_OFFSET (FLASH_CONTROLLER_USER_SLV_SPACE_OFFSET + 0x00000010)
#define FLASH_CONTROLLER_SLV_REG5_OFFSET (FLASH_CONTROLLER_USER_SLV_SPACE_OFFSET + 0x00000014)
#define FLASH_CONTROLLER_SLV_REG6_OFFSET (FLASH_CONTROLLER_USER_SLV_SPACE_OFFSET + 0x00000018)
#define FLASH_CONTROLLER_SLV_REG7_OFFSET (FLASH_CONTROLLER_USER_SLV_SPACE_OFFSET + 0x0000001C)
#define FLASH_CONTROLLER_SLV_REG8_OFFSET (FLASH_CONTROLLER_USER_SLV_SPACE_OFFSET + 0x00000020)
#define FLASH_CONTROLLER_SLV_REG9_OFFSET (FLASH_CONTROLLER_USER_SLV_SPACE_OFFSET + 0x00000024)
#define FLASH_CONTROLLER_SLV_REG10_OFFSET (FLASH_CONTROLLER_USER_SLV_SPACE_OFFSET + 0x00000028)
#define FLASH_CONTROLLER_SLV_REG11_OFFSET (FLASH_CONTROLLER_USER_SLV_SPACE_OFFSET + 0x0000002C)

/**
 * User Logic Master Space Offsets
 * -- MST_CNTL_REG : user logic master module control register
 * -- MST_STAT_REG : user logic master module status register
 * -- MST_ADDR_REG : user logic master module address register
 * -- MST_BE_REG   : user logic master module byte enable register
 * -- MST_LEN_REG  : user logic master module length (data transfer in bytes) register
 * -- MST_GO_PORT  : user logic master module go bit (to start master operation)
 */
#define FLASH_CONTROLLER_USER_MST_SPACE_OFFSET (0x00000100)
#define FLASH_CONTROLLER_MST_CNTL_REG_OFFSET (FLASH_CONTROLLER_USER_MST_SPACE_OFFSET + 0x00000000)
#define FLASH_CONTROLLER_MST_STAT_REG_OFFSET (FLASH_CONTROLLER_USER_MST_SPACE_OFFSET + 0x00000001)
#define FLASH_CONTROLLER_MST_ADDR_REG_OFFSET (FLASH_CONTROLLER_USER_MST_SPACE_OFFSET + 0x00000004)
#define FLASH_CONTROLLER_MST_BE_REG_OFFSET (FLASH_CONTROLLER_USER_MST_SPACE_OFFSET + 0x00000008)
#define FLASH_CONTROLLER_MST_LEN_REG_OFFSET (FLASH_CONTROLLER_USER_MST_SPACE_OFFSET + 0x0000000C)
#define FLASH_CONTROLLER_MST_GO_PORT_OFFSET (FLASH_CONTROLLER_USER_MST_SPACE_OFFSET + 0x0000000F)

/**
 * User Logic Master Module Masks
 * -- MST_RD_MASK   : user logic master read request control
 * -- MST_WR_MASK   : user logic master write request control
 * -- MST_BL_MASK   : user logic master bus lock control
 * -- MST_BRST_MASK : user logic master burst assertion control
 * -- MST_DONE_MASK : user logic master transfer done status
 * -- MST_BSY_MASK  : user logic master busy status
 * -- MST_BRRD      : user logic master burst read request
 * -- MST_BRWR      : user logic master burst write request
 * -- MST_SGRD      : user logic master single read request
 * -- MST_SGWR      : user logic master single write request
 * -- MST_START     : user logic master to start transfer
 */
#define MST_RD_MASK (0x80000000UL)
#define MST_WR_MASK (0x40000000UL)
#define MST_BL_MASK (0x20000000UL)
#define MST_BRST_MASK (0x10000000UL)
#define MST_DONE_MASK (0x00800000UL)
#define MST_BSY_MASK (0x00400000UL)
#define MST_BRRD (0x90)
#define MST_BRWR (0x50)
#define MST_SGRD (0x80)
#define MST_SGWR (0x40)
#define MST_START (0x0A)

/**************************** Type Definitions *****************************/


/***************** Macros (Inline Functions) Definitions *******************/

/**
 *
 * Write a value to a FLASH_CONTROLLER register. A 32 bit write is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is written.
 *
 * @param   BaseAddress is the base address of the FLASH_CONTROLLER device.
 * @param   RegOffset is the register offset from the base to write to.
 * @param   Data is the data written to the register.
 *
 * @return  None.
 *
 * @note
 * C-style signature:
 * 	void FLASH_CONTROLLER_mWriteReg(Xuint32 BaseAddress, unsigned RegOffset, Xuint32 Data)
 *
 */
#define FLASH_CONTROLLER_mWriteReg(BaseAddress, RegOffset, Data) \
 	Xil_Out32((BaseAddress) + (RegOffset), (Xuint32)(Data))

/**
 *
 * Read a value from a FLASH_CONTROLLER register. A 32 bit read is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is read from the register. The most significant data
 * will be read as 0.
 *
 * @param   BaseAddress is the base address of the FLASH_CONTROLLER device.
 * @param   RegOffset is the register offset from the base to write to.
 *
 * @return  Data is the data from the register.
 *
 * @note
 * C-style signature:
 * 	Xuint32 FLASH_CONTROLLER_mReadReg(Xuint32 BaseAddress, unsigned RegOffset)
 *
 */
#define FLASH_CONTROLLER_mReadReg(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (RegOffset))


/**
 *
 * Write/Read 32 bit value to/from FLASH_CONTROLLER user logic slave registers.
 *
 * @param   BaseAddress is the base address of the FLASH_CONTROLLER device.
 * @param   RegOffset is the offset from the slave register to write to or read from.
 * @param   Value is the data written to the register.
 *
 * @return  Data is the data from the user logic slave register.
 *
 * @note
 * C-style signature:
 * 	void FLASH_CONTROLLER_mWriteSlaveRegn(Xuint32 BaseAddress, unsigned RegOffset, Xuint32 Value)
 * 	Xuint32 FLASH_CONTROLLER_mReadSlaveRegn(Xuint32 BaseAddress, unsigned RegOffset)
 *
 */
#define FLASH_CONTROLLER_mWriteSlaveReg0(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (FLASH_CONTROLLER_SLV_REG0_OFFSET) + (RegOffset), (Xuint32)(Value))
#define FLASH_CONTROLLER_mWriteSlaveReg1(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (FLASH_CONTROLLER_SLV_REG1_OFFSET) + (RegOffset), (Xuint32)(Value))
#define FLASH_CONTROLLER_mWriteSlaveReg2(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (FLASH_CONTROLLER_SLV_REG2_OFFSET) + (RegOffset), (Xuint32)(Value))
#define FLASH_CONTROLLER_mWriteSlaveReg3(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (FLASH_CONTROLLER_SLV_REG3_OFFSET) + (RegOffset), (Xuint32)(Value))
#define FLASH_CONTROLLER_mWriteSlaveReg4(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (FLASH_CONTROLLER_SLV_REG4_OFFSET) + (RegOffset), (Xuint32)(Value))
#define FLASH_CONTROLLER_mWriteSlaveReg5(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (FLASH_CONTROLLER_SLV_REG5_OFFSET) + (RegOffset), (Xuint32)(Value))
#define FLASH_CONTROLLER_mWriteSlaveReg6(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (FLASH_CONTROLLER_SLV_REG6_OFFSET) + (RegOffset), (Xuint32)(Value))
#define FLASH_CONTROLLER_mWriteSlaveReg7(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (FLASH_CONTROLLER_SLV_REG7_OFFSET) + (RegOffset), (Xuint32)(Value))
#define FLASH_CONTROLLER_mWriteSlaveReg8(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (FLASH_CONTROLLER_SLV_REG8_OFFSET) + (RegOffset), (Xuint32)(Value))
#define FLASH_CONTROLLER_mWriteSlaveReg9(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (FLASH_CONTROLLER_SLV_REG9_OFFSET) + (RegOffset), (Xuint32)(Value))
#define FLASH_CONTROLLER_mWriteSlaveReg10(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (FLASH_CONTROLLER_SLV_REG10_OFFSET) + (RegOffset), (Xuint32)(Value))
#define FLASH_CONTROLLER_mWriteSlaveReg11(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (FLASH_CONTROLLER_SLV_REG11_OFFSET) + (RegOffset), (Xuint32)(Value))

#define FLASH_CONTROLLER_mReadSlaveReg0(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (FLASH_CONTROLLER_SLV_REG0_OFFSET) + (RegOffset))
#define FLASH_CONTROLLER_mReadSlaveReg1(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (FLASH_CONTROLLER_SLV_REG1_OFFSET) + (RegOffset))
#define FLASH_CONTROLLER_mReadSlaveReg2(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (FLASH_CONTROLLER_SLV_REG2_OFFSET) + (RegOffset))
#define FLASH_CONTROLLER_mReadSlaveReg3(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (FLASH_CONTROLLER_SLV_REG3_OFFSET) + (RegOffset))
#define FLASH_CONTROLLER_mReadSlaveReg4(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (FLASH_CONTROLLER_SLV_REG4_OFFSET) + (RegOffset))
#define FLASH_CONTROLLER_mReadSlaveReg5(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (FLASH_CONTROLLER_SLV_REG5_OFFSET) + (RegOffset))
#define FLASH_CONTROLLER_mReadSlaveReg6(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (FLASH_CONTROLLER_SLV_REG6_OFFSET) + (RegOffset))
#define FLASH_CONTROLLER_mReadSlaveReg7(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (FLASH_CONTROLLER_SLV_REG7_OFFSET) + (RegOffset))
#define FLASH_CONTROLLER_mReadSlaveReg8(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (FLASH_CONTROLLER_SLV_REG8_OFFSET) + (RegOffset))
#define FLASH_CONTROLLER_mReadSlaveReg9(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (FLASH_CONTROLLER_SLV_REG9_OFFSET) + (RegOffset))
#define FLASH_CONTROLLER_mReadSlaveReg10(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (FLASH_CONTROLLER_SLV_REG10_OFFSET) + (RegOffset))
#define FLASH_CONTROLLER_mReadSlaveReg11(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (FLASH_CONTROLLER_SLV_REG11_OFFSET) + (RegOffset))

/**
 *
 * Check status of FLASH_CONTROLLER user logic master module.
 *
 * @param   BaseAddress is the base address of the FLASH_CONTROLLER device.
 *
 * @return  Status is the result of status checking.
 *
 * @note
 * C-style signature:
 * 	bool FLASH_CONTROLLER_mMasterDone(Xuint32 BaseAddress)
 * 	bool FLASH_CONTROLLER_mMasterBusy(Xuint32 BaseAddress)
 * 	bool FLASH_CONTROLLER_mMasterError(Xuint32 BaseAddress)
 * 	bool FLASH_CONTROLLER_mMasterTimeout(Xuint32 BaseAddress)
 *
 */
#define FLASH_CONTROLLER_mMasterDone(BaseAddress) \
 	((((Xuint32) xil_io_in8((BaseAddress)+(FLASH_CONTROLLER_MST_STAT_REG_OFFSET)))<<16 & MST_DONE_MASK) == MST_DONE_MASK)
#define FLASH_CONTROLLER_mMasterBusy(BaseAddress) \
 	((((Xuint32) xil_io_in8((BaseAddress)+(FLASH_CONTROLLER_MST_STAT_REG_OFFSET)))<<16 & MST_BUSY_MASK) == MST_BUSY_MASK)
#define FLASH_CONTROLLER_mMasterError(BaseAddress) \
 	((((Xuint32) xil_io_in8((BaseAddress)+(FLASH_CONTROLLER_MST_STAT_REG_OFFSET)))<<16 & MST_ERROR_MASK) == MST_ERROR_MASK)
#define FLASH_CONTROLLER_mMasterTimeout(BaseAddress) \
 	((((Xuint32) xil_io_in8((BaseAddress)+(FLASH_CONTROLLER_MST_STAT_REG_OFFSET)))<<16 & MST_TIMEOUT_MASK) == MST_TIMEOUT_MASK)

/************************** Function Prototypes ****************************/


/**
 *
 * User logic master module to send/receive bytes to/from remote system memory.
 * While sending, the bytes are read from user logic local FIFO and write to remote memory.
 * While receiving, the bytes are read from remote memory and write to user logic local FIFO.
 *
 * @param   BaseAddress is the base address of the FLASH_CONTROLLER device.
 * @param   DstAddress is the destination memory address from/to which the data will be fetched/stored.
 * @param   Size is the number of bytes to be sent.
 *
 * @return  None.
 *
 * @note    None.
 *
 */
void FLASH_CONTROLLER_MasterSendByte(Xuint32 BaseAddress, Xuint32 DstAddress, int Size);
void FLASH_CONTROLLER_MasterRecvByte(Xuint32 BaseAddress, Xuint32 DstAddress, int Size);

/**
 *
 * Run a self-test on the driver/device. Note this may be a destructive test if
 * resets of the device are performed.
 *
 * If the hardware system is not built correctly, this function may never
 * return to the caller.
 *
 * @param   baseaddr_p is the base address of the FLASH_CONTROLLER instance to be worked on.
 *
 * @return
 *
 *    - XST_SUCCESS   if all self-test code passed
 *    - XST_FAILURE   if any self-test code failed
 *
 * @note    Caching must be turned off for this function to work.
 * @note    Self test may fail if data memory and device are not on the same bus.
 *
 */
XStatus FLASH_CONTROLLER_SelfTest(void * baseaddr_p);

#endif /** FLASH_CONTROLLER_H */
