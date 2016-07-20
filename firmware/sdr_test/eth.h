/*
 * eth.h
 *
 *  Created on: 03.12.2015
 *      Author: matthias
 */

#ifndef ETH_H_
#define ETH_H_


#define ETH_NO_PACKET	-1

#define ETH_PACKET_BUFFERS  10
#define ETH_PACKET_SIZE     1500


int ETH_CheckPacket();
unsigned char *ETH_GetBuffer(int dwPacketId);
void ETH_Free(int dwPacketId);

#endif /* ETH_H_ */
