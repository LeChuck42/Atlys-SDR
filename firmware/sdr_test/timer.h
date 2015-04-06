/*
 * timer.h
 *
 *  Created on: 04.11.2014
 *      Author: spectro
 */

#ifndef TIMER_H_
#define TIMER_H_

#define MAX_SWI 4

/* defined in or1k-support */
extern unsigned long or1k_timer_ticks;

#define TIMER_GetTicks()	or1k_timer_ticks

void TIMER_Init();
int  TIMER_AddHandler(void (*handler)(), unsigned int dwCount, unsigned int dwReload, unsigned int dwRunning);
void TIMER_RemoveHandler(unsigned int dwHandle);
void TIMER_Stop(unsigned int dwHandle);
void TIMER_Start(unsigned int dwHandle);
void TIMER_SetReload(unsigned int dwHandle, unsigned int dwReload);
unsigned int TIMER_GetDelta(unsigned int dwTimestamp);

#endif /* TIMER_H_ */
