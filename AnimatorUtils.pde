//------------EASING------------//

int counter2 = 0;
final int LINEAR = counter2++;
final int DEFAULT = counter2++;
final int POLY = counter2++;
final int POLY_INVERSE = counter2++;
final int STEEP = counter2++;
final int POLY_STEEP = counter2++;
final int EXPONENTIAL = counter2++;
final int EXPONENTIAL_SMOOTH = counter2++;
final int NUM_EASE_METHODS = counter2++;

final float easeValue = 3f;
final float polynomialPower = 2f;
final float exponentialFalloff = 2f;

int easeMethodX = 0;
int easeMethodY = 0;
int direction = 0;

float[][] easing;

void initializeEasing() {
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
}

void randomizeEasing() {
  easeMethodX = (int)random(3) + 1;
  do easeMethodY = (int)random(3) + 1;
  while(easeMethodX == easeMethodY); // Ensure you can't have two of the same polynomial easing
  
  direction = random(1) > 0.5f ? 1 : -1;
}

float easeFunc(float t, float strength) {
  return pow(t, strength)/(pow(t, strength)+pow((1-t), strength));
}

//---------TRIGONOMETRY---------//

final float trigTableSize = 4000f;
float[] sinTable, cosTable;

void initializeTrigTable() {
  int numEntries = (int)(TWO_PI * trigTableSize);
  sinTable = new float[numEntries + 1];
  cosTable = new float[numEntries + 1];
  for(int i = 0; i <= numEntries; ++i) {
    sinTable[i] = sin(i / trigTableSize);
    cosTable[i] = cos(i / trigTableSize);
  }
}

float getTrigTable(float[] table, float angle) {
  while(angle < 0) angle += TWO_PI;
  while(angle >= TWO_PI) angle -= TWO_PI;
  return table[(int)(angle * trigTableSize)];
}

//-------------SAND-------------//

final float sandFallDuration = 0.5f;
int sandFallFrames = (int)(sandFallDuration * TOTAL_ANIMATION_FRAMES);
float sandFallAcceleration;

void initializeSand() {
  float sandFallTime = sandFallDuration * TOTAL_ANIMATION_FRAMES;
  sandFallAcceleration = height * 2 / (sandFallTime * sandFallTime);
}

//------------NOISE------------//

float[][] noiseTableX;
float[][] noiseTableY;
final float NOISE_SCALE = 2000f; // How much the pixels move
final float NOISE_STEP = 0.0005f; // How varied the movements are across the whole image
final int NOISE_CIRCLE_RADIUS = 1000; // Don't change this one unless the movement is looking choppy
final int NOISE_CIRCLE_DIAMETER = NOISE_CIRCLE_RADIUS << 1;
final int NOISE_CIRCLE_ARRAY = NOISE_CIRCLE_RADIUS << 2;

float[][] edges = new float[][] {
  new float[] { 0, 0, WIDTH, 0 },
  new float[] { WIDTH, 0, WIDTH, HEIGHT },
  new float[] { 0, HEIGHT, WIDTH, HEIGHT },
  new float[] { 0, 0, 0, HEIGHT }
};

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

//------EDGE INTERSECTION------//

int DISTANCE = 2;

float[] getClosestEdgePoint(float[] segment) {
  float[] edgePoint = new float[3];
  edgePoint[DISTANCE] = LARGEST_DIM;
  for(int i = 0; i < 4; ++i) {
    float[] point = lineLineIntersection(segment, edges[i]);
    float dist = dist(segment[X1], segment[Y1], point[X1], point[Y1]);
    if(dist < edgePoint[DISTANCE]) {
      edgePoint[X1] = point[X1];
      edgePoint[Y1] = point[Y1];
      edgePoint[DISTANCE] = dist;
    }
  }
  return edgePoint;
}

float[] lineLineIntersection(float[] coords1, float[] coords2) { 
  // Line AB represented as a1x + b1y = c1 
  float a1 = coords1[Y2] - coords1[Y1]; 
  float b1 = coords1[X2] - coords1[X1]; 
  float c1 = a1*(coords1[X1]) + b1*(coords1[Y1]); 
 
  // Line CD represented as a2x + b2y = c2 
  float a2 = coords2[Y2] - coords2[Y1]; 
  float b2 = coords2[X2] - coords2[X1]; 
  float c2 = a2*(coords2[X1])+ b2*(coords2[Y1]); 
 
  float determinant = a1*b2 - a2*b1; 
 
  if (determinant == 0) 
  { 
      // The lines are parallel. This is simplified 
      // by returning a pair of FLT_MAX 
      return new float[] { width, height };
  } 
  else
  { 
      float x = (b2*c1 - b1*c2)/determinant; 
      float y = (a1*c2 - a2*c1)/determinant; 
      return new float[] { x, y }; 
  } 
} 
