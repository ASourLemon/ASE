

interface SmokeSensor {

	//implemented by the node
	command void getReading();

	//implemented by the user
	event void doneReading(error_t err, uint16_t smokeValue);

}

