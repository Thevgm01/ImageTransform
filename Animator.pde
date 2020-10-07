final int X1 = 0;
final int Y1 = 1;
final int X2 = 2;
final int Y2 = 3;

final int ANIMATION_LINEAR = 0;
final int ANIMATION_POLY = 1;
final int ANIMATION_POLY_INVERSE = 2;
final int ANIMATION_CIRCLE = 3;          //{centerX, centerY, startAngle, totalAngle, radius}
final int ANIMATION_CIRCLE_BACKWARDS = 4;//{centerX, centerY, startAngle, totalAngle, radius}
final int NUM_ANIMATIONS = 5;

final int DEFAULT = 0;
final int POLY = 1;
final int POLY_INVERSE = 2;

int curAnimation = 0;
float easeValue = 3f;
float polynomialPower = 2f;
float[][] easing;
float[][] animationData;

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
  if(curAnimation == ANIMATION_CIRCLE || curAnimation == ANIMATION_CIRCLE_BACKWARDS) {
    for(int i = offset; i < TOTAL_SIZE; i += NUM_THREADS) {
      int j = newOrder[i];
      int[] coords = getStartAndEnd(i, j);
      animationData[i][0] = (coords[X1] + coords[X2]) / 2f;
      animationData[i][1] = (coords[Y1] + coords[Y2]) / 2f;
      animationData[i][2] = atan2(coords[Y1] - animationData[i][1], coords[X1] - animationData[i][0]);
      animationData[i][3] = curAnimation == ANIMATION_CIRCLE_BACKWARDS ? -PI : PI;
      animationData[i][4] = dist(coords[X1], coords[Y1], coords[X2], coords[Y2]) / 2f;
    }
  }
  
  for(int i = offset; i < TOTAL_ANIMATION_FRAMES; i += NUM_THREADS) {
    switch(curAnimation) {
      case ANIMATION_LINEAR: 
        createAnimationFrame_linear(animationFrames[i].pixels, i);
        break;
      case ANIMATION_POLY:
        createAnimationFrame_poly(animationFrames[i].pixels, i);
        break;
      case ANIMATION_POLY_INVERSE:
        createAnimationFrame_polyInverse(animationFrames[i].pixels, i);
        break;
      case ANIMATION_CIRCLE:
      case ANIMATION_CIRCLE_BACKWARDS:
        createAnimationFrame_circle(animationFrames[i].pixels, i);
        break;
    }
    animationIndexes[offset]++;
  }
}

void createAnimationFrame_linear(color[] localPixels, int index) {
  for(int i = 0; i < TOTAL_SIZE; i++) {
    int j = newOrder[i];
    int[] coords = getStartAndEnd(i, j);
    float newX = coords[X1] + (coords[X2] - coords[X1]) * easing[index][DEFAULT],
          newY = coords[Y1] + (coords[Y2] - coords[Y1]) * easing[index][DEFAULT];
    localPixels[round(newY) * width + round(newX)] = startImg.pixels[j];
  }
}

void createAnimationFrame_poly(color[] localPixels, int index) {
  for(int i = 0; i < TOTAL_SIZE; i++) {
    int j = newOrder[i];
    int[] coords = getStartAndEnd(i, j);
    float newX = coords[X1] + (coords[X2] - coords[X1]) * easing[index][POLY],
          newY = coords[Y1] + (coords[Y2] - coords[Y1]) * easing[index][POLY_INVERSE];
    localPixels[round(newY) * width + round(newX)] = startImg.pixels[j];
  }
}

void createAnimationFrame_polyInverse(color[] localPixels, int index) {
  for(int i = 0; i < TOTAL_SIZE; i++) {
    int j = newOrder[i];
    int[] coords = getStartAndEnd(i, j);
    float newX = coords[X1] + (coords[X2] - coords[X1]) * easing[index][POLY_INVERSE],
          newY = coords[Y1] + (coords[Y2] - coords[Y1]) * easing[index][POLY];
    localPixels[round(newY) * width + round(newX)] = startImg.pixels[j];
  }
}

void createAnimationFrame_circle(color[] localPixels, int index) {  
  for(int i = 0; i < TOTAL_SIZE; i++) {
    int j = newOrder[i];    
    
    float rotateAmount = animationData[i][2] + animationData[i][3] * easing[index][0];
    float newX = animationData[i][0] + cos(rotateAmount) * animationData[i][4],
          newY = animationData[i][1] + sin(rotateAmount) * animationData[i][4];
    if(newX < 0 || newX >= width - 1 || newY < 0 || newY >= height - 1) continue;
        
    /*
    float rotateAmount = data[2] + data[3] * easing[index][DEFAULT];
    float newX = data[0] + cos(rotateAmount) * data[4],
          newY = data[1] + sin(rotateAmount) * data[4];
    if(newX < 0 || newX >= width - 1 || newY < 0 || newY >= height - 1) continue;
    */
    localPixels[round(newY) * width + round(newX)] = startImg.pixels[j];
  }
}
