void analyzeStartImage_legacy() {
  for(int i = 0; i < NUM_ANALYSIS_THREADS; i++) {
    thread("findBestFitThread" + i + "_legacy");
  }
}

void findBestFitThread0_legacy() { findBestFitThread_legacy(0); }
void findBestFitThread1_legacy() { findBestFitThread_legacy(1); }
void findBestFitThread2_legacy() { findBestFitThread_legacy(2); }
void findBestFitThread3_legacy() { findBestFitThread_legacy(3); }
void findBestFitThread4_legacy() { findBestFitThread_legacy(4); }
void findBestFitThread5_legacy() { findBestFitThread_legacy(5); }
void findBestFitThread6_legacy() { findBestFitThread_legacy(6); }
void findBestFitThread7_legacy() { findBestFitThread_legacy(7); }

void findBestFitThread_legacy(int offset) {
  for(int i = offset; i < TOTAL_SIZE; i += NUM_ANALYSIS_THREADS) {          
    findBestFit_legacy(i);
    analysisIndexes[offset]++;
  }
}

// Find a pixel from the start image that most closely matches the 
// given pixel from the end image
void findBestFit_legacy(int index) {
  color target = endImg.getPixel(index);  
  int targetR = target >> RED & 0xff,
      targetG = target >> GREEN & 0xff,
      targetB = target >> BLUE & 0xff;
     
  if(ignoreBlack && brightness(target) == 0) {
  newOrder[index] = -1;  
    return;
  }
     
  int bestFitIndex = -1;
  float bestFitValue = 999999f;
  
  int startingIndex = (int)random(TOTAL_SIZE - LEGACY_NUM_TO_CHECK);
  for(int i = startingIndex; i < startingIndex + LEGACY_NUM_TO_CHECK; i++) {
    color cur = startColorsRandomized[i];
    int curFit = 
      abs(targetR - (cur >> RED & 0xff)) +
      abs(targetG - (cur >> GREEN & 0xff)) +
      abs(targetB - (cur >> BLUE & 0xff));//(cur & 0xff)
    if(curFit < bestFitValue) {
      bestFitIndex = startIndexesRandomized[i];
      bestFitValue = curFit;
      if(curFit == 0) break;
    }
  }
  newOrder[index] = bestFitIndex;
}
