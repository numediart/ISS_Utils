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


public class ViveTrackerPose {
  private int lastUpdate;
  private String serial;
  private float x, y, z;
  private float qx, qy, qz, qw;
  private PGraphics pg;
  
  
  
  public ViveTrackerPose(Object[] oscArguments) {
    pg = createGraphics(200, (height - 20)/2);
    serial = (String)oscArguments[0];
    update(oscArguments);
  }
  
  
  
  public void update(Object[] oscArguments) {
    if(oscArguments.length == 8) {
      x = (float)oscArguments[1];
      y = (float)oscArguments[2];
      z = (float)oscArguments[3];
      qx = (float)oscArguments[4];
      qy = (float)oscArguments[5];
      qz = (float)oscArguments[6];
      qw = (float)oscArguments[7];
      lastUpdate = millis();
    }
  }
  
  
  
  public String serial() {
    return serial;
  }
  
  
  
  public int getLastUpdateTime() {
    return lastUpdate;
  }
  
  
  
  public PImage getAsImage() {
    pg.beginDraw();
    pg.background(0);
    pg.noFill();
    pg.stroke(127);
    pg.strokeWeight(3);
    pg.rect(5, 5, pg.width - 10, pg.height - 10);
    pg.fill(64, 196, 64);
    pg.textSize(16);
    pg.textAlign(CENTER);
    int lineY = 32;
    pg.text(serial, pg.width/2, lineY);
    pg.textAlign(LEFT);
    lineY += 48;
    pg.text("x :  " + nfs(x, 0, 2), 20, lineY);
    lineY += 24;
    pg.text("y :  " + nfs(y, 0, 2), 20, lineY);
    lineY += 24;
    pg.text("z :  " + nfs(z, 0, 2), 20, lineY);
    lineY += 24;
    pg.text("qx : " + nfs(qx, 0, 2), 20, lineY);
    lineY += 24;
    pg.text("qy : " + nfs(qy, 0, 2), 20, lineY);
    lineY += 24;
    pg.text("qz : " + nfs(qz, 0, 2), 20, lineY);
    lineY += 24;
    pg.text("qw : " + nfs(qw, 0, 2), 20, lineY);
    pg.endDraw();
    return pg.get();
  }
}
