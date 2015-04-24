#include "SmokeSensor.h"

module SmokeSensorP {
	provides interface SmokeSensor;
}

implementation {

	command void SmokeSensor.getReading(){
		uint16_t smokeValue = 10;
		signal 	SmokeSensor.doneReading(SUCCESS, smokeValue);
	}
}

