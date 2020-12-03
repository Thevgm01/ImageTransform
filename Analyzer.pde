final int RED = 16, GREEN = 8, BLUE = 0;

final int RGB_CUBE_VALUE_BIT_SHIFT = 2; // The number of times to halve each RGB value (for performance reasons)
final int RGB_CUBE_DIMENSIONS_BIT_SHIFT = 8 - RGB_CUBE_VALUE_BIT_SHIFT; // Max 256, currently 6
final int RGB_CUBE_DIMENSIONS = 1 << RGB_CUBE_DIMENSIONS_BIT_SHIFT; // 64

final int RGB_CUBE_X_SHIFT = 0;
final int RGB_CUBE_Y_SHIFT = RGB_CUBE_DIMENSIONS_BIT_SHIFT;
final int RGB_CUBE_Z_SHIFT = RGB_CUBE_Y_SHIFT + RGB_CUBE_DIMENSIONS_BIT_SHIFT;
final int RGB_CUBE_TOTAL_SIZE = 1 << (RGB_CUBE_Z_SHIFT + RGB_CUBE_DIMENSIONS_BIT_SHIFT);

// RGB          Indexes
ArrayList<ArrayList<Integer>> RGB_cube;
ArrayList<ArrayList<Integer>> RGB_cube_recordedResults;

final boolean PERFECT_RGB_CUBE_ANALYSIS = true;
final boolean LEGACY_ANALYSIS = false;
final int LEGACY_NUM_TO_CHECK = 2000;
final int SWITCH_TO_LEGACY_RGB_CUBE_SIZE = (int)(RGB_CUBE_DIMENSIONS * 0.33f);

int coordsToIndex(int x, int y, int z) {
  return (x << RGB_CUBE_X_SHIFT) + (y << RGB_CUBE_Y_SHIFT) + (z << RGB_CUBE_Z_SHIFT); 
}

void analyzeStartImage() {
  for(int i = 0; i < RGB_CUBE_TOTAL_SIZE; ++i) {
    RGB_cube.set(i, new ArrayList<Integer>());
    if(cacheAnalysisResults)
      RGB_cube_recordedResults.set(i, new ArrayList<Integer>());
    else
      RGB_cube_recordedResults.get(i).set(0, 1);
  }
  
  for(int i = 0; i < TOTAL_SIZE; ++i) {
    color pixel = startImg.pixels[i];
    if(ignoreBlack && brightness(pixel) == 0) continue;
    
    int pixelR = (pixel >> RED & 0xff) >> RGB_CUBE_VALUE_BIT_SHIFT,
        pixelG = (pixel >> GREEN & 0xff) >> RGB_CUBE_VALUE_BIT_SHIFT,
        pixelB = (pixel >> BLUE & 0xff) >> RGB_CUBE_VALUE_BIT_SHIFT;
    RGB_cube.get(coordsToIndex(pixelR, pixelG, pixelB)).add(i);
  }

  for(int i = 0; i < NUM_ANALYSIS_THREADS; ++i) {
    thread("findBestFitThread" + i);
  }
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
  for(int i = offset; i < TOTAL_SIZE; i += NUM_ANALYSIS_THREADS) {          
    findBestFit(i);
    ++analysisIndexes[offset];
  }
}

// Find a pixel from the start image that most closely matches the 
// given pixel from the end image
void findBestFit(int index) {
  color target = endImg.pixels[index];
  if(ignoreBlack && brightness(target) == 0) {
    newOrder[index] = -1;  
    return;
  }
  
  int targetR = (target >> RED & 0xff) >> RGB_CUBE_VALUE_BIT_SHIFT,
      targetG = (target >> GREEN & 0xff) >> RGB_CUBE_VALUE_BIT_SHIFT,
      targetB = (target >> BLUE & 0xff) >> RGB_CUBE_VALUE_BIT_SHIFT;

  int desiredIndex = coordsToIndex(targetR, targetG, targetB);
  int startShellSize = 1;

  if(cacheAnalysisResults) {
    ArrayList<Integer> results = RGB_cube_recordedResults.get(desiredIndex);
    if(results.size() > 0) {
      if(PERFECT_RGB_CUBE_ANALYSIS)
        newOrder[index] = findBestFitFromList(target, results);
      else
        newOrder[index] = results.get((int)random(results.size()));
      return;
    }
  }
  //else startShellSize = RGB_cube_recordedResults.get(desiredIndex).get(0);
  
  ArrayList<Integer> candidates = new ArrayList<Integer>();
  candidates.addAll(RGB_cube.get(coordsToIndex(targetR, targetG, targetB)));

  for(int shellSize = startShellSize; shellSize < RGB_CUBE_DIMENSIONS; shellSize++) {
    
    if(candidates.size() > 0) {
      if(PERFECT_RGB_CUBE_ANALYSIS)
        newOrder[index] = findBestFitFromList(target, candidates);
      else 
        newOrder[index] = candidates.get((int)random(candidates.size()));
      
      if(cacheAnalysisResults)
        RGB_cube_recordedResults.set(desiredIndex, candidates);
      //else RGB_cube_recordedResults.get(desiredIndex).set(0, shellSize);
      return;
    }
    
    if(switchToLegacyAnalysisOnSlowdown && shellSize >= SWITCH_TO_LEGACY_RGB_CUBE_SIZE) {
      findBestFit_legacy(index);
      pixelsLegacyAnalyzed.set(index, true);
      return; 
    }
    
    int minX = targetR - shellSize,
        maxX = targetR + shellSize,
        minY = targetG - shellSize,
        maxY = targetG + shellSize,
        minZ = targetB - shellSize,
        maxZ = targetB + shellSize;
    
    // Front side
    if(testCubeBounds(minZ))
      for(int x = minX; x <= maxX; ++x)
         for(int y = minY; y <= maxY; ++y)
           if(testCubeBounds(x, y))
             candidates.addAll(RGB_cube.get(coordsToIndex(x, y, minZ)));

    // Back side
    if(testCubeBounds(maxZ))
      for(int x = minX; x <= maxX; ++x)
         for(int y = minY; y <= maxY; ++y)
           if(testCubeBounds(x, y))
             candidates.addAll(RGB_cube.get(coordsToIndex(x, y, maxZ)));

    // Left side (minus front and back edges)
    if(testCubeBounds(minX))
      for(int y = minY; y <= maxY; ++y)
        for(int z = minZ + 1; z < maxZ; ++z)
          if(testCubeBounds(y, z))
            candidates.addAll(RGB_cube.get(coordsToIndex(minX, y, z)));

    // Right side (minus front and back edges)
    if(testCubeBounds(maxX))
      for(int y = minY; y <= maxY; ++y)
        for(int z = minZ + 1; z < maxZ; ++z)
          if(testCubeBounds(y, z))
            candidates.addAll(RGB_cube.get(coordsToIndex(maxX, y, z)));

    // Bottom side (minus front and back edges, left and right edges)
    if(testCubeBounds(minY))
      for(int x = minX + 1; x < maxX; ++x)
        for(int z = minZ + 1; z < maxZ; ++z)
          if(testCubeBounds(x, z))
            candidates.addAll(RGB_cube.get(coordsToIndex(x, minY, z)));
          
    // Top side (minus front and back edges, left and right edges)
    if(testCubeBounds(maxY))
      for(int x = minX + 1; x < maxX; ++x)
        for(int z = minZ + 1; z < maxZ; ++z)
          if(testCubeBounds(x, z))
            candidates.addAll(RGB_cube.get(coordsToIndex(x, maxY, z)));
  }
}

boolean testCubeBounds(int a) {
  return a >= 0 && a < RGB_CUBE_DIMENSIONS;
}

boolean testCubeBounds(int a, int b) {
  return testCubeBounds(a) && testCubeBounds(b);
}

int findBestFitFromList(color target, ArrayList<Integer> samples) {
  int targetR = target >> RED & 0xff,
      targetG = target >> GREEN & 0xff,
      targetB = target >> BLUE & 0xff;
     
  int bestFitIndex = -1;
  float bestFitValue = 999999f;
  
  for(int i = 0; i < samples.size(); ++i) {
    int index = samples.get(i);
    color cur = endImg.pixels[index];
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
