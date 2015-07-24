/*
 * fpga.h
 *
 *  Created on: 24.07.2015
 *      Author: matthias
 */

#ifndef FPGA_H_
#define FPGA_H_

#include <stdint.h>

#define FPGA_REG_ERRLED			(1<<15)
#define FPGA_REG_LED2			(1<<14)
#define FPGA_REG_LED1			(1<<13)
#define FPGA_REG_CLKOUT_TYPE1	(1<<7)
#define FPGA_REG_CLKOUT_TYPE0	(1<<6)
#define FPGA_REG_CLKIN_SEL1		(1<<5)
#define FPGA_REG_CLKIN_SEL0		(1<<4)
#define FPGA_REG_ADC_PDNB		(1<<3)
#define FPGA_REG_ADC_PDNA		(1<<2)
#define FPGA_REG_ADC_AMPB_ENAB	(1<<1)
#define FPGA_REG_ADC_AMPA_ENAB	(1<<0)

void FPGA_SetBits(uint16_t wMask);
void FPGA_ClearBits(uint16_t wMask);

#endif /* FPGA_H_ */
