/*
 * debug.c
 *
 *  Created on: 27.10.2014
 *      Author: spectro
 *
 *  __uart_xx functions are overwriting weak uart control functions of or1k-crt
 */


#include "atlys.h"
#include "debug.h"
#include "timer.h"
#include <or1k-support.h>

static unsigned int dwBlinkCnt;
static unsigned int dwDebugTimer;

void DEBUG_LEDCallback()
{
	*ATLYS_GPIO_DATA_PTR ^= ATLYS_GPIO_LED1;
	if (--dwBlinkCnt == 0)
	{
		*ATLYS_GPIO_DATA_PTR &= ~ATLYS_GPIO_LED1;
		TIMER_Stop(dwDebugTimer);
	}
}

void DEBUG_SetLed(unsigned int led, unsigned int state)
{
	unsigned int dwInterrupt, dwTimer;
	unsigned int mask = 0;

	switch(led)
	{
		case 0: mask = ATLYS_GPIO_LED0; break;
		case 1: mask = ATLYS_GPIO_LED1; break;
		case 2: mask = ATLYS_GPIO_LED2; break;
		case 3: mask = ATLYS_GPIO_LED3; break;
		case 4: mask = ATLYS_GPIO_LED4; break;
		case 5: mask = ATLYS_GPIO_LED5; break;
		case 6: mask = ATLYS_GPIO_LED6; break;
		default: return;
	}

	if (state) {
		ATLYS_ENTER_CRITICAL(dwInterrupt, dwTimer);
		*ATLYS_GPIO_DATA_PTR |= mask;
		ATLYS_EXIT_CRITICAL(dwInterrupt, dwTimer);
	} else {
		ATLYS_ENTER_CRITICAL(dwInterrupt, dwTimer);
		*ATLYS_GPIO_DATA_PTR &= ~mask;
		ATLYS_EXIT_CRITICAL(dwInterrupt, dwTimer);
	}
}

void DEBUG_TriggerLED()
{
	*ATLYS_GPIO_DATA_PTR |= ATLYS_GPIO_LED1;
	dwBlinkCnt = 5;
	TIMER_Start(dwDebugTimer);
}

/* -------------------------------------------------------------------------- */
/*!Initialize the UART
 * called by crt0                                                             */
/* -------------------------------------------------------------------------- */
void
__uart_init ()
{
	dwDebugTimer = TIMER_AddHandler(DEBUG_LEDCallback, 100, 100, 0);
}	/* __uart_init () */


/* -------------------------------------------------------------------------- */
/*!Put a character out on the UART
   called by stdio
   @param[in] c  The character to output				                      */
/* -------------------------------------------------------------------------- */
void
__uart_putc (char  c)
{
	unsigned int dwRetry;
	for (dwRetry = 10; dwRetry && (*ATLYS_UART_STATUS_PTR & ATLYS_UART_TX_FULL);dwRetry--);
	if (dwRetry)
		*ATLYS_UART_DATA_PTR = c;
}


/* -------------------------------------------------------------------------- */
/*!Get a character from the UART
   called by stdio
   @return  The character read.                                               */
/* -------------------------------------------------------------------------- */
char
__uart_getc ()
{
	/* Wait until a char is available, then get it. */
	while (*ATLYS_UART_STATUS_PTR & ATLYS_UART_RX_EMPTY);
	return *ATLYS_UART_DATA_PTR;
}
