#include "TemperatureSensor.h"

module TemperatureSensorP {
	provides interface TemperatureSensor;
}

implementation {

	command void TemperatureSensor.getReading(){
		uint16_t temperatureValue = 16;
		signal 	TemperatureSensor.doneReading(SUCCESS, temperatureValue);
	}
}

