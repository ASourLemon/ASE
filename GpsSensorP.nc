#include "GpsSensor.h"

module GpsSensorP {
	provides interface GpsSensor;
	uses interface Random;
}

implementation {

	command void GpsSensor.getGpsCoordinates(uint16_t id){
		uint16_t x = call Random.rand16() % FIELD_WIDTH;
		uint16_t y = call Random.rand16() % FIELD_HEIGHT;;
		signal 	GpsSensor.receiveCoordinates(SUCCESS, x, y);
	}
}

