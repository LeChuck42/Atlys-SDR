/*
 * arp.c
 *
 *  Created on: 22.12.2015
 *      Author: matthias
 */

#include "packet.h"
#include "arp.h"
#include "eth.h"

static int ARP_ResponseIP(int dwPacketId);

int ARP_Request(int dwPacketId)
{
	unsigned char* pPacket = ETH_GetBuffer(dwPacketId);
	arp_header* pHead = (arp_header*)(pPacket + sizeof(header_ethernet));
	if (pHead->hwAddrType == ADDRTYPE_ETH &&
		pHead->protoAddrType == ADDRTYPE_IP &&
		pHead->hwAddrSize == ADDRSIZE_ETH &&
		pHead->protoAddrSize == ADDRSIZE_IP &&
		pHead->opCode == ARP_OP_REQUEST)
		return ARP_ResponseIP(dwPacketId);
	return PACKET_DROP;
}

static int ARP_ResponseIP(int dwPacketId)
{
	unsigned char* pPacket = ETH_GetBuffer(dwPacketId);
	arp_ip* pRequest = (arp_ip*)(pPacket + sizeof(header_ethernet) + sizeof(arp_header));

	if (pRequest->dstMac[0] == 0 &&
		pRequest->dstMac[1] == 0 &&
		pRequest->dstMac[2] == 0 &&
		pRequest->dstMac[3] == 0 &&
		pRequest->dstMac[4] == 0 &&
		pRequest->dstMac[5] == 0 )
	{

		if (ETH_StartTransmit(dwPacketId, 20) == 0)
			return PACKET_DONE;
		else
			return PACKET_BUSY;
	}
	return PACKET_DROP;
}
