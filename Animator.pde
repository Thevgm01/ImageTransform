final int X1 = 0;
final int Y1 = 1;
final int X2 = 2;
final int Y2 = 3;
final int COLOR = 4;

final int ANIMATION_LINEAR = 0;
final int ANIMATION_CIRCLE = 1;      // centerX, centerY, startAngle, radius
final int ANIMATION_SPIRAL = 2;      // startAngle, totalAngle, startRadius, endRadius
final int ANIMATION_ELLIPSE = 3;
final int ANIMATION_BURST_PHYSICS = 4;
final int ANIMATION_LURCH = 5;
final int ANIMATION_FALLING_SAND = 6;
final int ANIMATION_LASER = 7;
final int ANIMATION_EVAPORATE = 8;
final int NUM_ANIMATIONS = 9;

final int ANIMATION_CIRCLE_AXIS = 10; // centerY, startAngle, endAngle, radius

final int DEFAULT = 0;
final int POLY = 1;
final int POLY_INVERSE = 2;
final int STEEP = 3;
final int POLY_STEEP = 4;
final int partialEasingOffset = 5;

final float easeValue = 3f;
final float polynomialPower = 2f;
final float noiseScale = 500f;
final float trigTableSize = 4000f;

final float sandFallDuration = 0.5f;
float sandFallAcceleration;
int sandFallFrames = (int)(sandFallDuration * TOTAL_ANIMATION_FRAMES);

int curAnimation = 0;
int easeMethodX = 0;
int easeMethodY = 0;
int direction = 0;

int startFrame = 0;
int[][] storedCoords;
boolean usingStoredCoords = false;

float[][] easing;
float[][] noiseTable;
float[] sinTable, cosTable;

void initializeAnimator() {
  easing = new float[TOTAL_ANIMATION_FRAMES][5 * 2];
  for(int i = 0; i < TOTAL_ANIMATION_FRAMES; i++) {
    easing[i][DEFAULT] = easeFunc((float)i / (TOTAL_ANIMATION_FRAMES - 1), easeValue);
    easing[i][POLY] = pow(easing[i][DEFAULT], polynomialPower);
    easing[i][POLY_INVERSE] = pow(easing[i][DEFAULT], 1f/polynomialPower);
    easing[i][STEEP] = easeFunc((float)i / (TOTAL_ANIMATION_FRAMES - 1), easeValue * 2f);
    easing[i][POLY_STEEP] = pow(easing[i][STEEP], polynomialPower);
  }
  
  for(int i = sandFallFrames; i < TOTAL_ANIMATION_FRAMES; i++) {
     float index = map(i, sandFallFrames, TOTAL_ANIMATION_FRAMES, 0, TOTAL_ANIMATION_FRAMES);
     int integerPart = (int)index;
     float floatPart = index - integerPart;
     for(int j = 0; j < partialEasingOffset; j++) {
       easing[i][j + partialEasingOffset] = lerp(easing[integerPart][j], easing[integerPart + 1][j], floatPart);
     }
  }
  
  int sandAnimationFrames = TOTAL_ANIMATION_FRAMES - sandFallFrames;
  for(int i = 0; i < sandAnimationFrames; i++) {
    easing[i + sandFallFrames][DEFAULT + partialEasingOffset] = easeFunc((float)i / (sandAnimationFrames - 1), easeValue);
    easing[i + sandFallFrames][POLY + partialEasingOffset] = pow(easing[i + sandFallFrames][DEFAULT + partialEasingOffset], polynomialPower);
    easing[i + sandFallFrames][POLY_INVERSE + partialEasingOffset] = pow(easing[i + sandFallFrames][DEFAULT + partialEasingOffset], 1f/polynomialPower);
    easing[i + sandFallFrames][STEEP + partialEasingOffset] = easeFunc((float)i / (sandAnimationFrames - 1), easeValue * 2f);
    easing[i + sandFallFrames][POLY_STEEP + partialEasingOffset] = pow(easing[i + sandFallFrames][STEEP + partialEasingOffset], polynomialPower);
  }
  
  noiseTable = new float[height][width];
  for(int i = 0; i < height; i++)
    for(int j = 0; j < width; j++)
      noiseTable[i][j] = noise(i / noiseScale, j / noiseScale);
  
  int numEntries = (int)(TWO_PI * trigTableSize);
  sinTable = new float[numEntries + 1];
  cosTable = new float[numEntries + 1];
  for(int i = 0; i <= numEntries; i++) {
    sinTable[i] = sin(i / trigTableSize);
    cosTable[i] = cos(i / trigTableSize);
  }
  
  float sandFallTime = sandFallDuration * TOTAL_ANIMATION_FRAMES;
  sandFallAcceleration = height * 2 / (sandFallTime * sandFallTime);
  
  storedCoords = new int[TOTAL_SIZE][5];
}

void resetAnimator() {
  
  do curAnimation = (int)random(NUM_ANIMATIONS);
  while(false
    || curAnimation == ANIMATION_FALLING_SAND
    || curAnimation == ANIMATION_ELLIPSE 
  );
  
  easeMethodX = (int)random(3);
  do easeMethodY = (int)random(3);
  while(easeMethodX == easeMethodY && easeMethodX != 0); // Ensure you can't have two of the same polynomial easing
  
  direction = random(1) > 0.5f ? 1 : -1;
  
  startFrame = 0;
  usingStoredCoords = false;
  
  // OVERRIDES //
  //curAnimation = ANIMATION_EVAPORATE;
  //curAnimation = ANIMATION_BURST_PHYSICS;
  //easeMethodX = 2;
}

float getTrigTable(float[] table, float angle) {
  while(angle < 0) angle += TWO_PI;
  while(angle >= TWO_PI) angle -= TWO_PI;
  return table[(int)(angle * trigTableSize)];
}

int[] getCoords(int i, int j) {
  return new int[] {
    j % width,
    j / width,
    i % width,
    i / width,
    startImg.pixels[j] };
}

float easeFunc(float t, float strength) {
  return pow(t, strength)/(pow(t, strength)+pow((1-t), strength));
}

void createTransitionAnimation() {
  switch(curAnimation) {
    case ANIMATION_FALLING_SAND:
      thread("animate_fallingSand");
      break;
    default:
      for(int i = 0; i < NUM_THREADS; i++)
        thread("createAnimationFrames" + i);
      break;
  }
}

void createAnimationFrames0() { createAnimationFrames(0); }
void createAnimationFrames1() { createAnimationFrames(1); }
void createAnimationFrames2() { createAnimationFrames(2); }
void createAnimationFrames3() { createAnimationFrames(3); }
void createAnimationFrames4() { createAnimationFrames(4); }
void createAnimationFrames5() { createAnimationFrames(5); }
void createAnimationFrames6() { createAnimationFrames(6); }
void createAnimationFrames7() { createAnimationFrames(7); }

void createAnimationFrames(int offset) {
  for(int i = offset; i < TOTAL_SIZE; i += NUM_THREADS) {
    animationIndexes[offset]++;

    int[] coords;
    if(usingStoredCoords) coords = storedCoords[i];
    else {
      int j = newOrder[i];
      if(j == -1) continue;
      coords = getCoords(i, j);
    }

    switch(curAnimation) {
      case ANIMATION_LINEAR: 
        animatePixel_linear(coords); break;
      case ANIMATION_CIRCLE: 
        animatePixel_circle(coords); break;
      case ANIMATION_SPIRAL: 
        animatePixel_spiral(coords); break;
      case ANIMATION_ELLIPSE: 
        animatePixel_ellipse(coords); break;
      case ANIMATION_BURST_PHYSICS: 
        animatePixel_burstPhysics(coords); break;
      case ANIMATION_LURCH: 
        animatePixel_lurch(coords); break;
      case ANIMATION_LASER: 
        animatePixel_laser(coords); break;
      case ANIMATION_EVAPORATE: 
        animatePixel_evaporate(coords); break;
      //case ANIMATION_CIRCLE_AXIS: 
      //  animatePixel_circleAxis(c, coords); break;
    }
  }
}

void animatePixel_linear(int[] coords) {  
  float xDiff = coords[X2] - coords[X1],
        yDiff = coords[Y2] - coords[Y1];
  for(int frame = startFrame; frame < TOTAL_ANIMATION_FRAMES; frame++) {
    float newX = coords[X1] + xDiff * easing[frame][easeMethodX],
          newY = coords[Y1] + yDiff * easing[frame][easeMethodY];
    plot(newX, newY, coords[COLOR], frame);
  }
}

void animatePixel_circle(int[] coords) {    
  float centerX = (coords[X1] + coords[X2]) / 2f;
  float centerY = (coords[Y1] + coords[Y2]) / 2f;
  float startAngle = atan2(coords[Y1] - centerY, coords[X1] - centerX);
  float radius = dist(coords[X1], coords[Y1], coords[X2], coords[Y2]) / 2f;
  
  for(int frame = startFrame; frame < TOTAL_ANIMATION_FRAMES; frame++) {    
    float rotateAmount = startAngle + PI * direction * easing[frame][DEFAULT];
    float newX = centerX + getTrigTable(cosTable, rotateAmount) * radius,
          newY = centerY + getTrigTable(sinTable, rotateAmount) * radius;
    if(newX < 0 || newX >= width - 1 || newY < 0 || newY >= height - 1) continue;
    plot(newX, newY, coords[COLOR], frame);
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
  
  for(int frame = startFrame; frame < TOTAL_ANIMATION_FRAMES; frame++) {    
    float rotateAmount = startAngle + angleDiff * direction * easing[frame][easeMethodX];
    float radiusAmount = startDist + radiusDiff * easing[frame][easeMethodY];
    float newX = HALF_WIDTH + getTrigTable(cosTable, rotateAmount) * radiusAmount,
          newY = HALF_HEIGHT + getTrigTable(sinTable, rotateAmount) * radiusAmount;
    if(newX < 0 || newX >= width - 1 || newY < 0 || newY >= height - 1) continue;
    plot(newX, newY, coords[COLOR], frame);
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

  for(int frame = startFrame; frame < TOTAL_ANIMATION_FRAMES; frame++) {    
    float rotateAmount = startAngle + angleDiff /** direction*/ * easing[frame][DEFAULT];    
    float newX = HALF_WIDTH + getTrigTable(cosTable, -rotateAmount) * ellipseWidthRadius,
          newY = centerY + getTrigTable(sinTable, -rotateAmount) * ellipseHeightRadius;
    if(newX < 0 || newX >= width - 1 || newY < 0 || newY >= height - 1) continue;
    plot(newX, newY, coords[COLOR], frame);
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
  float gravity = 0.0f;
  //float xVel = startVel * ((coords[X1] - HALF_WIDTH) / 5f);// + cos(startAngle));
  //float yVel = startVel * ((coords[Y1] - HALF_HEIGHT) / 5f);// + sin(startAngle));
  float maxSpeed = 5f;
  //float halfMaxSpeed = 0;
  float tempXVel = ((float)(coords[COLOR] >> SATURATION & 0xff) / 256f) * maxSpeed + cos(startAngle) * randomSpread;
  float tempYVel = ((float)(coords[COLOR] >> BRIGHTNESS & 0xff) / 256f) * maxSpeed * 2 - maxSpeed + sin(startAngle) * randomSpread;
  float rotation = ((float)(coords[COLOR] >> HUE & 0xff) / 256f) * 2 * PI;
  float xVel = tempXVel * cos(rotation) - tempYVel * sin(rotation);
  float yVel = tempXVel * sin(rotation) + tempYVel * cos(rotation);
  //float xVel = tempXVel;
  //float yVel = tempYVel;
  
  float speedDecay = 0.998f;
  
  for(int frame = startFrame; frame < TOTAL_ANIMATION_FRAMES; frame++) {
     //<>// //<>// //<>//
    newX += xVel;
    if(newX < 0) {
      newX = -newX;
      xVel = -xVel;
    } else if(newX > width - 2) {
      newX = 2 * width - newX - 2;
      xVel = -xVel;
    } else {
      xVel *= 0.995f;
    }
    
    newY += yVel;
    yVel += gravity;
    if(newY < 0) {
      newY = -newY;
      yVel = -yVel;
    } else if(newY > height - 2) {
      newY = 2 * height - newY - 4;
      yVel = -yVel;
    } else {
      yVel *= speedDecay;
    }

    plot(
      round(lerp(newX, coords[X2], easing[frame][easeMethodX])),
      round(lerp(newY, coords[Y2], easing[frame][easeMethodY])), 
      coords[COLOR],
      frame);
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
    for(int frame = startFrame; frame < TOTAL_ANIMATION_FRAMES; frame++) {
      if(frame < TOTAL_ANIMATION_FRAMES / 2) {
        newX = lerp(coords[X1], coords[X2], easing[frame * 2][POLY]); 
        newY = coords[Y1];
      } else {
        newX = coords[X2];
        newY = lerp(coords[Y1], coords[Y2], easing[frame * 2 - TOTAL_ANIMATION_FRAMES][POLY_INVERSE]); 
      }
      plot(newX, newY, coords[COLOR], frame);
    }
  } else {
    for(int frame = startFrame; frame < TOTAL_ANIMATION_FRAMES; frame++) {
      if(frame < TOTAL_ANIMATION_FRAMES / 2) {
        newX = coords[X1];
        newY = lerp(coords[Y1], coords[Y2], easing[frame * 2][POLY]);
      } else {
        newX = lerp(coords[X1], coords[X2], easing[frame * 2 - TOTAL_ANIMATION_FRAMES][POLY_INVERSE]); 
        newY = coords[Y2];
      }
      plot(newX, newY, coords[COLOR], frame);
    }
  }
}

class Sand {
  boolean falling = true;
  
  int x;
  float y;
  color c;
  
  int lastFrame = -1;
  
  public Sand(int x, int y, color c) {
    this.x = x;
    this.y = y;
    this.c = c;
  }
}

void animate_fallingSand() {
  int[] sandLastRadius = new int[width];
  Sand[] sandList = new Sand[TOTAL_SIZE];
  int[] sandPointers = new int[TOTAL_SIZE];
  float velocity = 0;
  //float gravity = 0.15f;
  
  for(int i = 0; i < TOTAL_SIZE; i++) {
    int j = newOrder[i]; // starting index
    if(j == -1) continue;
    
    int[] coords = getCoords(i, j);
    storedCoords[i] = coords;
    if(sandList[j] == null)
      sandList[j] = new Sand(coords[X1], coords[Y1], coords[COLOR]);
    sandPointers[i] = j;
  }
  
  int finalFallFrame = -1;
  for(int frame = startFrame; frame < sandFallFrames; frame++) {
    velocity += sandFallAcceleration;
    animationIndexes[0] += TOTAL_SIZE / TOTAL_ANIMATION_FRAMES;

    for(int i = TOTAL_SIZE - 1; i >= 0; i--) {
      if(sandList[sandPointers[i]] == null) continue;
      Sand s = sandList[sandPointers[i]];
      
      if(finalFallFrame < 0) {
        if(s.lastFrame == frame) continue;
        else s.lastFrame = frame;
        
        if (s.falling) {
          s.y += velocity;
  
          if (height - s.y - 1 < sandLastRadius[s.x]) {
            s.falling = false;
    
            boolean searching = true;
            int radius = sandLastRadius[s.x];
            while (searching) {
              for (int k = 0; k <= radius; k++) {
                //check x + radius - i, y + i
                if (
                  s.x + radius - k < width &&
                  sandLastRadius[s.x + radius - k] <= k) { 
                  sandLastRadius[s.x] = radius; 
                  s.x += radius - k; 
                  searching = false; 
                  break;
                } else if (
                  k != radius && 
                  s.x - radius + k >= 0 &&
                  sandLastRadius[s.x - radius + k] <= k) { 
                    sandLastRadius[s.x] = radius; 
                    s.x -= radius - k; 
                    searching = false; 
                    break;
                }
              }
              radius++;
            }
    
            sandLastRadius[s.x]++;
            s.y = height - sandLastRadius[s.x];
          }
        }      
        
        //if(s.x < 0 || s.x >= width - 1 || round(s.y) < 0 || round(s.y) >= height - 1) continue;
        plot(s.x, s.y, s.c, frame);
      }
    }
  }
  for(int i = 0; i < TOTAL_SIZE; i++) {
    Sand s = sandList[sandPointers[i]];
    if(sandList[sandPointers[i]] == null) continue;
    storedCoords[i][X1] = s.x;
    storedCoords[i][Y1] = (int)s.y;
  }
  easeMethodX += partialEasingOffset;
  easeMethodY += partialEasingOffset;
  while(curAnimation == ANIMATION_FALLING_SAND) curAnimation = (int)random(NUM_ANIMATIONS);
  usingStoredCoords = true;
  startFrame = sandFallFrames;
  createTransitionAnimation();
}

/*
void animatePixel_laser(int[] coords) {
  int laserDurationFrames = 10;
  //int laserStartFrame = (int)random(0, TOTAL_ANIMATION_FRAMES - laserDurationFrames);
  int laserStartFrame = (int)(((float)coords[Y2] / height) * (TOTAL_ANIMATION_FRAMES - laserDurationFrames));
    
  for(int frame = startFrame; frame < TOTAL_ANIMATION_FRAMES; frame++) {
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
  
  for(int frame = startFrame; frame < TOTAL_ANIMATION_FRAMES; frame++) {
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
  
  //for(int frame = startFrame; frame < startFrame + framesToFinish; frame++) {
  for(int frame = 0; frame < TOTAL_ANIMATION_FRAMES; frame++) {
    newY = lerp(coords[Y1], coords[Y2] - HEIGHT, easing[frame][DEFAULT]);
    while(newY < 0) {
      newY += HEIGHT - 1;
      newX = coords[X2];
    }
    //newX = lerp(coords[X1], coords[X2], easing[frame][DEFAULT]);
    plot(newX, newY, coords[COLOR], frame);
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
  
  for(int frame = 0; frame < TOTAL_ANIMATION_FRAMES; frame++) {    
    float rotateAmount = startAngle + angleDiff * easing[frame][DEFAULT];
    float newX = HALF_WIDTH + getTrigTable(cosTable, rotateAmount) * distance,
          newY = yIntercept + getTrigTable(sinTable, rotateAmount) * distance;
    if(newX < 0 || newX >= width - 1 || newY < 0 || newY >= height - 1) continue;
    animationFrames[frame].pixels[round(newY) * width + round(newX)] = coords[COLOR];
  }
}
*/

// make it look like a wave
// https://math.stackexchange.com/questions/121720/ease-in-out-function
// https://math.stackexchange.com/questions/547045/ellipses-given-focus-and-two-points
