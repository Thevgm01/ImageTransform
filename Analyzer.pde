final int HUE = 16, SATURATION = 8, BRIGHTNESS = 0;

void analyzeStartImage0() { analyzeStartImage(0); }
void analyzeStartImage1() { analyzeStartImage(1); }
void analyzeStartImage2() { analyzeStartImage(2); }
void analyzeStartImage3() { analyzeStartImage(3); }
void analyzeStartImage4() { analyzeStartImage(4); }
void analyzeStartImage5() { analyzeStartImage(5); }
void analyzeStartImage6() { analyzeStartImage(6); }
void analyzeStartImage7() { analyzeStartImage(7); }

void analyzeStartImage(int offset) {
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
     
  int bestFitIndex = -1;
  float bestFitValue = 999999f;
  
  int startingIndex = (int)random(TOTAL_SIZE - NUM_TO_CHECK);
  for(int i = startingIndex; i < startingIndex + NUM_TO_CHECK; i++) {
    color cur = startColorsRandomized[i];
    int curFit = 
      abs(targetHue - (cur >> HUE & 0xff)) +
      abs(targetSat - (cur >> SATURATION & 0xff)) +
      abs(targetBrt - (cur >> BRIGHTNESS & 0xff));//(cur & 0xff)
    if(curFit < bestFitValue) {
      bestFitIndex = startIndexesRandomized[i];
      bestFitValue = curFit;
      if(curFit == 0) break;
    }
  }
  newOrder[index] = bestFitIndex;
}
