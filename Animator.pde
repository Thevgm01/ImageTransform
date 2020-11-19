int counter1 = 0;
final int X1 = counter1++;
final int Y1 = counter1++;
final int X2 = counter1++;
final int Y2 = counter1++;
final int COLOR = counter1++;

private enum Animation {
  LINEAR,
  CIRCLE,
  SPIRAL,
  ELLIPSE,
  BURST_PHYSICS,
  LURCH,
  FALLING_SAND,
  LASER,
  EVAPORATE,
  WIGGLE,
}
final int NUM_ANIMATIONS = Animation.values().length;

//final int ANIMATION_CIRCLE_AXIS = 10; // centerY, startAngle, endAngle, radius

int counter2 = 0;
final int LINEAR = counter2++;
final int DEFAULT = counter2++;
final int POLY = counter2++;
final int POLY_INVERSE = counter2++;
final int STEEP = counter2++;
final int POLY_STEEP = counter2++;
final int EXPONENTIAL = counter2++;
final int EXPONENTIAL_SMOOTH = counter2++;
final int partialEasingOffset = counter2++;

//--------------------------------------//

final float easeValue = 3f;
final float polynomialPower = 2f;
final float exponentialFalloff = 2f;
final float trigTableSize = 4000f;

Animation curAnimation;
int easeMethodX = 0;
int easeMethodY = 0;
int direction = 0;

int startFrame = 0;

float[][] easing;
float[] sinTable, cosTable;

final float sandFallDuration = 0.5f;
int sandFallFrames = (int)(sandFallDuration * TOTAL_ANIMATION_FRAMES);
float sandFallAcceleration;

float[][] noiseTableX;
float[][] noiseTableY;
final float NOISE_SCALE = 2000f; // How much the pixels move
final float NOISE_STEP = 0.0005f; // How varied the movements are across the whole image
final int NOISE_CIRCLE_RADIUS = 1000; // Don't change this one unless the movement is looking choppy
final int NOISE_CIRCLE_DIAMETER = NOISE_CIRCLE_RADIUS << 1;
final int NOISE_CIRCLE_ARRAY = NOISE_CIRCLE_RADIUS << 2;

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

  int numEntries = (int)(TWO_PI * trigTableSize);
  sinTable = new float[numEntries + 1];
  cosTable = new float[numEntries + 1];
  for(int i = 0; i <= numEntries; ++i) {
    sinTable[i] = sin(i / trigTableSize);
    cosTable[i] = cos(i / trigTableSize);
  }
    
  thread("randomizeNoise");
    
  float sandFallTime = sandFallDuration * TOTAL_ANIMATION_FRAMES;
  sandFallAcceleration = height * 2 / (sandFallTime * sandFallTime);
}

void resetAnimator() {
  
  do curAnimation = Animation.values()[(int)random(NUM_ANIMATIONS)];
  while(false
    || curAnimation == Animation.FALLING_SAND
    || curAnimation == Animation.ELLIPSE 
  );
  
  easeMethodX = (int)random(3) + 1;
  do easeMethodY = (int)random(3) + 1;
  while(easeMethodX == easeMethodY); // Ensure you can't have two of the same polynomial easing
  
  direction = random(1) > 0.5f ? 1 : -1;
    
  startFrame = 0;
    
  // OVERRIDES //
  curAnimation = Animation.WIGGLE;
  //curAnimation = Animation.FALLING_SAND;
  //curAnimation = Animation.SPIRAL;
  //easeMethodX = 2;
}

void randomizeNoise() {
  noiseSeed(frameCount);
  noiseTableX = new float[width + NOISE_CIRCLE_ARRAY][height + NOISE_CIRCLE_ARRAY];
  noiseTableY = new float[width + NOISE_CIRCLE_ARRAY][height + NOISE_CIRCLE_ARRAY];
  for(int i = 0; i < width + NOISE_CIRCLE_ARRAY; ++i) {
    for(int j = 0; j < height + NOISE_CIRCLE_ARRAY; ++j) {
      noiseTableX[i][j] = noise((i + 10000) * NOISE_STEP, (j + 10000) * NOISE_STEP) * NOISE_SCALE;
      noiseTableY[i][j] = noise((i - 10000) * NOISE_STEP, (j - 10000) * NOISE_STEP) * NOISE_SCALE;
    }
  }
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

boolean inBounds(int x, int y) {
  return x >= 0 && x < width && y >= 0 && y < height;
}

void plotIfInBounds(float x, float y, color c, int f) {
  int xi = round(x);
  int yi = round(y);
  if(inBounds(xi, yi)) plot(xi, yi, c, f);
}

void createTransitionAnimation() {
  switch(curAnimation) {
    case FALLING_SAND:
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
      case LINEAR: 
        animatePixel_linear(coords); break;
      case CIRCLE: 
        animatePixel_circle(coords); break;
      case SPIRAL: 
        animatePixel_spiral(coords); break;
      case ELLIPSE: 
        animatePixel_ellipse(coords); break;
      case BURST_PHYSICS: 
        animatePixel_burstPhysics(coords); break;
      case LURCH: 
        animatePixel_lurch(coords); break;
      case FALLING_SAND:
        break;
      case LASER: 
        animatePixel_laser(coords); break;
      case EVAPORATE: 
        animatePixel_evaporate(coords); break;
      case WIGGLE: 
        animatePixel_noisefield(coords); break;
      //case ANIMATION_CIRCLE_AXIS: 
      //  animatePixel_circleAxis(c, coords); break;
    }
  }
}
