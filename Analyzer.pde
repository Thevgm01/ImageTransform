final int HUE = 16, SATURATION = 8, BRIGHTNESS = 0;

void findBestFitThread0() { findBestFitThread(0); }
void findBestFitThread1() { findBestFitThread(1); }
void findBestFitThread2() { findBestFitThread(2); }
void findBestFitThread3() { findBestFitThread(3); }
void findBestFitThread4() { findBestFitThread(4); }
void findBestFitThread5() { findBestFitThread(5); }
void findBestFitThread6() { findBestFitThread(6); }
void findBestFitThread7() { findBestFitThread(7); }

void analyzeStartImage() {
  for(int i = 0; i < HSB_CUBE_SIZE; i++) {
    for(int j = 0; j < HSB_CUBE_SIZE; j++) {
      for(int k = 0; k < HSB_CUBE_SIZE; k++) {
        startImage_HSB_cube.get(i).get(j).get(k).clear();
      }
    }
  }

  for(int i = 0; i < TOTAL_SIZE; i++) {
    color pixel = startImg.pixels[i];
    int pixelHue = pixel >> HUE & 0xff,
        pixelSat = pixel >> SATURATION & 0xff,
        pixelBrt = pixel >> BRIGHTNESS & 0xff;
    if(ignoreBlack && pixelBrt == 0) {
      continue;
    }
    startImage_HSB_cube
      .get(pixelHue / HSB_CUBE_COLOR_DEPTH_SCALE)
      .get(pixelSat / HSB_CUBE_COLOR_DEPTH_SCALE)
      .get(pixelBrt / HSB_CUBE_COLOR_DEPTH_SCALE)
      .add(i);
  }

  for(int i = 0; i < NUM_THREADS; i++) {
    thread("findBestFitThread" + i);
  }
}

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
  int targetHue = target >> HUE & 0xff,
      targetSat = target >> SATURATION & 0xff,
      targetBrt = target >> BRIGHTNESS & 0xff;
     
  if(ignoreBlack && targetBrt == 0) {
    newOrder[index] = -1;  
    return;
  }
  
  int x = targetHue / HSB_CUBE_COLOR_DEPTH_SCALE,
      y = targetSat / HSB_CUBE_COLOR_DEPTH_SCALE,
      z = targetBrt / HSB_CUBE_COLOR_DEPTH_SCALE;
  
  ArrayList<Integer> candidates = new ArrayList<Integer>();
  addIfNotNull(candidates, testPoint_HSB_cube(x, y, z));

  for(int shellSize = 1; shellSize < HSB_CUBE_SIZE; shellSize++) {
    
    if(candidates.size() > 0) {
      if(candidates.size() > 1) newOrder[index] = candidates.get((int)random(candidates.size()));
      else newOrder[index] = candidates.get(0);
      candidates = null;
      return;
    }
    
    // Front side
    for(int i = x - shellSize; i <= x + shellSize; i++) {
       for(int j = y - shellSize; j <= y + shellSize; j++) {
         addIfNotNull(candidates, testPoint_HSB_cube(i, j, z - shellSize));
       }
    }
    // Back side
    for(int i = x - shellSize; i <= x + shellSize; i++) {
       for(int j = y - shellSize; j <= y + shellSize; j++) {
         addIfNotNull(candidates, testPoint_HSB_cube(i, j, z + shellSize));
       }
    }
    // Left side (minus front and back edges)
    for(int j = y - shellSize; j <= y + shellSize; j++) {
      for(int k = z - shellSize + 1; k < z + shellSize; k++) {
        addIfNotNull(candidates, testPoint_HSB_cube(x - shellSize, j, k));
      }
    }
    // Right side (minus front and back edges)
    for(int j = y - shellSize; j <= y + shellSize; j++) {
      for(int k = z - shellSize + 1; k < z + shellSize; k++) {
        addIfNotNull(candidates, testPoint_HSB_cube(x + shellSize, j, k));
      }
    }
    // Bottom side (minus front and back edges, left and right edges)
    for(int i = x - shellSize + 1; i < x + shellSize; i++) {
      for(int k = z - shellSize + 1; k < z + shellSize; k++) {
        addIfNotNull(candidates, testPoint_HSB_cube(i, y - shellSize, k));
      }
    }
    // Top side (minus front and back edges, left and right edges)
    for(int i = x - shellSize + 1; i < x + shellSize; i++) {
      for(int k = z - shellSize + 1; k < z + shellSize; k++) {
        addIfNotNull(candidates, testPoint_HSB_cube(i, y + shellSize, k));
      }
    }
  }
}

ArrayList<Integer> testPoint_HSB_cube(int x, int y, int z) {
  if(x < 0 || x >= HSB_CUBE_SIZE
  || y < 0 || y >= HSB_CUBE_SIZE
  || z < 0 || z >= HSB_CUBE_SIZE)
    return null;
    
  ArrayList<Integer> options = startImage_HSB_cube.get(x).get(y).get(z);
  if(options.size() > 0) {
    //if(options.size() > 1) newOrder[index] = options.get((int)random(options.size()));
    //else newOrder[index] = options.get(0);
    return options;
  }
  
  return null;
}

void addIfNotNull(ArrayList a, ArrayList b) {
  if(b == null) return;
  a.addAll(b);
}
