/*
 * main.c
 *
 *  Created on: 29.03.2015
 *      Author: matthias
 */

#include "atlys.h"
#include "timer.h"

unsigned int dwTest;

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
	TIMER_Init();
}

int main()
{
	init();
	TIMER_AddHandler(blink, 0, 500, 1);
	while (1);
}
