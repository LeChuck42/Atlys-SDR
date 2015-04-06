/*
 * timer.c
 *
 *  Created on: 04.11.2014
 *      Author: spectro
 */

#include "atlys.h"
#include <or1k-support.h>
#include <spr-defs.h>
#include "timer.h"
#include "debug.h"

void ISR_Timer();

static struct SWI_Entry
{
	unsigned int dwReload;
	unsigned int dwCnt;
	unsigned int dwRunning;
	void (*handler)();
} SWI_List[MAX_SWI];

void TIMER_Init ()
{
	if (or1k_timer_init(1000)) // 1000 Hz
	{
		DEBUG_Print(LOG_ERR, LOG_TIMER, "Timer init failed\n");
		return;
	}
	or1k_timer_set_handler(ISR_Timer);
	or1k_timer_enable();
}

void ISR_Timer()
{
	unsigned int i;
	uint32_t ttmr = (or1k_mfspr(SPR_TTMR) & SPR_TTMR_PERIOD);
	or1k_mtspr(SPR_TTMR, ttmr | SPR_TTMR_IE | SPR_TTMR_RT);

	or1k_timer_ticks++;

	for (i=0; i<MAX_SWI; i++)
	{
		if (SWI_List[i].handler && SWI_List[i].dwRunning)
		{
			if (--SWI_List[i].dwCnt == 0)
			{
				// call software interrupt and reload counter
				DEBUG_Print(LOG_DEBUG, LOG_TIMER, "Calling SWI %u @ %p\n", i, (void *)SWI_List[i].handler);
				SWI_List[i].handler();
				if (SWI_List[i].dwReload)
					SWI_List[i].dwCnt = SWI_List[i].dwReload;
				else
					TIMER_RemoveHandler(i);
			}
		}
	}
}

int TIMER_AddHandler(void (*handler)(), unsigned int dwCount, unsigned int dwReload, unsigned int dwRunning)
{
	int i;
	unsigned int dwInterrupts, dwTimer;
	DEBUG_Print(LOG_DEBUG, LOG_TIMER, "Add Timer@%p(%u/%u %u) ", (void*)handler, dwCount, dwReload, dwRunning);
	ATLYS_ENTER_CRITICAL(dwInterrupts, dwTimer);
	for (i=0; i<MAX_SWI; i++)
	{
		if (!SWI_List[i].handler)
		{
			SWI_List[i].dwReload = dwReload;
			SWI_List[i].dwCnt = dwCount;
			SWI_List[i].dwRunning = dwRunning;
			SWI_List[i].handler = handler;

			if (SWI_List[i].dwCnt == 0)
			{
				// call software interrupt and reload counter
				DEBUG_Print(LOG_DEBUG, LOG_TIMER, "Calling initial SWI @ %p\n", (void *)SWI_List[i].handler);
				SWI_List[i].handler();
				if (SWI_List[i].dwReload)
					SWI_List[i].dwCnt = SWI_List[i].dwReload;
				else
					TIMER_RemoveHandler(i);
			}

			ATLYS_EXIT_CRITICAL(dwInterrupts, dwTimer);
			DEBUG_Print(LOG_DEBUG, LOG_TIMER, "Used SWI %u\n", i);
			return i;
		}
	}
	ATLYS_EXIT_CRITICAL(dwInterrupts, dwTimer);
	DEBUG_Print(LOG_ERR, LOG_TIMER, "No SWI entry available\n");
	return -1;
}

void TIMER_RemoveHandler(unsigned int dwHandle)
{
	unsigned int dwInterrupts, dwTimer;
	DEBUG_Print(LOG_DEBUG, LOG_TIMER, "RemoveHandler %u\n", dwHandle);
	ATLYS_ENTER_CRITICAL(dwInterrupts, dwTimer);
	if (dwHandle < MAX_SWI)
		SWI_List[dwHandle].handler = 0;
	ATLYS_EXIT_CRITICAL(dwInterrupts, dwTimer);
}

void TIMER_Stop(unsigned int dwHandle)
{
	unsigned int dwInterrupts, dwTimer;
	DEBUG_Print(LOG_DEBUG, LOG_TIMER, "Stop %u\n", dwHandle);
	ATLYS_ENTER_CRITICAL(dwInterrupts, dwTimer);
	if (dwHandle < MAX_SWI && SWI_List[dwHandle].handler)
		SWI_List[dwHandle].dwRunning = 0;
	ATLYS_EXIT_CRITICAL(dwInterrupts, dwTimer);
}

void TIMER_Start(unsigned int dwHandle)
{
	unsigned int dwInterrupts, dwTimer;
	DEBUG_Print(LOG_DEBUG, LOG_TIMER, "Start %u (%u/%u)\n", dwHandle, SWI_List[dwHandle].dwCnt, SWI_List[dwHandle].dwReload);
	ATLYS_ENTER_CRITICAL(dwInterrupts, dwTimer);
	if (dwHandle < MAX_SWI && SWI_List[dwHandle].handler)
	{
		SWI_List[dwHandle].dwCnt = SWI_List[dwHandle].dwReload;
		SWI_List[dwHandle].dwRunning = 1;
	}
	ATLYS_EXIT_CRITICAL(dwInterrupts, dwTimer);
}

void TIMER_SetReload(unsigned int dwHandle, unsigned int dwReload)
{
	unsigned int dwInterrupts, dwTimer;
	DEBUG_Print(LOG_DEBUG, LOG_TIMER, "SetReload %u=%u\n", dwHandle, dwReload);
	ATLYS_ENTER_CRITICAL(dwInterrupts, dwTimer);
	if (dwHandle < MAX_SWI && SWI_List[dwHandle].handler)
	{
		SWI_List[dwHandle].dwReload = dwReload;
	}
	ATLYS_EXIT_CRITICAL(dwInterrupts, dwTimer);
}

unsigned int TIMER_GetDelta(unsigned int dwTimestamp)
{
	return TIMER_GetTicks() - dwTimestamp;
}
