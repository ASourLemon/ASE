#include "HumiditySensor.h"

module HumiditySensorP {
	provides interface HumiditySensor;
	uses interface Random;
}

implementation {

	command void HumiditySensor.getReading(){
		uint16_t humidityValue = (call Random.rand16() % (MAX_HUMIDITY - MIN_HUMIDITY)) + MIN_HUMIDITY;
		signal 	HumiditySensor.doneReading(SUCCESS, humidityValue);
	}
}

