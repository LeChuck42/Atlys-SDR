/*
 * arp.c
 *
 *  Created on: 22.12.2015
 *      Author: matthias
 */

#include "packet.h"
#include "arp.h"

static int ARP_ResponseIP(unsigned char* pPacket);

int ARP_Request(unsigned char* pPacket)
{
	arp_header* pHead = pPacket + sizeof(header_ethernet);
	if (pHead->hwAddrType == ADDRTYPE_ETH &&
		pHead->protoAddrType == ADDRTYPE_IP &&
		pHead->hwAddrSize == ADDRSIZE_ETH &&
		pHead->protoAddrSize == ADDRSIZE_IP &&
		pHead->opCode == ARP_OP_REQUEST)
		return ARP_ResponseIP(pPacket);
	return PACKET_DROP;
}

static int ARP_ResponseIP(unsigned char* pPacket)
{
	arp_ip* pRequest = pPacket + sizeof(header_ethernet) + sizeof(arp_header) ;

	unsigned char* pResponseBuffer;

	if (pRequest->dstMac[0] == 0 &&
		pRequest->dstMac[1] == 0 &&
		pRequest->dstMac[2] == 0 &&
		pRequest->dstMac[3] == 0 &&
		pRequest->dstMac[4] == 0 &&
		pRequest->dstMac[5] == 0 )

	{
		pResponseBuffer = PACKET_CreateResponse(pPacket);

	}

}
