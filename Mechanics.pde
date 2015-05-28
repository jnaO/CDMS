
interface Channel {
  PVector getPosition(float r);
  void draw();
  void snugTo(Gear moveable, Gear fixed); // position moveable gear on this channel so it is snug to fixed gear, not needed for all channels
}

class MountPoint implements Channel {
  Channel itsChannel = null;
  float itsMountRatio;
  float x, y, radius;
  String typeStr = "MP";
  boolean isFixed = false;
  boolean selected = false;
  
  MountPoint(String typeStr, float x, float y) {
    this.typeStr = typeStr;
    this.itsChannel = null;
    this.itsMountRatio = 0;
    this.isFixed = true;
    this.radius = 12;
    this.x = x*inchesToPoints;
    this.y = y*inchesToPoints;
    println(this.typeStr + " is at " + this.x/inchesToPoints + "," + this.y/inchesToPoints);
  }

  MountPoint(String typeStr, Channel ch, float mr) {
    this.typeStr = typeStr;
    this.itsChannel = ch;
    this.itsMountRatio = mr;
    PVector pt = ch.getPosition(mr);
    this.x = pt.x;
    this.y = pt.y;
    this.radius = 12;
    println(this.typeStr + " is at " + this.x/inchesToPoints + "," + this.y/inchesToPoints);
    if (ch instanceof Gear) {
      println("  " + this.typeStr + " is mounted on a gear");
    }
  }
  
  void nudge(int direction) {
    float amt, mn=0, mx=1;
    if (itsChannel instanceof ConnectingRod) {
      amt = 0.125 * inchesToPoints;
      mx = 15 * inchesToPoints;
    } else {
      amt = 0.01;
    }
    amt *= direction;
    itsMountRatio += amt;
    itsMountRatio = constrain(itsMountRatio, mn, mx);
  }
  
  void doSelect() {
    if (selectMountPoint != null) {
      selectMountPoint.selected = false;
    }
    selected = true;
    selectMountPoint = this;
  }

  boolean isClicked(int mx, int my) {
    PVector p = this.getPosition();
    return dist(mx, my, p.x, p.y) <= this.radius;
  }

  PVector getPosition() {
    return getPosition(0.0);
  }

  PVector getPosition(float r) {
    if (itsChannel != null) {
      return itsChannel.getPosition(itsMountRatio);
    } else {
      return new PVector(x,y);
    }
  }

  void snugTo(Gear moveable, Gear fixed) { // not meaningful
  }
  
  void draw() {
    PVector p = getPosition();
    if (itsChannel instanceof ConnectingRod) {
      itsChannel.draw();
    } 
    if (selected) {
      fill(180,192);
      stroke(50);
    } else {
      fill(180,192);
      stroke(100);
    }
    strokeWeight(selected? 4 : 2);
    ellipse(p.x, p.y, this.radius, this.radius);
  }
}

class ConnectingRod implements Channel {
  MountPoint itsSlide = null;
  MountPoint itsAnchor = null;
  float armAngle = 0;

  ConnectingRod(MountPoint itsSlide, MountPoint itsAnchor)
  {
    this.itsSlide = itsSlide;
    itsSlide.radius = 20;
    this.itsAnchor = itsAnchor;
  }
  
  PVector getPosition(float r) {
    PVector ap = itsAnchor.getPosition();
    PVector sp = itsSlide.getPosition();
    armAngle = atan2(sp.y - ap.y, sp.x - ap.x);
    
    return new PVector(ap.x + cos(armAngle)*r, ap.y + sin(armAngle)*r);
  }  

  void snugTo(Gear moveable, Gear fixed) {
    // not relevant for connecting rods
  }
  
  void draw() {
    PVector ap = itsAnchor.getPosition();
    PVector sp = itsSlide.getPosition();

    itsSlide.draw();
    itsAnchor.draw();

//    pushMatrix();
//      translate(sp.x, sp.y);
//      noFill();
//      stroke(100);
//      fill(254,214,179,192);
//      strokeWeight(itsSlide.selected? 5 : 2);
//      ellipse(0,0,20,20);
//    popMatrix();
    
    noFill();
    stroke(100,200,100,128);
    strokeWeight(.33*inchesToPoints);
    armAngle = atan2(sp.y - ap.y, sp.x - ap.x);
    // println("Drawing arm " + ap.x/inchesToPoints +" " + ap.y/inchesToPoints + " --> " + sp.x/inchesToPoints + " " + sp.y/inchesToPoints);
    float L = 18 * inchesToPoints;
    line(ap.x,ap.y, ap.x+cos(armAngle)*L, ap.y+sin(armAngle)*L);
    
    if (passesPerFrame < 50) {
      stroke(100,100,200,128);
      fill(100,100,200);
      strokeWeight(0.5);
      float notchOffset = 0.73*inchesToPoints;
      float notchIncr = 0.25 * inchesToPoints;
      textFont(nFont);
      textAlign(CENTER);
      pushMatrix();
        translate(ap.x,ap.y);
        rotate(atan2(sp.y-ap.y,sp.x-ap.x));
        for (int i = 0; i < 29*2; ++i) {
          float x = notchOffset + notchIncr*i;
          line(x, 6, x, -(6+(i % 2 == 1? 2 : 0)));
          if (i % 2 == 1) {
            text(""+(1+i/2),x,8);
          }
        }
      popMatrix();
    }
  }
}

class PenRig {
  float len;
  float angle;
  boolean selected = false;
  ConnectingRod itsRod;
  MountPoint itsMP;
  
  PenRig(float len, float angle, ConnectingRod itsRod, float ml) {
    this.len = len * inchesToPoints;
    this.angle = angle;
    this.itsRod = itsRod;
    float mlp = ml * inchesToPoints;

    itsMP = addMP("EX", itsRod, mlp);

    PVector ap = itsMP.getPosition();
    PVector ep = this.getPosition();
    println("Pen Extender " + ap.x/inchesToPoints +" " + ap.y/inchesToPoints + " --> " + ep.x/inchesToPoints + " " + ep.y/inchesToPoints);
  }

  PVector getPosition() {
    PVector ap = itsMP.getPosition();
    return new PVector(ap.x + cos(itsRod.armAngle + this.angle)*this.len, ap.y + sin(itsRod.armAngle + this.angle)*this.len);
  }
  
  boolean isClicked(int mx, int my) 
  {
    PVector ap = itsMP.getPosition();
    PVector ep = this.getPosition();

    return (mx > min(ap.x,ep.x) && mx < max(ap.x,ep.x) &&
            my > min(ap.y,ep.y) && mx < max(ap.y,ep.y) &&
           abs(atan2(my-ep.y,mx-ep.x) - atan2(ap.y-ep.y,ap.x-ep.x)) < radians(5)); 
  }
  
  void doSelect() {
    selected = true;
    selectPenRig = this;
  }
  
  void nudge(int direction, int kc) {
    if (kc == RIGHT || kc == LEFT) {
      this.angle += radians(5)*direction;
    } else {
      this.len += 0.125 * inchesToPoints * direction;
    }
  }
  
  void draw() {
    itsMP.draw();
    PVector ap = itsMP.getPosition();
    PVector ep = this.getPosition();

    float a = atan2(ap.y-ep.y,ap.x-ep.x);
    float d = 6*inchesToPoints;
    ap.x = ep.x + cos(a)*d;
    ap.y = ep.y + sin(a)*d;

    noFill();
    if (selected)
      stroke(255,100,100,192);
    else
      stroke(200,150,150,128);
    strokeWeight(.33*inchesToPoints);
    line(ap.x, ap.y, ep.x, ep.y);
  
    if (passesPerFrame < 50) {
      float notchOffset = (605/300.0)*inchesToPoints;
      float notchIncr = 0.25 * inchesToPoints;
      stroke(100,100,200,128);
      strokeWeight(0.5);
      textFont(nFont);
      textAlign(CENTER);
      pushMatrix();
        translate(ep.x,ep.y);
        rotate(atan2(ap.y-ep.y,ap.x-ep.x));
        noFill();
        ellipse(0,0,4,4);
        line(-4,0,4,0);
        line(0,4,0,-4);
        
        fill(100,100,200);
        for (int i = 0; i < 15; ++i) {
          float x = notchOffset + notchIncr*i;
          line(x, 6, x, -(6+(i % 2 == 0? 2 : 0)));
          if (i % 2 == 0) {
            text(""+(8-i/2),x,8);
          }
        }
      popMatrix();
    }


  }
}

class LineRail implements Channel {
  float x1,y1, x2,y2;
  LineRail(float x1, float y1, float x2, float  y2) {
    this.x1 = x1*inchesToPoints;
    this.y1 = y1*inchesToPoints;
    this.x2 = x2*inchesToPoints;
    this.y2 = y2*inchesToPoints;
  }
  PVector getPosition(float r) {
    return new PVector(x1+(x2-x1)*r, y1+(y2-y1)*r);
  }  

  void draw() {
    noFill();
    stroke(200);
    strokeWeight(.23*inchesToPoints);

    line(x1,y1, x2,y2);
  }
  
  void snugTo(Gear moveable, Gear fixed) {
    float dx1 = x1-fixed.x;
    float dy1 = y1-fixed.y;
    float dx2 = x2-fixed.x;
    float dy2 = y2-fixed.y;
    float a1 = atan2(dy1,dx1);
    float a2 = atan2(dy2,dx2);
    float d1 = dist(x1,y1,fixed.x,fixed.y);
    float d2 = dist(x2,y2,fixed.x,fixed.y);
    float adiff = abs(a1-a2);
    float r = moveable.radius+fixed.radius+meshGap;
    if (adiff > TWO_PI)
      adiff -= TWO_PI;
    if (adiff < .01) {  // if rail is perpendicular to fixed circle
      moveable.mount(this, (r-d1)/(d2-d1));
      // find position on line (if any) which corresponds to two radii
    } else if ( abs(x2-x1) < .01 ) {
      println("Vertical line");
      float m = 0;
      float c = (-m * y1 + x1);
      float aprim = (1 + m*m);
      float bprim = 2 * m * (c - fixed.x) - 2 * fixed.y;
      float cprim = fixed.y * fixed.y + (c - fixed.x) * (c - fixed.x) - r * r;
      float delta = bprim * bprim - 4*aprim*cprim;
      float my1 = (-bprim + sqrt(delta)) / (2 * aprim);
      float mx1 = m * my1 + c;
      float my2 = (-bprim - sqrt(delta)) / (2 * aprim); // use this if it's better
      float mx2 = m * my2 + c;
      println("V x1,y1 " + x1/inchesToPoints + " " + y1/inchesToPoints + " x2,y2 " + x2/inchesToPoints + " " + y2/inchesToPoints + " fixed " + fixed.x/inchesToPoints + " " + fixed.y/inchesToPoints);
      println(" aprim,bprim,cprim = " + aprim + " " + bprim + " " + cprim);
      // of the two spots which are best, and pick the one that is A) On the line and B) closest to the moveable gear's current position
      println("  mx1,mx2 " + mx1/inchesToPoints + " " + my1/inchesToPoints + " mx2,my2 " + mx2/inchesToPoints + " " + my2/inchesToPoints);
      if (my1 < min(y1,y2) || my1 > max(y1,y2) || 
          dist(moveable.x,moveable.y,mx2,my2) < dist(moveable.x,moveable.y,mx1,mx2)) {
        println("  swap");
        mx1 = mx2;
        my1 = my2;
      } 
      moveable.mount(this, dist(x1,y1,mx1,my1)/dist(x1,y1,x2,y2));
    } else { // we likely have a gear on one of the lines on the left
      // given the line formed by x1,y1 x2,y2, find the two spots which are desiredRadius from fixed center.
      float m = (y2-y1)/(x2-x1);
      float c = (-m * x1 + y1);
      float aprim = (1 + m*m);
      float bprim = 2 * m * (c - fixed.y) - 2 * fixed.x;
      float cprim = fixed.x * fixed.x + (c - fixed.y) * (c - fixed.y) - r * r;
      float delta = bprim * bprim - 4*aprim*cprim;
      float mx1 = (-bprim + sqrt(delta)) / (2 * aprim);
      float my1 = m * mx1 + c;
      float mx2 = (-bprim - sqrt(delta)) / (2 * aprim); // use this if it's better
      float my2 = m * mx2 + c;
      println("x1,y1 " + x1/inchesToPoints + " " + y1/inchesToPoints + " x2,y2 " + x2/inchesToPoints + " " + y2/inchesToPoints);
      println(" aprim,bprim,cprim = " + aprim + " " + bprim + " " + cprim);
      // of the two spots which are best, and pick the one that is A) On the line and B) closest to the moveable gear's current position
      println("  mx1,mx2 " + mx1/inchesToPoints + " " + my1/inchesToPoints + " mx2,my2 " + mx2/inchesToPoints + " " + my2/inchesToPoints);
      if (mx1 < min(x1,x2) || mx1 > max(x1,x2) || my1 < min(y1,y2) || my1 > max(y1,y2) ||
          dist(moveable.x,moveable.y,mx2,my2) < dist(moveable.x,moveable.y,mx1,mx2)) {
        println("  swap");
        mx1 = mx2;
        my1 = my2;
      } 
      moveable.mount(this, dist(x1,y1,mx1,my1)/dist(x1,y1,x2,y2));
    }
  }
}

class ArcRail implements Channel {
  float cx,cy, rad, begAngle, endAngle;
  ArcRail(float cx, float cy, float rad, float begAngle, float  endAngle) {
    this.cx = cx*inchesToPoints;
    this.cy = cy*inchesToPoints;
    this.rad = rad*inchesToPoints;
    this.begAngle = begAngle;
    this.endAngle = endAngle;  
  }

  PVector getPosition(float r) {
    float a = begAngle + (endAngle - begAngle)*r;
    return new PVector(cx+cos(a)*rad, cy+sin(a)*rad);
  }  

  void snugTo(Gear moveable, Gear fixed) {
    // !! unimplemented for arc rails
  }

  void draw() {
    noFill();
    stroke(200);
    strokeWeight(.23*inchesToPoints);
    arc(cx, cy, rad, rad, begAngle, endAngle);
  }
}



class Gear implements Channel {
  int teeth;
  int setupIdx;
  float radius;
  float rotation;
  float phase = 0;
  float  x,y;
  float mountRatio = 0;
  boolean doFill = true;
  boolean showMount = true;
  boolean isMoving = false; // gear's position is moving
  boolean isFixed = false; // gear does not rotate or move
  boolean selected = false;
  boolean contributesToCycle = true;
  ArrayList<Gear> meshGears;
  ArrayList<Gear> stackGears;
  Channel itsChannel;
  String nom;
  
  Gear(int teeth, int setupIdx, String nom) {
    this.teeth = teeth;
    this.nom = nom;
    this.setupIdx = setupIdx;
    this.radius = (this.teeth*toothRadius/PI);
    this.x = 0;
    this.y = 0;
    this.phase = 0;
    meshGears = new ArrayList<Gear>();
    stackGears = new ArrayList<Gear>();
  }

  boolean isClicked(int mx, int my) {
    return dist(mx, my, this.x, this.y) <= this.radius;
  }


  void doSelect() {
    if (selectGear != null) {
      selectGear.selected = false;
    }
    selected = true;
    selectGear = this;
  }


  PVector getPosition(float r) {
    return new PVector(x+cos(this.rotation+this.phase)*radius*r, y+sin(this.rotation+this.phase)*radius*r);
  }  

  void meshTo(Gear parent) {
    parent.meshGears.add(this);

    // work out phase for gear meshing so teeth render interlaced
    float meshAngle = atan2(y-parent.y, x-parent.x); // angle where gears are going to touch (on parent gear)
    if (meshAngle < 0)
      meshAngle += TWO_PI;

    float iMeshAngle = meshAngle + PI;
    if (iMeshAngle >= TWO_PI)
      iMeshAngle -= TWO_PI;

    float parentMeshTooth = (meshAngle - parent.phase)*parent.teeth/TWO_PI; // tooth on parent, taking parent's phase into account
    
    // We want to insure that difference mod 1 is exactly .5 to insure a good mesh
    parentMeshTooth -= floor(parentMeshTooth);
    
    phase = (meshAngle+PI)+(parentMeshTooth+.5)*TWO_PI/teeth;
  }
  
  // Find position in our current channel which is snug to the fixed gear
  void snugTo(Gear anchor) {
    itsChannel.snugTo(this, anchor);
  }

  // Using this gear as the channel, find position for moveable gear which is snug to the fixed gear (assuming fixed gear is centered)
  void snugTo(Gear moveable, Gear fixed) {
    float d1 = 0;
    float d2 = radius;
    float d = moveable.radius+fixed.radius+meshGap;
    moveable.mount(this, d/d2);
      // find position on line (if any) which corresponds to two radii
  }

  void stackTo(Gear parent) {
    parent.stackGears.add(this);
    this.x = parent.x;
    this.y = parent.y;
    this.phase = parent.phase;
  }

  void mount(Channel ch) {
    mount(ch, 0.0);
  }

  void recalcPosition() { // used for orbiting gears
    PVector pt = this.itsChannel.getPosition(this.mountRatio);
    this.x = pt.x;
    this.y = pt.y;
  }

  void mount(Channel ch, float r) {
    this.itsChannel = ch;
    this.mountRatio = r;
    PVector pt = ch.getPosition(r);
    this.x = pt.x;
    this.y = pt.y;
    println("Gear " + teeth + " is at " + this.x/inchesToPoints + "," + this.y/inchesToPoints);
  }

  void crank(float pos) {
    if (!this.isFixed) {
      this.rotation = pos;
      float rTeeth = this.rotation*this.teeth;
      for (Gear mGear : meshGears) {
         mGear.crank(-(rTeeth)/mGear.teeth);
      }
      for (Gear sGear : stackGears) {
         sGear.crank(this.rotation);
      }
      if (isMoving)
       recalcPosition(); // technically only needed for orbiting gears
    }
    else {
      // this gear is fixed, but meshgears will rotate to the passed in pos
      for (Gear mGear : meshGears) {
        mGear.crank(pos + ( pos*this.teeth )/mGear.teeth);
      }
    }
  }

  void draw() {
    strokeWeight(1);
    strokeCap(ROUND);
    strokeJoin(ROUND);
    noFill();
    stroke(0);

    pushMatrix();
      translate(this.x, this.y);
      rotate(this.rotation+this.phase);

      float r1 = radius-.07*inchesToPoints;
      float r2 = radius+.07*inchesToPoints;
      float tAngle = TWO_PI/teeth;
      float tipAngle = tAngle*.1;

      if (doFill) {
        fill(240,240,240,192);
      } else {
       noFill();
      }
      if (selected) {
        strokeWeight(4);
        stroke(64);
      } else {
        strokeWeight(1);
        stroke(0);
      }
      beginShape();
      for (int i = 0; i < teeth; ++i) {
        float a1 = i*tAngle;
        float a2 = (i+.5)*tAngle;
        vertex(r2*cos(a1), r2*sin(a1));
        vertex(r2*cos(a1+tipAngle), r2*sin(a1+tipAngle));
        vertex(r1*cos(a2-tipAngle), r1*sin(a2-tipAngle));
        vertex(r1*cos(a2+tipAngle), r1*sin(a2+tipAngle));
        vertex(r2*cos(a1+tAngle-tipAngle), r2*sin(a1+tAngle-tipAngle));
        vertex(r2*cos(a1+tAngle), r2*sin(a1+tAngle));
      }
      endShape();
      strokeWeight(1);

      pushMatrix();
        fill(127);
        translate(0, radius-20);
        text(""+teeth, 0, 0);
        noFill();
        stroke(64);
        noFill();
      popMatrix();

      if (showMount) {
        noStroke();
        fill(192,128);
        ellipse(0, 0, 12, 12);

        fill(192,128);
        float inr = max(radius*.1,16);
        float outr = radius-max(radius*.1,8);
        rect(inr, -8.25, outr-inr, 16.5,12);
      }
        

    popMatrix();
  }
}


