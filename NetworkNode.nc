

interface NetworkNode {

	//implemented by the node
	command void getReading();

	//implemented by the user
	event void readingDone(error_t err, uint16_t sensorReading, uint16_t sensorID);

}

