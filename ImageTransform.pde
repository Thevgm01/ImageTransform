import java.io.BufferedReader;
import java.io.FileReader;

final int DESIRED_FRAMERATE = 30;
final String IMAGES_DIR = "C:/Users/thevg/Pictures/Wallpapers/Spaceships";
final String IMAGES_LIST_FILE = "";
final boolean CYCLE = true;
int imagesListFileSize = 0;

String startImgName;
String endImgName;
PImage startImg;
PImage endImg;
int totalSize;
int numToCheck;

int processIndex = 0;
int lastProcessIndex = 0;
int processStartFrame = 0;
float averageProcessed;
int[] processOrder;//Look at the pixels of the final image in this order
int[] newOrder;//Where each pixel in the final version comes from

int animationFrame = 0;
final int totalAnimationFrames = DESIRED_FRAMERATE * 4;
boolean record = false;
String recordingFilename = "frames/frame_#####";

int delayFrame = 0;
final int totalDelayFrames = DESIRED_FRAMERATE * 1;

int fadeFrame = 0;
final int totalFadeFrames = DESIRED_FRAMERATE * 3;

final int HUE = 16, SATURATION = 8, BRIGHTNESS = 0;

void setup() {
  //size(1600, 900);
  size(800, 450);
  //size(800, 600);
  //size(400, 225);
  //size(200, 100);
  frameRate(DESIRED_FRAMERATE);
  colorMode(HSB);
  totalSize = width * height;
  numToCheck = round(sqrt(totalSize));//500;
  
  startImgName = getRandomImage("");
  endImgName = getRandomImage(startImgName);
  startImg = loadImageAndResize(startImgName);
  endImg = loadImageAndResize(endImgName);
  
  newOrder = new int[totalSize];
  processOrder = new int[totalSize];
  for(int i = 0; i < totalSize; i++) {
    newOrder[i] = -1;
    processOrder[i] = i;
  }
  randomizeArrayOrder(processOrder);
}

PImage loadImageAndResize(String name) {
  PImage img = loadImage(name);
  img.resize(width, height);
  return img;
}

String getRandomImage(String exclude) {
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
        reader = new BufferedReader(new FileReader(IMAGES_LIST_FILE));
        while(reader.readLine() != null)
          imagesListFileSize++;
        reader.close();
      }
      String result = "";
      do {
        int line = (int)random(0, imagesListFileSize);
        reader = new BufferedReader(new FileReader(IMAGES_LIST_FILE));
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
  if(processIndex < totalSize) {
    background(startImg);
    analyzeStartImage(true);
    showAnalysisText();
    averageProcessed = increaseAverage(
      averageProcessed, 
      frameCount - processStartFrame, 
      processIndex - lastProcessIndex);
    lastProcessIndex = processIndex;
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
      startImg = get(0, 0, width, height);
    } else {
      float frac = (float)fadeFrame / totalFadeFrames;
      fadeToImage(startImg, endImg, frac);
    }
    fadeFrame++;
  } else {
    startImgName = endImgName;
    startImg = endImg;
    //startImg = loadImage("orange.jpg");
    //startImg.resize(width, height);
    endImgName = getRandomImage(startImgName);
    endImg = loadImageAndResize(endImgName);
     
    processIndex = 0;
    lastProcessIndex = 0;
    processStartFrame = frameCount;
    //averageProcessed = 0;
    animationFrame = 0;
    delayFrame = 0;
    fadeFrame = 0;
  }
}

void analyzeStartImage(boolean highlightPixels) {
  long startTime = System.currentTimeMillis();
  while(System.currentTimeMillis() - startTime < 1000f/DESIRED_FRAMERATE &&
        processIndex < totalSize) {
          
    int index = processIndex;//processOrder[processIndex];
    findBestFit(index);
    
    if(highlightPixels) {
      int[] curPixel = getCoords(index);
      set(curPixel[0], curPixel[1], color(255));
      //set(curPixel[0], curPixel[1], color(startImg.pixels[index] >> HUE & 0xff, 255, 255));
    }
    processIndex++;
  }
}

void showAnalysisText() {
  float percent = ((float)processIndex / totalSize) * 100;
  String titles = "analyzed:\nper frame:\npercent:\nframerate:";
  String values = processIndex + "/" + totalSize + "\n"
                  + round(averageProcessed) + "\n"
                  + round(percent*10)/10f + "\n"
                  + round(frameRate*10)/10f;
  fill(255);
  text(titles, 0, 10);
  text(values, 60, 10);
}

void fadeToBlack(PImage back, float frac) {
  background(back);
  fill(0, 0, 0, frac * 255);
  rect(0, 0, width, height);
}

void animatePixels(float frac) {
  for(int i = 0; i < totalSize; i++) {
    int[] destination = getCoords(processOrder[i]);
    int[] beginning = getCoords(newOrder[processOrder[i]]);
    set(
      (int)lerp(beginning[0], destination[0], frac),
      (int)lerp(beginning[1], destination[1], frac),
      startImg.pixels[newOrder[processOrder[i]]]);
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
