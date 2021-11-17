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
import java.util.*;

OscP5 oscP5;
int thisOscPort = 9001; // Listening port

NetAddress[] remotes = { // sending addresses and ports
  new NetAddress("127.0.0.1", 9001),
  new NetAddress("127.0.0.1", 9876)
};

PrintWriter writer;
boolean isWriting = false;
int writeT0;
int recordTime = 0;

String[] lines;
int lineIndex = -1;
boolean isReading = false;
boolean loopReading = false;
int playbackT0 = -1;
int playbackTime = 0;

String[] help = {
  "Press key for action:",
  "h - toogle this help display",
  "n - create new or overwrite save file",
  "r - start / stop recording values",
  "o - open playback file",
  "p - Play / pause playback",
  "l - Loop / unloop playback",
  "s - Stop playback",
  "t - send OSC test message",
  "e - close opened file and exit"
};
boolean showHelp = false;
int helpTextSize = 12;
int helpTextW, helpTextH;



void setup() {
  size(640, 320);
  
  oscP5 = new OscP5(this, thisOscPort);
  println("ready to receive OSC on port " + thisOscPort);
  for(NetAddress rem : remotes)
    println("playback data will be sent to " + rem.address() + ":" + rem.port());
  
  textFont(createFont("Consolas", helpTextSize));
  textSize(helpTextSize);
  helpTextW = 0;
  for(String s : help) {
    if(textWidth(s) > helpTextW)
      helpTextW = ceil(textWidth(s));
  }
  helpTextW += 20;
  helpTextH = ceil((help.length + 1) * helpTextSize * 1.5);
  
  ellipseMode(CENTER);
}


void updateValuesAndSendOsc() {
  if(isReading && lineIndex > -1) {
    int ms;
    do {
      String line = lines[lineIndex];
      String[] values = split(line, ',');
      ms =  Integer.parseInt(values[0]);
      if(millis() - playbackT0 >= ms) {
        OscMessage msg = new OscMessage(values[1]);
        String typetag = values[2];
        int i = 3;
        for(char t : typetag.toCharArray()) {
          switch(t) {
            case 's':
              msg.add(values[i]);
              break;
            case 'i':
              msg.add(Integer.parseInt(values[i]));
              break;
            case 'f':
              msg.add(Float.parseFloat(values[i]));
              break;
            default:
              println("type not handled");
              break;
          }
          i++;
        }
        for(NetAddress rem : remotes)
          oscP5.send(msg, rem);
        lineIndex++;
        if(lineIndex >= lines.length) {
          if(loopReading) {
            lineIndex = 0;
            playbackT0 = millis();
          }
          else {
            isReading = false;
            lineIndex = -1;
            playbackT0 = -1;
            playbackTime = ms;
          }
        }
      }
      else break;
    }
    while(millis() - playbackT0 >= ms && lineIndex >= 0 && lineIndex < lines.length);
  }
}


void draw() {
  background(0);
  updateValuesAndSendOsc();

  if(showHelp) {
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
    fill(255);
    textSize(helpTextSize);
    textAlign(LEFT);
    float y = 1.5 * helpTextSize;
    text("Press 'h' for help", 10, y);
  }
  fill(0, 128);
  
  fill(255);
  int elapsedRecording = isWriting? millis() - writeT0 : recordTime;
  String elapsedTimeString = timeString(elapsedRecording);
  textAlign(LEFT, CENTER);
  textSize(1.4*helpTextSize);
  int timeStringY = height - round(2.8 * helpTextSize);
  text(elapsedTimeString, 10, timeStringY);
  int recordIconX = 10 + round(textWidth(elapsedTimeString)) + 20;
  stroke(255);
  fill(255, 128);
  rectMode(CENTER);
  rect(recordIconX, timeStringY, 20, 20, 4);
  if(isWriting) {
    fill(255, 0, 0);
    ellipse(recordIconX, timeStringY, 12, 12);
  }
  else {
    fill(255);
    noStroke();
    rect(recordIconX - 4, timeStringY, 4, 14);
    rect(recordIconX + 4, timeStringY, 4, 14);
  }
  

    pushStyle();
    fill(255);
    int elapsedPlayback = isReading? millis() - playbackT0 : playbackTime;
    String elapsedPlaybackTimeString = timeString(elapsedPlayback);
    textAlign(LEFT, CENTER);
    textSize(1.4*helpTextSize);
    timeStringY = height - round(5.8 * helpTextSize);
    text(elapsedPlaybackTimeString, 10, timeStringY);
    if(lines != null) {
      int playbackIconX = 10 + round(textWidth(elapsedTimeString)) + 20;
      stroke(255);
      fill(255, 128);
      rectMode(CENTER);
      rect(playbackIconX, timeStringY, 20, 20, 4);
      if(isReading) {
        fill(0, 196, 0);
        triangle(playbackIconX-6, timeStringY-6, playbackIconX-6, timeStringY+6, playbackIconX+6, timeStringY);
      }
      else {
        fill(255);
        noStroke();
        rect(playbackIconX - 4, timeStringY, 4, 14);
        rect(playbackIconX + 4, timeStringY, 4, 14);
      }
      if(loopReading) {
        stroke(255);
        fill(255, 128);
        rectMode(CENTER);
        playbackIconX += 40;
        rect(playbackIconX, timeStringY, 20, 20, 4);
        noFill();
        strokeWeight(2);
        arc(playbackIconX, timeStringY, 12, 12, PI/4, TWO_PI);
        strokeWeight(1);
        line(playbackIconX+6, timeStringY, playbackIconX+3, timeStringY-3);
        line(playbackIconX+6, timeStringY, playbackIconX+8, timeStringY-3);
      }
    }
    popStyle();

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
      if(!isReading) {
        File f = new File(dataPath("")+"/*.csv"); 
        selectOutput("Select a file to write to:", "fileSelectedForWriting", f);
      }
      else {
        println("can't save while reading");
      }
      break;
    case 'r':
    case 'R':
      if(writer != null && !isReading) {
        isWriting = !isWriting;
        if(isWriting) {
          writeT0 = millis() - recordTime;
          println("RECORDING VALUES");
        }
        else {
          recordTime = millis() - writeT0;
          println("recording paused");
        }
      }
      else {
        println("No save file selected");
      }
      break;
    case 'o':
    case 'O':
      if(!isWriting) {
        File of = new File(dataPath("")+"/*.csv"); 
        selectInput("Select a file to read:", "fileSelectedForReading", of);
      }
      else {
        println("can't read while recording");
      }
      break;
    case 'p':
    case 'P': {
      if(lines != null && !isWriting) {
        isReading = !isReading;
        if(playbackT0 < 0 && isReading) {
          playbackT0 = millis();
          playbackTime = 0;
          lineIndex = 0;
        }
        else if(playbackT0 >= 0 && !isReading) {
          // pause begins
          playbackTime = millis() - playbackT0;
        }
        else if(playbackT0 >= 0 && isReading) {
          // pause ends
          playbackT0 = millis() - playbackTime;
        }
      }
      else {
        println("Open a csv file before playing");
      }
    }
      break;
    case 'l':
    case 'L':
      loopReading = !loopReading;
      break;
    case 's':
    case 'S':
      isReading = false;
      playbackT0 = -1;
      lineIndex = -1;
      break;
    case 't':
    case 'T':
      OscMessage msg = new OscMessage("/oscrecorder/test");
      msg.add(123);
      for(NetAddress rem : remotes)
          oscP5.send(msg, rem);
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



void fileSelectedForWriting(File selection) {
  if (selection == null) {
    println("No file selected.");
  } else {
    println("Tracker path will be saved to " + selection.getAbsolutePath());
    writer = createWriter(selection.getAbsolutePath());
    recordTime = 0;
  }
}


void fileSelectedForReading(File selection) {
  if (selection == null) {
    println("No file selected.");
  } else {
    println("Reading path from " + selection.getAbsolutePath());
    lines = loadStrings(selection.getAbsolutePath());
  }
}



void oscEvent(OscMessage m) {
  m.print();
  if(isWriting && writer != null) {
    writer.print(millis() - writeT0);
    writer.print("," + m.addrPattern());
    String typetag = m.typetag();
    writer.print(","  + typetag);
    int i = 0;
    for(char t : typetag.toCharArray()) {
      switch(t) {
        case 's':
          writer.print("," + m.get(i).stringValue());
          break;
        case 'i':
          writer.print("," + m.get(i).intValue());
          break;
        case 'f':
          writer.print("," + m.get(i).floatValue());
          break;
        default :
          println("arg type not handled : " + t);
          break;
      }
      i++;
    }
    writer.println("");
    writer.flush();
  }
}
