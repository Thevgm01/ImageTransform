final int RED = 16, GREEN = 8, BLUE = 0;

int coordsToIndex(int x, int y, int z) {
  return (x << RGB_CUBE_X_SHIFT) + (y << RGB_CUBE_Y_SHIFT) + (z << RGB_CUBE_Z_SHIFT); 
}

void analyzeStartImage() {
  for(int i = 0; i < startImage_RGB_cube.length; i += RGB_CUBE_MAX_RANDOM_SAMPLES)
    startImage_RGB_cube[i] = 0;
  
  for(int i = 0; i < TOTAL_SIZE; ++i) {
    color pixel = startImg.pixels[i];
    if(ignoreBlack && brightness(pixel) == 0) continue;
    
    int pixelR = (pixel >> RED & 0xff) >> RGB_CUBE_VALUE_BIT_SHIFT,
        pixelG = (pixel >> GREEN & 0xff) >> RGB_CUBE_VALUE_BIT_SHIFT,
        pixelB = (pixel >> BLUE & 0xff) >> RGB_CUBE_VALUE_BIT_SHIFT;
    addIndexToSizeArray(startImage_RGB_cube, coordsToIndex(pixelR, pixelG, pixelB), i);
  }

  for(int i = 0; i < NUM_THREADS; ++i) {
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
  for(int i = offset; i < TOTAL_SIZE; i += NUM_THREADS) {          
    findBestFit(i);
    analyzeIndexes[offset]++;
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

  int[] candidates = new int[RGB_CUBE_MAX_RANDOM_SAMPLES];
  addCandidatesToArray(candidates, startImage_RGB_cube, coordsToIndex(targetR, targetG, targetB));

  for(int shellSize = 1; shellSize < RGB_CUBE_DIMENSIONS; shellSize++) {
    
    if(SWITCH_TO_LEGACY_ON_SLOWDOWN && shellSize >= SWITCH_TO_LEGACY_RGB_CUBE_SIZE) {
      findBestFit_legacy(index);
      return; 
    }
    
    if(candidates[0] > 0) {
      if(candidates[0] > 1) newOrder[index] = candidates[(int)random(candidates[0]) + 1];
      else newOrder[index] = candidates[1];
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
             addCandidatesToArray(candidates, startImage_RGB_cube, coordsToIndex(x, y, minZ));

    // Back side
    if(testCubeBounds(maxZ))
      for(int x = minX; x <= maxX; ++x)
         for(int y = minY; y <= maxY; ++y)
           if(testCubeBounds(x, y))
             addCandidatesToArray(candidates, startImage_RGB_cube, coordsToIndex(x, y, maxZ));

    // Left side (minus front and back edges)
    if(testCubeBounds(minX))
      for(int y = minY; y <= maxY; ++y)
        for(int z = minZ + 1; z < maxZ; ++z)
          if(testCubeBounds(y, z))
            addCandidatesToArray(candidates, startImage_RGB_cube, coordsToIndex(minX, y, z));

    // Right side (minus front and back edges)
    if(testCubeBounds(maxX))
      for(int y = minY; y <= maxY; ++y)
        for(int z = minZ + 1; z < maxZ; ++z)
          if(testCubeBounds(y, z))
            addCandidatesToArray(candidates, startImage_RGB_cube, coordsToIndex(maxX, y, z));

    // Bottom side (minus front and back edges, left and right edges)
    if(testCubeBounds(minY))
      for(int x = minX + 1; x < maxX; ++x)
        for(int z = minZ + 1; z < maxZ; ++z)
          if(testCubeBounds(x, z))
            addCandidatesToArray(candidates, startImage_RGB_cube, coordsToIndex(x, minY, z));
          
    // Top side (minus front and back edges, left and right edges)
    if(testCubeBounds(maxY))
      for(int x = minX + 1; x < maxX; ++x)
        for(int z = minZ + 1; z < maxZ; ++z)
          if(testCubeBounds(x, z))
            addCandidatesToArray(candidates, startImage_RGB_cube, coordsToIndex(x, maxY, z));
  }
}

void addIndexToSizeArray(int[] array, int start, int newVal) {
   if(array[start] >= RGB_CUBE_MAX_RANDOM_SAMPLES - 1) return;
   array[start + ++array[start]] = newVal;
}

void addCandidatesToArray(int[] mainArray, int[] otherArray, int otherStart) {
  for(int i = 1; i <= otherArray[otherStart]; ++i) {
    if(mainArray[0] >= RGB_CUBE_MAX_RANDOM_SAMPLES - 1) return;
    mainArray[++mainArray[0]] = otherArray[i + otherStart];
  }
}

boolean testCubeBounds(int a) {
  return a >= 0 && a < RGB_CUBE_DIMENSIONS;
}

boolean testCubeBounds(int a, int b) {
  return testCubeBounds(a) && testCubeBounds(b);
}
