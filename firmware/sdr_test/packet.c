/*
 * packet.c
 *
 *  Created on: 03.12.2015
 *      Author: matthias
 */

#include "packet.h"
#include "arp.h"

int PACKET_Process(int dwPacketId)
{
	unsigned char* pPacket = ETH_GetBuffer(dwPacketId);
	header_ethernet* head = pPacket;
	if (head->dstMac[0] == 0xff &&
		head->dstMac[1] == 0xff &&
		head->dstMac[2] == 0xff &&
		head->dstMac[3] == 0xff &&
		head->dstMac[4] == 0xff &&
		head->dstMac[5] == 0xff )
	{
		// broadcast
		switch (head->etherType)
		{
		case ETHERTYPE_ARP:
			return ARP_Request(dwPacketId);
		case ETHERTYPE_IP:
			break;
		default:
			break;
		}
	}
	else
	{

	}

	return PACKET_DROP;
}

