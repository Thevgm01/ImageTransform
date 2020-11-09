void analyzeStartImage_legacy() {
  for(int i = 0; i < NUM_THREADS; i++) {
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
  for(int i = offset; i < TOTAL_SIZE; i += NUM_THREADS) {          
    findBestFit_legacy(i);
    analyzeIndexes[offset]++;
  }
}

// Find a pixel from the start image that most closely matches the 
// given pixel from the end image
void findBestFit_legacy(int index) {
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
