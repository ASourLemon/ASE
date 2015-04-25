#ifndef FIREDETECTION_H
#define FIREDETECTION_H

#include <Timer.h>
#include "NetworkNode.h"
#include "GpsSensor.h"
#include "TemperatureSensor.h"
#include "SmokeSensor.h"
#include "HumiditySensor.h"

 
enum {
	AM_BLINKTORADIO = 6,
	TIMER_PERIOD_MILLI = 10
};

typedef nx_struct RoutingMsg {

	nx_uint16_t nodeid;
	nx_uint16_t msgNumber;

	nx_uint16_t humidityValue;
	nx_uint16_t smokeValue;
	nx_uint16_t temperatureValue;

	nx_uint16_t measureTime;

	

} RoutingMsg;
 
 
#endif
