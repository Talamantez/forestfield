//processing serial library:
import processing.serial.*;
//minim sound synthesis libraries:
import ddf.minim.*;
import ddf.minim.signals.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;

int indent=40;
//Serial Variables:
Serial port;  // Create object from Serial class
//Signal Strength Data Received from Serial Port
int rssi;// signal strength received from the the transmitting dancer's 
            // xbee module. rssi range is between 36 and 80. 36 is, like, 0. 

//Boxcar average Variables:
int window_size=40;//size of the Box car array to average
int[] readings = new int[window_size]; //create an array called "readings" that will be averaged
int index = 0;//start at the first index of the array
int total = 0;//total will = total- readings[index]
float average = 0; //average will = total/window_size
int low_rssi = 36;//lowest rssi value->maps to 1
int high_rssi = 80;// highest rssi value-> maps to width
PFont font;
//Audio Variables:
int onCount = 0;//"On" Counter, counts the time that performers have been close
              //and is used to increment the volume the longer they've been near each other
            
int offCount = 0;//"Off" Counter, counts the time that performers have been apart
              //and is used to decrement the volume the longer they've been apart

int onThreshold = 0;//set the threshold that the "On" Counter has to reach before the volume increments
int offThreshold = 1;//set the threshold that the "Off" Counter has to reach before the volume decrements

float onIncrement = 2;//amount volume is increased per near time step
float offIncrement = .7;//amount volume is decresead per away time step
float volMax = 120.0;//maximum volume
float volMin = 30.0;//minimum volume

float vol;//This is the amplitude (functionally volume) used in the synthesizer
int off=0;//This is the variable for the amplitude when a note is turned off

int closeCount=0;//count how many times performers have come close
int farCount=0;//count how many time performers have been far - closenessCount can't increase 
                 //until this has an equal value

AudioOutput out;//audio output
SineWave sineG;//audio G sine wave
SineWave sineC;//audio C sine wave
SineWave sineF;//audio F sine wave
SineWave sineB;//B flat sine wave
Minim minim;//minim session
//End audio variables


//Graphics variables
//color
float r, g, b;//red, green, and blue color values used to draw the fractal and the background
//create the range of color values - since we want high contrast colors, we require that the 
//rgb values are all either below 5 or above 250.
int low=5;//create a low threshold for r,g,b
int high=250;//create a high threshold for r,g,b

//drawing variables
float a;//fractal branching angle
float theta;// theta = radians(a)
float c;//branch # modulator-randomizes when rssi reaches minimum

//**----END VARIABLES----**\\


//*************SET UP THE SKETCH*********\\
void setup(){
   size(screenWidth, screenHeight);//set the size to 1100 px wide and 768 high
   
  
  //**SECTION HEAD------SERIAL EVENT-----**//
//**This section created a serial event. The serial port reads the rssi strength up to the
//size of of the window array "readings". This will then be averaged later as the
//functional RSSI(the control value for all dynamics in the project)
  //println(Serial.list());
  String arduinoPort = Serial.list()[0];
  port = new Serial(this, arduinoPort, 9600);
  for (int thisReading = 0; thisReading < window_size; thisReading++)
    readings[thisReading]=0;

//**SECTION FOOTER-----SERIAL EVENT**//

//**MAIN HEADER-------------AUDIO------------**\\
  //**SECTION HEADER----AUDIO SYNTH-----**\\
   //**This section creates a sine wave audio synthesizer from the Minim Library**//
  minim = new Minim(this);
  // get a line out from Minim, default bufferSize is 1024, default sample rate is 44100, bit depth is 16
  out = minim.getLineOut(Minim.STEREO);
  // create a sine wave Oscillator, set to 440 Hz, at 0.5 amplitude(volume, sample rate from line out
  sineG = new SineWave(196.00, off, out.sampleRate());//1st sine wave - frequency between G and an A
  sineC = new SineWave(130.81, off, out.sampleRate());//2nd sine wave - frequency between C and D
  sineF = new SineWave(174.61, off, out.sampleRate());//3rd sine wave - frequency ~F
  sineB = new SineWave(20.60, off, out.sampleRate()); 
 //sineB = new SineWave(120.21, off, out.sampleRate());low option 4th sine wave - low b flat
  //sineB = new SineWave(00.01, off, out.sampleRate());//low option 4th sine wave - low b flat
  // set the portamento speed on the oscillator to 200 milliseconds
  sineG.portamento(200);
  sineC.portamento(200);
  sineF.portamento(200);
  sineB.portamento(50);
 // add the oscillator to the line out
  out.addSignal(sineG);
  out.addSignal(sineC);  
  out.addSignal(sineF);  
  out.addSignal(sineB);
  //**SECTION FOOTER----AUDIO SYNTH-----**//
  
//MAIN FOOTER ------------AUDIO-----------**\\
}
//***********END SKETCH SETUP**********\\



//*******BEGIN MAIN LOOP*********\\
void serialEvent (Serial myPort) {
  // get the signal strength between the dancers' xbee modules through the serial port:
  rssi= myPort.read();
}

void draw(){
 println(vol);
  println(onCount); 
 
 
 smooth();//turn on antialiasing
 //**SECTION HEADER ---- PROCESS THE RSSI **\\    
  total = total - readings[index];
  readings[index] = rssi;
  total = total + readings[index];
  index = index + 1;
  
   if (index == window_size)
    index = 0;

    average = (total / window_size);
    
  average= map(average, low_rssi, high_rssi, 1, width);  //1 is min screen width
  
  if (average<=0)
    average=0; 
//**SECTION FOOTER ----PROCESS THE RSSI***\\

 
  
//*MAIN HEADER -----------AUDIO---------------******\\  
              
   //**SECTION HEAD------SYNTH VOLUME CONTROLLER------**//
 //**The following code increments the volume while the performers are very close
 //and decrements it if they are away from each other**//
 //**Use the closeCount to control which notes are played
  
   if (rssi>=58){
     if (farCount==4)farCount=closeCount;
     else if (closeCount>farCount)farCount+=1;
   }
                                       
   if (rssi<=36 && closeCount==farCount){
          closeCount+=1;
   }

                                       
  if (closeCount==5)closeCount=1;
  if (farCount==5)farCount=1;
  if (closeCount==1){
if(average<=36){  //if rssi is at its lowest value 
              //(performers are as close as they can get to oneanother
            //increse the closenessCount  
              //run this code:
       offCount=0;//set the "Off" Counter to Zero
      if(vol>=volMax){    //if the volume is maxxed out
                onCount = 0; //set the On counter to 0
                //continue;  //and continue with the show
                     }
       else{              //else
                onCount+=1;//increment the "On" Counter
                      if(onCount>=onThreshold){  //if the "On" Counter reaches the "On" Threshold
                               vol+=onIncrement; //increase the volume
                               onCount = 0;        //set the "On" Counter to 0
                                              }
                                                            }
          sineG.setAmp(vol);//set the amplitude of the sine wave synth to the new volume
          sineC.setAmp(off);
          sineF.setAmp(off);
          sineB.setAmp(off);
        }
else{           
   onCount=0; //set the "On" Counter to zero 
   
  if(vol<=volMin){//if the volume is minned out
        offCount = 0;   } 
  else{    //
          offCount+=1;//increment the "Off" Counter
                 if(offCount>=offThreshold){ //if the "Off" Counter reaches the "Off" Threshold
                            vol-=offIncrement; //decrease the volume\
                             offCount = 0;       //and set the "Off" Counter to 0
                                            }
                 else{                         //if the "Off" Counter hasn't reached the 
                                               //decrement threshold yet
                     // continue;                //continue with the show
                 }                      
   }
   sineG.setAmp(vol);//set the amplitude of the sine wave synth to the new volume
   sineC.setAmp(off);
   sineF.setAmp(off);
   sineB.setAmp(off);
 }   }
else if (closeCount ==2){
if(average<=36){  //if rssi is at its lowest value 
              //(performers are as close as they can get to oneanother
            //increse the closenessCount  
              //run this code:
       offCount=0;//set the "Off" Counter to Zero
      if(vol>=volMax){    //if the volume is maxxed out
                onCount = 0; //set the On counter to 0
                //continue;  //and continue with the show
                     }
       else{              //else
                onCount+=1;//increment the "On" Counter
                      if(onCount>=onThreshold){  //if the "On" Counter reaches the "On" Threshold
                               vol+=onIncrement; //increase the volume
                               onCount = 0;        //set the "On" Counter to 0
                                              }
                                                            }
          sineG.setAmp(vol);//set the amplitude of the sine wave synth to the new volume
          sineC.setAmp(vol);
          sineF.setAmp(off);
          sineB.setAmp(off);
        }
else{           
   onCount=0; //set the "On" Counter to zero 
   
  if(vol<=volMin){//if the volume is minned out
        offCount = 0;   } 
  else{    //
          offCount+=1;//increment the "Off" Counter
                 if(offCount>=offThreshold){ //if the "Off" Counter reaches the "Off" Threshold
                            vol-=offIncrement; //decrease the volume\
                             offCount = 0;       //and set the "Off" Counter to 0
                                            }
                 else{                         //if the "Off" Counter hasn't reached the 
                                               //decrement threshold yet
                     // continue;                //continue with the show
                 }                      
   }
   sineG.setAmp(vol);//set the amplitude of the sine wave synth to the new volume
   sineC.setAmp(vol);
   sineF.setAmp(off);
   sineB.setAmp(off);
 }   }
 
 else if(closeCount ==3){
if(average<=36){  //if rssi is at its lowest value 
              //(performers are as close as they can get to oneanother
            //increse the closenessCount  
              //run this code:
       offCount=0;//set the "Off" Counter to Zero
      if(vol>=volMax){    //if the volume is maxxed out
                onCount = 0; //set the On counter to 0
                //continue;  //and continue with the show
                     }
       else{              //else
                onCount+=1;//increment the "On" Counter
                      if(onCount>=onThreshold){  //if the "On" Counter reaches the "On" Threshold
                               vol+=onIncrement; //increase the volume
                               onCount = 0;        //set the "On" Counter to 0
                                              }
                                                            }
          sineG.setAmp(vol);//set the amplitude of the sine wave synth to the new volume
          sineC.setAmp(vol);
          sineF.setAmp(vol);
          sineB.setAmp(off);
      }
else{         //else, if the rssi is not at its l
              //(the performers are away from each other)
              //run this code:              
   onCount=0; //set the "On" Counter to zero 
   
  if(vol<=volMin){//if the volume is minned out
        offCount = 0;//set the "Off" counter to 0
       // continue;  //and continue with the show
   } 
  else{    //
          offCount+=1;//increment the "Off" Counter
                 if(offCount>=offThreshold){ //if the "Off" Counter reaches the "Off" Threshold
                            vol-=offIncrement; //decrease the volume\
                             offCount = 0;       //and set the "Off" Counter to 0
                                            }
                 else{                         //if the "Off" Counter hasn't reached the 
                                               //decrement threshold yet
                     // continue;                //continue with the show
                 }                      
   }
   sineG.setAmp(vol);//set the amplitude of the sine wave synth to the new volume
   sineC.setAmp(vol);
   sineF.setAmp(vol);
   sineB.setAmp(off);
 }   }
 
 else if(closeCount ==4){
if(average<=36){
       offCount=0;//set the "Off" Counter to Zero
      if(vol>=volMax){    //if the volume is maxxed out
                onCount = 0; //set the On counter to 0
                     }
       else{
                onCount+=1;//increment the "On" Counter
                      if(onCount>=onThreshold){  //if the "On" Counter reaches the "On" Threshold
                               vol+=onIncrement; //increase the volume
                               onCount = 0;        //set the "On" Counter to 0
                                              }}
          sineG.setAmp(vol);//set the amplitude of the sine wave synth to the new volume
          sineC.setAmp(vol);
          sineF.setAmp(vol);
          sineB.setAmp(vol);  
      }
else{               
   onCount=0;
  if(vol<=volMin){//if the volume is minned out
        offCount = 0;//set the "Off" counter to 0
   } 
  else{
          offCount+=1;//increment the "Off" Counter
                 if(offCount>=offThreshold){ //if the "Off" Counter reaches the "Off" Threshold
                            vol-=offIncrement; //decrease the volume\
                             offCount = 0;       //and set the "Off" Counter to 0
                                            }
                 else{                         //if the "Off" Counter hasn't reached the 
                                               //decrement threshold yet
                     // continue;                //continue with the show
                 }                      
   }
   sineG.setAmp(vol);//set the amplitude of the sine wave synth to the new volume
   sineC.setAmp(vol);
   sineF.setAmp(vol);
   sineB.setAmp(vol);
 }   }
 
 println("close count = " + closeCount);//,indent,80);
  println("far count = " + farCount);//,indent,120); 
  
    //**SECTION FOOTER----AUDIO SYNTH VOLUME CONTROLLER-----**//


//**MAIN FOOTER------------AUDIO----------------***\\



//**MAIN HEADER -----------GRAPHICS--------------**\\
  //**The following code controls the projected graphics**\\
  
  background(0);
  frameRate(30);

  //**SECTION HEAD ----HIGH CONTRAST COLOR RANDOMIZER-----**\\
 //**This section randomizes color when the performers are very far away. The rgb values of the projected fractal and 
//background randomize after reaching a high rssi number. 
  if (rssi>=70) { //if rssi value is > or = to 70, 
    r=random(0, 255); //randomize red
    while (r>low && r<high)//if color is not high enough contrast
    {
      r=random(0, 255);//randomize again
    }
//println (r);//print the red value

    g=random(0, 255);//randomize green
    while (g>low && g<high)//if color is not high contrast
    {
      g=random(0, 255);//randomize again
    }
    //println (g);//print the green value    

    b=random(0, 255);//randomize blue
    while (b>low && b<high)//if the color is not high contrast
    {
      b=random(0, 255);//randomize again
    }
    //println (b);//print the blue value
  }
  //**SECTION FOOTER ----HIGH CONTRAST COLOR RANDOMIZER-----**\\
  //**SECTION HEADER ---TREE FRACTAL-----**\\
//The following code controls the drawing of the projected tree fractal and background 
  // Let's pick an angle 0 to 90 degrees based on the value of the rssi
     //**SUB SECTION HEADER---COLOR OF BACKGROUND AND FRACTAL---**\\
  background(255-r, 255-g, 255-b); //set background to the inverse of the 
                                  //randomized r,g,b values. This makes the color of the
                                  //background always the complement to the color of the
                                  //fractal
  stroke(r, g, b); //set the line color to the randomized r,g,b colors
     //**SUB SECTION FOOTER ---COLOR OF BACKGROUND AND FRACTAL----**\\
  
     //**SUB SECTION HEADER ---BRANCHING ANGLE CONTROL---**\\
     //Here, we relate the rssi to the branching angle:
     //the closer the dancers are, the smaller the branching angle.
  if (rssi<=36) { //if the rssi is at its minimum (dancers are close)
         a=0;    //the branching angle is Zero (this results in a projected vertical line)
               }
               
  else {         //if the rssi is not at minimum
        a =  ((average)/width) * 135f;//the branching angle = the rssi average/width *135f 
       }                              //I don't remember what f is? 
       
  theta = radians(a);//convert angle to radians
      //** SUB SECTION FOOTER ---BRANCHING ANGLE CONTROL---**\\
      
      //** SUB SECTION HEADER ---DRAW THE FRACTAL---**\\
  translate(550, 700);// Draw a line 120 pixels
  strokeWeight(20); //set the stroke weight to 20
  line(0, 0, 0, -100);//draw the first line
  // Move to the end of that line
  translate(0, -100);
  // Start the recursive branching
  branch(300);
  stroke(255);
  int h=2*height/3;
     //**SUB SECTION FOOTER ---DRAW THE FRACTAL---**\\
     
     delay(0);//Delay the loop
//**MAIN FOOTER --------------GRAPHICS-------------**\\     
}
//******END OF MAIN LOOP*********//


//**MAIN HEADER ---------FUNCTION DEFINITIONS-----------------****\\

  //**SECTION HEADER----BRANCH FUNCTION---**\\
  //**the Branch function is drawn in halves**\\
void branch(float h) {
  // Each branch will be 2/3rds the size of the previous one
  float sw= map(h, 2, 100, 1, 5);//taper the branches- this makes the trunk thick and the 
                                 //twigs at the end of the branches very thin
  strokeWeight(sw); //set the strokeWeight to sw
  
  if (rssi<=36)//if the rssi is less than 36
    c=random(.6, .62);//slightly randomize the number of branches 
    h*= c;//multiply the length of the branches by the new           
// Draw the lines. If the pixel size is smaller than 2, stop the recursive branching
  if (h > 2) {
    pushMatrix();    // Save the current state of transformation 
    rotate(theta);   // Rotate the screen reference by theta
    line(0, 0, 0, -h);  // Draw the branch
    translate(0, -h); // Move to the end of the branch
    branch(h);       // Call the branch function to draw the next recursive branch
    popMatrix();     // Return to the orgiginal screen reference point
    strokeWeight(sw); //set the strokeWeight to sw
    //Repeat the recursive branching on the left side of the screen
    pushMatrix();
    rotate(-theta);
    line(0, 0, 0, -h);
    translate(0, -h);
    branch(h);
    popMatrix();
  }
}

  //**SECTION FOOTER ----BRANCH FUNCTION---**\\
  
  //**MAIN FOOTER ---------FUNCTION DEFINITIONS-----------------****\\
