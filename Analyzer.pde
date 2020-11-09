final int RED = 16, GREEN = 8, BLUE = 0;

void analyzeStartImage() {
  for(int i = 0; i < RGB_CUBE_DIMENSIONS; i++) {
    for(int j = 0; j < RGB_CUBE_DIMENSIONS; j++) {
      for(int k = 0; k < RGB_CUBE_DIMENSIONS; k++) {
        startImage_HSB_cube.get(i).get(j).get(k).clear();
      }
    }
  }

  for(int i = 0; i < TOTAL_SIZE; i++) {
    color pixel = startImg.pixels[i];
    if(ignoreBlack && brightness(pixel) == 0) continue;
    
    int pixelR = (pixel >> RED & 0xff) >> RGB_CUBE_BIT_SHIFT,
        pixelG = (pixel >> GREEN & 0xff) >> RGB_CUBE_BIT_SHIFT,
        pixelB = (pixel >> BLUE & 0xff) >> RGB_CUBE_BIT_SHIFT;
    startImage_HSB_cube
      .get(pixelR)
      .get(pixelG)
      .get(pixelB)
      .add(i);
  }

  for(int i = 0; i < NUM_THREADS; i++) {
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
  
  int targetR = (target >> RED & 0xff) >> RGB_CUBE_BIT_SHIFT,
      targetG = (target >> GREEN & 0xff) >> RGB_CUBE_BIT_SHIFT,
      targetB = (target >> BLUE & 0xff) >> RGB_CUBE_BIT_SHIFT;

  ArrayList<Integer> candidates = new ArrayList<Integer>();
  addAllIfNotNull(candidates, testPoint_HSB_cube(targetR, targetG, targetB));

  for(int shellSize = 1; shellSize < RGB_CUBE_DIMENSIONS; shellSize++) {
    
    if(candidates.size() > 0) {
      if(candidates.size() > 1) newOrder[index] = candidates.get((int)random(candidates.size()));
      else newOrder[index] = candidates.get(0);
      candidates = null;
      return;
    }
    
    // Front side
    for(int i = targetR - shellSize; i <= targetR + shellSize; i++) {
       for(int j = targetG - shellSize; j <= targetG + shellSize; j++) {
         addAllIfNotNull(candidates, testPoint_HSB_cube(i, j, targetB - shellSize));
       }
    }
    // Back side
    for(int i = targetR - shellSize; i <= targetR + shellSize; i++) {
       for(int j = targetG - shellSize; j <= targetG + shellSize; j++) {
         addAllIfNotNull(candidates, testPoint_HSB_cube(i, j, targetB + shellSize));
       }
    }
    // Left side (minus front and back edges)
    for(int j = targetG - shellSize; j <= targetG + shellSize; j++) {
      for(int k = targetB - shellSize + 1; k < targetB + shellSize; k++) {
        addAllIfNotNull(candidates, testPoint_HSB_cube(targetR - shellSize, j, k));
      }
    }
    // Right side (minus front and back edges)
    for(int j = targetG - shellSize; j <= targetG + shellSize; j++) {
      for(int k = targetB - shellSize + 1; k < targetB + shellSize; k++) {
        addAllIfNotNull(candidates, testPoint_HSB_cube(targetR + shellSize, j, k));
      }
    }
    // Bottom side (minus front and back edges, left and right edges)
    for(int i = targetR - shellSize + 1; i < targetR + shellSize; i++) {
      for(int k = targetB - shellSize + 1; k < targetB + shellSize; k++) {
        addAllIfNotNull(candidates, testPoint_HSB_cube(i, targetG - shellSize, k));
      }
    }
    // Top side (minus front and back edges, left and right edges)
    for(int i = targetR - shellSize + 1; i < targetR + shellSize; i++) {
      for(int k = targetB - shellSize + 1; k < targetB + shellSize; k++) {
        addAllIfNotNull(candidates, testPoint_HSB_cube(i, targetG + shellSize, k));
      }
    }
  }
}

ArrayList<Integer> testPoint_HSB_cube(int x, int y, int z) {
  if(x < 0 || x >= RGB_CUBE_DIMENSIONS
  || y < 0 || y >= RGB_CUBE_DIMENSIONS
  || z < 0 || z >= RGB_CUBE_DIMENSIONS)
    return null;
    
  ArrayList<Integer> options = startImage_HSB_cube.get(x).get(y).get(z);
  if(options.size() > 0) {
    //if(options.size() > 1) newOrder[index] = options.get((int)random(options.size()));
    //else newOrder[index] = options.get(0);
    return options;
  }
  
  return null;
}

void addAllIfNotNull(ArrayList a, ArrayList b) {
  if(b == null) return;
  a.addAll(b);
}
