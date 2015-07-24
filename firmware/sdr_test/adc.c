/*
 * adc.c
 *
 *  Created on: 22.07.2015
 *      Author: matthias
 */

#include <stdint.h>
#include "spi.h"

static void ADC_SendData(uint8_t ucRegister, uint16_t wData);

static void ADC_SendData(uint8_t ucRegister, uint16_t wData)
{
	uint16_t wBuf;
	wBuf = (ucRegister << 11) | (wData & 0x3FF);

	SPI_SetMode(1);
	SPI_SetInterruptCount(1);
	SPI_ChipSelect(SPI_TARGET_ADC_WRITE);
	SPI_Write(wBuf>>8,0);
	SPI_Write(wBuf & 0xFF,0);
	SPI_WaitBusy();
	SPI_Read(0);
	SPI_Read(0);
	SPI_ChipSelect(SPI_TARGET_NONE);
}

void ADC_SetFormat(uint8_t ucBinary, uint8_t ucPattern)
{
	uint16_t wData;

	wData = ucPattern << 5;	// Bits D7, D6, D5

	if (ucBinary)
		wData |= 0x200;		// Bit D9

	ADC_SendData(0x0A, wData);
}
