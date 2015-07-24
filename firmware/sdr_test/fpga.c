/*
 * fpga.c
 *
 *  Created on: 24.07.2015
 *      Author: matthias
 */


#include <stdint.h>
#include "fpga.h"
#include "spi.h"

static uint16_t wReg;

static void FPGA_UpdateReg()
{
	if (SPI_GetMutex())
	{
		SPI_SetMode(0);
		SPI_SetInterruptCount(1);
		SPI_ChipSelect(SPI_TARGET_FPGA);
		SPI_Write(wReg>>8,0);
		SPI_Write(wReg & 0xFF,0);
		SPI_WaitBusy();
		SPI_Read(0);
		SPI_Read(0);
		SPI_ChipSelect(SPI_TARGET_NONE);
		SPI_ReleaseMutex();
	}
}

void FPGA_SetBits(uint16_t wMask)
{
	wReg |= wMask;
	FPGA_UpdateReg();
}

void FPGA_ClearBits(uint16_t wMask)
{
	wReg &= ~wMask;
	FPGA_UpdateReg();
}
