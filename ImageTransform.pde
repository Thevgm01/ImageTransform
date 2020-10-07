final int desiredFramerate = 30;

PImage startImg;
PImage endImg;
int totalSize;
final float fractionToCheck = 0.001f;

String frameName = "frames/frame_#####";

int[] processOrder;//Look at the pixels of the final image in this order
int[] newOrder;//Where each pixel in the final version comes from
int processIndex = 0;

int animationFrame = 0;
final int totalAnimationFrames = desiredFramerate * 4;
boolean record = false;

final int HUE = 16, SATURATION = 8, BRIGHTNESS = 0;

void setup() {
  //size(1600, 900);
  size(800, 450);
  //size(400, 225);
  //size(200, 100);
  frameRate(desiredFramerate);
  colorMode(HSB);
  totalSize = width * height;

  startImg = loadImage("rainbow.jpg");
  endImg = loadImage("spaceship.jpg");
  startImg.resize(width, height);
  endImg.resize(width, height);
  
  newOrder = new int[totalSize];
  processOrder = new int[totalSize];
  for(int i = 0; i < totalSize; i++) {
    newOrder[i] = -1;
    processOrder[i] = i;
  }
  randomizeArrayOrder(processOrder);
}

void mouseClicked() {
  animationFrame = 0;
  record = false;
}

void draw() {
  if(processIndex < totalSize) {
    long startTime = System.currentTimeMillis();
    background(startImg);
    while(System.currentTimeMillis() - startTime < desiredFramerate &&
          processIndex < totalSize) {
            
      int index = processIndex;//processOrder[processIndex];
      findBestFit(index);
      
      int[] curPixel = getCoords(index);
      set(curPixel[0], curPixel[1], color(255));
      
      processIndex++;
    }
    float percent = ((float)processIndex / totalSize) * 100;
    String titles = "analyzed:\npercent:\nframerate:";
    String values = processIndex + "\n"
                    + round(percent*10)/10f + "\n"
                    + round(frameRate*10)/10f;
    text(titles, 0, 10);
    text(values, 60, 10);
  } else if(animationFrame <= totalAnimationFrames) {
    float frac = (float)animationFrame / totalAnimationFrames;
    
    background(startImg);
    fill(0, 0, 0, frac * 255);
    rect(0, 0, width, height);
    
    for(int i = 0; i < totalSize; i++) {
      int[] destination = getCoords(processOrder[i]);
      int[] beginning = getCoords(newOrder[processOrder[i]]);
      set(
        (int)lerp(beginning[0], destination[0], frac),
        (int)lerp(beginning[1], destination[1], frac),
        startImg.pixels[newOrder[processOrder[i]]]);
    }
    if(record) saveFrame(frameName);
    animationFrame++; 
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
  float bestFitValue = 9999999f;
  
  int numToCheck = (int)(totalSize * fractionToCheck);
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

class ColorIndex {
  color c;
  int i;
  ColorIndex(color c, int i) {
    this.c = c;
    this.i = i;
  }
}
