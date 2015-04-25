#ifndef NETWORKNODE_H
#define NETWORKNODE_H


//Sensor notes have ids greater than 100
//Routing nodes have ids lower of equal to 99
#define IS_ROUTINGNODE(id)(id<100 && id>0)
#define IS_SENSORNODE(id)(id>99)
#define IS_SERVERNODE(id)(id==0)

#define MAX_SENSOR_NODES 100

enum {
	SENSORNODE_PERIOD_MILLI = 10	
};
 
#endif
