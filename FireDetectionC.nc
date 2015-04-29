#include "FireDetection.h"
 
module FireDetectionC {
	//basic 
	uses interface Boot;
	uses interface Timer<TMilli> as Timer0;
	uses interface Timer<TMilli> as Timer1;

	//communication
	uses interface Packet; 						//access the message_t struct
	uses interface AMPacket;					//access message_t struct
	uses interface AMSend; 						//send menssages
	uses interface SplitControl as AMControl; 	//
	uses interface Receive; 					//receive packets

	//logic
	uses interface GpsSensor;
	uses interface TemperatureSensor;
	uses interface SmokeSensor;
	uses interface HumiditySensor;

}
implementation {
	/*for all nodes*/
	bool isBusy = FALSE;
	bool isConnected = FALSE;
	bool isWaitingAck = FALSE;
	message_t pkt; 



	/*for sensor nodes*/
	bool isRegistred = FALSE;
	uint16_t x_coordinate;
	uint16_t y_coordinate;
	uint16_t myRoutingNode;		
	uint16_t timeStamp=0;
	uint16_t readTemperatureValue;
	uint16_t readHumidityValue;
	uint16_t readSmokeValue;

	/*for routing nodes*/
	uint16_t numSensorNodes = 0;
	uint8_t	myRank=0;
	
	

	event void Boot.booted() {
		call AMControl.start();
	}
	
	event void Timer1.fired(){
		if(!IS_SERVERNODE(TOS_NODE_ID)){
			if(isWaitingAck){
				//timeout!
				dbg("Debug", "Something nasty happend, i'm broadcasting discovry again!\n");
				isConnected = FALSE;
				isWaitingAck = FALSE;
			}
		}
	}
 
	event void Timer0.fired() {
		if (!isBusy) {
			if(IS_SENSORNODE(TOS_NODE_ID)){
				if(isConnected){
					if(!isWaitingAck){
						NetworkMsg* btrpkt = (NetworkMsg*)(call Packet.getPayload(&pkt, sizeof (NetworkMsg)));
						if(TRUE){
							call TemperatureSensor.getReading();
							call SmokeSensor.getReading();
							call HumiditySensor.getReading();
							btrpkt->opcode = ROUTE_OPCODE;
							btrpkt->nodeid = TOS_NODE_ID;
							btrpkt->rank = FORCE_ROOT_RANK;
							btrpkt->humidityValue = readHumidityValue;
							btrpkt->smokeValue = readSmokeValue;
							btrpkt->temperatureValue = readTemperatureValue;
							btrpkt->measureTime = timeStamp;
							timeStamp++;	

						}else{
							call GpsSensor.getGpsCoordinates(TOS_NODE_ID);
							btrpkt->opcode = REGISTER_GPS_OPCODE;
							btrpkt->nodeid = TOS_NODE_ID;
							btrpkt->rank = FORCE_ROOT_RANK;
							btrpkt->x_gps_coordinate = x_coordinate;
							btrpkt->y_gps_coordinate = y_coordinate;
							isRegistred = TRUE; //FIXME: NEED ACKS FOR THIS OPERATION!
						}
						if (call AMSend.send(myRoutingNode, &pkt, sizeof(NetworkMsg)) == SUCCESS) {			//FIXME: Change my size!
							isBusy = TRUE;
							isWaitingAck = TRUE;
							call Timer1.startPeriodic(FAILURE_TIMEOUT_MILLI);
						}
					}else {
						//do nothing
						return;
					}
				}else {
					NetworkMsg* btrpkt = (NetworkMsg*)(call Packet.getPayload(&pkt, sizeof (NetworkMsg)));
					dbg("Debug", "Sending discovery!\n");	
					btrpkt->opcode = DISCOVER_OPCODE;
					btrpkt->nodeid = TOS_NODE_ID;
					if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(NetworkMsg)) == SUCCESS) {			//FIXME: Change my size!
						isBusy = TRUE;
					}	
				}
			}else if(IS_ROUTINGNODE(TOS_NODE_ID)){
				if(isConnected){
					//do nothing, just receive messages
				}else {
					NetworkMsg* btrpkt = (NetworkMsg*)(call Packet.getPayload(&pkt, sizeof (NetworkMsg)));
					btrpkt->opcode = DISCOVER_OPCODE;
					btrpkt->nodeid = TOS_NODE_ID;
					if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(NetworkMsg)) == SUCCESS) {			//FIXME: Change my size!
						isBusy = TRUE;
					}	
				}	
			}
		}
	}

	event void AMSend.sendDone(message_t* msg, error_t error) {
		if (&pkt == msg) {
			isBusy = FALSE;
		}
	}

	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {

			if(IS_SERVERNODE(TOS_NODE_ID)){
				isConnected=TRUE;
			}else {
				//call Timer1.startPeriodic(FAILURE_TIMEOUT_MILLI);
			}

			call Timer0.startPeriodic(SENSORNODE_PERIOD_MILLI);
		}
		else {
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err) {
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		NetworkMsg* btrpkt = (NetworkMsg*)payload;
		dbg("Debug", "Got message from %d, opcode:%d\n", call AMPacket.source(msg), btrpkt->opcode);	
		if (len == sizeof(NetworkMsg)) {		//FIXME: Msg size
			if(IS_SENSORNODE(TOS_NODE_ID)){
				if(isConnected){
					dbg("Debug", "Got something. opcode:%d nodeid:%d \n", btrpkt->opcode, btrpkt->nodeid);	
					if(isWaitingAck){
						if(myRoutingNode == call AMPacket.source(msg)){
							call Timer1.stop();
							isWaitingAck=FALSE;
							dbg("Debug", "Stoped timer\n");	
						}else{
							dbg("Debug", "Discarded\n");	
						}
					}
				}else {
					if(btrpkt->opcode==DISCOVER_OPCODE && btrpkt->nodeid==TOS_NODE_ID){
						myRoutingNode = call AMPacket.source(msg);
						isConnected=TRUE;	
						dbg("Debug", "I'm connected to node %d\n", myRoutingNode);	
					}
				}
			}else if(IS_ROUTINGNODE(TOS_NODE_ID)){
				if(isConnected){

					if(isWaitingAck){
						if(myRank>btrpkt->rank){
							call Timer1.stop();
							isWaitingAck=FALSE;
						}
					}else {

						if(btrpkt->opcode==ROUTE_OPCODE){
							if(btrpkt->rank>myRank || btrpkt->rank==FORCE_ROOT_RANK){
								NetworkMsg* res = (NetworkMsg*)(call Packet.getPayload(&pkt, sizeof (NetworkMsg)));
								res->opcode = btrpkt->opcode;
								res->nodeid = btrpkt->nodeid;
								res->rank = myRank;
								res->humidityValue = btrpkt->humidityValue;
								res->smokeValue = btrpkt->smokeValue;
								res->temperatureValue = btrpkt->temperatureValue;
								res->measureTime = btrpkt->measureTime;
								dbg("Debug", "Routed msg from %d\n", call AMPacket.source(msg));	
								if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(NetworkMsg)) == SUCCESS) {	//FIXME: Change my size!
									isBusy = TRUE;
									if(myRank!=1){
										isWaitingAck = TRUE;
									}
									call Timer1.startPeriodic(FAILURE_TIMEOUT_MILLI);
								}						
							}else {
								dbg("Debug", "Discarded msg from %d\n", call AMPacket.source(msg));	
							}
						}else if(btrpkt->opcode==DISCOVER_OPCODE){
							if(btrpkt->nodeid!=TOS_NODE_ID){
								NetworkMsg* res = (NetworkMsg*)(call Packet.getPayload(&pkt, sizeof (NetworkMsg)));
								res->opcode = btrpkt->opcode;
								res->nodeid = btrpkt->nodeid;
								res->rank = myRank;
								if(IS_SENSORNODE(btrpkt->nodeid)){
									res->routingid = TOS_NODE_ID;
								}else if(IS_ROUTINGNODE(btrpkt->nodeid)){
									res->rank = myRank+1;
									myRoutingNode = call AMPacket.source(msg);
								}
								if (call AMSend.send(call AMPacket.source(msg), &pkt, sizeof(NetworkMsg)) == SUCCESS) {	//FIXME: Change my size!
									isBusy = TRUE;
								}
							}else {
								if(myRank>btrpkt->rank){
									myRank=btrpkt->rank;
									myRoutingNode = call AMPacket.source(msg);
								}
							}
						}else if(btrpkt->opcode==REGISTER_GPS_OPCODE){
							NetworkMsg* res = (NetworkMsg*)(call Packet.getPayload(&pkt, sizeof (NetworkMsg)));
							res->opcode = btrpkt->opcode;
							res->nodeid = btrpkt->nodeid;
							res->x_gps_coordinate = btrpkt->x_gps_coordinate;
							res->y_gps_coordinate = btrpkt->y_gps_coordinate;
							if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(NetworkMsg)) == SUCCESS) {	//FIXME: Change my size!
								isBusy = TRUE;
							}
						}


					}


				}else {
					if(btrpkt->opcode==DISCOVER_OPCODE && btrpkt->nodeid==TOS_NODE_ID){
						myRank=btrpkt->rank;
						isConnected=TRUE;
					}
				}


			}else if(IS_SERVERNODE(TOS_NODE_ID)){
				if(btrpkt->opcode==ROUTE_OPCODE){
					dbg("Debug", "Received reading %d from sensor %d\n", btrpkt->measureTime,  btrpkt->nodeid);	

				}else if(btrpkt->opcode==REGISTER_GPS_OPCODE){
					dbg("Debug", "Received gps reg x:%d y:%d from sensor %d\n", btrpkt->x_gps_coordinate, btrpkt->y_gps_coordinate, btrpkt->nodeid);
	
				}else if(btrpkt->opcode==DISCOVER_OPCODE){

					NetworkMsg* res = (NetworkMsg*)(call Packet.getPayload(&pkt, sizeof (NetworkMsg)));
					res->opcode = btrpkt->opcode;
					res->nodeid = btrpkt->nodeid;

					if(IS_SENSORNODE(btrpkt->nodeid)){
						res->routingid = TOS_NODE_ID;
					}else if(IS_ROUTINGNODE(btrpkt->nodeid)){
						res->rank = myRank+1;
					}

					if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(NetworkMsg)) == SUCCESS) {	//FIXME: Change my size!
						isBusy = TRUE;
					}	
				}


			}
		}
		return msg;
	}


	event void HumiditySensor.doneReading(error_t err, uint16_t humidityValue){
		if(err==SUCCESS){
			readHumidityValue=humidityValue;		
		}
	}

	event void TemperatureSensor.doneReading(error_t err, uint16_t temperatureValue){
		if(err==SUCCESS){
			readTemperatureValue=temperatureValue;
		}
	}

	event void SmokeSensor.doneReading(error_t err, uint16_t smokeValue){
		if(err==SUCCESS){
			readSmokeValue=smokeValue;	
		}
	}

	event void GpsSensor.receiveCoordinates(error_t err, uint16_t x, uint16_t y){
		if(err==SUCCESS){
			x_coordinate=x;
			y_coordinate=y;
		}		
	}

}


