#include "NetworkNode.h"

module NetworkNodeP {
	provides interface NetworkNode;
}

implementation {

	command void NetworkNode.getReading(){
		uint16_t reading = 7;
		uint16_t id = TOS_NODE_ID;
		signal 	NetworkNode.readingDone(SUCCESS, reading, id);
	}
}

