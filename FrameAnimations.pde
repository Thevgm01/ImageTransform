void animate_fallingSand() {
  int[] sandLastRadius = new int[width];
  float velocity = 0;
  //float gravity = 0.15f;
  
  ArrayList<ArrayList<Integer>> linkedCoords = new ArrayList<ArrayList<Integer>>();
  for(int i = 0; i < TOTAL_SIZE; ++i)
    linkedCoords.add(new ArrayList<Integer>()); 
  
  ArrayList<int[]> allCoords = new ArrayList<int[]>();
  ArrayList<Boolean> falling = new ArrayList<Boolean>();
  for(int i = 0; i < TOTAL_SIZE; ++i) {
    int j = newOrder[i];
    if(j == -1) continue;
    if(linkedCoords.get(j).size() < 1) {
      allCoords.add(getCoords(i, j));
      falling.add(true);
    }
    linkedCoords.get(j).add(i);
  }
  
  //int finalFallFrame = -1;
  for(int frame = 0; frame < TOTAL_ANIMATION_FRAMES/*sandFallFrames*/; ++frame) {
    velocity += sandFallAcceleration;
    //animationIndexes[0] += TOTAL_SIZE / TOTAL_ANIMATION_FRAMES;

    for(int i = allCoords.size() - 1; i >= 0; --i) {
      ++animationIndexes[0];
      int[] coords = allCoords.get(i);
      if (falling.get(i)) {
        coords[Y1] += velocity;

        if (height - coords[Y1] - 1 < sandLastRadius[coords[X1]]) {
          falling.set(i, false);
  
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
          /*
          ArrayList<Integer> linked = linkedCoords.get(newOrder[i]);
          for(int j = 0; j < linked.size(); ++j) {
            
          }*/
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
