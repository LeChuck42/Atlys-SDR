/*
 * packet.h
 *
 *  Created on: 03.12.2015
 *      Author: matthias
 */

#ifndef PACKET_H_
#define PACKET_H_

#define ETHERTYPE_IP	0x0800

#define PACKET_DONE		1
#define PACKET_DROP		0
#define PACKET_BUSY		-1

int PACKET_Process(unsigned char* pPacket);
int PACKET_Create(int size);

typedef struct {
	unsigned char dstMac[6];
	unsigned char srcMac[6];
	unsigned short etherType;
} header_ethernet;

#endif /* PACKET_H_ */
