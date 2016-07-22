/*
 * arp.h
 *
 *  Created on: 22.12.2015
 *      Author: matthias
 */

#ifndef ARP_H_
#define ARP_H_

#define ETHERTYPE_ARP	0x0806

#define ADDRTYPE_ETH	0x0001
#define ADDRTYPE_IP		0x0800
#define	ADDRSIZE_ETH	6
#define ADDRSIZE_IP		4

#define ARP_OP_REQUEST	1
#define ARP_OP_REPLY	2

typedef struct {
	unsigned short hwAddrType;
	unsigned short protoAddrType;
	unsigned char hwAddrSize;
	unsigned char protoAddrSize;
	unsigned short opCode;
} arp_header;

typedef struct  {
	unsigned char srcMac[6];
	unsigned char srcIp[4];
	unsigned char dstMac[6];
	unsigned char dstIp[4];
} arp_ip;

int ARP_Request(int dwPacketId);

#endif /* ARP_H_ */
