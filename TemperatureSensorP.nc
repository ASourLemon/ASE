#include "TemperatureSensor.h"

module TemperatureSensorP {
	provides interface TemperatureSensor;
	uses interface Random;
}

implementation {

	command void TemperatureSensor.getReading(){		
		uint16_t temperatureValue = (call Random.rand16() % (MAX_TEMPERATURE - MIN_TEMPERATURE)) + MIN_TEMPERATURE;;
		signal 	TemperatureSensor.doneReading(SUCCESS, temperatureValue);
	}
}

