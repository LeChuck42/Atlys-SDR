/*
 * main.c
 *
 *  Created on: 29.03.2015
 *      Author: matthias
 */

#include <stdint.h>
#include "atlys.h"
#include "timer.h"
#include "spi.h"
#include "adc.h"
#include "clk.h"
#include "fpga.h"
#include "eth.h"
#include "packet.h"
#include <or1k-support.h>

unsigned int dwTest;

extern or1k_exception_handler_fptr or1k_interrupt_handler;

void blink()
{
	// software interrupt for LED heartbeat
	*ATLYS_GPIO_DATA_PTR ^= ATLYS_GPIO_LED0;
}

static void init()
{
	// GPIO
	*ATLYS_GPIO_DIR_PTR = 0xFFFF0000;
	*ATLYS_GPIO_DATA_PTR = ATLYS_GPIO_LED6;
	// enable interrupt exception
	// TODO: there ought to be a library call for that
	or1k_exception_handler_add(0x8, (or1k_exception_handler_fptr)&or1k_interrupt_handler);
	TIMER_Init();
	SPI_Init();
	ETH_Init();
	or1k_interrupts_enable();
}

int main()
{
	int dwPacketId;

	init();
	TIMER_AddHandler(blink, 0, 500, 1);
	CLK_WriteConfig();

	ADC_SetFormat(ADC_FORMAT_TWOS_COMP, ADC_PATTERN_NORMAL);
	FPGA_SetBits(
			FPGA_REG_LED1 |
			FPGA_REG_CLKOUT_TYPE0 |
			FPGA_REG_ADC_AMPA_ENAB |
			FPGA_REG_ADC_AMPB_ENAB);
	while (1)
	{
		dwPacketId = ETH_CheckPacket();
		if (dwPacketId != ETH_NO_PACKET)
		{
			while (PACKET_Process(dwPacketId) == PACKET_BUSY);
			ETH_Free(dwPacketId);
		}
	}
}
