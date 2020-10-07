final int DESIRED_FRAMERATE = 30;
final int PROCESS_THREADS = 4;
final String IMAGES_DIR = "C:/Users/thevg/Pictures/Wallpapers/Spaceships";
final String IMAGES_LIST_FILE = "";
final boolean SUBDIVIDE = false;
final boolean CYCLE = true;

int imagesListFileSize = 0;

String startImgName;
String endImgName;
PImage startImg;
PImage endImg;
int totalSize;//The size of the window, width * height
int numToCheck;//Check this many pixels from the original image

int[] processIndex;//How many loops each of the image processing threads have gone through
int lastProcessIndex = 0;
int processStartFrame = 0;
float averageProcessed;
int[] processOrder;//Check the pixels of the original image in this order
int[] newOrder;//Where each pixel in the final arrangement originally comes from
boolean showCalculatedPixels = true;

int animationFrame = 0;
final int totalAnimationFrames = DESIRED_FRAMERATE * 2;//4;
boolean record = false;
String recordingFilename = "frames/frame_#####";

int delayFrame = 0;
final int totalDelayFrames = DESIRED_FRAMERATE * 1;

int fadeFrame = 0;
final int totalFadeFrames = DESIRED_FRAMERATE * 1;//3;

final int HUE = 16, SATURATION = 8, BRIGHTNESS = 0;

void setup() {
  //size(1600, 900);
  //size(1000, 500);
  size(800, 450);
  //size(800, 600);
  //size(400, 225);
  //size(200, 100);
  frameRate(DESIRED_FRAMERATE);
  colorMode(HSB);
  totalSize = width * height;
  numToCheck = 700;//round(sqrt(totalSize));
  
  startImgName = getRandomImageName("");
  endImgName = getRandomImageName(startImgName);
  startImg = loadImageAndResize(startImgName);
  endImg = loadImageAndResize(endImgName);
  
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

PImage loadImageAndResize(String name) {
  PImage img = loadImage(name);
  background(0);
  if(img.width >= img.height) {
    img.resize(width, 0);
    image(img, 0, height/2 - img.height/2);
  } else {
    img.resize(0, height);
    image(img, width/2 - img.width/2, 0);
  }
  img = get(0, 0, width, height);
  return img;
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
        for(int i = 0; i < line; i++) {
          result = reader.readLine(); 
        }
        reader.close();
      } while(result.equals(exclude));
      return result;
    } catch(Exception e) { println("Images list file not found"); }
  }
  return null;
}

void mouseClicked() {
  if(fadeFrame == 0) {
    animationFrame = 0;
    delayFrame = 0;
  }
  record = false;
}

void draw() {
  int numProcessed = 0;
  for(int i = 0; i < PROCESS_THREADS; i++) numProcessed += processIndex[i];
  
  if(numProcessed < totalSize) {
    background(startImg);
    //analyzeStartImage(true);
    if(showCalculatedPixels) {
      noStroke();
      fill(255);
      int posY = lastProcessIndex / width;
      rect(0, posY, width, numProcessed / width - posY);
    }
    showAnalysisText(numProcessed);
    averageProcessed = increaseAverage(
      averageProcessed, 
      frameCount - processStartFrame, 
      numProcessed - lastProcessIndex);
    lastProcessIndex = numProcessed;
  } else if(animationFrame <= totalAnimationFrames + 1) {
    float frac = (float)animationFrame / totalAnimationFrames;
    fadeToBlack(startImg, frac);    
    animatePixels(frac, SUBDIVIDE);
    animationFrame++; 
    if(record) saveFrame(recordingFilename);
  } else if(!CYCLE) {
    return;
  } else if(delayFrame < totalDelayFrames) {
    delayFrame++; 
  } else if(fadeFrame < totalFadeFrames) {
    if(fadeFrame == 0) {
      startImg = get(0, 0, width, height);
    } else {
      float frac = (float)fadeFrame / totalFadeFrames;
      fadeToImage(startImg, endImg, frac);
    }
    fadeFrame++;
  } else {
    startImgName = endImgName;
    startImg = endImg;
    endImgName = getRandomImageName(startImgName);
    endImg = loadImageAndResize(endImgName);
    
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

void fadeToBlack(PImage back, float frac) {
  background(back);
  noStroke();
  fill(0, 0, 0, frac * 255);
  rect(0, 0, width, height);
}

void animatePixels(float frac, boolean subdivide) {
  int delta = 1;
  if(frac > 1) frac = 1;
  else if(subdivide) delta = 4;
  
  for(int i = 0; i < totalSize; i += delta) {
    int[] destination = getCoords(processOrder[i]);
    int[] beginning = getCoords(newOrder[processOrder[i]]);
    int posX = (int)lerp(beginning[0], destination[0], frac);
    int posY = (int)lerp(beginning[1], destination[1], frac);
    color col = startImg.pixels[newOrder[processOrder[i]]];
    set(posX, posY, col);
    if(delta == 4) {
      set(posX+1, posY, col);
      set(posX, posY+1, col);
      set(posX+1, posY+1, col);
    }
  }
}

void fadeToImage(PImage back, PImage front, float frac) {
  tint(255, 255);
  image(back, 0, 0);
  tint(255, frac * 255);
  image(front, 0, 0);
}

// Returns an index in the startImg.pixels[] array
// where the pixel at that index most closely matches the target color
void findBestFit(int index) {
  color target = endImg.pixels[index];
  int targetHue = target >> HUE & 0xff,
      targetSat = target >> SATURATION & 0xff,
      targetBrt = target >> BRIGHTNESS & 0xff;
     
  int bestFitIndex = -1;
  float bestFitValue = 9999999f;
  
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
         abs(targetBrt - (test & 0xff));//(cur >> BRIGHTNESS & 0xff)
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

int[] getCoords(int index) {
   return new int[]{index % width, index / width};
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
