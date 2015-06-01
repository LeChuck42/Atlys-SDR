/*
 * clk.h
 *
 *  Created on: 26.05.2015
 *      Author: matthias
 */

#ifndef CLK_H_
#define CLK_H_

#define CLK_SPI_ADDR_REG(n)		((n) & 0xF)
#define CLK_SPI_ADDR_STATUS		0x8
#define CLK_SPI_ADDR_READ		0xE
#define CLK_SPI_ADDR_UNLOCK		0xF

unsigned int CLK_ReadRegister(unsigned int dwRegAddr);

#endif /* CLK_H_ */
