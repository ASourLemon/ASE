#include "SmokeSensor.h"

module SmokeSensorP {
	provides interface SmokeSensor;
	uses interface Random;
}

implementation {

	command void SmokeSensor.getReading(){
		bool smokeValue = (call Random.rand16() % 100) < SMOKE_PROBABILITY;
		signal 	SmokeSensor.doneReading(SUCCESS, smokeValue);
	}
}

