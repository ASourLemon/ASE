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

	FORCE_ROOT_RANK = 0,			/*Used when a node wants to force send a mensage.*/

	DISCOVER_OPCODE = 0,			/*Used for node deployment.*/	
	ROUTE_OPCODE = 1,				/*Used for routing msgs*/
	REGISTER_GPS_OPCODE = 2,		/*Used for sensor node gps registry*/
	EMERGENCY_OPCODE = 3			/*Used for emergent msgs, i.e. smoke detected*/ 
	
};

typedef nx_struct NetworkMsg {

	nx_uint8_t opcode;
	nx_uint16_t nodeid;
	nx_uint8_t rank;

	nx_uint16_t value1;		//humidity, x_gps
	nx_uint16_t value2;		//temperature, y_gps
	nx_uint8_t value3;		//smoke value

	nx_uint16_t measureTime;

} NetworkMsg;
 
 
#endif
