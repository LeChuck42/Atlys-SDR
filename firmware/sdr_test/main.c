/*
 * main.c
 *
 *  Created on: 29.03.2015
 *      Author: matthias
 */

#include "atlys.h"
#include "timer.h"
#include "spi.h"
#include "clk.h"
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
}

int main()
{
	unsigned int dwPollTimer;
	unsigned int regnr;
	init();
	TIMER_AddHandler(blink, 0, 500, 1);
	dwPollTimer = TIMER_GetTicks();
	regnr = 0;
	while (1)
	{
		if (TIMER_GetDelta(dwPollTimer) > 100)
		{
			if (SPI_GetMutex())
			{
				dwPollTimer = TIMER_GetTicks();
				CLK_ReadRegister(regnr);
				SPI_ReleaseMutex();
				regnr = (regnr + 1) & 0xF;
			}
		}
	}
}
