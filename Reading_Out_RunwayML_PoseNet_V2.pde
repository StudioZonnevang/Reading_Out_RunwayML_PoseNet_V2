//import processing.video.*;

import oscP5.*;
import netP5.*;
import com.runwayml.*;

boolean isRightHanded;
boolean handPreferenceSet;
boolean drawLines;
boolean drawPoints;
boolean drawAngles;
boolean drawInfo;

int red = 250;
int green = 250;
int blue = 250;
int alpha = 250;

int playerScore = 0;
int targetDisplayed = 0;

RunwayOSC runway;
JSONObject data;
//Capture cam;

ArrayList<DotColor> dotColors = new ArrayList<DotColor>();

int[] displayPoints = {
  ModelUtils.POSE_NOSE_INDEX, //0
  ModelUtils.POSE_LEFT_SHOULDER_INDEX, //1
  ModelUtils.POSE_RIGHT_SHOULDER_INDEX, //2
  ModelUtils.POSE_LEFT_ELBOW_INDEX, //3
  ModelUtils.POSE_RIGHT_ELBOW_INDEX, //4
  ModelUtils.POSE_LEFT_WRIST_INDEX, //5
  ModelUtils.POSE_RIGHT_WRIST_INDEX, //6
  ModelUtils.POSE_LEFT_HIP_INDEX, //7
  ModelUtils.POSE_RIGHT_HIP_INDEX, //8
  ModelUtils.POSE_LEFT_KNEE_INDEX, //9
  ModelUtils.POSE_RIGHT_KNEE_INDEX, //10
  ModelUtils.POSE_LEFT_ANKLE_INDEX, //11
  ModelUtils.POSE_RIGHT_ANKLE_INDEX //12
};

int[][] connections = {
  //face
  //{ModelUtils.POSE_NOSE_INDEX, ModelUtils.POSE_LEFT_EYE_INDEX},
  //{ModelUtils.POSE_NOSE_INDEX,ModelUtils.POSE_RIGHT_EYE_INDEX},
  //body
  {ModelUtils.POSE_RIGHT_SHOULDER_INDEX,ModelUtils.POSE_LEFT_SHOULDER_INDEX},
  {ModelUtils.POSE_RIGHT_SHOULDER_INDEX,ModelUtils.POSE_RIGHT_HIP_INDEX},
  {ModelUtils.POSE_LEFT_SHOULDER_INDEX,ModelUtils.POSE_LEFT_HIP_INDEX},
  {ModelUtils.POSE_RIGHT_HIP_INDEX,ModelUtils.POSE_LEFT_HIP_INDEX},
  //right arm
  {ModelUtils.POSE_RIGHT_SHOULDER_INDEX,ModelUtils.POSE_RIGHT_ELBOW_INDEX},
  {ModelUtils.POSE_RIGHT_ELBOW_INDEX,ModelUtils.POSE_RIGHT_WRIST_INDEX},
  //left arm
  {ModelUtils.POSE_LEFT_SHOULDER_INDEX,ModelUtils.POSE_LEFT_ELBOW_INDEX},
  {ModelUtils.POSE_LEFT_ELBOW_INDEX,ModelUtils.POSE_LEFT_WRIST_INDEX}, 
  //right leg
  {ModelUtils.POSE_RIGHT_HIP_INDEX,ModelUtils.POSE_RIGHT_KNEE_INDEX},
  {ModelUtils.POSE_RIGHT_KNEE_INDEX,ModelUtils.POSE_RIGHT_ANKLE_INDEX},
  //left leg
  {ModelUtils.POSE_LEFT_HIP_INDEX,ModelUtils.POSE_LEFT_KNEE_INDEX},
  {ModelUtils.POSE_LEFT_KNEE_INDEX,ModelUtils.POSE_LEFT_ANKLE_INDEX}
};

int[][] angles = {
  //0 nose angles
    //{ModelUtils.POSE_LEFT_EYE_INDEX, ModelUtils.POSE_NOSE_INDEX, ModelUtils.POSE_RIGHT_EYE_INDEX},
  //1 left shoulder angle
    //{ModelUtils.POSE_LEFT_ELBOW_INDEX, ModelUtils.POSE_LEFT_SHOULDER_INDEX, ModelUtils.POSE_LEFT_HIP_INDEX},
  //2 left elbow angle
    {ModelUtils.POSE_LEFT_WRIST_INDEX, ModelUtils.POSE_LEFT_ELBOW_INDEX, ModelUtils.POSE_LEFT_SHOULDER_INDEX},
  //3 right shoulder angle
    //{ModelUtils.POSE_RIGHT_ELBOW_INDEX, ModelUtils.POSE_RIGHT_SHOULDER_INDEX, ModelUtils.POSE_RIGHT_HIP_INDEX},
  //4 right elbow angle
    {ModelUtils.POSE_RIGHT_WRIST_INDEX, ModelUtils.POSE_RIGHT_ELBOW_INDEX, ModelUtils.POSE_RIGHT_SHOULDER_INDEX},
  //5 left hip angle
    //{ModelUtils.POSE_RIGHT_HIP_INDEX, ModelUtils.POSE_LEFT_HIP_INDEX, ModelUtils.POSE_LEFT_KNEE_INDEX},
  //6 right hip angle
    //{ModelUtils.POSE_RIGHT_LEFT_INDEX, ModelUtils.POSE_RIGHT_HIP_INDEX, ModelUtils.POSE_RIGHT_KNEE_INDEX},
  //7 left knee angle
    {ModelUtils.POSE_LEFT_HIP_INDEX, ModelUtils.POSE_LEFT_KNEE_INDEX, ModelUtils.POSE_LEFT_ANKLE_INDEX},
  //8 right knee angle
    {ModelUtils.POSE_RIGHT_HIP_INDEX, ModelUtils.POSE_RIGHT_KNEE_INDEX, ModelUtils.POSE_RIGHT_ANKLE_INDEX},
  //left back angle
  //right back angle
};

//Righties
float[][] desiredAnglesR = {
  //0 nose angles
    //{80,100},
  //1 left shoulder angle
  //2 left elbow angle
      {170, 190},
  //3 right shoulder angle
  //4 right elbow angle
      {170, 190},
  //5 left hip angle
  //6 right hip angle
  //7 left knee angle
      {90, 110},
  //8 right knee angle
      {170, 190},
};

//lefties
float[][] desiredAnglesL = {
  //0 nose angles
    //{80,100},
  //1 left shoulder angle
  //2 left elbow angle
  //3 right shoulder angle
  //4 right elbow angle
    {125, 145},
  //5 left hip angle
  //6 right hip angle
  //7 left knee angle
  //8 right knee angle
};

void setup() {
  //size (400, 267);
  fullScreen();
  
  textSize(40);
  strokeWeight(3);
  
  //cam = new Capture(this, Capture.list()[0]);
  //cam.start();
  
  handPreferenceSet = false; //really needed?
  isRightHanded = true;
  drawLines = true;
  drawPoints = true;
  drawAngles = true;
  drawInfo = false;
  
  runway = new RunwayOSC (this);
  
  for (int dP = 0; dP < displayPoints.length; dP++){
    dotColors.add(new DotColor());
  }
}

void draw() {
  background(30);
  //cam.read();
  
    switch(targetDisplayed){
    case 0:
      break;
    case 1:
      fill(250);
      rect(width * 0.9, 0, width * 0.9, height * 0.33);
      break;
    case 2:
      fill(250);
      rect(width * 0.9, height * 0.33, width * 0.9, height * 0.33);
      break;
    case 3:
      fill(250);
      rect(width * 0.9, height * 0.66, width * 0.9, height * 0.33);
      break;
  } 
  
  if (drawAngles){
    drawPoseNetAngles(data);}
  if (drawLines){
    drawPoseNetParts(data);}
  if (drawPoints){
    drawPoseNetPoints(data);
  }
  if (drawInfo){
     drawInfo();
   }   
}

/* CHOSING WHICH POINTS ARE SHOWN FOR PERFORMANCE */
void drawPoseNetPoints(JSONObject data) {
  if (data != null){
    JSONArray humans = data.getJSONArray("poses");
    for(int h = 0; h < humans.size(); h++) {
      JSONArray keypoints = humans.getJSONArray(h);
      
      for (int dP = 0; dP < displayPoints.length; dP++){
        JSONArray json = keypoints.getJSONArray(displayPoints[dP]);
        float pointX = json.getFloat(0) * width;
        float pointY = json.getFloat(1) * height;  
      
        color strokeColor = color(red, green, blue);
        stroke(strokeColor, alpha);
        if (dP > 0){
          fill(dotColors.get(dP).getColor());
          circle(pointX, pointY, 0.05 * width);
        }
        else {
          fill(red, green, blue, 180);
          circle(pointX, pointY, 0.10 * width);
          fill(230, 230, 230);
          circle(pointX, pointY, 0.05 * width);
        }
      }
    }
  }
}

    /*DRAW ALL THE CONNECTIONS*/
void drawPoseNetParts(JSONObject data) {
  if (data != null){
    JSONArray humans = data.getJSONArray("poses");
    for(int h = 0; h < humans.size(); h++) {
      JSONArray keypoints = humans.getJSONArray(h);
      // Now that we have one human, let's draw its body parts
      
      for(int i = 0 ; i < connections.length; i++){
                /*CONNECTIONS*/
        JSONArray startPart = keypoints.getJSONArray(connections[i][0]);
        JSONArray endPart   = keypoints.getJSONArray(connections[i][1]);
        // extract floats fron JSON array and scale normalized value to sketch size
        float startX = startPart.getFloat(0) * width;
        float startY = startPart.getFloat(1) * height;
        float endX   = endPart.getFloat(0) * width;
        float endY   = endPart.getFloat(1) * height;
        
        stroke(250,250,250);  //white
        line(startX,startY,endX,endY);
      }
    }
  }
}

void drawPoseNetAngles(JSONObject data){
  if (data != null){
    JSONArray humans = data.getJSONArray("poses");
    for(int h = 0; h < humans.size(); h++) {
      JSONArray keypoints = humans.getJSONArray(h);
      
                      /*ANGLES*/
      for(int i = 0 ; i < angles.length; i++){
        JSONArray one = keypoints.getJSONArray(angles[i][0]);
        JSONArray two   = keypoints.getJSONArray(angles[i][1]);
        JSONArray three   = keypoints.getJSONArray(angles[i][2]);
        // extract floats fron JSON array and scale normalized value to sketch size
        float oneX = one.getFloat(0) * width;
        float oneY = one.getFloat(1) * height;
        float twoX = two.getFloat(0) * width;
        float twoY = two.getFloat(1) * height;
        float threeX = three.getFloat(0) * width;
        float threeY = three.getFloat(1) * height;
        
        //connection with first point
        float twoOneL = sqrt(sq(twoX - oneX) + sq(twoY - oneY));
        //connection with second point
        float twoThreeL = sqrt(sq(twoX - threeX) + sq(twoY - threeY));
        //connection between points
        float oneThreeL = sqrt(sq(oneX - threeX) + sq(oneY - threeY));
        
        float angle = acos((sq(twoOneL) + sq(twoThreeL) - sq(oneThreeL))/(2 * twoOneL * twoThreeL)) / (3.14/180);
        //println("a = " + twoOneL + ", b = " + twoThreeL + ", c = " + oneThreeL + ", angle = " + angle);
        
        //println(angles[i][1]);
        
        switch(angles[i][1]){
          case 7:
              dotColors.get(1).setColor(angle, desiredAnglesR[i][0], desiredAnglesR[i][1]);
              dotColors.get(1).setAlphaValue(dotColors.get(0).getGreenValue());
              
              dotColors.get(3).setColor(angle, desiredAnglesR[i][0], desiredAnglesR[i][1]);
              dotColors.get(3).setAlphaValue(dotColors.get(0).getGreenValue());
              
              dotColors.get(5).setColor(angle, desiredAnglesR[i][0], desiredAnglesR[i][1]);
              dotColors.get(5).setAlphaValue(dotColors.get(0).getGreenValue());
              
              if (drawInfo){
              fill(250);
              textAlign(LEFT);
              text("angle A: " + angle + " desired angle A: " + ((desiredAnglesR[i][0] + desiredAnglesR[i][1])/2), 0.01 * width, 0.05 * height);
              }
              break;
          case 8:
              dotColors.get(2).setColor(angle, desiredAnglesR[i][0], desiredAnglesR[i][1]);
              dotColors.get(2).setAlphaValue(dotColors.get(0).getGreenValue());
              
              dotColors.get(4).setColor(angle, desiredAnglesR[i][0], desiredAnglesR[i][1]);
              dotColors.get(4).setAlphaValue(dotColors.get(0).getGreenValue());
              
              dotColors.get(6).setColor(angle, desiredAnglesR[i][0], desiredAnglesR[i][1]);
              dotColors.get(6).setAlphaValue(dotColors.get(0).getGreenValue());
              
              if (drawInfo){
              fill(250);
              textAlign(LEFT);
              text("angle B: " + angle + " desired angle B: " + ((desiredAnglesR[i][0] + desiredAnglesR[i][1])/2), 0.01 * width, 0.10 * height);
              }
              break;
          case 13:
              dotColors.get(7).setColor(angle, desiredAnglesR[i][0], desiredAnglesR[i][1]);
              dotColors.get(7).setAlphaValue(dotColors.get(0).getGreenValue());
              
              dotColors.get(9).setColor(angle, desiredAnglesR[i][0], desiredAnglesR[i][1]);
              dotColors.get(9).setAlphaValue(dotColors.get(0).getGreenValue());
              
              dotColors.get(11).setColor(angle, desiredAnglesR[i][0], desiredAnglesR[i][1]);
              dotColors.get(11).setAlphaValue(dotColors.get(0).getGreenValue());
              
              if (drawInfo){
              fill(250);
              textAlign(LEFT);
              text("angle C: " + angle + " desired angle C: " + ((desiredAnglesR[i][0] + desiredAnglesR[i][1])/2), 0.01 * width, 0.15 * height);
              }
              break;
           case 14:
              dotColors.get(8).setColor(angle, desiredAnglesR[i][0], desiredAnglesR[i][1]);
              dotColors.get(8).setAlphaValue(dotColors.get(0).getGreenValue());
              
              dotColors.get(10).setColor(angle, desiredAnglesR[i][0], desiredAnglesR[i][1]);
              dotColors.get(10).setAlphaValue(dotColors.get(0).getGreenValue());
              
              dotColors.get(12).setColor(angle, desiredAnglesR[i][0], desiredAnglesR[i][1]);
              dotColors.get(12).setAlphaValue(dotColors.get(0).getGreenValue());
              
              if (drawInfo){
              fill(250);
              textAlign(LEFT);
              text("angle D: " + angle  + " desired angle D: " + ((desiredAnglesR[i][0] + desiredAnglesR[i][1])/2), 0.01 * width, 0.20 * height);
              }
              break;
          }
          
          //set head Halo
          red = (dotColors.get(3).getRedValue() + dotColors.get(4).getRedValue() + dotColors.get(9).getRedValue() + dotColors.get(10).getRedValue())/4;
          green = (dotColors.get(3).getRedValue() + dotColors.get(4).getRedValue() + dotColors.get(9).getRedValue() + dotColors.get(10).getRedValue())/4;
          blue = 30;
          //dotColors.get(0).setRedValue((dotColors.get(3).getRedValue() + dotColors.get(4).getRedValue() + dotColors.get(9).getRedValue() + dotColors.get(10).getRedValue())/4);
          //dotColors.get(0).setGreenValue((dotColors.get(3).getRedValue() + dotColors.get(4).getRedValue() + dotColors.get(9).getRedValue() + dotColors.get(10).getRedValue())/4);
      }
    }
  }
}

void drawInfo(){
    //preference of fencing arm to sustainably calculate the right angles
    if (handPreferenceSet){
      if (isRightHanded){
       rect(140,20,20,20);}
      else {
       circle(150,30,20);}
    }
    fill(250);
    textAlign(RIGHT);
    text("Score: " + playerScore,(width * 0.9) - (0.01 * width), 0.05 * height);
}

void runwayDataEvent(JSONObject runwayData){
  // point the sketch data to the Runway incoming data 
  data = runwayData;
}

public void runwayInfoEvent(JSONObject info){
  println(info);
}

// if anything goes wrong
public void runwayErrorEvent(String message){
  println(message);
}

void keyPressed(){
  switch(key) {
    case('c'):
      /* connect to Runway */
      runway.connect();
      break;
    case('d'):
      /* disconnect from Runway */
      runway.disconnect();
      break;
    case('l'):
      if (drawLines){
        drawLines = false;
      } 
      else {
        drawLines = true;
      }
        break;
    case('p'):
      if (drawPoints){
        drawPoints = false;
      } 
      else {
        drawPoints = true;
      }
      break;
    case('i'):
      if (drawInfo){
        drawInfo = false;
      } 
      else {
        drawInfo = true;
      }
      break;
     case('a'):
      if (drawAngles){
        drawAngles = false;
      } 
      else {
        drawAngles = true;
      }
      break;
    case('r'):
      if (isRightHanded){
        isRightHanded = false;
      } 
      else {
        isRightHanded = true;
        handPreferenceSet = true;
      }
      break;
    case('='):
      playerScore++;
      break;
    case('-'):
      if (playerScore > 0)
         playerScore = playerScore - 1;
      break;
    case('0'):
      targetDisplayed = 0;
      break;
    case('1'):
      targetDisplayed = 1;
      break;
    case('2'):
      targetDisplayed = 2;
      break;
    case('3'):
      targetDisplayed = 3;
      break;
  }
}

class DotColor {
  int redValue = 250;
  int greenValue = 250;
  int blueValue = 250;
  int alphaValue = 250;
  
  void setColor(float angle, float minAngle, float maxAngle){
    float averageDesiredAngle = (minAngle + maxAngle)/2;
    float absoluteDifference = Math.abs(averageDesiredAngle - angle);
    
    redValue = (int) map(absoluteDifference, 0, averageDesiredAngle, 80, 220);
    greenValue = (int) map(absoluteDifference, 0, averageDesiredAngle, 220, 80);
    blueValue = 80;
  }
  
  
  
  private void setRedValue(int val) {
    redValue = val;
  }
  private void setGreenValue(int val) {
    greenValue = val;
  }
  private void setBlueValue(int val) {
    blueValue = val;
  }
  void setAlphaValue(int val) {
    alphaValue = val;
  }
  
  int getRedValue() {
    return redValue;
  }
  int getGreenValue() {
    return greenValue;
  }
  int getBlueValue() {
    return blueValue;
  }
  int getAlphaValue() {
    return alphaValue;
  }
  
  color getColor(){
    color thisColor = color(redValue, greenValue, blueValue, alphaValue);
    return thisColor;
  }
}
