/*
 * eth.c
 *
 *  Created on: 03.12.2015
 *      Author: matthias
 */

#include "atlys.h"
#include "eth.h"
#include <stdint.h>
#include <or1k-support.h>

void ETH_RX_Interrupt(uint32_t dwData);
void ETH_TX_Interrupt(uint32_t dwData);

static enum {
	ETH_PKT_FREE,
	ETH_PKT_BUSY,
	ETH_PKT_CPU,
	ETH_PKT_VALID} ETH_PacketState[ETH_PACKET_BUFFERS];

static unsigned char ucETH_PacketBuf[ETH_PACKET_BUFFERS][ETH_PACKET_SIZE];
static unsigned int dwCurrentTxBuf =0;

void ETH_Init()
{
	or1k_interrupt_handler_add(ATLYS_INTERRUPT_ETH_RX, ETH_RX_Interrupt, 0);
	or1k_interrupt_enable(ATLYS_INTERRUPT_ETH_RX);
	or1k_interrupt_handler_add(ATLYS_INTERRUPT_ETH_TX, ETH_TX_Interrupt, 0);
	or1k_interrupt_enable(ATLYS_INTERRUPT_ETH_TX);
}

int ETH_CheckPacket()
{
	static unsigned int dwLast = 0;
	unsigned int dwNext;
	unsigned int i;
	unsigned int dwInterrupt, dwTimer;
	dwNext = dwLast;

	ATLYS_ENTER_CRITICAL(dwInterrupt, dwTimer);

	for (i=0; i<ETH_PACKET_BUFFERS; i++)
	{
		if (++dwNext == ETH_PACKET_BUFFERS)
			dwNext = 0;
		if (ETH_PacketState[dwNext] == ETH_PKT_VALID)
		{
			ETH_PacketState[dwNext] = ETH_PKT_CPU;
			ATLYS_EXIT_CRITICAL(dwInterrupt, dwTimer);

			DEBUG_SetLed(3,1);
			dwLast = dwNext;
			return dwNext;
		}
	}
	ATLYS_EXIT_CRITICAL(dwInterrupt, dwTimer);
	return ETH_NO_PACKET;
}

int ETH_GetEmpty()
{
	unsigned int dwInterrupt, dwTimer;
	int ret_val = -1;
	int i;
	ATLYS_ENTER_CRITICAL(dwInterrupt, dwTimer);
	for (i=0; i<ETH_PACKET_BUFFERS; i++)
	{
		if (ETH_PacketState[i] == ETH_PKT_FREE)
		{
			ETH_PacketState[i] = ETH_PKT_CPU;
			ATLYS_EXIT_CRITICAL(dwInterrupt, dwTimer);
			ret_val = i;
			break;
		}
	}
	ATLYS_EXIT_CRITICAL(dwInterrupt, dwTimer);
	return ret_val;
}

unsigned char *ETH_GetBuffer(int dwPacketId)
{
	if (dwPacketId >= 0 && dwPacketId < ETH_PACKET_BUFFERS)
		if (ETH_PacketState[dwPacketId] == ETH_PKT_CPU)
			return ucETH_PacketBuf[dwPacketId];
	return 0;
}

int ETH_StartTransmit(int dwPacketId, int dwSize)
{
	unsigned int dwInterrupt, dwTimer;
	int ret_val = 0;
	ATLYS_ENTER_CRITICAL(dwInterrupt, dwTimer);

	if (! (*ATLYS_GPIO_DATA_PTR & ATLYS_GPIO_ETH_TX_RDY))
	{
		if (ETH_PacketState[dwPacketId] == ETH_PKT_CPU)
		{
			ETH_PacketState[dwPacketId] = ETH_PKT_BUSY;
			*ETH_CONFIG_TX_BUF = ucETH_PacketBuf[dwPacketId];
			*ETH_CONFIG_TX_SIZE = dwSize;
			dwCurrentTxBuf = dwPacketId;
			*ATLYS_GPIO_DATA_PTR |= ATLYS_GPIO_ETH_TX_RDY;
		}
		else
		{
			ret_val = -2;
		}
	}
	else
	{
		ret_val = -1;
	}

	ATLYS_EXIT_CRITICAL(dwInterrupt, dwTimer);
	return ret_val;
}

void ETH_Free(int dwPacketId)
{
	if (dwPacketId >= 0 && dwPacketId < ETH_PACKET_BUFFERS)
		if (ETH_PacketState[dwPacketId] == ETH_PKT_CPU)
			ETH_PacketState[dwPacketId] = ETH_PKT_FREE;
}

void ETH_RX_Interrupt(uint32_t dwData)
{
	// Interrupt context
	static unsigned int dwCurrentRxBuf = 0;

	ETH_PacketState[dwCurrentRxBuf] = ETH_PKT_VALID;

	*ATLYS_GPIO_DATA_PTR &= ~ATLYS_GPIO_ETH_RX_RDY;

	if (++dwCurrentRxBuf >= ETH_PACKET_BUFFERS)
		dwCurrentRxBuf = 0;

	while (ETH_PacketState[dwCurrentRxBuf] != ETH_PKT_FREE)
	{
		if (++dwCurrentRxBuf == ETH_PACKET_BUFFERS)
			dwCurrentRxBuf = 0;
	}

	while (ETH_PacketState[dwCurrentRxBuf] == ETH_PKT_CPU)
	{
		if (++dwCurrentRxBuf == ETH_PACKET_BUFFERS)
			dwCurrentRxBuf = 0;
	}

	ETH_PacketState[dwCurrentRxBuf] = ETH_PKT_BUSY;
	*ETH_CONFIG_RX_BUF = ucETH_PacketBuf[dwCurrentRxBuf];

	*ATLYS_GPIO_DATA_PTR |= ATLYS_GPIO_ETH_RX_RDY;
}

void ETH_TX_Interrupt(uint32_t dwData)
{
	if (*ATLYS_GPIO_DATA_PTR & ATLYS_GPIO_ETH_TX_RDY)
	{
		*ATLYS_GPIO_DATA_PTR &= ~ATLYS_GPIO_ETH_TX_RDY;
		ETH_PacketState[dwCurrentTxBuf] = ETH_PKT_FREE;
	}
}
