/*
 * atlys.h
 *
 *  Created on: 29.03.2015
 *      Author: matthias
 */

#ifndef ATLYS_H_
#define ATLYS_H_

#define ATLYS_MEM_BASE			0x00000000
#define ATLYS_UART_BASE			0x90000000
#define ATLYS_GPIO_BASE			0x91000000
#define ATLYS_SPI_BASE			0xB0000000

// UART Registers
#define ATLYS_UART_DATA_PTR		(((unsigned char*)ATLYS_UART_BASE) + 0)
#define ATLYS_UART_STATUS_PTR	(((unsigned char*)ATLYS_UART_BASE) + 1)

// UART Status Bits
#define ATLYS_UART_TX_FULL		(1<<0)
#define ATLYS_UART_TX_EMPTY		(1<<1)
#define ATLYS_UART_RX_FULL		(1<<2)
#define ATLYS_UART_RX_EMPTY		(1<<3)
#define ATLYS_UART_RX_ERROR		(1<<4)

// GPIO Registers
#define ATLYS_GPIO_DATA_PTR		(((unsigned int*)ATLYS_GPIO_BASE) + 0)
#define ATLYS_GPIO_DIR_PTR		(((unsigned int*)ATLYS_GPIO_BASE) + 1)

#define ATLYS_GPIO_SW0			(1<<0)
#define ATLYS_GPIO_SW1			(1<<1)
#define ATLYS_GPIO_SW2			(1<<2)
#define ATLYS_GPIO_SW3			(1<<3)
#define ATLYS_GPIO_SW4			(1<<4)
#define ATLYS_GPIO_SW5			(1<<5)
#define ATLYS_GPIO_SW6			(1<<6)
#define ATLYS_GPIO_SW7			(1<<7)

#define ATLYS_GPIO_MUX0			(1<<8)
#define ATLYS_GPIO_MUX1			(1<<9)
#define ATLYS_GPIO_MUX2			(1<<10)
#define ATLYS_GPIO_MUX3			(1<<11)
#define ATLYS_GPIO_MUX4			(1<<12)
#define ATLYS_GPIO_MUX5			(1<<13)

#define ATLYS_GPIO_LED0			(1<<16)
#define ATLYS_GPIO_LED1			(1<<17)
#define ATLYS_GPIO_LED2			(1<<18)
#define ATLYS_GPIO_LED3			(1<<19)
#define ATLYS_GPIO_LED4			(1<<20)
#define ATLYS_GPIO_LED5			(1<<21)
#define ATLYS_GPIO_LED6			(1<<22)

// Helper macros ********************************************************************
#define ATLYS_ENTER_CRITICAL(interrupt, timer) interrupt = or1k_interrupts_disable(); timer = or1k_timer_disable()
#define ATLYS_EXIT_CRITICAL(interrupt, timer) or1k_interrupts_restore(interrupt); or1k_timer_restore(timer)

#endif /* ATLYS_H_ */
