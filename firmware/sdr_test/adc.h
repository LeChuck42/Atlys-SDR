/*
 * adc.h
 *
 *  Created on: 22.07.2015
 *      Author: matthias
 */

#ifndef ADC_H_
#define ADC_H_

#define ADC_PATTERN_NORMAL		0b000
#define ADC_PATTERN_ALL_ZEROS	0b001
#define ADC_PATTERN_ALL_ONES	0b010
#define ADC_PATTERN_TOGGLE		0b011
#define ADC_PATTERN_CUSTOM		0b101
#define ADC_PATTERN_DESKEW		0b110
#define ADC_PATTERN_SYNC		0b111

#define ADC_FORMAT_TWOS_COMP	0
#define ADC_FORMAT_BINARY		1


void ADC_SetFormat(uint8_t ucBinary, uint8_t ucPattern);

#endif /* ADC_H_ */
