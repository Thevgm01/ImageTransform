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
final int NUM_ANIMATIONS = 7;

final int ANIMATION_CIRCLE_AXIS = 10; // centerY, startAngle, endAngle, radius

final int DEFAULT = 0;
final int POLY = 1;
final int POLY_INVERSE = 2;
final int STEEP = 3;
final int POLY_STEEP = 4;

final float easeValue = 3f;
final float polynomialPower = 2f;
final float noiseScale = 500f;
final float trigTableSize = 4000f;

int curAnimation = 0;
int easeMethodX = 0;
int easeMethodY = 0;
int direction = 0;

float[][] easing;
float[][] noiseTable;
float[] sinTable, cosTable;

void initializeAnimator() {
  easing = new float[TOTAL_ANIMATION_FRAMES][5];
  for(int i = 0; i < TOTAL_ANIMATION_FRAMES; i++) {
    easing[i][DEFAULT] = easeFunc((float)i / (TOTAL_ANIMATION_FRAMES - 1), easeValue);
    easing[i][POLY] = pow(easing[i][DEFAULT], polynomialPower);
    easing[i][POLY_INVERSE] = pow(easing[i][DEFAULT], 1f/polynomialPower);
    easing[i][STEEP] = easeFunc((float)i / (TOTAL_ANIMATION_FRAMES - 1), easeValue * 2f);
    easing[i][POLY_STEEP] = pow(easing[i][STEEP], polynomialPower);
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
}

void randomizeAnimator() {
    
  curAnimation = (int)random(NUM_ANIMATIONS);
  //curAnimation = ANIMATION_ELLIPSE;
  curAnimation = ANIMATION_LURCH;
  //curAnimation = ANIMATION_FALLING_SAND;
  
  easeMethodX = (int)random(3);
  do easeMethodY = (int)random(3);
  while(easeMethodX == easeMethodY && easeMethodX != 0); // Ensure you can't have two of the same polynomial easing
  
  direction = random(1) > 0.5f ? 1 : -1;
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
      thread("animate_fallingSand"); break;
    default:
      for(int i = 0; i < NUM_THREADS; i++)
        thread("createAnimationFrames" + i);
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

    int j = newOrder[i];
    if(j == -1) continue;
    int[] coords = getCoords(i, j);

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
      //case ANIMATION_CIRCLE_AXIS: 
      //  animatePixel_circleAxis(c, coords); break;
    }
  }
}

void animatePixel_linear(int[] coords) {  
  float xDiff = coords[X2] - coords[X1],
        yDiff = coords[Y2] - coords[Y1];
  for(int frame = 0; frame < TOTAL_ANIMATION_FRAMES; frame++) {
    float newX = coords[X1] + xDiff * easing[frame][easeMethodX],
          newY = coords[Y1] + yDiff * easing[frame][easeMethodY];
    animationFrames[frame].pixels[round(newY) * width + round(newX)] = coords[COLOR];
  }
}

void animatePixel_circle(int[] coords) {    
  float centerX = (coords[X1] + coords[X2]) / 2f;
  float centerY = (coords[Y1] + coords[Y2]) / 2f;
  float startAngle = atan2(coords[Y1] - centerY, coords[X1] - centerX);
  float radius = dist(coords[X1], coords[Y1], coords[X2], coords[Y2]) / 2f;
  
  for(int frame = 0; frame < TOTAL_ANIMATION_FRAMES; frame++) {    
    float rotateAmount = startAngle + PI * direction * easing[frame][DEFAULT];
    float newX = centerX + getTrigTable(cosTable, rotateAmount) * radius,
          newY = centerY + getTrigTable(sinTable, rotateAmount) * radius;
    if(newX < 0 || newX >= width - 1 || newY < 0 || newY >= height - 1) continue;
    animationFrames[frame].pixels[round(newY) * width + round(newX)] = coords[COLOR];
  }
}

void animatePixel_spiral(int[] coords) {
  float startAngle = atan2(coords[Y1] - HALF_HEIGHT, coords[X1] - HALF_WIDTH);
  float endAngle = atan2(coords[Y2] - HALF_HEIGHT, coords[X2] - HALF_WIDTH);
  float startDist = dist(coords[X1], coords[Y1], HALF_WIDTH, HALF_HEIGHT);
  float endDist = dist(coords[X2], coords[Y2], HALF_WIDTH, HALF_HEIGHT);
  
  float angleDiff = endAngle - startAngle;
  while(angleDiff < 0) angleDiff += TWO_PI;
  if(direction == -1) angleDiff = TWO_PI - angleDiff;
  
  float radiusDiff = endDist - startDist;
  
  for(int frame = 0; frame < TOTAL_ANIMATION_FRAMES; frame++) {    
    float rotateAmount = startAngle + angleDiff * direction * easing[frame][easeMethodX];
    float radiusAmount = startDist + radiusDiff * easing[frame][easeMethodY];
    float newX = HALF_WIDTH + getTrigTable(cosTable, rotateAmount) * radiusAmount,
          newY = HALF_HEIGHT + getTrigTable(sinTable, rotateAmount) * radiusAmount;
    if(newX < 0 || newX >= width - 1 || newY < 0 || newY >= height - 1) continue;
    animationFrames[frame].pixels[round(newY) * width + round(newX)] = coords[COLOR];
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

  for(int frame = 0; frame < TOTAL_ANIMATION_FRAMES; frame++) {    
    float rotateAmount = startAngle + angleDiff /** direction*/ * easing[frame][DEFAULT];    
    float newX = HALF_WIDTH + getTrigTable(cosTable, -rotateAmount) * ellipseWidthRadius,
          newY = centerY + getTrigTable(sinTable, -rotateAmount) * ellipseHeightRadius;
    if(newX < 0 || newX >= width - 1 || newY < 0 || newY >= height - 1) continue;
    animationFrames[frame].pixels[round(newY) * width + round(newX)] = coords[COLOR];
  }
}

void animatePixel_burstPhysics(int[] coords) {
  float newX = coords[X1];
  float newY = coords[Y1];
  //float startAngle = random(0, TWO_PI);
  //float startVel = abs(randomGaussian()) / 20f;
  float startVel = random(0.01f, 0.1f);
  //float gravity = 0.1f;
  float gravity = random(0.1f, 0.2f);
  //float gravity = noiseTable[coords[Y1]][coords[X1]] / 5f;
  float xVel = startVel * ((coords[X1] - HALF_WIDTH) / 5f);// + cos(startAngle));
  float yVel = startVel * ((coords[Y1] - HALF_HEIGHT) / 5f);// + sin(startAngle));
  
  for(int frame = 0; frame < TOTAL_ANIMATION_FRAMES; frame++) {
     //<>// //<>//
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
      yVel *= 0.995f;
    }

    animationFrames[frame].pixels[
      round(lerp(newY, coords[Y2], easing[frame][POLY_STEEP])) * width + 
      round(lerp(newX, coords[X2], easing[frame][POLY_STEEP]))] = coords[COLOR];
  }
}

void animatePixel_lurch(int[] coords) {
  float newX, newY;
  boolean horizontalFirst;
  
  //boolean horizontalFirst = true;
  //boolean horizontalFirst = direction > 0 ? true : false;
  if(easeMethodX == 0) horizontalFirst = random(0f, 1f) < 0.5f ? true : false;
  else if(easeMethodX == 1) horizontalFirst = true;
  else horizontalFirst = false;
  
  if(horizontalFirst) {
    for(int frame = 0; frame < TOTAL_ANIMATION_FRAMES; frame++) {
      if(frame < TOTAL_ANIMATION_FRAMES / 2) {
        newX = lerp(coords[X1], coords[X2], easing[frame * 2][POLY]); 
        newY = coords[Y1];
      } else {
        newX = coords[X2];
        newY = lerp(coords[Y1], coords[Y2], easing[frame * 2 - TOTAL_ANIMATION_FRAMES][POLY_INVERSE]); 
      }
      animationFrames[frame].pixels[round(newY) * width + round(newX)] = coords[COLOR];
    }
  } else {
    for(int frame = 0; frame < TOTAL_ANIMATION_FRAMES; frame++) {
      if(frame < TOTAL_ANIMATION_FRAMES / 2) {
        newX = coords[X1];
        newY = lerp(coords[Y1], coords[Y2], easing[frame * 2][POLY]);
      } else {
        newX = lerp(coords[X1], coords[X2], easing[frame * 2 - TOTAL_ANIMATION_FRAMES][POLY_INVERSE]); 
        newY = coords[Y2];
      }
      animationFrames[frame].pixels[round(newY) * width + round(newX)] = coords[COLOR];
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
  float gravity = 0.15f;
  
  for(int i = 0; i < TOTAL_SIZE; i++) {
    int j = newOrder[i];
    if(j == -1) continue;
    if(sandList[j] == null) {
      int[] coords = getCoords(i, j);
      sandList[j] = new Sand(coords[X1], coords[Y1], coords[COLOR]);
    }
    sandPointers[i] = j;
  }
  
  int finalFallFrame = -1;
  for(int frame = 0; frame < TOTAL_ANIMATION_FRAMES; frame++) {
    velocity += gravity;
    animationIndexes[0] += TOTAL_SIZE / TOTAL_ANIMATION_FRAMES;
    boolean fellThisFrame = false;

    for(int i = TOTAL_SIZE - 1; i >= 0; i--) {
      if(sandList[sandPointers[i]] == null) continue;
      Sand s = sandList[sandPointers[i]];
      
      if(finalFallFrame < 0) {
        if(s.lastFrame == frame) continue;
        else s.lastFrame = frame;
        
        if (s.falling) {
          s.y += velocity;
          fellThisFrame = true;
  
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
        animationFrames[frame].pixels[
          round(s.y) * width + s.x] = s.c;
          
      } else {
        float frac = (float)(frame - finalFallFrame) / (TOTAL_ANIMATION_FRAMES - finalFallFrame);
        float fracEase = easing[(int)(frac * TOTAL_ANIMATION_FRAMES)][DEFAULT];
        float newX = s.x + (i % width - s.x) * fracEase;
        float newY = s.y + (i / width - s.y) * fracEase;
        animationFrames[frame].pixels[
          round(newY) * width + round(newX)] = s.c;
      }
    }
    if(finalFallFrame < 0 && !fellThisFrame) {
      finalFallFrame = frame;
    }
  }
}

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

// https://math.stackexchange.com/questions/121720/ease-in-out-function
// https://math.stackexchange.com/questions/547045/ellipses-given-focus-and-two-points
