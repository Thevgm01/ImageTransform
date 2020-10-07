final int DESIRED_FRAMERATE = 60;
final int NUM_THREADS = 6;//The number of threads, up to 8
final int HUE = 16, SATURATION = 8, BRIGHTNESS = 0;
final int TOTAL_ANIMATION_FRAMES = DESIRED_FRAMERATE * 4;//4;
final int TOTAL_DELAY_FRAMES = DESIRED_FRAMERATE * 1;
final int TOTAL_FADE_FRAMES = DESIRED_FRAMERATE * 2;//3;
final String IMAGES_DIR = "";//"C:/Users/thevg/Desktop/Processing/Projects/Images/Spaceships";
final String IMAGES_LIST_FILE = "C:/Users/thevg/Pictures/Wallpapers/list.txt";
final boolean preAnimate = true;
final boolean cycle = true;
final boolean showCalculatedPixels = false;
final boolean showAnalysisText = false;
final boolean showProgressBar = true;
final boolean showNextImage = false;
final float logSlope = 30f;
final float logMultX = 1;
final float logMultY = 1;

int imagesListFileSize = 0;

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

int animationInitializer;
int[] animationIndexes;
PImage[] animationFrames;

int curState;
int curFrame;

int averageTrackerLastValue = 0;
int averageTrackerStartFrame = 0;
float averageTracker;

boolean record = false;
String recordingFilename = "frames/frame_#####";

void setup() {
  fullScreen();
  //size(1600, 900);
  //size(800, 450);
  //size(400, 225);
  //size(200, 100);
  frameRate(DESIRED_FRAMERATE);
  colorMode(HSB);
  totalSize = width * height;
  numToCheck = 750;//round(sqrt(totalSize));
  
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
  for(int i = 0; i < totalSize; i++)
    processOrder[i] = i;
  randomizeArrayOrder(processOrder);
  
  animationIndexes = new int[NUM_THREADS];
  if(preAnimate) animationFrames = new PImage[TOTAL_ANIMATION_FRAMES];
  
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
  return get();
}

void mouseClicked() {
  if(preAnimate && curState > 2) curState = 2;
  else if(curState > 1)          curState = 1;
  curFrame = 0;
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
      boolean stillProcessing = numProcessed < totalSize,
              initializeAnimationFrame = preAnimate && animationInitializer < TOTAL_ANIMATION_FRAMES;
      if(stillProcessing || initializeAnimationFrame) {
        while(initializeAnimationFrame) {
          float frac = (float)animationInitializer / TOTAL_ANIMATION_FRAMES;
          fadeToBlack(startImg, frac);
          animationFrames[animationInitializer] = get();
          animationInitializer++;
          if(stillProcessing || animationInitializer >= TOTAL_ANIMATION_FRAMES)
            initializeAnimationFrame = false;
        }
        background(startImg);
        showAllInfo(numProcessed, totalSize, "Pixels analyzed");
      } else {
        resetAverage();
        if(record) saveFrame(recordingFilename);
        if(preAnimate) {
          curState++;
          for(int i = 0; i < NUM_THREADS; i++)
            thread("createAnimationFrames" + i);
        }
        curState++;
      } break;
    case 1:
      if(curFrame < TOTAL_ANIMATION_FRAMES) {
        float frac = (float)curFrame / TOTAL_ANIMATION_FRAMES;
        fadeToBlack(startImg, frac);
        loadPixels();
        createAnimationFrame(pixels, frac);
        updatePixels();
        curFrame++; 
        if(record) saveFrame(recordingFilename);
      } else if(cycle) {
        curFrame = 0;
        curState += 3;
      } break;
    case 2:
      if(numAnimated < TOTAL_ANIMATION_FRAMES) {
        background(startImg);
        showAllInfo(numAnimated, TOTAL_ANIMATION_FRAMES, "Frames animated");
      } else {
        curState++;
      } break;
    case 3:
      if(curFrame < TOTAL_ANIMATION_FRAMES) {
        background(animationFrames[curFrame]);
        curFrame++; 
        if(record) saveFrame(recordingFilename);
      } else if(cycle) {
        curFrame = 0;
        curState++;
      } break;
    case 4:
      if(curFrame < TOTAL_DELAY_FRAMES) {
        curFrame++;
      } else { 
        assembledImg = get();
        if(nextImg == null) thread("loadNextImage");
        curFrame = 0;
        curState++;
      } break;
    case 5:
      if(curFrame < TOTAL_FADE_FRAMES) {
        float frac = (float)curFrame / TOTAL_FADE_FRAMES;
        fadeToImage(assembledImg, endImg, frac);
        curFrame++;
      } else {
        curFrame = 0;
        curState++;
      } break;
    case 6:
      if(curFrame < TOTAL_DELAY_FRAMES) {
        curFrame++;
      } else {
        curState++;
      } break;
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
    int curFit = 
      abs(targetHue - (cur >> HUE & 0xff)) +
      abs(targetSat - (cur >> SATURATION & 0xff)) +
      abs(targetBrt - (cur >> BRIGHTNESS & 0xff));//(cur & 0xff)
    if(curFit < bestFitValue) {
      bestFitIndex = curIndex;
      bestFitValue = curFit;
    }
  }
  newOrder[index] = bestFitIndex;
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
    createAnimationFrame(animationFrames[i].pixels, (float)i / TOTAL_ANIMATION_FRAMES);
    animationIndexes[offset]++;
  }
}

void createAnimationFrame(color[] localPixels, float frac) {
  //PImage result = createImage(width, height, ARGB);
  //PImage image = animationFrames[index];
  //float frac = (float)index / TOTAL_ANIMATION_FRAMES;
  
  for(int i = 0; i < totalSize; i++) {
    int index0 = processOrder[i],
        index1 = newOrder[index0];
    int startX = index1 % width,
        startY = index1 / width,
        destX  = index0 % width,
        destY  = index0 / width;
    //int deltaX = (int)((destX - startX) * frac);
    //int deltaY = (int)((destY - startY) * frac);
    //float logFrac = frac * logSlope - logSlope/2f;
    //float logFrac = frac * 30f - 15f;
    //image.set(startX + deltaX, startY + deltaY, col);
    float logFracX = frac * logSlope * logMultX - logSlope * logMultX / 2f;
    float logFracY = frac * logSlope * logMultY - logSlope * logMultY / 2f;
    int deltaX = round(logisticFunc(logFracX, destX - startX, 0.65f));
    int deltaY = round(logisticFunc(logFracY, destY - startY, 0.65f));
    color col = startImg.pixels[index1];
    localPixels[(startY + deltaY) * width + startX + deltaX] = col;
  }
}

void fadeToBlack(PImage back, float frac) {
  background(back);
  noStroke();
  fill(0, 0, 0, frac * 255);
  rect(0, 0, width, height);
}

void fadeToImage(PImage back, PImage front, float frac) {
  background(back);
  tint(255, frac * 255);
  image(front, 0, 0);
}

void resetAll() {
  for(int i = 0; i < NUM_THREADS; i++) {
    processIndexes[i] = 0;
    animationIndexes[i] = 0;
    thread("analyzeStartImage" + i);
  }
  animationInitializer = 0;
    
  curFrame = 0;
  curState = 0;
  
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
  if(showProgressBar) {
    float scale = preAnimate ? 0.5f : 1f;
    float frac = scale * cur / max;
    if(curState == 2) frac += scale;
    progressBar(frac);
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

void progressBar(float frac) {
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
  rect(x, y, w*frac, h);
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
