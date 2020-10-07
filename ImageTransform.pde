final int DESIRED_FRAMERATE = 30;
final int PROCESS_THREADS = 5;
final int HUE = 16, SATURATION = 8, BRIGHTNESS = 0;
final String IMAGES_DIR = "C:/Users/thevg/Pictures/Wallpapers/Spaceships";
final String IMAGES_LIST_FILE = "";
final boolean CYCLE = true;

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

int[] processIndex;//How many loops each of the image processing threads have gone through
int lastProcessIndex = 0;
int processStartFrame = 0;
float averageProcessed;
int[] processOrder;//Check the pixels of the original image in this order
int[] newOrder;//Where each pixel in the final arrangement originally comes from
boolean showCalculatedPixels = true;
boolean showAnalysisText = true;

int animationFrame = 0;
final int totalAnimationFrames = DESIRED_FRAMERATE * 2;//4;
boolean record = false;
String recordingFilename = "frames/frame_#####";

int delayFrame = 0;
final int totalDelayFrames = DESIRED_FRAMERATE * 1;

int fadeFrame = 0;
final int totalFadeFrames = DESIRED_FRAMERATE * 1;//3;

void setup() {
  //size(1600, 900);
  size(800, 450);
  //size(400, 225);
  //size(200, 100);
  frameRate(DESIRED_FRAMERATE);
  colorMode(HSB);
  totalSize = width * height;
  numToCheck = 2000;//round(sqrt(totalSize));
  
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
  
  processIndex = new int[PROCESS_THREADS];
  newOrder = new int[totalSize];
  processOrder = new int[totalSize];
  for(int i = 0; i < totalSize; i++) {
    newOrder[i] = -1;
    processOrder[i] = i;
  }
  randomizeArrayOrder(processOrder);
  
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
  animationFrame = 0;
  delayFrame = 0;
  fadeFrame = 0;
  record = false;
}

void draw() {
  int numProcessed = 0;
  for(int i = 0; i < PROCESS_THREADS; i++) numProcessed += processIndex[i];
  
  if(numProcessed < totalSize) {
    background(startImg);
    if(showCalculatedPixels) {
      noStroke();
      fill(255);
      int topOfRectangle = lastProcessIndex / width;
      rect(0, topOfRectangle, width, 1 + numProcessed / width - topOfRectangle);
      tint(255, 220);
      image(nextImgSmall, width - nextImgSmall.width, 0);
    }
    if(showAnalysisText) {
      showAnalysisText(numProcessed);
      averageProcessed = increaseAverage(
        averageProcessed, 
        frameCount - processStartFrame, 
        numProcessed - lastProcessIndex);
    }
    lastProcessIndex = numProcessed;
  } else if(animationFrame <= totalAnimationFrames) {
    float frac = (float)animationFrame / totalAnimationFrames;
    fadeToBlack(startImg, frac);    
    animatePixels(frac);
    animationFrame++; 
    if(record) saveFrame(recordingFilename);
  } else if(!CYCLE) {
    return;
  } else if(delayFrame < totalDelayFrames) {
    delayFrame++; 
  } else if(fadeFrame < totalFadeFrames) {
    if(fadeFrame == 0) {
      assembledImg = get(0, 0, width, height);
      if(nextImg == null) thread("loadNextImage");
    } else {
      float frac = (float)fadeFrame / totalFadeFrames;
      fadeToImage(assembledImg, endImg, frac);
    }
    fadeFrame++;
  } else {
    if(nextImg == null){
      //println("Next image not loaded");
      return;
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
  for(int i = offset; i < totalSize; i += PROCESS_THREADS) {          
    findBestFit(i);
    processIndex[offset]++;
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

void showAnalysisText(int numProcessed) {
  float percent = ((float)numProcessed / totalSize) * 100;
  String titles = "analyzed:\nper frame:\npercent:\nframerate:";
  String values = numProcessed + "/" + totalSize + "\n"
                  + round(averageProcessed) + "\n"
                  + round(percent*10)/10f + "\n"
                  + round(frameRate*10)/10f;
  fill(255);
  text(titles, 0, 10);
  text(values, 60, 10);
}

void animatePixels(float frac) {  
  for(int i = 0; i < totalSize; i++) {
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
    set(startX + deltaX, startY + deltaY, col);
  }
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
  for(int i = 0; i < PROCESS_THREADS; i++) {
    processIndex[i] = 0;
    thread("analyzeStartImage" + i);
  }
  
  lastProcessIndex = 0;
  processStartFrame = frameCount;
  //averageProcessed = 0;
  animationFrame = 0;
  delayFrame = 0;
  fadeFrame = 0;
  
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

float increaseAverage(float average, float size, float value) {
  return average + (value - average)/(size+1);
}

float logisticFunc(float x, float l, float k) {
  return l / (1 + exp(-k * x));
}
