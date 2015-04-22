#include "FireDetection.h"

configuration FireDetectionAppC {

}
implementation {
	//basic
	components MainC;
	components FireDetectionC as App;
	
	//comunication
	components new TimerMilliC() as Timer0;
	components ActiveMessageC;
	components new AMSenderC(AM_BLINKTORADIO);
	components new AMReceiverC(AM_BLINKTORADIO);

	//logic
	components SensorNodeP;
	components RoutingNodeP;
	
	App.Boot -> MainC;
	App.Timer0 -> Timer0;

	App.Packet -> AMSenderC;
	App.AMPacket -> AMSenderC;
	App.AMSend -> AMSenderC;
	App.AMControl -> ActiveMessageC;
	App.Receive -> AMReceiverC;

	App.SensorNode -> SensorNodeP;
	App.RoutingNode ->RoutingNodeP;
}
