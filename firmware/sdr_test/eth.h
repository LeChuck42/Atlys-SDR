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
int ETH_StartTransmit(int dwPacketId, int dwSize);
void ETH_Free(int dwPacketId);
int ETH_GetEmpty();
void ETH_Init();


#endif /* ETH_H_ */
