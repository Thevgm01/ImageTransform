void animate_fallingSand() {
  int[] sandLastRadius = new int[width];
  boolean[] falling = new boolean[TOTAL_SIZE];
  float velocity = 0;
  //float gravity = 0.15f;
  
  int[][] allCoords = new int[TOTAL_SIZE][0];
  for(int i = 0; i < TOTAL_SIZE; ++i) {
    int j = newOrder[i];
    if(j == -1) continue;
    allCoords[i] = getCoords(i, j);
    
    falling[i] = true;
  }
  
  //int finalFallFrame = -1;
  for(int frame = 0; frame < TOTAL_ANIMATION_FRAMES/*sandFallFrames*/; ++frame) {
    velocity += sandFallAcceleration;
    //animationIndexes[0] += TOTAL_SIZE / TOTAL_ANIMATION_FRAMES;

    for(int i = TOTAL_SIZE - 1; i >= 0; --i) {
      ++animationIndexes[0];
      int[] coords = allCoords[i];
      if(coords.length == 0) continue;
      if (falling[i]) {
        coords[Y1] += velocity;

        if (height - coords[Y1] - 1 < sandLastRadius[coords[X1]]) {
          falling[i] = false;
  
          boolean searching = true;
          int radius = sandLastRadius[coords[X1]];
          while (searching) {
            for (int k = 0; k <= radius; k++) {
              //check x + radius - i, y + i
              if (
                coords[X1] + radius - k < width &&
                sandLastRadius[coords[X1] + radius - k] <= k) { 
                sandLastRadius[coords[X1]] = radius; 
                coords[X1] += radius - k; 
                searching = false; 
                break;
              } else if (
                k != radius && 
                coords[X1] - radius + k >= 0 &&
                sandLastRadius[coords[X1] - radius + k] <= k) { 
                  sandLastRadius[coords[X1]] = radius; 
                  coords[X1] -= radius - k; 
                  searching = false; 
                  break;
              }
            }
            radius++;
          }
  
          ++sandLastRadius[coords[X1]];
          coords[Y1] = height - sandLastRadius[coords[X1]];
        }
      }
      plot(coords[X1], coords[Y1], coords[COLOR], frame);
    }
  }
  /*
  for(int i = 0; i < TOTAL_SIZE; ++i) {
    Sand s = sandList[sandPointers[i]];
    if(sandList[sandPointers[i]] == null) continue;
    storedCoords[i][X1] = s.x;
    storedCoords[i][Y1] = (int)s.y;
  }
  easeMethodX += partialEasingOffset;
  easeMethodY += partialEasingOffset;
  while(curAnimation == ANIMATION_FALLING_SAND) curAnimation = (int)random(NUM_ANIMATIONS);
  usingStoredCoords = true;
  startFrame = sandFallFrames;
  createTransitionAnimation();*/
}
