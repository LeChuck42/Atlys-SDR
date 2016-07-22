/*
 * atlys.h
 *
 *  Created on: 29.03.2015
 *      Author: matthias
 */

#ifndef ATLYS_H_
#define ATLYS_H_

#define ATLYS_MEM_BASE			    0x00000000
#define ATLYS_UART_BASE			    0x90000000
#define ATLYS_GPIO_BASE			    0x91000000
#define ATLYS_SPI_BASE			    0xB0000000
#define ATLYS_CONFIG_BASE           0x40000000

// UART Registers
#define ATLYS_UART_DATA_PTR		    (((unsigned char*)ATLYS_UART_BASE) + 0)
#define ATLYS_UART_STATUS_PTR	    (((unsigned char*)ATLYS_UART_BASE) + 1)

// UART Status Bits
#define ATLYS_UART_TX_FULL		    (1<<0)
#define ATLYS_UART_TX_EMPTY		    (1<<1)
#define ATLYS_UART_RX_FULL		    (1<<2)
#define ATLYS_UART_RX_EMPTY		    (1<<3)
#define ATLYS_UART_RX_ERROR		    (1<<4)

// GPIO Registers
#define ATLYS_GPIO_DATA_PTR		    (((unsigned int*)ATLYS_GPIO_BASE) + 0)
#define ATLYS_GPIO_DIR_PTR		    (((unsigned int*)ATLYS_GPIO_BASE) + 1)

#define ATLYS_GPIO_SW0			    (1<<0)
#define ATLYS_GPIO_SW1			    (1<<1)
#define ATLYS_GPIO_SW2			    (1<<2)
#define ATLYS_GPIO_SW3			    (1<<3)
#define ATLYS_GPIO_SW4			    (1<<4)
#define ATLYS_GPIO_SW5			    (1<<5)
#define ATLYS_GPIO_SW6			    (1<<6)
#define ATLYS_GPIO_SW7			    (1<<7)

#define ATLYS_GPIO_MUX0			    (1<<8)
#define ATLYS_GPIO_MUX1			    (1<<9)
#define ATLYS_GPIO_MUX2			    (1<<10)
#define ATLYS_GPIO_MUX3			    (1<<11)
#define ATLYS_GPIO_MUX4			    (1<<12)
#define ATLYS_GPIO_MUX5			    (1<<13)

#define ATLYS_GPIO_LED0			    (1<<16)
#define ATLYS_GPIO_LED1			    (1<<17)
#define ATLYS_GPIO_LED2			    (1<<18)
#define ATLYS_GPIO_LED3			    (1<<19)
#define ATLYS_GPIO_LED4			    (1<<20)
#define ATLYS_GPIO_LED5			    (1<<21)
#define ATLYS_GPIO_LED6			    (1<<22)

#define ATLYS_GPIO_ETH_RX_RDY       (1<<23)
#define ATLYS_GPIO_ETH_RX_OVR       (1<<24)
#define ATLYS_GPIO_ETH_TX_RDY       (1<<25)
#define ATLYS_GPIO_ETH_TX_STATUS    (1<<26)

#define ATLYS_SPI_SPCR_PTR		    (((         unsigned char*)(ATLYS_SPI_BASE)) + 0 ) // Serial Peripheral Control Register
#define ATLYS_SPI_SPSR_PTR		    (((volatile unsigned char*)(ATLYS_SPI_BASE)) + 1 ) // Serial Peripheral Status Register
#define ATLYS_SPI_DATA_PTR		    (((volatile unsigned char*)(ATLYS_SPI_BASE)) + 2 ) // Serial Peripheral Data Register
#define ATLYS_SPI_SPER_PTR		    (((         unsigned char*)(ATLYS_SPI_BASE)) + 3 ) // Serial Peripheral Extension Register
#define ATLYS_SPI_SS_PTR		    (((         unsigned char*)(ATLYS_SPI_BASE)) + 4 ) // Serial Peripheral Slave Select

#define SPI_SPCR_SPIE			    (1<<7) // Interrupt enable bit
#define SPI_SPCR_SPE			    (1<<6) // System enable bit
#define SPI_SPCR_DWOM			    (1<<5) // Port D Wired-OR Mode Bit
#define SPI_SPCR_MSTR			    (1<<4) // Master Mode select bit
#define SPI_SPCR_CPOL			    (1<<3) // Clock Polarity bit
#define SPI_SPCR_CPHA			    (1<<2) // Clock Phase bit
#define SPI_SPCR_SPR1			    (1<<1) // Clock rate select bit 1
#define SPI_SPCR_SPR0			    (1<<0) // Clock rate select bit 0

#define SPI_SPSR_SPIF			    (1<<7) // Interrupt Flag
#define SPI_SPSR_WCOL			    (1<<6) // Write Collision (FIFO overrun)
#define SPI_SPSR_WFFULL			    (1<<3) // Write FIFO full
#define SPI_SPSR_WFEMPTY		    (1<<2) // Write FIFO empty
#define SPI_SPSR_RFFULL			    (1<<1) // Read FIFO full
#define SPI_SPSR_RFEMPTY		    (1<<0) // Read FIFO empty

#define SPI_SPER_ICNT1			    (1<<7) // interrupt on transfer count bit 1
#define SPI_SPER_ICNT0			    (1<<6) // interrupt on transfer count bit 0
#define SPI_SPER_SPRE1			    (1<<1) // extended clock rate select bit 1
#define SPI_SPER_SPRE0			    (1<<0) // extended clock rate select bit 0

#define SPI_SLAVE_OE			    (1<<0)
#define SPI_SLAVE_CLK			    (1<<1)
#define SPI_SLAVE_DAC			    (1<<2)
#define SPI_SLAVE_ADC			    (1<<3)
#define SPI_SLAVE_FPGA			    (1<<4)

// Config Register
#define ETH_CONFIG_MY_IP            (((unsigned int*)  ATLYS_CONFIG_BASE)+0)
#define ETH_CONFIG_MY_MAC_LOW       (((unsigned int*)  ATLYS_CONFIG_BASE)+1)
#define ETH_CONFIG_MY_MAC_HIGH      (((unsigned int*)  ATLYS_CONFIG_BASE)+2)
#define ETH_CONFIG_DST_IP           (((unsigned int*)  ATLYS_CONFIG_BASE)+3)
#define ETH_CONFIG_DST_MAC_LOW      (((unsigned int*)  ATLYS_CONFIG_BASE)+4)
#define ETH_CONFIG_DST_MAC_HIGH     (((unsigned int*)  ATLYS_CONFIG_BASE)+5)
#define ETH_CONFIG_RX_BUF           (((unsigned char**)ATLYS_CONFIG_BASE)+6)
#define ETH_CONFIG_TX_BUF           (((unsigned char**)ATLYS_CONFIG_BASE)+7)
#define ETH_CONFIG_TX_SIZE          (((unsigned int*)  ATLYS_CONFIG_BASE)+8)

// Interrupt lines ******************************************************************
#define ATLYS_INTERRUPT_UART	    2
#define ATLYS_INTERRUPT_SPI		    6
#define ATLYS_INTERRUPT_ETH_RX      8
#define ATLYS_INTERRUPT_ETH_TX      9

// Helper macros ********************************************************************
#define ATLYS_ENTER_CRITICAL(interrupt, timer) interrupt = or1k_interrupts_disable(); timer = or1k_timer_disable()
#define ATLYS_EXIT_CRITICAL(interrupt, timer) or1k_interrupts_restore(interrupt); or1k_timer_restore(timer)



#endif /* ATLYS_H_ */
