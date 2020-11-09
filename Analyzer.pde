final int HUE = 16, SATURATION = 8, BRIGHTNESS = 0;

void analyzeStartImage() {
  for(int i = 0; i < HSB_CUBE_DIMENSIONS; i++) {
    for(int j = 0; j < HSB_CUBE_DIMENSIONS; j++) {
      for(int k = 0; k < HSB_CUBE_DIMENSIONS; k++) {
        startImage_HSB_cube.get(i).get(j).get(k).clear();
      }
    }
  }

  for(int i = 0; i < TOTAL_SIZE; i++) {
    color pixel = startImg.pixels[i];
    int pixelHue = (pixel >> HUE & 0xff) >> HSB_CUBE_BIT_SHIFT,
        pixelSat = (pixel >> SATURATION & 0xff) >> HSB_CUBE_BIT_SHIFT,
        pixelBrt = (pixel >> BRIGHTNESS & 0xff) >> HSB_CUBE_BIT_SHIFT;
    if(ignoreBlack && pixelBrt == 0) {
      continue;
    }
    startImage_HSB_cube
      .get(pixelHue)
      .get(pixelSat)
      .get(pixelBrt)
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
  int targetHue = (target >> HUE & 0xff) >> HSB_CUBE_BIT_SHIFT,
      targetSat = (target >> SATURATION & 0xff) >> HSB_CUBE_BIT_SHIFT,
      targetBrt = (target >> BRIGHTNESS & 0xff) >> HSB_CUBE_BIT_SHIFT;
     
  if(ignoreBlack && targetBrt == 0) {
    newOrder[index] = -1;  
    return;
  }
    
  ArrayList<Integer> candidates = new ArrayList<Integer>();
  addAllIfNotNull(candidates, testPoint_HSB_cube(targetHue, targetSat, targetBrt));

  for(int shellSize = 1; shellSize < HSB_CUBE_DIMENSIONS; shellSize++) {
    
    if(candidates.size() > 0) {
      if(candidates.size() > 1) newOrder[index] = candidates.get((int)random(candidates.size()));
      else newOrder[index] = candidates.get(0);
      candidates = null;
      return;
    }
    
    // Front side
    for(int i = targetHue - shellSize; i <= targetHue + shellSize; i++) {
       for(int j = targetSat - shellSize; j <= targetSat + shellSize; j++) {
         addAllIfNotNull(candidates, testPoint_HSB_cube(i, j, targetBrt - shellSize));
       }
    }
    // Back side
    for(int i = targetHue - shellSize; i <= targetHue + shellSize; i++) {
       for(int j = targetSat - shellSize; j <= targetSat + shellSize; j++) {
         addAllIfNotNull(candidates, testPoint_HSB_cube(i, j, targetBrt + shellSize));
       }
    }
    // Left side (minus front and back edges)
    for(int j = targetSat - shellSize; j <= targetSat + shellSize; j++) {
      for(int k = targetBrt - shellSize + 1; k < targetBrt + shellSize; k++) {
        addAllIfNotNull(candidates, testPoint_HSB_cube(targetHue - shellSize, j, k));
      }
    }
    // Right side (minus front and back edges)
    for(int j = targetSat - shellSize; j <= targetSat + shellSize; j++) {
      for(int k = targetBrt - shellSize + 1; k < targetBrt + shellSize; k++) {
        addAllIfNotNull(candidates, testPoint_HSB_cube(targetHue + shellSize, j, k));
      }
    }
    // Bottom side (minus front and back edges, left and right edges)
    for(int i = targetHue - shellSize + 1; i < targetHue + shellSize; i++) {
      for(int k = targetBrt - shellSize + 1; k < targetBrt + shellSize; k++) {
        addAllIfNotNull(candidates, testPoint_HSB_cube(i, targetSat - shellSize, k));
      }
    }
    // Top side (minus front and back edges, left and right edges)
    for(int i = targetHue - shellSize + 1; i < targetHue + shellSize; i++) {
      for(int k = targetBrt - shellSize + 1; k < targetBrt + shellSize; k++) {
        addAllIfNotNull(candidates, testPoint_HSB_cube(i, targetSat + shellSize, k));
      }
    }
  }
}

ArrayList<Integer> testPoint_HSB_cube(int x, int y, int z) {
  if(x < 0 || x >= HSB_CUBE_DIMENSIONS
  || y < 0 || y >= HSB_CUBE_DIMENSIONS
  || z < 0 || z >= HSB_CUBE_DIMENSIONS)
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
