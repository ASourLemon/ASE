#include "SensorNode.h"

module SensorNodeP {
	provides interface SensorNode;
}

implementation {

	command void SensorNode.getReading(){
		uint16_t reading = 7;
		uint16_t id = TOS_NODE_ID;
		signal 	SensorNode.readingDone(SUCCESS, reading, id);
	}
}

