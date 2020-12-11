void animatePixel_linear(int[] coords) {  
  float xDiff = coords[X2] - coords[X1],
        yDiff = coords[Y2] - coords[Y1];
  for(int frame = startFrame; frame < TOTAL_ANIMATION_FRAMES; ++frame) {
    float newX = coords[X1] + xDiff * easing[frame][easeMethodX],
          newY = coords[Y1] + yDiff * easing[frame][easeMethodY];
    roundAndPlot(newX, newY, coords[COLOR], frame);
  }
}

void animatePixel_circle(int[] coords) {    
  float centerX = (coords[X1] + coords[X2]) / 2f;
  float centerY = (coords[Y1] + coords[Y2]) / 2f;
  float startAngle = atan2(coords[Y1] - centerY, coords[X1] - centerX);
  float radius = dist(coords[X1], coords[Y1], coords[X2], coords[Y2]) / 2f;
  
  for(int frame = startFrame; frame < TOTAL_ANIMATION_FRAMES; ++frame) {
    float rotateAmount = startAngle + PI * direction * easing[frame][DEFAULT];
    float newX = centerX + getTrigTable(cosTable, rotateAmount) * radius,
          newY = centerY + getTrigTable(sinTable, rotateAmount) * radius;
    roundAndPlotIfInBounds(newX, newY, coords[COLOR], frame);
  }
}

void animatePixel_spiral(int[] coords) {
  float startAngle = atan2(coords[Y1] - HALF_HEIGHT, coords[X1] - HALF_WIDTH);
  float endAngle = atan2(coords[Y2] - HALF_HEIGHT, coords[X2] - HALF_WIDTH);
  float startDist = dist(coords[X1], coords[Y1], HALF_WIDTH, HALF_HEIGHT);
  float endDist = dist(coords[X2], coords[Y2], HALF_WIDTH, HALF_HEIGHT);
  
  float angleDiff = endAngle - startAngle;
  while(angleDiff < PI/8) angleDiff += TWO_PI;
  if(direction == -1) angleDiff = TWO_PI - angleDiff;
  
  float radiusDiff = endDist - startDist;
  
  for(int frame = startFrame; frame < TOTAL_ANIMATION_FRAMES; ++frame) {    
    float rotateAmount = startAngle + angleDiff * direction * easing[frame][easeMethodX];
    float radiusAmount = startDist + radiusDiff * easing[frame][easeMethodY];
    float newX = HALF_WIDTH + getTrigTable(cosTable, rotateAmount) * radiusAmount,
          newY = HALF_HEIGHT + getTrigTable(sinTable, rotateAmount) * radiusAmount;
    roundAndPlotIfInBounds(newX, newY, coords[COLOR], frame);
  }
}

void animatePixel_ellipse(int[] coords) {
  if(coords[Y1] == coords[Y2]) { animatePixel_linear(coords); return; } // Do linear interp

  float reflectedX1 = coords[X1] > width/2 ? width - coords[X1] : coords[X1];
  float reflectedX2 = coords[X2] > width/2 ? width - coords[X2] : coords[X2];
  if(reflectedX1 == reflectedX2) reflectedX2 += 0.1f;
  
  float x1DistToCenter = abs(reflectedX1 - width/2),
        x2DistToCenter = abs(reflectedX2 - width/2);
  float xDiff = x2DistToCenter - x1DistToCenter;
  float yDiff = abs(coords[Y1] - coords[Y1]);
  float averageHeight = (coords[Y1] + coords[Y2]) / 2f;
  
  //float widthMult = random(1, 1.5f);
  float widthMult = yDiff * 2f + 1;
  //float centerX = width/2;
  float centerY = map(xDiff, 0, reflectedX1 - width * widthMult, averageHeight, coords[Y1]);
  float[][] eqs = new float[2][3];
  eqs[0][0] = sq((float)reflectedX1 - width/2);
  eqs[0][1] = sq((float)coords[Y1] - centerY);
  eqs[1][0] = sq((float)reflectedX2 - width/2);
  eqs[1][1] = sq((float)coords[Y2] - centerY);
    
  float xMult = eqs[0][0] * eqs[1][1] - eqs[1][0] * eqs[0][1];
  float equalTo = eqs[1][1] - eqs[0][1];
  float m = equalTo / xMult;
  float n = (1 - eqs[0][0] * m) / eqs[0][1];
    
  float ellipseWidthRadius = sqrt(1f/m);
  float ellipseHeightRadius = sqrt(1f/n);
  /*
  if(Float.isInfinite(ellipseWidthRadius) || Float.isNaN(ellipseWidthRadius) ||
    Float.isInfinite(ellipseHeightRadius) || Float.isNaN(ellipseHeightRadius))
      println(millis());
  */
  float startAngle = acos((coords[X1] - width/2) / ellipseWidthRadius);//atan2(coords[Y1] - centerY, coords[X1] - centerX);
  if(coords[Y1] > centerY) startAngle = TWO_PI - startAngle;
  
  float endAngle = acos((coords[X2] - width/2) / ellipseWidthRadius);//atan2(coords[Y1] - centerY, coords[X1] - centerX);
  if(coords[Y2] > centerY) endAngle = TWO_PI - endAngle;

  if(coords[Y1] > coords[Y2]) endAngle += TWO_PI;
  float angleDiff = endAngle - startAngle;
  //if(angleDiff < PI*3f/5) angleDiff += TWO_PI;

  for(int frame = startFrame; frame < TOTAL_ANIMATION_FRAMES; ++frame) {    
    float rotateAmount = startAngle + angleDiff /** direction*/ * easing[frame][DEFAULT];    
    float newX = HALF_WIDTH + getTrigTable(cosTable, -rotateAmount) * ellipseWidthRadius,
          newY = centerY + getTrigTable(sinTable, -rotateAmount) * ellipseHeightRadius;
    roundAndPlotIfInBounds(newX, newY, coords[COLOR], frame);
  }
}

void animatePixel_burstPhysics(int[] coords) {
  float newX = coords[X1];
  float newY = coords[Y1];
  float startAngle = random(0, TWO_PI);
  float randomSpread = randomGaussian() / 10f;
  //float startVel = abs(randomGaussian()) / 20f;
  //float startVel = random(0.0f, 0.2f);
  //float startVel = (float) coords[COLOR] / 0xffffff / 5;
  //float gravity = 0.1f;
  //float gravity = random(0.18f, 0.2f);
  //float gravity = noiseTable[coords[Y1]][coords[X1]] / 5f;
  float gravity = 0f;
  //float xVel = startVel * ((coords[X1] - HALF_WIDTH) / 5f);// + cos(startAngle));
  //float yVel = startVel * ((coords[Y1] - HALF_HEIGHT) / 5f);// + sin(startAngle));
  float maxSpeed = 8f;
  //float halfMaxSpeed = 0;
  float tempXVel = ((saturation(coords[COLOR]) + brightness(coords[COLOR])) / 512f) * maxSpeed;
  float tempYVel = 0;//(brightness(coords[COLOR]) / 256f) * maxSpeed * 2 - maxSpeed;
  float rotation = (hue(coords[COLOR]) / 256f) * 2 * PI;
  float xVel = tempXVel * cos(rotation) - tempYVel * sin(rotation) + cos(startAngle) * randomSpread;
  float yVel = tempXVel * sin(rotation) + tempYVel * cos(rotation) + sin(startAngle) * randomSpread;
  //float xVel = tempXVel;
  //float yVel = tempYVel;
  
  float speedDecay = 0.998f;
    
  for(int frame = startFrame; frame < TOTAL_ANIMATION_FRAMES; ++frame) {

    newX += xVel; //<>// //<>// //<>// //<>//
    xVel *= 0.995f;
    
    newY += yVel;
    yVel += gravity;
    yVel *= speedDecay;

    float plotX = round(lerp(newX, coords[X2], easing[frame][easeMethodX]));
    if(plotX < 0) {
      plotX = 0;
      newX = 0;
      xVel = -xVel;
    } else if(plotX >= width) {
      plotX = width - 1;
      newX = width - 1;
      xVel = -xVel;
    }
    
    float plotY = round(lerp(newY, coords[Y2], easing[frame][easeMethodY]));
    if(plotY < 0) {
      plotY = 0;
      newY = 0;
      yVel = -yVel;
    } else if(plotY >= height) {
      plotY = height - 1;
      newY = height - 1;
      yVel = -yVel;
    }

    roundAndPlot(plotX, plotY, coords[COLOR], frame);
  }
}

void animatePixel_lurch(int[] coords) {
  float newX, newY;

  boolean horizontalFirst;
  switch(easeMethodX) {
    case 0: horizontalFirst = true; break;
    case 1: horizontalFirst = false; break;
    default: horizontalFirst = random(0f, 1f) < 0.5f ? true : false; break;
  }
  
  if(horizontalFirst) {
    for(int frame = startFrame; frame < TOTAL_ANIMATION_FRAMES; ++frame) {
      if(frame < TOTAL_ANIMATION_FRAMES / 2) {
        newX = lerp(coords[X1], coords[X2], easing[frame * 2][POLY]); 
        newY = coords[Y1];
      } else {
        newX = coords[X2];
        newY = lerp(coords[Y1], coords[Y2], easing[frame * 2 - TOTAL_ANIMATION_FRAMES][POLY_INVERSE]); 
      }
      roundAndPlot(newX, newY, coords[COLOR], frame);
    }
  } else {
    for(int frame = startFrame; frame < TOTAL_ANIMATION_FRAMES; ++frame) {
      if(frame < TOTAL_ANIMATION_FRAMES / 2) {
        newX = coords[X1];
        newY = lerp(coords[Y1], coords[Y2], easing[frame * 2][POLY]);
      } else {
        newX = lerp(coords[X1], coords[X2], easing[frame * 2 - TOTAL_ANIMATION_FRAMES][POLY_INVERSE]); 
        newY = coords[Y2];
      }
      roundAndPlot(newX, newY, coords[COLOR], frame);
    }
  }
}

/*
void animatePixel_laser(int[] coords) {
  int laserDurationFrames = 10;
  //int laserStartFrame = (int)random(0, TOTAL_ANIMATION_FRAMES - laserDurationFrames);
  int laserStartFrame = (int)(((float)coords[Y2] / height) * (TOTAL_ANIMATION_FRAMES - laserDurationFrames));
    
  for(int frame = startFrame; frame < TOTAL_ANIMATION_FRAMES; ++frame) {
    if(frame < laserStartFrame) {
      plot(coords[X1], coords[Y1], coords[COLOR], animationFrames[frame].pixels);
    } else if(frame == laserStartFrame) {
      plotLine(
        coords[X1], 
        coords[Y1], 
        coords[X2],
        coords[Y2],
        coords[COLOR], 
        animationFrames[frame].pixels);
    } else {
      plot(coords[X2], coords[Y2], coords[COLOR], animationFrames[frame].pixels);
    }
  }
}
*/
void animatePixel_laser(int[] coords) {
  int laserDurationFrames = 15;
  float laserLength = 0.1f;
  
  // Could randomize these more, but due to rendering order certain things overlap
  int laserStartFrame;
  switch(easeMethodX) {
    case 0: laserStartFrame = 
      (int)(((float)coords[Y1] / height) * (TOTAL_ANIMATION_FRAMES - laserDurationFrames));
      //if(direction < 0) laserStartFrame = TOTAL_ANIMATION_FRAMES - laserStartFrame - laserDurationFrames * 2;
      laserStartFrame = TOTAL_ANIMATION_FRAMES - laserStartFrame - laserDurationFrames * 2;
      break;
    case 1: laserStartFrame = 
      (int)(((float)coords[Y2] / height) * (TOTAL_ANIMATION_FRAMES - laserDurationFrames));
      //if(direction < 0) laserStartFrame = TOTAL_ANIMATION_FRAMES - laserStartFrame - laserDurationFrames * 2;
      break;
    default: laserStartFrame = 
      (int)random(0, TOTAL_ANIMATION_FRAMES - laserDurationFrames);
      break;
  }
  
  int laserEndFrame = laserStartFrame + laserDurationFrames;
  
  for(int frame = startFrame; frame < TOTAL_ANIMATION_FRAMES; ++frame) {
    if(frame < laserStartFrame) {
      plot(coords[X1], coords[Y1], coords[COLOR], frame);
    } else if(frame < laserEndFrame) {
      float frac = map(frame - laserStartFrame, 0, laserDurationFrames, 0, 1 + laserLength);
      //float frac = ((float)frame - laserStartFrame) / laserDurationFrames;
      //float fracFrame = map(frame, laserStartFrame, laserEndFrame, 0, TOTAL_ANIMATION_FRAMES);
      //float frac = easing[round(fracFrame)][STEEP];
      if(frac < laserLength) {
        plotLine(
          coords[X1],
          coords[Y1],
          round(lerp(coords[X1], coords[X2], frac)),
          round(lerp(coords[Y1], coords[Y2], frac)),
          coords[COLOR], 
          frame);
      } else if(frac < 1) {
        plotLine( 
          round(lerp(coords[X1], coords[X2], frac - laserLength)),
          round(lerp(coords[Y1], coords[Y2], frac - laserLength)),
          round(lerp(coords[X1], coords[X2], frac)),
          round(lerp(coords[Y1], coords[Y2], frac)),
          coords[COLOR], 
          frame);
      } else {
        plotLine( 
          round(lerp(coords[X1], coords[X2], frac - laserLength)),
          round(lerp(coords[Y1], coords[Y2], frac - laserLength)),
          coords[X2],
          coords[Y2],
          coords[COLOR], 
          frame);
      }
    } else {
      plot(coords[X2], coords[Y2], coords[COLOR], frame);
    }
  }
}

void animatePixel_evaporate(int[] coords) {
  float newX = coords[X1], newY = coords[Y1];
  
  int pixelDistance = coords[Y2] - coords[Y1] + HEIGHT;
  float speed = 30;
  int framesToFinish = (int)((float)pixelDistance / speed);
  int startFrame = (int)random(TOTAL_ANIMATION_FRAMES - framesToFinish);
  //float timeToFinish = 0.2f;
  //int framesToFinish = (int)(TOTAL_ANIMATION_FRAMES * timeToFinish);
  //int startFrame = (int)random(TOTAL_ANIMATION_FRAMES - framesToFinish);
  
  //for(int frame = startFrame; frame < startFrame + framesToFinish; ++frame) {
  for(int frame = 0; frame < TOTAL_ANIMATION_FRAMES; ++frame) {
    newY = round(lerp(coords[Y1], coords[Y2] - HEIGHT, easing[frame][DEFAULT]));
    while(newY < 0) {
      newY += HEIGHT;
      newX = coords[X2];
    }
    //newX = lerp(coords[X1], coords[X2], easing[frame][DEFAULT]);
    roundAndPlot(newX, newY, coords[COLOR], frame);
  }
}

/*
void animatePixel_circleAxis(int[] coords) {
  float perpSlope = -((float)coords[X2] - coords[X1]) / ((float)coords[Y2] - coords[Y1]);
  perpSlope = constrain(perpSlope, -10000, 10000);
  float yIntercept = 
    ((coords[Y1] + coords[Y2]) / 2f) -
    ((coords[X1] + coords[X2]) / 2f) *
    perpSlope;
  float startAngle = atan2(coords[Y1] - yIntercept, coords[X1] - HALF_WIDTH);
  float endAngle = atan2(coords[Y2] - yIntercept, coords[X2] - HALF_WIDTH);
  float distance = dist(coords[X1], coords[Y1], HALF_WIDTH, yIntercept);

  float angleDiff = startAngle - endAngle;
  
  for(int frame = 0; frame < TOTAL_ANIMATION_FRAMES; ++frame) {    
    float rotateAmount = startAngle + angleDiff * easing[frame][DEFAULT];
    float newX = HALF_WIDTH + getTrigTable(cosTable, rotateAmount) * distance,
          newY = yIntercept + getTrigTable(sinTable, rotateAmount) * distance;
    if(newX < 0 || newX >= width - 1 || newY < 0 || newY >= height - 1) continue;
    animationFrames[frame].pixels[round(newY) * width + round(newX)] = coords[COLOR];
  }
}
*/

void animatePixel_noisefield(int[] coords) {
  float startAngle = random(0, TWO_PI);
  float randomSpread = randomGaussian() * 10f;
  int baseNoiseX = round(coords[X1] + cos(startAngle) * randomSpread);
  int baseNoiseY = round(coords[Y1] + sin(startAngle) * randomSpread);
  
  float[] baseJitter = getNoiseXY(baseNoiseX + NOISE_CIRCLE_RADIUS, baseNoiseY);
  
  float xDiff = coords[X2] - coords[X1],
        yDiff = coords[Y2] - coords[Y1];
        
  for(int frame = startFrame; frame < TOTAL_ANIMATION_FRAMES; ++frame) {
    float newX = coords[X1] + xDiff * easing[frame][DEFAULT],//easeMethodX],
          newY = coords[Y1] + yDiff * easing[frame][DEFAULT];//easeMethodY];
          
    float noiseCircleAngle = PI * 2 * easing[frame][POLY_INVERSE];//DEFAULT];
    float noiseCircleX = baseNoiseX + getTrigTable(cosTable, noiseCircleAngle) * NOISE_CIRCLE_RADIUS,
          noiseCircleY = baseNoiseY + getTrigTable(sinTable, noiseCircleAngle) * NOISE_CIRCLE_RADIUS;
        
    float[] noiseJitter = getNoiseXY(noiseCircleX, noiseCircleY);
    noiseJitter[0] = (noiseJitter[0] - baseJitter[0]);
    noiseJitter[1] = (noiseJitter[1] - baseJitter[1]);
    
    newX += noiseJitter[0];
    newY += noiseJitter[1];
    
    roundAndPlotIfInBounds(newX, newY, coords[COLOR], frame);
  }
}

void animatePixel_evaporateCircle(int[] coords) {  
  float[] startSegment = new float[] { coords[X1], coords[Y1], coords[X1] - (coords[X1] - HALF_WIDTH) * LARGEST_DIM, coords[Y1] + (coords[Y1] - HALF_HEIGHT) * LARGEST_DIM };
  float[] endSegment = new float[] { coords[X2], coords[Y2], coords[X2] - (coords[X2] - HALF_WIDTH) * LARGEST_DIM, coords[Y2] + (coords[Y2] - HALF_HEIGHT) * LARGEST_DIM };
    
  float[] startEdgePoint = getClosestEdgePoint(startSegment);
  float[] endEdgePoint = getClosestEdgePoint(endSegment);
  
  float totalDist = startEdgePoint[DISTANCE] + endEdgePoint[DISTANCE];
  //float sat = brightness(coords[COLOR]);

  int frame;
  for(frame = startFrame; frame < TOTAL_ANIMATION_FRAMES; ++frame) {
    float curDist = totalDist * easing[frame][DEFAULT];
    //float curDist = totalDist * lerp(easing[frame][POLY], easing[frame][POLY_INVERSE], sat / 256);
    
    float newX = 0, newY = 0;
    if(curDist < startEdgePoint[DISTANCE]) {
      float frac = curDist / startEdgePoint[DISTANCE];
      newX = lerp(coords[X1], startEdgePoint[X1], frac);
      newY = lerp(coords[Y1], startEdgePoint[Y1], frac);
    } else {
      float frac = (curDist - startEdgePoint[DISTANCE]) / endEdgePoint[DISTANCE];
      newX = lerp(endEdgePoint[X1], coords[X2], frac);
      newY = lerp(endEdgePoint[Y1], coords[Y2], frac);
    }
    roundAndPlotIfInBounds(newX, newY, coords[COLOR], frame);
  }
}

void animatePixel_arcToEdge(int[] coords) {
  //int rx = (int)random(width);
  //int ry = (int)random(height);
  float[] startSegment = new float[] { coords[X1], coords[Y1], coords[X1] - (coords[X1] - HALF_WIDTH) * LARGEST_DIM, coords[Y1] + (coords[Y1] - HALF_HEIGHT) * LARGEST_DIM };
  float[] endSegment = new float[] { coords[X2], coords[Y2], coords[X2] - (coords[X2] - HALF_WIDTH) * LARGEST_DIM, coords[Y2] + (coords[Y2] - HALF_HEIGHT) * LARGEST_DIM };  
  //float[] startSegment = new float[] { -100, coords[Y1], coords[X1], coords[Y1] };
  //float[] endSegment = new float[] { -100, coords[Y2], coords[X2], coords[Y2] };  
  //float[] startSegment = new float[] { coords[X1], coords[Y1], coords[X1], coords[Y1] + LARGEST_DIM };
  //float[] endSegment = new float[] { coords[X2], coords[Y2], coords[X2] + LARGEST_DIM, coords[Y2] };
    
  float[] startEdgePoint = getClosestEdgePoint(startSegment);
  float[] endEdgePoint = getClosestEdgePoint(endSegment);

  float edgePointDist = dist(startEdgePoint[X1], startEdgePoint[Y1], endEdgePoint[X1], endEdgePoint[Y1]) * 2; 
  float[] edgeMidPoint = new float[] { 
    (startEdgePoint[X1] + endEdgePoint[X1]) / 2,
    (startEdgePoint[Y1] + endEdgePoint[Y1]) / 2 };
  
  float totalDist = startEdgePoint[DISTANCE] + edgePointDist + endEdgePoint[DISTANCE];
  float startHalfEdgeDist = startEdgePoint[DISTANCE] + edgePointDist / 2;
  float endHalfEdgeDist = endEdgePoint[DISTANCE] + edgePointDist / 2;

  //float sat = brightness(coords[COLOR]);

  int frame;
  for(frame = startFrame; frame < TOTAL_ANIMATION_FRAMES; ++frame) {
    float curDist = totalDist * easing[frame][DEFAULT];
    //float curDist = totalDist * lerp(easing[frame][POLY], easing[frame][POLY_INVERSE], sat / 256);
    
    float newX = 0, newY = 0;
    if(curDist < startHalfEdgeDist) {
      //float frac1 = curDist / startDist;
      //float frac2 = (curDist - startDist) / edgePointDist;
      float mainFrac = curDist / startHalfEdgeDist;
      newX = lerp(
        lerp(coords[X1], startEdgePoint[X1], mainFrac),
        lerp(startEdgePoint[X1], edgeMidPoint[X1], mainFrac),
        mainFrac);
      newY = lerp(
        lerp(coords[Y1], startEdgePoint[Y1], mainFrac),
        lerp(startEdgePoint[Y1], edgeMidPoint[Y1], mainFrac),
        mainFrac);
    } else {
      float mainFrac = (curDist - startHalfEdgeDist) / endHalfEdgeDist;
      newX = lerp(
        lerp(edgeMidPoint[X1], endEdgePoint[X1], mainFrac),
        lerp(endEdgePoint[X1], coords[X2], mainFrac),
        mainFrac);
      newY = lerp(
        lerp(edgeMidPoint[Y1], endEdgePoint[Y1], mainFrac),
        lerp(endEdgePoint[Y1], coords[Y2], mainFrac),
        mainFrac);
    }
    roundAndPlotIfInBounds(newX, newY, coords[COLOR], frame);
  }
}

// make it look like a wave
// random of all available animations
// raindrops based on distance
// https://math.stackexchange.com/questions/121720/ease-in-out-function
// https://math.stackexchange.com/questions/547045/ellipses-given-focus-and-two-points
