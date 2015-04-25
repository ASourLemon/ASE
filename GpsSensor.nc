

interface GpsSensor {

	//implemented by the node
	command void getGpsCoordinates(uint16_t id);

	//implemented by the user
	event void receiveCoordinates(error_t err, uint16_t x, uint16_t y);

}

