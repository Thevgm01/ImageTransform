final int DESIRED_FRAMERATE = 60;
final int NUM_THREADS = 5;//The number of threads, up to 8
final int HUE = 16, SATURATION = 8, BRIGHTNESS = 0;
final int TOTAL_ANIMATION_FRAMES = DESIRED_FRAMERATE * 2;//4;
final int TOTAL_DELAY_FRAMES = DESIRED_FRAMERATE * 1;
final int TOTAL_FADE_FRAMES = DESIRED_FRAMERATE * 1;//3;
final String IMAGES_DIR = "C:/Users/thevg/Pictures/Wallpapers/Spaceships";
final String IMAGES_LIST_FILE = "C:/Users/thevg/Pictures/Wallpapers/list.txt";
final boolean CYCLE = true;
boolean showCalculatedPixels = false;
boolean showAnalysisText = false;
boolean showProgressBar = true;
boolean showNextImage = false;

int imagesListFileSize = 0;

int curState = 0;

String startImgName;
String endImgName;
String nextImgName;
PImage startImg;
PImage endImg;
PImage nextImg;
PImage nextImgSmall;
PImage assembledImg;
int totalSize;//The size of the window, width * height
int numToCheck;//Check this many pixels from the original image

int[] processIndexes;//How many loops each of the image processing threads have gone through
int[] processOrder;//Check the pixels of the original image in this order
int[] newOrder;//Where each pixel in the final arrangement originally comes from

int[] animationIndexes;
PImage[] animationFrames;

int curAnimationFrame = 0;
int curDelayFrame = 0;
int curFadeFrame = 0;

int averageTrackerLastValue = 0;
int averageTrackerStartFrame = 0;
float averageTracker;

boolean record = false;
String recordingFilename = "frames/frame_#####";

void setup() {
  size(1600, 900);
  //size(800, 450);
  //size(400, 225);
  //size(200, 100);
  frameRate(DESIRED_FRAMERATE);
  colorMode(HSB);
  totalSize = width * height;
  numToCheck = 500;//round(sqrt(totalSize));
  
  startImgName = getRandomImageName("");
  endImgName = getRandomImageName(startImgName);
  startImg = loadImage(startImgName);
  endImg = loadImage(endImgName);
  nextImgSmall = endImg.copy();
  resizeImage(startImg, width, height);
  resizeImage(endImg, width, height);
  resizeImage(nextImgSmall, width/4, height/3);
  startImg = imageOnBlack(startImg);
  endImg = imageOnBlack(endImg);
  
  processIndexes = new int[NUM_THREADS];
  newOrder = new int[totalSize];
  processOrder = new int[totalSize];
  for(int i = 0; i < totalSize; i++) {
    newOrder[i] = -1;
    processOrder[i] = i;
  }
  randomizeArrayOrder(processOrder);
  
  animationIndexes = new int[NUM_THREADS];
  animationFrames = new PImage[TOTAL_ANIMATION_FRAMES];
  
  resetAll();
}

String getRandomImageName(String exclude) {
  if(IMAGES_LIST_FILE.equals("")) {
    File[] files = new File(IMAGES_DIR).listFiles();
    File result;
    do {
      result = files[(int)random(0, files.length)];
    } while(result.getAbsolutePath().equals(exclude));
    return result.getAbsolutePath();
  } else {
    try {
      BufferedReader reader;
      if(imagesListFileSize == 0) {
        reader = createReader(IMAGES_LIST_FILE);
        while(reader.readLine() != null)
          imagesListFileSize++;
        reader.close();
      }
      String result = "";
      do {
        int line = (int)random(0, imagesListFileSize);
        reader = createReader(IMAGES_LIST_FILE);
        for(int i = 0; i < line; i++)
          result = reader.readLine(); 
        reader.close();
      } while(result.equals(exclude));
      return result;
    } catch(Exception e) { println("Images list file not found"); }
  }
  return null;
}

void loadNextImage() {
  nextImgName = getRandomImageName(endImgName);
  nextImg = loadImage(nextImgName);
  nextImgSmall = nextImg.copy();
  resizeImage(nextImg, width, height);
  resizeImage(nextImgSmall, width/4, height/3);
}

void resizeImage(PImage img, int w, int h) {
  img.resize(w, 0); 
  if(img.height > h) img.resize(0, h);
}

PImage imageOnBlack(PImage img) {
  background(0);
  image(img, width/2 - img.width/2, height/2 - img.height/2);
  return get(0, 0, width, height);
}

void mouseClicked() {
  if(curState > 2) curState = 2;
  curAnimationFrame = 0;
  curDelayFrame = 0;
  curFadeFrame = 0;
  record = false;
}

void draw() {
  int numProcessed = 0, numAnimated = 0;
  for(int i = 0; i < NUM_THREADS; i++) {
    numProcessed += processIndexes[i];
    numAnimated += animationIndexes[i];
  }
  
  switch(curState) {
    case 0: 
      if(numProcessed < totalSize) {
        tint(255);
        background(startImg);
        showAllInfo(numProcessed, totalSize, "Pixels analyzed");
        break;
      } else {
        for(int i = 0; i < NUM_THREADS; i++)
          thread("createAnimationFrames" + i);
        resetAverage();
        curState++;
      }
    case 1:
      if(numAnimated < TOTAL_ANIMATION_FRAMES) {
        tint(255);
        background(startImg);
        showAllInfo(numAnimated, TOTAL_ANIMATION_FRAMES, "Frames animated");
        break;
      } else curState++;
    case 2:
      if(curAnimationFrame < TOTAL_ANIMATION_FRAMES) {
        float frac = (float)curAnimationFrame / TOTAL_ANIMATION_FRAMES;
        fadeToBlack(startImg, frac);
        tint(255);
        image(animationFrames[curAnimationFrame], 0, 0);
        curAnimationFrame++; 
        if(record) saveFrame(recordingFilename);
        break;
      } else if(CYCLE) curState++;
    case 3:
      if(curDelayFrame < TOTAL_DELAY_FRAMES) {
        curDelayFrame++;
        break;
      } else { 
        assembledImg = get(0, 0, width, height);
        if(nextImg == null) thread("loadNextImage");
        curState++;
      }
    case 4:
      if(curFadeFrame < TOTAL_FADE_FRAMES) {
        float frac = (float)curFadeFrame / TOTAL_FADE_FRAMES;
        fadeToImage(assembledImg, endImg, frac);
        curFadeFrame++;
        break;
      } else curState++;
    default:
      if(nextImg == null){
        //println("Next image not yet loaded!");
        break;
      }
      
      startImgName = endImgName;
      startImg = endImg;
      endImgName = nextImgName;
      endImg = imageOnBlack(nextImg);
      nextImg = null;
      
      resetAll();
  } 
}

void analyzeStartImage0() { analyzeStartImage(0); }
void analyzeStartImage1() { analyzeStartImage(1); }
void analyzeStartImage2() { analyzeStartImage(2); }
void analyzeStartImage3() { analyzeStartImage(3); }
void analyzeStartImage4() { analyzeStartImage(4); }
void analyzeStartImage5() { analyzeStartImage(5); }
void analyzeStartImage6() { analyzeStartImage(6); }
void analyzeStartImage7() { analyzeStartImage(7); }

void analyzeStartImage(int offset) {
  for(int i = offset; i < totalSize; i += NUM_THREADS) {          
    findBestFit(i);
    processIndexes[offset]++;
  }
}

// Returns an index in the startImg.pixels[] array
// where the pixel at that index most closely matches the target color
void findBestFit(int index) {
  color target = endImg.pixels[index];
  int targetHue = target >> HUE & 0xff,
      targetSat = target >> SATURATION & 0xff,
      targetBrt = target >> BRIGHTNESS & 0xff;
     
  int bestFitIndex = -1;
  float bestFitValue = 999999f;
  
  int startingIndex = (int)random(totalSize - numToCheck);
  for(int i = startingIndex; i < startingIndex + numToCheck; i++) {
    int curIndex = processOrder[i];
    color cur = startImg.pixels[curIndex];
    int curFit = calculateFit(targetHue, targetSat, targetBrt, cur);
    if(curFit < bestFitValue) {
      bestFitIndex = curIndex;
      bestFitValue = curFit;
    }
  }
  newOrder[index] = bestFitIndex;
}

int calculateFit(int targetHue, int targetSat, int targetBrt, color test) {
  return abs(targetHue - (test >> HUE & 0xff)) +
         abs(targetSat - (test >> SATURATION & 0xff)) +
         abs(targetBrt - (test >> BRIGHTNESS & 0xff));//(cur & 0xff)
}

void createAnimationFrames0() { createAnimationFrames(0); }
void createAnimationFrames1() { createAnimationFrames(1); }
void createAnimationFrames2() { createAnimationFrames(2); }
void createAnimationFrames3() { createAnimationFrames(3); }
void createAnimationFrames4() { createAnimationFrames(4); }
void createAnimationFrames5() { createAnimationFrames(5); }
void createAnimationFrames6() { createAnimationFrames(6); }
void createAnimationFrames7() { createAnimationFrames(7); }

void createAnimationFrames(int offset) {
  for(int i = offset; i < TOTAL_ANIMATION_FRAMES; i += NUM_THREADS) {
    animationFrames[i] = createAnimationFrame((float)i / TOTAL_ANIMATION_FRAMES);
    animationIndexes[offset]++;
  }
}

PImage createAnimationFrame(float frac) {
  PImage result = createImage(width, height, ARGB);
  for(int i = 0; i < totalSize; i++) {
    //if(result.pixels[i] != 0) continue;
    
    int index0 = processOrder[i],
        index1 = newOrder[index0];
    int startX = index1 % width,
        startY = index1 / width,
        destX  = index0 % width,
        destY  = index0 / width;
    //int posX = (int)((destX - startX) * frac);
    //int posY = (int)((destY - startY) * frac);
    float logFrac = frac * 30f - 15f;
    int deltaX = round(logisticFunc(logFrac, destX - startX, 0.65f));
    int deltaY = round(logisticFunc(logFrac, destY - startY, 0.65f));
    color col = startImg.pixels[index1];
    result.set(startX + deltaX, startY + deltaY, col);
  }
  return result;
}

void fadeToBlack(PImage back, float frac) {
  background(back);
  noStroke();
  fill(0, 0, 0, frac * 255);
  rect(0, 0, width, height);
}

void fadeToImage(PImage back, PImage front, float frac) {
  tint(255, 255);
  image(back, 0, 0);
  tint(255, frac * 255);
  image(front, 0, 0);
}

void resetAll() {
  for(int i = 0; i < NUM_THREADS; i++) {
    processIndexes[i] = 0;
    animationIndexes[i] = 0;
    thread("analyzeStartImage" + i);
  }
    
  curState = 0;
  curAnimationFrame = 0;
  curDelayFrame = 0;
  curFadeFrame = 0;
  
  resetAverage();
  
  background(startImg);
}

void randomizeArrayOrder(int[] array) {
  for(int i = array.length - 1; i > 0; i--) {
    int index = (int)random(0, i+1);
    // Simple swap
    int a = array[index];
    array[index] = array[i];
    array[i] = a;
  }
}

void showAllInfo(int cur, int max, String label) {
  if(showCalculatedPixels) {
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
  if(showProgressBar) {
    progressBar(cur, max); 
  }
  
  advanceAverageTracker(cur);
}

void showAnalysisText(int cur, int max, String label) {  
  String titles = label + "\n" + cur + "/" + max
                  + "\nper frame:\nper second:\npercent:\nframerate:";
  String values = "\n\n"
                  + round(averageTracker) + "\n"
                  + round(averageTracker * DESIRED_FRAMERATE) + "\n"
                  + round(((float)cur / max) * 1000)/10f + "\n"
                  + round(frameRate*10)/10f;
  fill(255);
  text(titles, 0, 10);
  text(values, 70, 10);
}

void progressBar(int cur, int max) {
  final int barHeight = height/40;
  final int sideDistance = width/40;
  
  int x = sideDistance, w = width - sideDistance*2,
      y = height - sideDistance - barHeight, h = barHeight;
  
  noFill();
  stroke(255);
  strokeWeight(2);
  rect(x, y, w, h);
  fill(255);
  noStroke();
  rect(x, y, w*(float)cur/max, h);
}

void advanceAverageTracker(int nextVal) {
  increaseAverage(nextVal);
  averageTrackerLastValue = nextVal;
}

void resetAverage() {
  averageTrackerLastValue = 0;
  averageTrackerStartFrame = frameCount;
  averageTracker = 0;
}

void increaseAverage(float value) {
  averageTracker += (value - averageTrackerLastValue - averageTracker)/(frameCount - averageTrackerStartFrame + 1);
}

float logisticFunc(float x, float l, float k) {
  return l / (1 + exp(-k * x));
}
