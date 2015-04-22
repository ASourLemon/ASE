#ifndef FIREDETECTION_H
#define FIREDETECTION_H

#include <Timer.h>
#include "SensorNode.h"
#include "RoutingNode.h"
 
enum {
	AM_BLINKTORADIO = 6,
	TIMER_PERIOD_MILLI = 1
};

typedef nx_struct RoutingMsg {

	nx_uint16_t nodeid;
	nx_uint16_t counter;

} RoutingMsg;
 
 
#endif
