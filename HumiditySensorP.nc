#include "HumiditySensor.h"

module HumiditySensorP {
	provides interface HumiditySensor;
}

implementation {

	command void HumiditySensor.getReading(){
		uint16_t humidityValue = 8;
		signal 	HumiditySensor.doneReading(SUCCESS, humidityValue);
	}
}

