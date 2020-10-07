final int X1 = 0;
final int Y1 = 1;
final int X2 = 2;
final int Y2 = 3;

final int ANIMATION_LINEAR = 0;
final int ANIMATION_POLY = 1;
final int ANIMATION_POLY_INVERSE = 2;
final int ANIMATION_CIRCLE = 3;        //{centerX, centerY, startAngle, totalAngle, radius}
final int ANIMATION_CIRCLE_REVERSE = 4;//{centerX, centerY, startAngle, totalAngle, radius}
final int ANIMATION_SPIRAL = 5;        //{startAngle, totalAngle, startRadius, endRadius}
final int ANIMATION_SPIRAL_REVERSE = 6;//{startAngle, totalAngle, startRadius, endRadius}
final int NUM_ANIMATIONS = 7;

final int DEFAULT = 0;
final int POLY = 1;
final int POLY_INVERSE = 2;

int curAnimation = 0;
int easeMethodX = 0;
int easeMethodY = 0;

float easeValue = 3f;
float polynomialPower = 2f;
float[][] easing;
float trigTableSize = 2000f;
float[] sinTable, cosTable;

void initializeAnimator() {
  easing = new float[TOTAL_ANIMATION_FRAMES][3];
  for(int i = 0; i < TOTAL_ANIMATION_FRAMES; i++) {
    easing[i][DEFAULT] = easeFunc((float)i / (TOTAL_ANIMATION_FRAMES - 1));
    easing[i][POLY] = pow(easing[i][DEFAULT], polynomialPower);
    easing[i][POLY_INVERSE] = pow(easing[i][DEFAULT], 1f/polynomialPower);
  } 
  
  int numEntries = (int)(TWO_PI * trigTableSize);
  sinTable = new float[numEntries + 1];
  cosTable = new float[numEntries + 1];
  for(int i = 0; i <= numEntries; i++) {
    sinTable[i] = sin(i / trigTableSize);
    cosTable[i] = cos(i / trigTableSize);
    println(((float)i / numEntries));
  }
}

float getTrigTable(float[] table, float angle) {
  while(angle < 0) angle += TWO_PI;
  while(angle >= TWO_PI) angle -= TWO_PI;
  return table[(int)(angle * trigTableSize)];
}

int[] getStartAndEnd(int i, int j) {
  return new int[] {
    j % width,
    j / width,
    i % width,
    i / width };
}

float easeFunc(float t) {
  return pow(t, easeValue)/(pow(t, easeValue)+pow((1-t), easeValue));
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
    int j = newOrder[i];
    color c = startImg.pixels[j];
    int[] coords = getStartAndEnd(i, j);

    switch(curAnimation) {
      case ANIMATION_LINEAR: 
        animatePixel_linear(c, coords);
        break;
      case ANIMATION_POLY:
        animatePixel_poly(c, coords);
        break;
      case ANIMATION_POLY_INVERSE:
        animatePixel_polyInverse(c, coords);
        break;
      case ANIMATION_CIRCLE:
      case ANIMATION_CIRCLE_REVERSE:
        animatePixel_circle(c, coords);
        break;
      case ANIMATION_SPIRAL:
      case ANIMATION_SPIRAL_REVERSE:
        animatePixel_spiral(c, coords);
        break;

    }
    animationIndexes[offset]++;
  }
}

void animatePixel_linear(color c, int[] coords) {  
  float xDiff = coords[X2] - coords[X1],
        yDiff = coords[Y2] - coords[Y1];
  for(int frame = 0; frame < TOTAL_ANIMATION_FRAMES; frame++) {
    float newX = coords[X1] + xDiff * easing[frame][DEFAULT],
          newY = coords[Y1] + yDiff * easing[frame][DEFAULT];
    animationFrames[frame].pixels[round(newY) * width + round(newX)] = c;
  }
}

void animatePixel_poly(color c, int[] coords) {
  float xDiff = coords[X2] - coords[X1],
        yDiff = coords[Y2] - coords[Y1];
        
  for(int frame = 0; frame < TOTAL_ANIMATION_FRAMES; frame++) {
    float newX = coords[X1] + xDiff * easing[frame][POLY],
          newY = coords[Y1] + yDiff * easing[frame][POLY_INVERSE];
    animationFrames[frame].pixels[round(newY) * width + round(newX)] = c;
  }
}

void animatePixel_polyInverse(color c, int[] coords) {
  float xDiff = coords[X2] - coords[X1],
        yDiff = coords[Y2] - coords[Y1];
  
  for(int frame = 0; frame < TOTAL_ANIMATION_FRAMES; frame++) {
    float newX = coords[X1] + xDiff * easing[frame][POLY_INVERSE],
          newY = coords[Y1] + yDiff * easing[frame][POLY];
    animationFrames[frame].pixels[round(newY) * width + round(newX)] = c;
  }
}

void animatePixel_circle(color c, int[] coords) {    
  float[] animationData = new float[5];
  animationData[0] = (coords[X1] + coords[X2]) / 2f;
  animationData[1] = (coords[Y1] + coords[Y2]) / 2f;
  animationData[2] = atan2(coords[Y1] - animationData[1], coords[X1] - animationData[0]);
  animationData[3] = curAnimation == ANIMATION_CIRCLE_REVERSE ? -PI : PI;
  animationData[4] = dist(coords[X1], coords[Y1], coords[X2], coords[Y2]) / 2f;
  
  for(int frame = 0; frame < TOTAL_ANIMATION_FRAMES; frame++) {    
    float rotateAmount = animationData[2] + animationData[3] * easing[frame][DEFAULT];
    float newX = animationData[0] + getTrigTable(cosTable, rotateAmount) * animationData[4],
          newY = animationData[1] + getTrigTable(sinTable, rotateAmount) * animationData[4];
    if(newX < 0 || newX >= width - 1 || newY < 0 || newY >= height - 1) continue;
    animationFrames[frame].pixels[round(newY) * width + round(newX)] = c;
  }
}

void animatePixel_spiral(color c, int[] coords) {
  float[] animationData = new float[5];
  animationData[0] = atan2(coords[Y1] - height/2, coords[X1] - width/2);
  animationData[1] = atan2(coords[Y2] - height/2, coords[X2] - width/2);
  animationData[2] = dist(coords[X1], coords[Y1], width/2, height/2);
  animationData[3] = dist(coords[X2], coords[Y2], width/2, height/2);
  //animationData[3] = curAnimation == ANIMATION_CIRCLE_BACKWARDS ? -PI : PI;
  //animationData[4] = dist(coords[X1], coords[Y1], coords[X2], coords[Y2]) / 2f;
  
  float angleDiff;
  if(curAnimation == ANIMATION_SPIRAL) {
    angleDiff = animationData[1] - animationData[0];
    if(angleDiff < 0 && curAnimation == ANIMATION_SPIRAL) angleDiff += TWO_PI;
  } else {
    angleDiff = animationData[0] - animationData[1];
    if(angleDiff >= TWO_PI && curAnimation == ANIMATION_SPIRAL_REVERSE) angleDiff -= TWO_PI;
  }
  
  float radiusDiff = animationData[3] - animationData[2];
  
  for(int frame = 0; frame < TOTAL_ANIMATION_FRAMES; frame++) {    
    float rotateAmount = animationData[0] + angleDiff * easing[frame][DEFAULT];
    float radiusAmount = animationData[2] + radiusDiff * easing[frame][POLY];
    float newX = width/2 + getTrigTable(cosTable, rotateAmount) * radiusAmount,
          newY = height/2 + getTrigTable(sinTable, rotateAmount) * radiusAmount;
    if(newX < 0 || newX >= width - 1 || newY < 0 || newY >= height - 1) continue;
    animationFrames[frame].pixels[round(newY) * width + round(newX)] = c;
  }
}
