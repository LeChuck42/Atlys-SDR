/*
 * eth.c
 *
 *  Created on: 03.12.2015
 *      Author: matthias
 */

#include "atlys.h"
#include "eth.h"
#include <stdint.h>



static enum {
	ETH_PKT_FREE,
	ETH_PKT_BUSY,
	ETH_PKT_READ,
	ETH_PKT_WRITE,
	ETH_PKT_VALID} ETH_PacketState[ETH_PACKET_BUFFERS];

static unsigned char ucETH_PacketBuf[ETH_PACKET_BUFFERS][ETH_PACKET_SIZE];
static unsigned int dwETH_CurrentBuf;

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
			ETH_PacketState[dwNext] = ETH_PKT_READ;
			ATLYS_EXIT_CRITICAL(dwInterrupt, dwTimer);
			dwLast = dwNext;
			return dwNext;
		}
	}
	ATLYS_EXIT_CRITICAL(dwInterrupt, dwTimer);
	return ETH_NO_PACKET;
}

int ETH_CreateEmpty()
{

}

unsigned char *ETH_GetBuffer(int dwPacketId)
{
	if (dwPacketId >= 0 && dwPacketId < ETH_PACKET_BUFFERS)
		if (ETH_PacketState[dwPacketId] == ETH_PKT_READ ||
		    ETH_PacketState[dwPacketId] == ETH_PKT_WRITE)
			return ucETH_PacketBuf[dwPacketId];
	return 0;
}

void ETH_Free(int dwPacketId)
{
	if (dwPacketId >= 0 && dwPacketId < ETH_PACKET_BUFFERS)
		if (ETH_PacketState[dwPacketId] == ETH_PKT_READ)
			ETH_PacketState[dwPacketId] = ETH_PKT_FREE;
}

void ETH_Interrupt(uint32_t dwData)
{
	ETH_PacketState[dwETH_CurrentBuf] = ETH_PKT_VALID;

	if (++dwETH_CurrentBuf == ETH_PACKET_BUFFERS)
		dwETH_CurrentBuf = 0;

	while (ETH_PacketState[dwETH_CurrentBuf] != ETH_PKT_FREE)
	{
		if (++dwETH_CurrentBuf == ETH_PACKET_BUFFERS)
			dwETH_CurrentBuf = 0;
	}

	while (ETH_PacketState[dwETH_CurrentBuf] == ETH_PKT_READ)
	{
		if (++dwETH_CurrentBuf == ETH_PACKET_BUFFERS)
			dwETH_CurrentBuf = 0;
	}

	ETH_PacketState[dwETH_CurrentBuf] = ETH_PKT_BUSY;
	*ETH_TARGET_ADDRESS = ucETH_PacketBuf[dwETH_CurrentBuf];
}
