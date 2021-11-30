// Copyright (c) 2020 UMONS - numediart - CLICK'
// 
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
// 
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA


import oscP5.*;
import netP5.*;
import controlP5.*;
import java.util.Map;

OscP5 oscP5;
int oscPort = 9001;

ControlP5 cp5;


final int TIMEOUT = 2000; // (milliseconds) after how long without message the trackers are removed from hashmap
IntList messagesT0;
HashMap<String, ViveTrackerPose> trackers;



void setup() {
  size(1200, 540);

  oscP5 = new OscP5(this, oscPort);
  
  cp5 = new ControlP5(this);
  //cp5.setColor(ControlP5.THEME_GREY);
  cp5.addTextfield("osc_port")
     .setPosition(width-180, 0)
     .setSize(60, 20)
     .setText(""+oscPort)
     .setFont(createFont("arial", 12))
     .getCaptionLabel()
       .align(ControlP5.LEFT_OUTSIDE, ControlP5.CENTER)
       .toUpperCase(false)
       .setText("OSC Port")
       .getStyle()
         .setPaddingLeft(-10)     
     ;
  cp5.addBang("changePort")
     .setPosition(width - 80, 0)
     .setSize(60, 20)
     .setFont(createFont("arial", 12))
     .getCaptionLabel()
       .align(ControlP5.CENTER, ControlP5.CENTER)
       .toUpperCase(false)
       .setText("Change")
     ;    
     
  println("Now listening port " + oscPort + " for incomming OSC messages");
  
  messagesT0 = new IntList();
  trackers = new HashMap<String, ViveTrackerPose>();
  
  fill(255);
  textSize(18);
  delay(500);
}



public void changePort() {
  int oscPortTemp = int(cp5.get(Textfield.class,"osc_port").getText());
  if(oscPortTemp >= 1024 && oscPortTemp <= 65536) {
    oscPort = oscPortTemp;
    oscP5.stop();
    oscP5 = new OscP5(this, oscPort);
    println("Now listening port " + oscPort + " for incomming OSC messages");
  }
  else {
    System.err.println("The OSC port must be betwen 1024 and 65536");
    cp5.get(Textfield.class,"osc_port").setText("" + oscPort);
  }
}



void draw() {
  background(0);
  int loopTime = millis();
  
  // update display
  if(trackers.size() > 0) {
    synchronized(trackers) {
      StringList toRemove = new StringList();
      int x = 0;
      int y = 20;
      for (ViveTrackerPose t : trackers.values()) {
        if(loopTime - t.getLastUpdateTime() > TIMEOUT) {
          toRemove.append(t.serial());
        }
        else {
          image(t.getAsImage(), x, y);
          x += 200;
          if(x >= width) {
            x = 0;
            y += (height - 20)/2;
          }
        }
      }
      for(String s : toRemove) {
        trackers.remove(s);
      }
    }
  }
  
  float valPerSecond = 0;
  if(messagesT0.size() > 1) {
    synchronized(messagesT0) {
      valPerSecond = messagesT0.size() * 1000.0 / (messagesT0.get(messagesT0.size() - 1) - messagesT0.get(0));
      if((loopTime - messagesT0.get(messagesT0.size() - 1)) > 5000) {
         messagesT0.clear();
      }
    }
  }
  text("values per second : " + (valPerSecond > 0 && trackers.size() > 0? nf(valPerSecond/trackers.size(), 0, 2) : "none"), 20, 20);
}



void oscEvent(OscMessage msg) {
  synchronized(messagesT0) {
    messagesT0.append(millis());
    if(messagesT0.size() > 50) {
      messagesT0.remove(0);
    }
  }
  synchronized(trackers) {
    String serial = msg.get(0).stringValue();
    if(trackers.containsKey(serial)) {
      trackers.get(serial).update(msg.arguments());
    }
    else {
      trackers.put(serial, new ViveTrackerPose(msg.arguments()));
    }
  }
}
