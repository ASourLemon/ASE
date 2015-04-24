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
	uses interface NetworkNode;
	uses interface Gps;
	uses interface TemperatureSensor;
	uses interface SmokeSensor;
	uses interface HumiditySensor;

}
implementation {
	bool busy = FALSE;
	message_t pkt; 

	uint16_t counter = 0;

	event void Boot.booted() {
		call AMControl.start();
	}
 
	event void Timer0.fired() {
		dbg("Counter", "Event!\n");
		counter++;
		if (!busy) {
			//RoutingMsg* btrpkt = (RoutingMsg*)(call Packet.getPayload(&pkt, sizeof (RoutingMsg)));
			//btrpkt->nodeid = TOS_NODE_ID;
			//btrpkt->counter = counter;
			//if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(RoutingMsg)) == SUCCESS) {
			//	busy = TRUE;
			//}	
			call NetworkNode.getReading();
			call Gps.getGpsCoordinates(TOS_NODE_ID);
			call TemperatureSensor.getReading();
			call SmokeSensor.getReading();
			call HumiditySensor.getReading();
		}
	}

	event void AMSend.sendDone(message_t* msg, error_t error) {
		if (&pkt == msg) {
			busy = FALSE;
		}
	}

	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {
			call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
		}
		else {
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err) {
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		if (len == sizeof(RoutingMsg)) {
			RoutingMsg* btrpkt = (RoutingMsg*)payload;
			dbg("Counter", "Received counter %d from %d\n", btrpkt->counter,  btrpkt->nodeid);
		}
		return msg;
	}

	event void NetworkNode.readingDone(error_t err, uint16_t sensorReading, uint16_t sensorID){
		if(err==SUCCESS){
			dbg("Counter", "Received reading %d from sensor %d\n", sensorReading, sensorID);			
		}
	}

	event void HumiditySensor.doneReading(error_t err, uint16_t humidityValue){
		if(err==SUCCESS){
			dbg("Counter", "Received reading %d from humidity sensor\n", humidityValue);			
		}
	}

	event void TemperatureSensor.doneReading(error_t err, uint16_t temperatureValue){
		if(err==SUCCESS){
			dbg("Counter", "Received reading %d from temperature sensor\n", temperatureValue);			
		}
	}

	event void SmokeSensor.doneReading(error_t err, uint16_t smokeValue){
		if(err==SUCCESS){
			dbg("Counter", "Received reading %d from smoke sensor\n", smokeValue);			
		}
	}

	event void Gps.receiveCoordinates(error_t err, uint16_t x, uint16_t y){
		if(err==SUCCESS){
			dbg("Counter", "Received gps coordinates: %d : %d\n", x, y);
		}		
	}

}


