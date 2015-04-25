#include "GpsSensor.h"

module GpsSensorP {
	provides interface GpsSensor;
}

implementation {

	command void GpsSensor.getGpsCoordinates(uint16_t id){
		uint16_t x = 100;
		uint16_t y = 100;
		signal 	GpsSensor.receiveCoordinates(SUCCESS, x, y);
	}
}

