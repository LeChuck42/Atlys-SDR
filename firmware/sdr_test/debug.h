/*
 * debug.h
 *
 *  Created on: 31.05.2012
 *      Author: mseidel
 */

#ifndef DEBUG_H_
#define DEBUG_H_

#include <stdio.h>

#define LOG_DEBUG		16
#define LOG_INFO		32
#define LOG_WARN		64
#define LOG_ERR			128
#define LOG_DISABLED	255

// Log levels
#define LOG_MAIN		LOG_DEBUG
#define LOG_TIMER		LOG_DEBUG
#define LOG_SPI			LOG_DEBUG

#define LOG_WARNING_LED_LEVEL	LOG_WARN // Messages of equal or higher severity cause the error LED to flash

#define DEBUG_Print(nLogLevel, nLogBook, ...) do { \
	if (nLogLevel>=nLogBook) iprintf(#nLogLevel "|" #nLogBook ": " __VA_ARGS__ );\
	if (nLogLevel>=LOG_WARNING_LED_LEVEL) DEBUG_TriggerLED();} while (0)

#define DEBUG_Print_Without_Info(nLogLevel, nLogBook, ...) do {if (nLogLevel>=nLogBook) iprintf(__VA_ARGS__);} while (0)

void DEBUG_TriggerLED();

#endif /* DEBUG_H_ */
