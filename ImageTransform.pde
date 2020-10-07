final int desiredFramerate = 30;

PImage startImg;
PImage endImg;
final int colorRange = 256;
int totalSize;
ArrayList<ArrayList<ColorIndex>> colorsByHue;

String frameName = "frames/frame_#####";

int[] processOrder;//Look at the pixels of the final image in this order
int[] newOrder;//The order of pixels (starting image) to resemble the final image
int processIndex = 0;

int animationFrames = 0;
final int totalAnimationFrames = desiredFramerate * 4;

final int HUE = 16, SATURATION = 8, BRIGHTNESS = 0;

void setup() {
  //size(1600, 900);
  size(800, 450);
  //size(400, 225);
  //size(200, 100);
  frameRate(desiredFramerate);
  colorMode(HSB, colorRange);
  totalSize = width * height;

  startImg = loadImage("spaceship.jpg");
  endImg = loadImage("cat.jpg");
  startImg.resize(width, height);
  endImg.resize(width, height);
  
  newOrder = new int[totalSize];
  processOrder = new int[totalSize];
  for(int i = 0; i < totalSize; i++) {
    newOrder[i] = -1;
    processOrder[i] = i;
  }
  randomizeArrayOrder(processOrder);
  
  colorsByHue = new ArrayList<ArrayList<ColorIndex>>();
  for(int i = 0; i < colorRange; i++) {
    colorsByHue.add(new ArrayList<ColorIndex>()); 
  }
  for(int i = 0; i < totalSize; i++) {
    int index = processOrder[i];
    color cur = startImg.pixels[index];
    colorsByHue.get(cur >> HUE & 0xff).add(new ColorIndex(cur, index));
  }
}

void draw() {
  if(processIndex < totalSize) {
    long startTime = System.currentTimeMillis();
    background(startImg);
    while(System.currentTimeMillis() - startTime < desiredFramerate &&
          processIndex < totalSize) {
            
      int index = processOrder[processIndex];
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
  } else if(animationFrames <= totalAnimationFrames) {
    background(0);
    float frac = (float)animationFrames / totalAnimationFrames;
    for(int i = 0; i < totalSize; i++) {
      int[] beginning = getCoords(processOrder[i]);
      int[] destination = getCoords(newOrder[processOrder[i]]);
      set(
        (int)lerp(beginning[0], destination[0], frac),
        (int)lerp(beginning[1], destination[1], frac),
        startImg.pixels[processOrder[i]]);
    }
    saveFrame(frameName);
    animationFrames++; 
  }
}

// Returns an index in the startImg.pixels[] array
// where the pixel at that index most closely matches the target color
void findBestFit(int index) {
  color target = endImg.pixels[index];
  int targetHue = target >> HUE & 0xff,
      targetSat = target >> SATURATION & 0xff,
      targetBrt = target >> BRIGHTNESS & 0xff;
     
  ColorIndex bestFit = null;
  float bestFitValue = 9999999f;

  int variance = 0;
  while(bestFit == null) {
    int hueToCheck = targetHue + variance;
    if(hueToCheck >= 0 && hueToCheck < colorsByHue.size()) {
      ArrayList<ColorIndex> curList = colorsByHue.get(hueToCheck);
      for(int j = 0; j < curList.size(); j++) {
        ColorIndex curColor = curList.get(j);
        if(curColor.i >= 0) {
          int curFit = calculateFit(targetHue, targetSat, targetBrt, curColor.c);
          if(curFit < bestFitValue) {
            bestFit = curColor;
            bestFitValue = curFit;
          }
        }
      }
    }
    if(variance > 0) variance = variance * -1;
    else variance = variance * -1 + 1;
  }
  newOrder[bestFit.i] = index;
  bestFit.i = -1;
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
