int lastCur;

ArrayList<Integer> numAnalyzedPerFrame = new ArrayList<Integer>();
//ArrayList<Integer> totalAnalyzedPerFrame = new ArrayList<Integer>();
float graphSizeFrac = 0.9f;
int numAnalyzedPerFrame_maxIndex = 0;

void showAllInfo(int cur, int max, String label) {
  advanceAverageTracker(cur - lastCur);
    
  if(showCalculatedPixels && curState == 0) {
    noStroke();
    fill(255);
    int topOfRectangle = lastCur / width;
    rect(0, topOfRectangle, width, 1 + cur / width - topOfRectangle);
  }
  if(showAnalysisText) {
    showAnalysisText(cur, max, label);
  }
  if(showAnalysisGraph) {
    drawAnalysisGraph(numAnalyzedPerFrame, numAnalyzedPerFrame_maxIndex);
    //totalAnalyzedPerFrame.add(cur);
    //drawAnalysisGraph(totalAnalyzedPerFrame, -1);
  }
  if(showNextImage) {
    tint(255, 220);
    image(nextImgSmall, width - nextImgSmall.width, 0);
    if(showNextImageCalculatedPixels) {
      noStroke();
      fill(255);
      float lastCurHeight = nextImgSmall.height * (float) lastCur / max;
      float curHeight = nextImgSmall.height * (float) (cur - lastCur) / max;
      //if(curHeight < 1) curHeight = 1;
      rect(width - nextImgSmall.width, ceil(lastCurHeight), nextImgSmall.width, ceil(curHeight));
    }
  }
  
  lastCur = cur;
}

void showAnalysisText(int cur, int max, String label) {  
  String titles = "Current:\nNext\n\n"
                  + label + "\n" + cur + "/" + max + "\n"
                  + "\npercent:\nper frame:\nseconds:\nper second:\nframerate:";
  String values = startImgName + "\n"
                  + endImgName + "\n\n\n\n\n"
                  + round(((float)cur / max) * 1000)/10f + "\n"
                  + round(averageTracker) + "\n"
                  + (((float)millis() - averageTrackerStartTime)/1000f) + "\n"
                  + round(averageTracker * DESIRED_FRAMERATE) + "\n"
                  + round(frameRate*10)/10f;
  fill(255);
  textAlign(BASELINE);
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

void drawAnalysisGraph(ArrayList<Integer> values, int maxIndex) {
  int maxValue = TOTAL_SIZE;
  if(maxIndex >= 0) maxValue = values.get(maxIndex);
  
  float graphWidth = width * graphSizeFrac;
  float graphHeight = height * graphSizeFrac;
  float graphStartX = width * ((1 - graphSizeFrac) / 2);
  float graphStartY = height - height * ((1 - graphSizeFrac) / 2);
  float graphXStep = graphWidth / (values.size());
  float graphYStep = graphHeight / maxValue / 2;
  
  //boolean legacyColor = false;
  
  noFill();
  stroke(255);
  strokeWeight(1);
  beginShape();
  vertex(graphStartX + graphWidth, graphStartY);
  vertex(graphStartX, graphStartY);
  int iStep = ceil(values.size() / graphWidth); // Ensure we're not drawing more lines than we have pixels
  for(int i = 0; i < values.size(); i += iStep) {
    vertex(graphStartX + graphXStep * (i + 1), graphStartY - graphYStep * values.get(i));
  }
  endShape();
  
  if(maxIndex >= 0) {
    textAlign(CENTER, CENTER);
    text(maxValue, graphStartX + graphXStep * (maxIndex + 1), graphStartY - graphYStep * maxValue - 20);
  }
}

void advanceAverageTracker(int nextVal) {
  averageTrackerFrames[frameCount % AVERAGE_TRACKER_LENGTH] = nextVal;

  numAnalyzedPerFrame.add(round(averageTrackerLastXValues(averageTrackerFrames, 30)));
  if(numAnalyzedPerFrame.get(numAnalyzedPerFrame.size() - 1) > numAnalyzedPerFrame.get(numAnalyzedPerFrame_maxIndex))
    numAnalyzedPerFrame_maxIndex = numAnalyzedPerFrame.size() - 1;
    
  averageTracker = averageTrackerLastXValues(averageTrackerFrames, AVERAGE_TRACKER_LENGTH);
}

float averageTrackerLastXValues(int[] array, int size) {
  if(size > frameCount - averageTrackerStartFrame)
    size = frameCount - averageTrackerStartFrame;
  int sum = 0;
  for(int i = frameCount; i >= frameCount - size; --i)
    sum += array[i % array.length];
  return (float)sum / size;
}

void resetAverage() {
  averageTrackerStartFrame = frameCount;
  averageTrackerStartTime = millis();
  averageTrackerFrames = new int[AVERAGE_TRACKER_LENGTH];
  numAnalyzedPerFrame.clear();
  //totalAnalyzedPerFrame.clear();
  lastCur = 0;
  numAnalyzedPerFrame_maxIndex = 0;
}
