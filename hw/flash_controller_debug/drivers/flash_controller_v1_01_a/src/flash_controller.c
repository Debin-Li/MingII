/*****************************************************************************
* Filename:          C:\EDK\flash_controller_debug/drivers/flash_controller_v1_01_a/src/flash_controller.c
* Version:           1.01.a
* Description:       flash_controller Driver Source File
* Date:              Wed Mar 09 10:11:38 2011 (by Create and Import Peripheral Wizard)
*****************************************************************************/


/***************************** Include Files *******************************/

#include "flash_controller.h"

/************************** Function Definitions ***************************/


/**
 *
 * User logic master module to send/receive bytes to/from remote system memory.
 * While sending, the bytes are read from user logic local FIFO and write to remote system memory.
 * While receiving, the bytes are read from remote system memory and write to user logic local FIFO.
 *
 * @param   BaseAddress is the base address of the FLASH_CONTROLLER device.
 * @param   DstAddress is the destination system memory address from/to which the data will be fetched/stored.
 * @param   Size is the number of bytes to be sent.
 *
 * @return  None.
 *
 * @note    None.
 *
 */
void FLASH_CONTROLLER_MasterSendByte(Xuint32 BaseAddress, Xuint32 DstAddress, int Size)
{
  /*
   * Set user logic master control register for write transfer.
   */
  xil_io_out8(BaseAddress+FLASH_CONTROLLER_MST_CNTL_REG_OFFSET, MST_BRWR);

  /*
   * Set user logic master address register to drive IP2Bus_Mst_Addr signal.
   */
  Xil_Out32(BaseAddress+FLASH_CONTROLLER_MST_ADDR_REG_OFFSET, DstAddress);

  /*
   * Set user logic master byte enable register to drive IP2Bus_Mst_BE signal.
   */
  xil_io_out16(BaseAddress+FLASH_CONTROLLER_MST_BE_REG_OFFSET, 0xFFFF);

  /*
   * Set user logic master length register.
   */
  xil_io_out16(BaseAddress+FLASH_CONTROLLER_MST_LEN_REG_OFFSET, (Xuint16) Size);
  /*
   * Start user logic master write transfer by writting special pattern to its go port.
   */
  xil_io_out8(BaseAddress+FLASH_CONTROLLER_MST_GO_PORT_OFFSET, MST_START);
}

void FLASH_CONTROLLER_MasterRecvByte(Xuint32 BaseAddress, Xuint32 DstAddress, int Size)
{
  /*
   * Set user logic master control register for read transfer.
   */
  xil_io_out8(BaseAddress+FLASH_CONTROLLER_MST_CNTL_REG_OFFSET, MST_BRRD);

  /*
   * Set user logic master address register to drive IP2Bus_Mst_Addr signal.
   */
  Xil_Out32(BaseAddress+FLASH_CONTROLLER_MST_ADDR_REG_OFFSET, DstAddress);

  /*
   * Set user logic master byte enable register to drive IP2Bus_Mst_BE signal.
   */
  xil_io_out16(BaseAddress+FLASH_CONTROLLER_MST_BE_REG_OFFSET, 0xFFFF);

  /*
   * Set user logic master length register.
   */
  xil_io_out16(BaseAddress+FLASH_CONTROLLER_MST_LEN_REG_OFFSET, (Xuint16) Size);
  /*
   * Start user logic master read transfer by writting special pattern to its go port.
   */
  xil_io_out8(BaseAddress+FLASH_CONTROLLER_MST_GO_PORT_OFFSET, MST_START);
}

/**
 *
 * Enable all possible interrupts from FLASH_CONTROLLER device.
 *
 * @param   baseaddr_p is the base address of the FLASH_CONTROLLER device.
 *
 * @return  None.
 *
 * @note    None.
 *
 */
void FLASH_CONTROLLER_EnableInterrupt(void * baseaddr_p)
{
  Xuint32 baseaddr;
  baseaddr = (Xuint32) baseaddr_p;

  /*
   * Enable all interrupt source from user logic.
   */
  FLASH_CONTROLLER_mWriteReg(baseaddr, FLASH_CONTROLLER_INTR_IPIER_OFFSET, 0x00000001);

  /*
   * Enable all possible interrupt sources from device.
   */
  FLASH_CONTROLLER_mWriteReg(baseaddr, FLASH_CONTROLLER_INTR_DIER_OFFSET,
    INTR_TERR_MASK
    | INTR_DPTO_MASK
    | INTR_IPIR_MASK
    );

  /*
   * Set global interrupt enable.
   */
  FLASH_CONTROLLER_mWriteReg(baseaddr, FLASH_CONTROLLER_INTR_DGIER_OFFSET, INTR_GIE_MASK);
}

/**
 *
 * Example interrupt controller handler for FLASH_CONTROLLER device.
 * This is to show example of how to toggle write back ISR to clear interrupts.
 *
 * @param   baseaddr_p is the base address of the FLASH_CONTROLLER device.
 *
 * @return  None.
 *
 * @note    None.
 *
 */
void FLASH_CONTROLLER_Intr_DefaultHandler(void * baseaddr_p)
{
  Xuint32 baseaddr;
  Xuint32 IntrStatus;
Xuint32 IpStatus;
  baseaddr = (Xuint32) baseaddr_p;

  /*
   * Get status from Device Interrupt Status Register.
   */
  IntrStatus = FLASH_CONTROLLER_mReadReg(baseaddr, FLASH_CONTROLLER_INTR_DISR_OFFSET);

  xil_printf("Device Interrupt! DISR value : 0x%08x \n\r", IntrStatus);

  /*
   * Verify the source of the interrupt is the user logic and clear the interrupt
   * source by toggle write baca to the IP ISR register.
   */
  if ( (IntrStatus & INTR_IPIR_MASK) == INTR_IPIR_MASK )
  {
    xil_printf("User logic interrupt! \n\r");
    IpStatus = FLASH_CONTROLLER_mReadReg(baseaddr, FLASH_CONTROLLER_INTR_IPISR_OFFSET);
    FLASH_CONTROLLER_mWriteReg(baseaddr, FLASH_CONTROLLER_INTR_IPISR_OFFSET, IpStatus);
  }

}

