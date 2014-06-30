/*
 *   RSSI is NOT filtered or averaged.
 *   Alert is off   
 *
 *   Based on ConnectedV2.pde
 */ 

#include <NewSoftSerial.h>
#include <XBee.h>

//set up serial to xbee
NewSoftSerial xbeeSerial(3, 4);
XBee xbee = XBee();
XBeeResponse response = XBeeResponse();

//broadcasts to all FFFF
uint8_t payload[] = {0, 0};
TxStatusResponse txStatus = TxStatusResponse();
Tx16Request tx = Tx16Request(5678, payload, sizeof(payload));

// create reusable response objects for responses we expect to handle 
Rx16Response rx16 = Rx16Response();

//timing variables in milliseconds
unsigned long lastTimeSent;
unsigned long sendInterval = 100; //1000 for 5 agents  //2000 ms for 8 agents

//message variables
uint8_t data;
uint8_t rssi = 0;
uint8_t addr;
unsigned long msgcount = 0;

void setup() {
  
  Serial.begin(9600);
  Serial.println("hi");

  xbee.setSerial(&xbeeSerial);

  // start serial
  xbee.begin(9600);  
}


void loop() {  
  parsePacket();
    
  //send message every second, defined by sendInterval
  if (millis() - lastTimeSent > sendInterval)
    sendMsg();
} // loop


void parsePacket(){
  xbee.readPacket(10);

  while (xbee.getResponse().isAvailable()) {
    // got something

    if (xbee.getResponse().getApiId() == RX_16_RESPONSE) {
      // got a rx16 packet
      getRx16Reponse();
   } 
    
  long unsigned now  = millis();
  xbee.readPacket(10
  );
  
  }//got something

}


void sendMsg(){
    lastTimeSent = millis(); 
    xbee.send(tx);
//    Serial.println("sent!");
    
}

void getRx16Reponse(){
  int length, nedges;
  xbee.getResponse().getRx16Response(rx16);
  uint8_t * data;
  data = rx16.getData(); 
  length = rx16.getDataLength();
  rssi = rx16.getRssi();
  addr = rx16.getRemoteAddress16();

  msgcount++;   
  
 // Serial.print(addr, DEC);
  //Serial.print(" ");
  //Serial.print(msgcount, DEC);
  //Serial.print(" ");
  //Serial.print(millis(), DEC);

  //Serial.print(" ");
  //Serial.println(rssi, DEC);
  Serial.println(payload[0]);

}



