/*
 * spi.c
 *
 *  Created on: 25.05.2015
 *      Author: mseidel
 */


#include "atlys.h"
#include "spi.h"
#include "debug.h"
#include <or1k-support.h>
#include <stdint.h>

static void(*SPI_pCallback)() = 0;

volatile uint32_t dwFinished;
volatile uint32_t dwMutex;

void SPI_Interrupt(uint32_t dwData);
void SPI_DefaultCallback();
static void SPI_Reset();

void SPI_Init()
{
	DEBUG_Print(LOG_DEBUG, LOG_SPI, "SPI Init\n");
	*ATLYS_SPI_SPCR_PTR = SPI_SPCR_SPIE | SPI_SPCR_MSTR | SPI_SPCR_SPR1 | SPI_SPCR_SPR0; // Interrupt Master mode, 1/32 divider = 1.25 MHz
	*ATLYS_SPI_SPER_PTR = 0;
	or1k_interrupt_handler_add(ATLYS_INTERRUPT_SPI, SPI_Interrupt, 0);
	or1k_interrupt_enable(ATLYS_INTERRUPT_SPI);
	SPI_Reset();
}

void SPI_ChipSelect(uint8_t ucTarget)
{
	DEBUG_Print(LOG_DEBUG, LOG_SPI, "Selecting SPI Target ");
	switch (ucTarget)
	{
	case SPI_TARGET_CLK:
		*ATLYS_SPI_SS_PTR = SPI_SLAVE_CLK;
		DEBUG_Print_Without_Info(LOG_DEBUG, LOG_SPI, "CLK\n");
		break;
	case SPI_TARGET_ADC_READ:
		*ATLYS_SPI_SS_PTR = SPI_SLAVE_ADC;
		DEBUG_Print_Without_Info(LOG_DEBUG, LOG_SPI, "ADC\n");
		break;
	case SPI_TARGET_ADC_WRITE:
		*ATLYS_SPI_SS_PTR = SPI_SLAVE_ADC | SPI_SLAVE_OE;
		DEBUG_Print_Without_Info(LOG_DEBUG, LOG_SPI, "ADC\n");
		break;
	case SPI_TARGET_DAC_READ:
		*ATLYS_SPI_SS_PTR = SPI_SLAVE_DAC;
		DEBUG_Print_Without_Info(LOG_DEBUG, LOG_SPI, "DAC\n");
		break;
	case SPI_TARGET_DAC_WRITE:
		*ATLYS_SPI_SS_PTR = SPI_SLAVE_DAC | SPI_SLAVE_OE;
		DEBUG_Print_Without_Info(LOG_DEBUG, LOG_SPI, "DAC\n");
		break;
	case SPI_TARGET_FPGA:
		*ATLYS_SPI_SS_PTR = SPI_SLAVE_FPGA;
		DEBUG_Print_Without_Info(LOG_DEBUG, LOG_SPI, "FPGA\n");
		break;
	case SPI_TARGET_NONE:
		*ATLYS_SPI_SS_PTR = 0;
		SPI_pCallback = 0;
		DEBUG_Print_Without_Info(LOG_DEBUG, LOG_SPI, "None\n");
		break;
	default:
		DEBUG_Print_Without_Info(LOG_WARN, LOG_SPI, "Unknown\n");
		break;
	}
}

void SPI_Write(uint8_t ucData, void(*pCallback)() )
{
	*ATLYS_SPI_DATA_PTR = ucData;
	if (pCallback)
	{
		SPI_pCallback = pCallback;
	}
	else
	{
		SPI_pCallback = SPI_DefaultCallback;
		dwFinished = 0;
	}
}

void SPI_WaitBusy()
{
	while (!dwFinished);
}

int SPI_Read(uint8_t *ucData)
{
	uint8_t ucRxBuf;
	if (! (*ATLYS_SPI_SPCR_PTR & SPI_SPCR_SPE))
	{
		DEBUG_Print(LOG_INFO, LOG_SPI, "SPI_Read while SPI disabled\n");
		return -1; // system disabled
	}


	if ((*ATLYS_SPI_SPSR_PTR & SPI_SPSR_RFEMPTY))
	{
		DEBUG_Print(LOG_INFO, LOG_SPI, "SPI_Read but no data\n");
		return -2; // no data
	}

	ucRxBuf = *ATLYS_SPI_DATA_PTR;
	*ucData = ucRxBuf;

	DEBUG_Print(LOG_DEBUG, LOG_SPI, "Received SPI Data 0x%x\n", (unsigned int)ucRxBuf);
	return 0;
}

void SPI_SetInterruptCount(uint32_t dwCnt)
{
	uint8_t ucTemp = *ATLYS_SPI_SPER_PTR;

	switch (dwCnt)
	{
	case 3:
		ucTemp |= (SPI_SPER_ICNT0|SPI_SPER_ICNT1);
		break;
	case 2:
		ucTemp &= ~(SPI_SPER_ICNT0|SPI_SPER_ICNT1);
		ucTemp |= SPI_SPER_ICNT1;
		break;
	case 1:
		ucTemp &= ~(SPI_SPER_ICNT0|SPI_SPER_ICNT1);
		ucTemp |= SPI_SPER_ICNT0;
		break;
	case 0:
		ucTemp &= ~(SPI_SPER_ICNT0|SPI_SPER_ICNT1);
		break;
	}

	*ATLYS_SPI_SPER_PTR = ucTemp;
	SPI_Reset();
}

void SPI_SetMode(uint32_t dwMode)
{
	if (dwMode & 0x01)
		*ATLYS_SPI_SPCR_PTR |= SPI_SPCR_CPHA;
	else
		*ATLYS_SPI_SPCR_PTR &= ~SPI_SPCR_CPHA;

	if (dwMode & 0x02)
		*ATLYS_SPI_SPCR_PTR |= SPI_SPCR_CPOL;
	else
		*ATLYS_SPI_SPCR_PTR &= ~SPI_SPCR_CPOL;
}

int SPI_Busy()
{
	if (*ATLYS_SPI_SPCR_PTR & SPI_SPCR_SPE)
		return 1;
	return 0;
}

void SPI_DefaultCallback()
{
	dwFinished = 1;
}

static void SPI_Reset()
{
	*((volatile uint8_t*)ATLYS_SPI_SPCR_PTR) &= ~SPI_SPCR_SPE;
	*((volatile uint8_t*)ATLYS_SPI_SPCR_PTR) |= SPI_SPCR_SPE;
}

int SPI_GetMutex()
{
	uint32_t dwTimer, dwInterrupt;
	uint32_t dwMutex=0;
	ATLYS_ENTER_CRITICAL(dwInterrupt, dwTimer);
	if (dwMutex == 0)
	{
		dwMutex = 1;
		dwMutex = 1;
	}
	ATLYS_EXIT_CRITICAL(dwInterrupt, dwTimer);
	return dwMutex;
}

void SPI_ReleaseMutex()
{
	if (dwMutex)
	{
		dwMutex = 0;
	}
	else
	{
		DEBUG_Print(LOG_WARN, LOG_SPI, "SPI_ReleaseMutex but already released!\n");
	}
}

void SPI_Interrupt(uint32_t dwData)
{
	if (SPI_pCallback)
		SPI_pCallback();
	// clear interrupt
	*ATLYS_SPI_SPSR_PTR = SPI_SPSR_SPIF;
}
