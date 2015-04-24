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
	components HumiditySensorP;
	components SmokeSensorP;
	components TemperatureSensorP;
	components NetworkNodeP;
	components GpsP;

	//***************//
	//basic
	App.Boot -> MainC;
	App.Timer0 -> Timer0;

	//comunication
	App.Packet -> AMSenderC;
	App.AMPacket -> AMSenderC;
	App.AMSend -> AMSenderC;
	App.AMControl -> ActiveMessageC;
	App.Receive -> AMReceiverC;

	//logic
	App.HumiditySensor -> HumiditySensorP;
	App.SmokeSensor -> SmokeSensorP;
	App.TemperatureSensor -> TemperatureSensorP;
	App.NetworkNode -> NetworkNodeP;
	App.Gps -> GpsP;
}
