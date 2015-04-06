/*
 * atlys.c
 *
 *  Created on: Aug 6, 2014
 *      Author: or1k
 */

#include "atlys.h"

/* define board */
const unsigned long _board_mem_base = ATLYS_MEM_BASE;
const unsigned long _board_mem_size = 128*1024*1024; // reserved space for bootloader
const unsigned long _board_clk_freq = 40000000;

const unsigned long _board_uart_base = ATLYS_UART_BASE;
const unsigned long _board_uart_baud = 115200;
const unsigned long _board_uart_IRQ = 2;
