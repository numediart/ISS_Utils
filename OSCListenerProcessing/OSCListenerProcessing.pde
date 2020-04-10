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
import java.util.Map;

OscP5 oscP5;

final int TIMEOUT = 2000; // (milliseconds) after how long without message the trackers are removed from hashmap
IntList messagesT0;
HashMap<String, ViveTrackerPose> trackers;



void setup() {
  size(1200, 540);

  oscP5 = new OscP5(this, 9001);
  
  messagesT0 = new IntList();
  trackers = new HashMap<String, ViveTrackerPose>();
  
  fill(255);
  textSize(18);
  delay(500);
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
  
  float valPerSecond = -1;
  if(messagesT0.size() > 1) {
    synchronized(messagesT0) {
      valPerSecond = messagesT0.size() * 1000.0 / (messagesT0.get(messagesT0.size() - 1) - messagesT0.get(0));
      if((loopTime - messagesT0.get(messagesT0.size() - 1)) > 5000) {
         messagesT0.clear();
      }
    }
  }
  text("values per second : " + nf(valPerSecond, 0, 2), 20, 20);
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
  //msg.print();
}
