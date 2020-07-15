import oscP5.*;
import netP5.*;
import controlP5.*;
import java.util.*;

OscP5 oscP5;
ControlP5 cp5;
final int oscPort = 9001;
ScrollableList trackerList;

StringList trackerSerials;
String trackerToRecord = "";
float[] trackerPosRot;

PrintWriter writer;
boolean isWriting = false;
int writeT0;
int recordTime = 0;


String[] help = {
  "Press key for action:",
  "h - toogle this help display",
  "n - create new or overwrite save file",
  "r - start / stop recording values",
  "e - close opened file and exit"
};
boolean showHelp = false;
int helpTextSize = 12;
int helpTextW, helpTextH;

String statusText = "waiting something to do";
color statusTextColor = color(0);



void setup() {
  size(960, 680, P3D);
  
  oscP5 = new OscP5(this, oscPort);
  statusText = "ready to receive OSC on port " + oscPort;
  cp5 = new ControlP5(this);
  cp5.setColor(ControlP5.THEME_GREY);
  trackerList = cp5.addScrollableList("tracker_to_follow")
     .setPosition(width-200, 0)
     .setSize(200, 100)
     .setBarHeight(2 * helpTextSize)
     .setItemHeight(2 * helpTextSize)
     .setType(ScrollableList.DROPDOWN)
     ;
  
  textSize(helpTextSize);
  helpTextW = 0;
  for(String s : help) {
    if(textWidth(s) > helpTextW)
      helpTextW = ceil(textWidth(s));
  }
  helpTextW += 20;
  helpTextH = ceil((help.length + 1) * helpTextSize * 1.5);
  
  trackerSerials = new StringList();
  trackerPosRot = new float[7];
  
  ellipseMode(CENTER);
}



void tracker_to_follow(int n) {
  trackerToRecord = trackerSerials.get(n);
  statusText = "Tracker to follow / record is " + trackerToRecord;
}



void draw() {
  background(64);
  
  fill(196);
  stroke(64);
  strokeWeight(2);
  rect(1, height - (1.5 * helpTextSize), width - 2, (1.5 * helpTextSize) - 1);
  fill(statusTextColor);
  int xOffset = 10;
  int statusTextW = ceil(textWidth(statusText)) + 20;
  xOffset -= frameCount % statusTextW;
  int textInstanceX = xOffset;
  while(textInstanceX < width) {
    text(statusText + " | ", textInstanceX, height - helpTextSize * 0.5);
    textInstanceX += statusTextW;
  }
  
  if(showHelp) {
    fill(0, 128);
    noStroke();
    rect(0, 0, helpTextW, helpTextH);
    fill(255);
    textSize(helpTextSize);
    textAlign(LEFT);
    float y = 1.5 * helpTextSize;
    for(String s : help) {
      text(s, 10, y);
      y += 1.5 * helpTextSize;
    }
  }
  else {
    fill(0, 128);
    noStroke();
    rect(0, 0, helpTextW, 2 * helpTextSize);
    fill(255);
    textSize(helpTextSize);
    textAlign(LEFT);
    float y = 1.5 * helpTextSize;
    text("Press 'h' for help", 10, y);
  }
  
  fill(255);
  int elapsedRecording = isWriting? millis() - writeT0 : recordTime;
  text(timeString(elapsedRecording), 10, height - (1.8 * helpTextSize));
  
  
  // draw ground grid
  pushMatrix();
  stroke(255);
  strokeWeight(1);
  translate(width/2, height, -height);
  rotateX(HALF_PI);
  int gridHalfSize = 5;
  for(int l = -gridHalfSize; l <= gridHalfSize; l++) {
    line(100 * l, -gridHalfSize * 100, 100 * l, gridHalfSize * 100);
  }
  for(int r = -gridHalfSize; r <= gridHalfSize; r++) {
    line(-gridHalfSize * 100, 100 * r, gridHalfSize * 100, 100 * r);
  }
  stroke(255, 0, 0);
  line(0, 0, 0, 100, 0, 0);
  stroke(0, 255, 0);
  line(0, 0, 0, 0, 0, 100);
  stroke(0, 0, 255);
  line(0, 0, 0, 0, 100, 0);
    
  if(!trackerToRecord.equals("")) {
    fill(255);
    stroke(0);
    pushMatrix();
    translate(trackerPosRot[0]*100,trackerPosRot[2]*100, trackerPosRot[1]*100);
    box(20);
    popMatrix();
    stroke(255, 255, 0);
    strokeWeight(3);
    line(trackerPosRot[0]*100, trackerPosRot[2]*100, trackerPosRot[1]*100, trackerPosRot[0]*100, trackerPosRot[2]*100, 0);
    fill(255, 255, 0, 128);
    ellipse(trackerPosRot[0]*100, trackerPosRot[2]*100, 40, 40);
  }
  popMatrix();
}



String timeString(int millis) {
  int h = millis / 3600000;
  int m = millis / 60000 - h * 60;
  int s = millis / 1000 - m * 60 - h * 3600;
  int mi = millis % 1000;  
  return nf(h,2) + ":" + nf(m, 2) + ":" + nf(s, 2) + "." + nf(mi, 3);
}



void keyPressed() {
  switch(key) {
    case 'h':
    case 'H':
      showHelp = !showHelp;
      break;
    case 'n':
    case 'N':
      File f = new File(dataPath("")+"/*.csv"); 
      selectOutput("Select a file to write to:", "fileSelected", f);
      break;
    case 'r':
    case 'R':
      if(writer != null) {
        isWriting = !isWriting;
        if(isWriting) {
          writeT0 = millis() - recordTime;
          statusTextColor = color(0, 127, 0);
          statusText = "RECORDING VALUES";
        }
        else {
          recordTime = millis() - writeT0;
          statusTextColor = color(0, 0, 0);
          statusText = "recording paused";
        }
      }
      else {
        statusTextColor = color(127, 0, 0);
        statusText = "No save file selected";
      }
      break;
    case 'e':
    case 'E':
      if(writer != null) {
        writer.flush();
        writer.close();
      }
      exit();
      break;
    default:
      break;
  }
}



void fileSelected(File selection) {
  if (selection == null) {
    println("No file selected.");
  } else {
    println("Tracker path will be saved to " + selection.getAbsolutePath());
    writer = createWriter(selection.getAbsolutePath());
    statusTextColor = color(0);
    statusText = "Tracker path will be saved to " + selection.getAbsolutePath();
  }
}



void oscEvent(OscMessage m) {
  if(m.checkAddrPattern("/iss/tracker")) {
    String serial = m.get(0).stringValue();
    if(!trackerSerials.hasValue(serial)) {
      trackerSerials.append(serial);
      trackerList.addItem(serial, serial);
    }
    if(trackerToRecord.equals(serial)) {
      //m.print();
      for(int i = 0; i < 7; i++) {
        trackerPosRot[i] = m.get(i+1).floatValue();
      }
      if(isWriting && writer != null) {
        writer.print(millis() - writeT0 + ",");
        int i = 0;
        for(float f : trackerPosRot) {
          writer.print(f);
          if(i < 6)
            writer.print(",");
          else
            writer.println("");
          i++;
        }
        writer.flush();
      }
    }
  }
}
