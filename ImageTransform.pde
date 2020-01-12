final int desiredFramerate = 30;

PImage startImg;
PImage endImg;

String frameName = "frames/frame_#####";

int totalSize;
int[] processOrder;//Look at the pixels of the final image in this order
int[] newOrder;//The order of pixels (starting image) to resemble the final image
int processIndex = 0;

int animationFrames = 0;
final int totalAnimationFrames = 120;

final int HUE = 16, SATURATION = 8, BRIGHTNESS = 0;

void setup() {
  size(1600, 900);
  //size(800, 450);
  //size(400, 225);
  //size(200, 100);
  frameRate(desiredFramerate);
  colorMode(HSB);

  startImg = loadImage("cabin.jpg");
  endImg = loadImage("dock.jpg");
  startImg.resize(width, height);
  endImg.resize(width, height);
  
  totalSize = width * height;
  newOrder = new int[totalSize];
  processOrder = new int[totalSize];
  for(int i = 0; i < totalSize; i++) {
    newOrder[i] = -1;
    processOrder[i] = i;
  }
  randomizeArrayOrder(processOrder);
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
  float targetHue = target >> HUE & 0xff,
        targetSaturation = target >> SATURATION & 0xff,
        targetBrightness = target >> BRIGHTNESS & 0xff;
     
  int bestFitIndex = 0;
  float bestFitValue = 9999999f;

  for(int i = 0; i < totalSize; i++) {
    int curIndex = processOrder[i];
    if(newOrder[curIndex] < 0) {
      color cur = startImg.pixels[curIndex];
      float curFit = 
        abs(targetHue - (cur >> HUE & 0xff)) +
        abs(targetSaturation - (cur >> SATURATION & 0xff)) +
        abs(targetBrightness - (cur & 0xff));//(cur >> BRIGHTNESS & 0xff)
      if(curFit < bestFitValue) {
        bestFitIndex = curIndex;
        bestFitValue = curFit;
      }
    }
  }
  newOrder[bestFitIndex] = index;
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
