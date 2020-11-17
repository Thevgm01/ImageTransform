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
final int ANIMATION_NOISEFIELD = 9;
final int NUM_ANIMATIONS = 10;

final int ANIMATION_CIRCLE_AXIS = 10; // centerY, startAngle, endAngle, radius

final int LINEAR = 0;
final int DEFAULT = 1;
final int POLY = 2;
final int POLY_INVERSE = 3;
final int STEEP = 4;
final int POLY_STEEP = 5;
final int EXPONENTIAL = 6;
final int EXPONENTIAL_SMOOTH = 6;
final int partialEasingOffset = 7;

final float easeValue = 3f;
final float polynomialPower = 2f;
final float exponentialFalloff = 2f;
final float trigTableSize = 4000f;

int curAnimation = 0;
int easeMethodX = 0;
int easeMethodY = 0;
int direction = 0;

int startFrame = 0;

float[][] easing;
float[] sinTable, cosTable;

float[][] noiseTableX;
float[][] noiseTableY;
final float NOISE_SCALE = 1000f; // How much the pixels move
final float NOISE_STEP = 0.001f; // How varied the movements are across the whole image

// Don't change this one, this is basically how finely detailed the noise movement is
final int NOISE_CIRCLE_RADIUS = 500;//NOISE_CIRCLE_DIAMETER / 2;
final int NOISE_CIRCLE_DIAMETER = NOISE_CIRCLE_RADIUS * 2;

float[] getNoiseXY(float x, float y) {
  int i = round(x) + NOISE_CIRCLE_DIAMETER,
      j = round(y) + NOISE_CIRCLE_DIAMETER;
  return new float[] {
    noiseTableX[i][j], 
    noiseTableY[i][j] 
    //noise(x + 5000, y + 5000),
    //noise(x + 5000, y - 5000)
  };
}

void initializeAnimator() {
  easing = new float[TOTAL_ANIMATION_FRAMES][5 * 2];
  for(int i = 0; i < TOTAL_ANIMATION_FRAMES; ++i) {
    float frac = (float)i / (TOTAL_ANIMATION_FRAMES - 1);
    easing[i][LINEAR] = frac;
    easing[i][DEFAULT] = easeFunc(frac, easeValue);
    easing[i][POLY] = pow(easing[i][DEFAULT], polynomialPower);
    easing[i][POLY_INVERSE] = pow(easing[i][DEFAULT], 1f/polynomialPower);
    easing[i][STEEP] = easeFunc(frac, easeValue * 2f);
    easing[i][POLY_STEEP] = pow(easing[i][STEEP], polynomialPower);
    easing[i][EXPONENTIAL] = 1 - exp(-frac * exponentialFalloff) * (1 - frac);
    easing[i][EXPONENTIAL_SMOOTH] = lerp(easing[i][DEFAULT], easing[i][EXPONENTIAL], 0.5f);
  }

  noiseTableX = new float[width + 2000][height + 2000];
  noiseTableY = new float[width + 2000][height + 2000];
  for(int i = 0; i < width + 2000; ++i) {
    for(int j = 0; j < height + 2000; ++j) {
      noiseTableX[i][j] = noise((i + 10000) * NOISE_STEP, (j + 10000) * NOISE_STEP) * NOISE_SCALE;
      noiseTableY[i][j] = noise((i - 10000) * NOISE_STEP, (j - 10000) * NOISE_STEP) * NOISE_SCALE;
    }
  }

  int numEntries = (int)(TWO_PI * trigTableSize);
  sinTable = new float[numEntries + 1];
  cosTable = new float[numEntries + 1];
  for(int i = 0; i <= numEntries; ++i) {
    sinTable[i] = sin(i / trigTableSize);
    cosTable[i] = cos(i / trigTableSize);
  }
  
  float sandFallTime = sandFallDuration * TOTAL_ANIMATION_FRAMES;
  sandFallAcceleration = height * 2 / (sandFallTime * sandFallTime);
}

void resetAnimator() {
  
  do curAnimation = (int)random(NUM_ANIMATIONS);
  while(false
    || curAnimation == ANIMATION_FALLING_SAND
    || curAnimation == ANIMATION_ELLIPSE 
  );
  
  easeMethodX = (int)random(3) + 1;
  do easeMethodY = (int)random(3) + 1;
  while(easeMethodX == easeMethodY); // Ensure you can't have two of the same polynomial easing
  
  direction = random(1) > 0.5f ? 1 : -1;
    
  startFrame = 0;
    
  // OVERRIDES //
  //curAnimation = ANIMATION_NOISEFIELD;
  curAnimation = ANIMATION_FALLING_SAND;
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

boolean inBounds(float x, float y) {
  return x >= 0 && x < width && y >= 0 && y < height;
}

void createTransitionAnimation() {
  switch(curAnimation) {
    case ANIMATION_FALLING_SAND:
      thread("animate_fallingSand");
      break;
    default:
      for(int i = 0; i < NUM_THREADS; ++i)
        thread("createAnimationFrames" + i);
        //createAnimationFrames(i);
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
    ++animationIndexes[offset];

    int[] coords;
    int j = newOrder[i];
    if(j == -1) continue;
    coords = getCoords(i, j);

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
      case ANIMATION_NOISEFIELD: 
        animatePixel_noisefield(coords); break;
      //case ANIMATION_CIRCLE_AXIS: 
      //  animatePixel_circleAxis(c, coords); break;
    }
  }
}
