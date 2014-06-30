import pitaru.sonia_v2_9.*;
import processing.serial.*;

Serial myPort;
    int val;
    int current = 0;
    int last = 0;
    
Sample mySample;

void setup() { 
  
  Sonia.start(this); 
  mySample = new Sample("satisfied.wav"); 
  
  mySample.play();
  mySample.setVolume(.2) ;
  mySample.repeat(); 
   size(400,300);   //window size
     
     //list all the available serial ports
     println(Serial.list());
     myPort = new Serial(this, "COM3", 9600);
      
     background(150,200,5);
}


void draw () {}

void serialEvent (Serial myPort) {
  // get the byte:
  int inByte = myPort.read(); 
  // print it:
  println(inByte);
  mySample.setVolume(inByte/25) ;
}

