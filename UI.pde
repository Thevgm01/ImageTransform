void showAllInfo(int cur, int max, String label) {
  if(showCalculatedPixels && curState == 0) {
    noStroke();
    fill(255);
    int topOfRectangle = averageTrackerLastValue / width;
    rect(0, topOfRectangle, width, 1 + cur / width - topOfRectangle);
  }
  if(showAnalysisText) {
    showAnalysisText(cur, max, label);
  }
  if(showNextImage) {
    tint(255, 220);
    image(nextImgSmall, width - nextImgSmall.width, 0);
  }  
  advanceAverageTracker(cur);
}

void showAnalysisText(int cur, int max, String label) {  
  String titles = "Current:\nNext\n\n"
                  + label + "\n" + cur + "/" + max + "\n"
                  + (legacyAnalysis && curState == 0 ? "LEGACY MODE" : "")
                  + "\npercent:\nper frame:\nseconds:\nper second:\nframerate:";
  String values = startImgName + "\n"
                  + endImgName + "\n\n\n\n\n"
                  + round(((float)cur / max) * 1000)/10f + "\n"
                  + round(averageTracker) + "\n"
                  + (((float)millis() - averageTrackerStartTime)/1000f) + "\n"
                  + round(averageTracker * DESIRED_FRAMERATE) + "\n"
                  + round(frameRate*10)/10f;
  fill(255);
  text(titles, 5, 15);
  text(values, 75, 15);
}

void showProgress(int numAnalyzed, int numAnimated) {  
  float frac = 0f;
  if(curState < 2) frac = (float)numAnalyzed / TOTAL_SIZE / 2f;
  else if(curState == 2) frac = 0.5f + (float)numAnimated / TOTAL_SIZE / 2f;
  else if(curState == 3) frac = 1f;
        
  if(showProgressBar) showProgressBar(frac);
  if(showProgressBorder) showProgressBorder(frac);
}

void moveProgressBar(float amount) {
  progressSlide -= amount;
  if(progressSlide < 0) progressSlide = 0;
  else if(progressSlide > PI) progressSlide = PI;
}

void showProgressBar(float frac) {
  final int barHeight = height/50;
  final int sideDistance = width/60;
  final int borderThickness = 2;
  
  int x = sideDistance, w = width - sideDistance*2,
      y = height - sideDistance - barHeight, h = barHeight;
      
  float animationY = (cos(progressSlide) - 1f) * (barHeight + sideDistance + borderThickness)/2f;
  
  if(y + animationY < height) {
    noFill();
    stroke(255);
    strokeWeight(borderThickness);
    rect(x, y - animationY, w, h);
    fill(255);
    noStroke();
    rect(x, y - animationY, w*frac, h);
  }
}

void showProgressBorder(float frac) {
  float progressSlideMult = (cos(progressSlide) + 1f) / 2f;
  stroke(255);
  strokeWeight(3f);
  //strokeWeight(progressSlideMult * 3f);
  frac *= progressSlideMult;
  
  if(frac == 0) return;
  int perimeterSize = WIDTH + HEIGHT;
  int perimeter = round(perimeterSize * frac);
  
  if(perimeter > HALF_WIDTH + HEIGHT) {
    line(0, HEIGHT - 1, perimeter - HALF_WIDTH - HEIGHT, HEIGHT - 1);
    line(WIDTH + HALF_WIDTH + HEIGHT - perimeter, HEIGHT - 1, WIDTH, HEIGHT - 1); 
  }
  if(perimeter > HALF_WIDTH) {
    line(0, 0, 0, perimeter - HALF_WIDTH);
    line(WIDTH - 1, 0, WIDTH - 1, perimeter - HALF_WIDTH);
  }
  if(perimeter > 0) {
    line(HALF_WIDTH - perimeter, 0, HALF_WIDTH + perimeter, 0);
  }
}

void advanceAverageTracker(int nextVal) {
  increaseAverage(nextVal);
  averageTrackerLastValue = nextVal;
}

void resetAverage() {
  averageTrackerLastValue = 0;
  averageTrackerStartFrame = frameCount;
  averageTrackerStartTime = millis();
  averageTracker = 0;
}

void increaseAverage(float value) {
  averageTracker += (value - averageTrackerLastValue - averageTracker)/(frameCount - averageTrackerStartFrame + 1);
}
