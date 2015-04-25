#include "FireDetection.h"
 
module FireDetectionC {
	//basic 
	uses interface Boot;
	uses interface Timer<TMilli> as Timer0;

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
	message_t pkt; 
	uint16_t x_coordinate;
	uint16_t y_coordinate;


	/*for sensor nodes*/
	uint16_t timeStamp=0;
	uint16_t readTemperatureValue;
	uint16_t readHumidityValue;
	uint16_t readSmokeValue;

	/*for routing nodes*/
	uint16_t numSensorNodes = 0;
	uint16_t messageNumber[100][2];
	

	event void Boot.booted() {
		call AMControl.start();
	}
 
	event void Timer0.fired() {
		if (!isBusy) {
			if(IS_SENSORNODE(TOS_NODE_ID)){
				RoutingMsg* btrpkt = (RoutingMsg*)(call Packet.getPayload(&pkt, sizeof (RoutingMsg)));

				call TemperatureSensor.getReading();
				call SmokeSensor.getReading();
				call HumiditySensor.getReading();

				btrpkt->nodeid = TOS_NODE_ID;
				btrpkt->humidityValue = readHumidityValue;
				btrpkt->smokeValue = readSmokeValue;
				btrpkt->temperatureValue = readTemperatureValue;
				btrpkt->measureTime = timeStamp;
				//timeStamp++;
				if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(RoutingMsg)) == SUCCESS) {
					isBusy = TRUE;
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
			call Timer0.startPeriodic(SENSORNODE_PERIOD_MILLI);
		}
		else {
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err) {
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		if (len == sizeof(RoutingMsg)) {
			if(IS_ROUTINGNODE(TOS_NODE_ID)){
				RoutingMsg* btrpkt = (RoutingMsg*)payload;
				uint16_t i;
				bool found=FALSE;
				for(i=0;i<numSensorNodes;i++){
					if(messageNumber[i][0]==btrpkt->nodeid){
						found=TRUE;
						if(messageNumber[i][1]<btrpkt->measureTime){
							messageNumber[i][1]=btrpkt->measureTime;
							if (call AMSend.send(AM_BROADCAST_ADDR, msg, sizeof(RoutingMsg)) == SUCCESS) {
								dbg("Debug", "Routed msg %d from %d\n", btrpkt->measureTime, btrpkt->nodeid);	
								isBusy = TRUE;
							}
						}else {
							dbg("Debug", "Discarded msg %d from %d\n", btrpkt->measureTime, btrpkt->nodeid);
						}
						
					}
				}
				
				if(!found){
					messageNumber[numSensorNodes][0]=btrpkt->nodeid;
					messageNumber[numSensorNodes][1]=btrpkt->measureTime;
					numSensorNodes++;
					if (call AMSend.send(AM_BROADCAST_ADDR, msg, sizeof(RoutingMsg)) == SUCCESS) {
						dbg("Debug", "Routed msg %d from %d and registered\n", btrpkt->measureTime, btrpkt->nodeid);	
						isBusy = TRUE;
					}
				}
			}else if(IS_SERVERNODE(TOS_NODE_ID)){
					RoutingMsg* btrpkt = (RoutingMsg*)payload;
					dbg("Debug", "Received reading %d from sensor %d\n", btrpkt->measureTime,  btrpkt->nodeid);	
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


