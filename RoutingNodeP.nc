#include "RoutingNode.h"

module RoutingNodeP {
	provides interface RoutingNode;
}

implementation {

	command void RoutingNode.routeMsg(){

		dbg("Counter", "I'm alive!");	
		//signal 	SensorNode.ack(SUCCESS, reading, id);
	}

}

