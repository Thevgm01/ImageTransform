final int RED = 16, GREEN = 8, BLUE = 0;

final int RGB_CUBE_VALUE_BIT_SHIFT = 2; // The number of times to halve each RGB value (for performance reasons)
final int RGB_CUBE_DIMENSIONS_BIT_SHIFT = 8 - RGB_CUBE_VALUE_BIT_SHIFT; // Max 8, currently 6
final int RGB_CUBE_DIMENSIONS = 1 << RGB_CUBE_DIMENSIONS_BIT_SHIFT; // 2^6 = 64

final int RGB_CUBE_X_SHIFT = RGB_CUBE_DIMENSIONS_BIT_SHIFT * 0;
final int RGB_CUBE_Y_SHIFT = RGB_CUBE_DIMENSIONS_BIT_SHIFT * 1;
final int RGB_CUBE_Z_SHIFT = RGB_CUBE_DIMENSIONS_BIT_SHIFT * 2;
final int RGB_CUBE_TOTAL_SIZE = 1 << (RGB_CUBE_DIMENSIONS_BIT_SHIFT * 3);

/* The RGB cube is a multidimensional arraylist that stores the indexes of all the pixels in the start image.
 *
 * The indexes are arranged by their corresponding Red, Green, and Blue values. 
 *
 * The outermost arraylist is very long and has a place for each possible value of RGB, divided by the bit shift.
 * Indexes in this outermost list should only be accessed via coordsToCubeIndex because of the divisions that occur.
 *
 * The next arraylist contains all the indexes of the start image that match that RGB value. 
 */
 
// RGB    Indexes
ArrayList<ArrayList<Integer>> RGB_cube;
ArrayList<ArrayList<Integer>> RGB_cube_recordedResults;

final boolean PERFECT_RGB_CUBE_ANALYSIS = false; // Makes gradients look better
final int RGB_CUBE_MAX_SAMPLES = 1000;
final boolean LEGACY_ANALYSIS = false;
final int LEGACY_NUM_TO_CHECK = 2000;
final int SWITCH_TO_LEGACY_RGB_CUBE_SIZE = (int)(RGB_CUBE_DIMENSIONS * 0.33f);

// We want to store the x and y coordinates of the best matching pixel inside of an image
// We have 32 bits of color to work with
// Want to keep some of the alpha bits to make displaying the coordinate image easier (for debugging)
// AAAAAAAA RRRRRRRR GGGGGGGG BBBBBBBB normal
// AAAAAAAA XXXXXXXX XXXXYYYY YYYYYYYY 12 bits per coordinate, numbers up to 4096
// AAAAAAXX XXXXXXXX XXXYYYYY YYYYYYYY 13 bits per coordinate, numbers up to 8192
// Should work for monitors with up to 8K resolution
final int BITS_FOR_COORDS = 13;
final int COLOR_BIT_MASK = (1 << BITS_FOR_COORDS) - 1;
final int ALPHA_BITS = 0xff << (BITS_FOR_COORDS * 2);

PImage coordsData;


void analyzeStartImage() {
  resetRGBCube();
  
  coordsData = createImage(endImg.width(), endImg.height(), ARGB);

  for(int i = 0; i < NUM_ANALYSIS_THREADS; ++i) {
    thread("findBestFitThread" + i);
  }
}

void resetRGBCube() {
  for(int i = 0; i < RGB_CUBE_TOTAL_SIZE; ++i) {
    RGB_cube.set(i, new ArrayList<Integer>());
    if(cacheAnalysisResults)
      RGB_cube_recordedResults.set(i, new ArrayList<Integer>());
    else
      RGB_cube_recordedResults.get(i).set(0, 1);
  }
  
  for(int i = 0; i < startImg.length(); ++i) {
    color pixel = startImg.getPixel(i);
    if(ignoreBlack && brightness(pixel) <= 1)
      continue;
    
    int pixelR = (pixel >> RED & 0xff) >> RGB_CUBE_VALUE_BIT_SHIFT,
        pixelG = (pixel >> GREEN & 0xff) >> RGB_CUBE_VALUE_BIT_SHIFT,
        pixelB = (pixel >> BLUE & 0xff) >> RGB_CUBE_VALUE_BIT_SHIFT;
        
    ArrayList<Integer> indexes = RGB_cube.get(coordsToCubeIndex(pixelR, pixelG, pixelB));
    if(indexes.size() < RGB_CUBE_MAX_SAMPLES)
      indexes.add(i);
    else
      indexes.set((int)random(RGB_CUBE_MAX_SAMPLES), i);
  }
}

int coordsToCubeIndex(int x, int y, int z) {
  return (x << RGB_CUBE_X_SHIFT) + (y << RGB_CUBE_Y_SHIFT) + (z << RGB_CUBE_Z_SHIFT); 
}

void findBestFitThread0() { findBestFitThread(0); }
void findBestFitThread1() { findBestFitThread(1); }
void findBestFitThread2() { findBestFitThread(2); }
void findBestFitThread3() { findBestFitThread(3); }
void findBestFitThread4() { findBestFitThread(4); }
void findBestFitThread5() { findBestFitThread(5); }
void findBestFitThread6() { findBestFitThread(6); }
void findBestFitThread7() { findBestFitThread(7); }

void findBestFitThread(int offset) {
  for(int i = offset; i < endImg.length(); i += NUM_ANALYSIS_THREADS) {
    findBestFit(i);
    ++analysisIndexes[offset];
  }
}

// Find a pixel from the start image that most closely matches the 
// given pixel from the end image
void findBestFit(int index) {
  color target = endImg.getPixel(index);
  if(ignoreBlack && brightness(target) == 0) {
    //newOrder[index] = -1;  
    return;
  }
  
  int targetR = (target >> RED & 0xff) >> RGB_CUBE_VALUE_BIT_SHIFT,
      targetG = (target >> GREEN & 0xff) >> RGB_CUBE_VALUE_BIT_SHIFT,
      targetB = (target >> BLUE & 0xff) >> RGB_CUBE_VALUE_BIT_SHIFT;

  int desiredIndex = coordsToCubeIndex(targetR, targetG, targetB);
  int startShellSize = 1;

  if(cacheAnalysisResults) {
    ArrayList<Integer> results = RGB_cube_recordedResults.get(desiredIndex);
    if(results.size() > 0) {
      if(PERFECT_RGB_CUBE_ANALYSIS)
        storeCoordsInImage(index, findBestFitFromList(target, results));
      else
        storeCoordsInImage(index, results.get((int)random(results.size())));
      return;
    }
  }
  //else startShellSize = RGB_cube_recordedResults.get(desiredIndex).get(0);
  
  ArrayList<Integer> candidates = new ArrayList<Integer>();
  addAll(candidates, RGB_cube.get(coordsToCubeIndex(targetR, targetG, targetB)));

  for(int shellSize = startShellSize; shellSize < RGB_CUBE_DIMENSIONS; shellSize++) {
    
    if(candidates.size() > 0) {
      if(PERFECT_RGB_CUBE_ANALYSIS)
        //newOrder[index] = findBestFitFromList(target, candidates);
        storeCoordsInImage(index, findBestFitFromList(target, candidates));
      else 
        //newOrder[index] = candidates.get((int)random(candidates.size()));
        storeCoordsInImage(index, candidates.get((int)random(candidates.size())));
      
      if(cacheAnalysisResults)
        RGB_cube_recordedResults.set(desiredIndex, candidates);
      //else RGB_cube_recordedResults.get(desiredIndex).set(0, shellSize);
      return;
    }
    /*
    if(switchToLegacyAnalysisOnSlowdown && shellSize >= SWITCH_TO_LEGACY_RGB_CUBE_SIZE) {
      findBestFit_legacy(index);
      pixelsLegacyAnalyzed.set(index, true);
      return; 
    }
    */
    final int
      MIN_X = 0, MAX_X = 1,
      MIN_Y = 2, MAX_Y = 3,
      MIN_Z = 4, MAX_Z = 5;
              
    int[] borders = {
      targetR - shellSize,
      targetR + shellSize,
      targetG - shellSize,
      targetG + shellSize,
      targetB - shellSize,
      targetB + shellSize };
        
    if(borders[MIN_X] < 0)                    borders[MIN_X] = 0;
    if(borders[MAX_X] >= RGB_CUBE_DIMENSIONS) borders[MAX_X] = RGB_CUBE_DIMENSIONS - 1;
    if(borders[MIN_Y] < 0)                    borders[MIN_Y] = 0;
    if(borders[MAX_Y] >= RGB_CUBE_DIMENSIONS) borders[MAX_Y] = RGB_CUBE_DIMENSIONS - 1;
    if(borders[MIN_Z] < 0)                    borders[MIN_Z] = 0;
    if(borders[MAX_Z] >= RGB_CUBE_DIMENSIONS) borders[MAX_Z] = RGB_CUBE_DIMENSIONS - 1;
    
    // Back side
    for(int x = borders[MIN_X]; x <= borders[MAX_X]; ++x)
      for(int y = borders[MIN_Y]; y <= borders[MAX_Y]; ++y)
        addAll(candidates, RGB_cube.get(coordsToCubeIndex(x, y, borders[MIN_Z])));
    
    // Front side
    for(int x = borders[MIN_X]; x <= borders[MAX_X]; ++x)
      for(int y = borders[MIN_Y]; y <= borders[MAX_Y]; ++y)
        addAll(candidates, RGB_cube.get(coordsToCubeIndex(x, y, borders[MAX_Z])));

    // Left side (minus front and back edges)
    for(int y = borders[MIN_Y]; y <= borders[MAX_Y]; ++y)
      for(int z = borders[MIN_Z] + 1; z < borders[MAX_Z]; ++z)
        addAll(candidates, RGB_cube.get(coordsToCubeIndex(borders[MIN_X], y, z)));

    // Right side (minus front and back edges)
    for(int y = borders[MIN_Y]; y <= borders[MAX_Y]; ++y)
      for(int z = borders[MIN_Z] + 1; z < borders[MAX_Z]; ++z)
        addAll(candidates, RGB_cube.get(coordsToCubeIndex(borders[MAX_X], y, z)));

    // Bottom side (minus front and back edges, left and right edges)
    for(int x = borders[MIN_X] + 1; x < borders[MAX_X]; ++x)
      for(int z = borders[MIN_Z] + 1; z < borders[MAX_Z]; ++z)
        addAll(candidates, RGB_cube.get(coordsToCubeIndex(x, borders[MIN_Y], z)));
          
    // Top side (minus front and back edges, left and right edges)
    for(int x = borders[MIN_X] + 1; x < borders[MAX_X]; ++x)
      for(int z = borders[MIN_Z] + 1; z < borders[MAX_Z]; ++z)
        addAll(candidates, RGB_cube.get(coordsToCubeIndex(x, borders[MAX_Y], z)));
  }
}

void addAll(ArrayList<Integer> dest, ArrayList<Integer> source) {
  for(int i : source) {
    dest.add(i);
  }
}

int findBestFitFromList(color target, ArrayList<Integer> samples) {
  int targetR = target >> RED & 0xff,
      targetG = target >> GREEN & 0xff,
      targetB = target >> BLUE & 0xff;
     
  int bestFitIndex = -1;
  float bestFitValue = 999999f;
  
  for(int i = 0; i < samples.size(); ++i) {
    int index = samples.get(i);
    color cur = endImg.getPixel(index);
    int curFit = 
      abs(targetR - (cur >> RED & 0xff)) +
      abs(targetG - (cur >> GREEN & 0xff)) +
      abs(targetB - (cur >> BLUE & 0xff));//(cur & 0xff)
    if(curFit < bestFitValue) {
      bestFitIndex = index;
      bestFitValue = curFit;
      if(curFit == 0) break;
    }
  }
  return bestFitIndex;
}

void storeCoordsInImage(int endIndex, int startIndex) {
  int x = startIndex % startImg.width(), y = startIndex / startImg.width();
  coordsData.pixels[endIndex] = ALPHA_BITS + (x << BITS_FOR_COORDS) + y;
}

int[] retrieveCoordsFromImage(int index) {
  return new int[] {
    (coordsData.pixels[index] >> BITS_FOR_COORDS) & COLOR_BIT_MASK,
    coordsData.pixels[index] & COLOR_BIT_MASK
  };
}
