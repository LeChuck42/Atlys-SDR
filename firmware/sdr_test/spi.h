/*
 * spi.h
 *
 *  Created on: 17.04.2015
 *      Author: spectro
 */

#ifndef SPI_H_
#define SPI_H_

#define SPI_TARGET_CLK			6
#define SPI_TARGET_ADC_READ		5
#define SPI_TARGET_ADC_WRITE	4
#define SPI_TARGET_DAC_READ		3
#define SPI_TARGET_DAC_WRITE	2
#define SPI_TARGET_FPGA			1
#define SPI_TARGET_NONE			0

void SPI_Init();
int SPI_Busy();
void SPI_WaitBusy();
void SPI_ChipSelect(unsigned char ucTarget);
void SPI_Write(unsigned char ucData, void(*pCallback)() );
int SPI_Read(unsigned char *ucData);
void SPI_SetInterruptCount(unsigned int dwCnt);
void SPI_SetMode(unsigned int dwMode);
void SPI_ReleaseMutex();
int SPI_GetMutex();

#endif /* SPI_H_ */
