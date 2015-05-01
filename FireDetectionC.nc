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
	bool isBusy=FALSE;
	bool isConnected=FALSE;
	bool isWaitingAck=FALSE;
	bool isEmergent=FALSE;
	bool forcedSend=FALSE;
	message_t pkt; 
	message_t emergertMsg;

	/*for sensor nodes*/
	bool isRegistred = FALSE;
	uint16_t myRoutingNode;		
	uint16_t timeStamp=0;
	uint16_t value1;		//humidity, x_gps
	uint16_t value2;		//temperature, y_gps
	bool value3;			//smoke value

	/*for routing nodes*/
	uint16_t numSensorNodes=0;
	uint8_t	myRank=0;
	
	

	event void Boot.booted() {
		call AMControl.start();
	}
	
	event void Timer1.fired(){
		if(!IS_SERVERNODE(TOS_NODE_ID)){
			if(!isEmergent){
				if(isWaitingAck){
					//timeout!
					dbg("Debug", "Something nasty happend, i'm broadcasting discovry again!\n");
					isConnected = FALSE;
					isWaitingAck = FALSE;
				}
			}else {
				NetworkMsg* btrpkt = (NetworkMsg*)(call Packet.getPayload(&emergertMsg, sizeof (NetworkMsg)));
				dbg("Debug", "Force transmitting emergency msg!\n");
				btrpkt->rank=FORCE_ROOT_RANK;
				if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(NetworkMsg)) == SUCCESS) {	//FIXME: Change my size!
					isBusy=TRUE;
					if(myRank!=1){
						isWaitingAck=TRUE;
						forcedSend=TRUE;
					}
				}	
			}
		}
	}
 
	event void Timer0.fired() {
		if (!isBusy) {
			if(IS_SENSORNODE(TOS_NODE_ID)){
				if(isConnected){
					if(!isWaitingAck){
						NetworkMsg* btrpkt = (NetworkMsg*)(call Packet.getPayload(&pkt, sizeof (NetworkMsg)));
						if(isRegistred){
							dbg("Debug", "Send rmsg\n");	
							call TemperatureSensor.getReading();
							call SmokeSensor.getReading();
							call HumiditySensor.getReading();
							if(value3){
								btrpkt->opcode = EMERGENCY_OPCODE;			
							}else {
								btrpkt->opcode = ROUTE_OPCODE;
							}
							btrpkt->nodeid = TOS_NODE_ID;
							btrpkt->rank = FORCE_ROOT_RANK;
							btrpkt->value1 = value1;
							btrpkt->value3 = value3;
							btrpkt->value2 = value2;
							btrpkt->measureTime = timeStamp;
							timeStamp++;	
						}else{
							call GpsSensor.getGpsCoordinates(TOS_NODE_ID);
							btrpkt->opcode = REGISTER_GPS_OPCODE;
							btrpkt->nodeid = TOS_NODE_ID;
							btrpkt->rank = FORCE_ROOT_RANK;
							btrpkt->value1 = value1;
							btrpkt->value2 = value2;
						}
						if (call AMSend.send(myRoutingNode, &pkt, sizeof(NetworkMsg)) == SUCCESS) {			//FIXME: Change my size!
							isBusy = TRUE;
							isWaitingAck = TRUE;
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
	


				}else {
					NetworkMsg* btrpkt = (NetworkMsg*)(call Packet.getPayload(&pkt, sizeof (NetworkMsg)));
					dbg("Debug", "OMG halp me!\n");	
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
			if(myRank!=1){
				isBusy = FALSE;
				call Timer1.startPeriodic(FAILURE_TIMEOUT_MILLI);
			}
		}
	}

	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {

			if(IS_SERVERNODE(TOS_NODE_ID)){
				isConnected=TRUE;
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
		//dbg("Debug", "Got message from %d, opcode:%d\n", call AMPacket.source(msg), btrpkt->opcode);	
		if (len == sizeof(NetworkMsg)) {		//FIXME: Msg size
			if(IS_SENSORNODE(TOS_NODE_ID)){
				if(isConnected){
					dbg("Debug", "Got something. opcode:%d nodeid:%d \n", btrpkt->opcode, btrpkt->nodeid);	
					if(isWaitingAck){
						if(isRegistred){
							if(myRoutingNode == call AMPacket.source(msg)){
								call Timer1.stop();
								isWaitingAck=FALSE;
							}
						}else if(btrpkt->opcode==REGISTER_GPS_OPCODE && btrpkt->nodeid==TOS_NODE_ID) {
							dbg("Debug", "Got reg ack.\n");	
							call Timer1.stop();
							isWaitingAck=FALSE;
							isRegistred=TRUE;
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
						if(forcedSend){
							forcedSend=FALSE;
							isEmergent=FALSE;
							isConnected=FALSE;
							isWaitingAck=FALSE;
						}else if(myRank>btrpkt->rank){
							call Timer1.stop();
							isWaitingAck=FALSE;
						}
					}else {
						if(btrpkt->opcode==EMERGENCY_OPCODE){
							if(btrpkt->rank>myRank || btrpkt->rank==FORCE_ROOT_RANK){
								NetworkMsg* res = (NetworkMsg*)(call Packet.getPayload(&pkt, sizeof (NetworkMsg)));
								res->opcode = btrpkt->opcode;
								res->nodeid = btrpkt->nodeid;
								res->rank = myRank;
								res->value1 = btrpkt->value1;
								res->value2 = btrpkt->value2;
								res->value3 = btrpkt->value3;
								res->measureTime = btrpkt->measureTime;
								emergertMsg=pkt;
								if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(NetworkMsg)) == SUCCESS) {	//FIXME: Change my size!
									isBusy = TRUE;
									if(myRank!=1){
										isWaitingAck=TRUE;
										isEmergent=TRUE;
									}
								}
							}						
						}else if(btrpkt->opcode==ROUTE_OPCODE){
							if(btrpkt->rank>myRank || btrpkt->rank==FORCE_ROOT_RANK){
								NetworkMsg* res = (NetworkMsg*)(call Packet.getPayload(&pkt, sizeof (NetworkMsg)));
								res->opcode = btrpkt->opcode;
								res->nodeid = btrpkt->nodeid;
								res->rank = myRank;
								res->value1 = btrpkt->value1;
								res->value2 = btrpkt->value2;
								res->value3 = btrpkt->value3;
								res->measureTime = btrpkt->measureTime;
								if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(NetworkMsg)) == SUCCESS) {	//FIXME: Change my size!
									isBusy = TRUE;
									if(myRank!=1){
										isWaitingAck = TRUE;
									}
								}						
							}
						}else if(btrpkt->opcode==DISCOVER_OPCODE){
							if(btrpkt->nodeid!=TOS_NODE_ID){
								NetworkMsg* res = (NetworkMsg*)(call Packet.getPayload(&pkt, sizeof (NetworkMsg)));
								res->opcode = btrpkt->opcode;
								res->nodeid = btrpkt->nodeid;
								res->rank = myRank;
								if(IS_ROUTINGNODE(btrpkt->nodeid)){
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
									dbg("Debug", "Changed rank:%d \n", myRank);	
								}
							}
						}else if(btrpkt->opcode==REGISTER_GPS_OPCODE){
							if(btrpkt->rank>myRank || btrpkt->rank==FORCE_ROOT_RANK){
								NetworkMsg* res = (NetworkMsg*)(call Packet.getPayload(&pkt, sizeof (NetworkMsg)));
								res->opcode = btrpkt->opcode;
								res->nodeid = btrpkt->nodeid;
								res->rank = myRank;
								res->value1 = btrpkt->value1;
								res->value2 = btrpkt->value2;
								if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(NetworkMsg)) == SUCCESS) {	//FIXME: Change my size!
									isBusy = TRUE;
								}
							}
						}


					}


				}else {
					if(btrpkt->opcode==DISCOVER_OPCODE && btrpkt->nodeid==TOS_NODE_ID){
						myRank=btrpkt->rank;
						isConnected=TRUE;
						dbg("Debug", "Connected rank:%d \n", myRank);	
					}
				}


			}else if(IS_SERVERNODE(TOS_NODE_ID)){
				if(btrpkt->opcode==ROUTE_OPCODE){
					dbg("Debug", "Received reading %d from sensor %d\n", btrpkt->measureTime,  btrpkt->nodeid);	

				}else if(btrpkt->opcode==REGISTER_GPS_OPCODE){
					dbg("Debug", "Received gps reg x:%d y:%d from sensor %d\n", btrpkt->value1, btrpkt->value2, btrpkt->nodeid);
				
				}else if(btrpkt->opcode==EMERGENCY_OPCODE){
					dbg("Debug", "Received smoke %d from sensor %d\n", btrpkt->measureTime,  btrpkt->nodeid);	

				}else if(btrpkt->opcode==DISCOVER_OPCODE){

					NetworkMsg* res = (NetworkMsg*)(call Packet.getPayload(&pkt, sizeof (NetworkMsg)));
					res->opcode = btrpkt->opcode;
					res->nodeid = btrpkt->nodeid;

					if(IS_ROUTINGNODE(btrpkt->nodeid)){
						res->rank = myRank+1;
					}

					if (call AMSend.send(call AMPacket.source(msg), &pkt, sizeof(NetworkMsg)) == SUCCESS) {	//FIXME: Change my size!
						isBusy = TRUE;
					}	
				}


			}
		}
		return msg;
	}


	event void HumiditySensor.doneReading(error_t err, uint16_t humidityValue){
		if(err==SUCCESS){
			value1=humidityValue;		
		}
	}

	event void TemperatureSensor.doneReading(error_t err, uint16_t temperatureValue){
		if(err==SUCCESS){
			value2=temperatureValue;
		}
	}

	event void SmokeSensor.doneReading(error_t err, bool smokeValue){
		if(err==SUCCESS){
			value3=smokeValue;	
		}
	}

	event void GpsSensor.receiveCoordinates(error_t err, uint16_t x, uint16_t y){
		if(err==SUCCESS){
			value1=x;
			value2=y;
		}		
	}

}


