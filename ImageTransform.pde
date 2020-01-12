PImage startImg;
PImage endImg;

final float percentPerFrame = 2.5f;
float percentCounter = percentPerFrame;
String frameName = "frames/frame_#####";

int[] processOrder;
int processIndex = 0;

final int HUE = 16, SATURATION = 8, BRIGHTNESS = 0;

void setup() {
  size(1600, 900);
  size(400, 225);
  frameRate(30);
  colorMode(HSB);

  startImg = loadImage("cabin.jpg");
  endImg = loadImage("spaceship.jpg");
  startImg.resize(width, height);
  endImg.resize(width, height);
  
  processOrder = new int[width * height];
  for(int i = 0; i < processOrder.length; i++)
    processOrder[i] = i;
  randomizeArrayOrder(processOrder);
  
  background(startImg);
  saveFrame(frameName);
  println("0.0 - frame saved!");
}

void draw() {
  if(processIndex < processOrder.length) {
    startImg.loadPixels();
    
    for(int i = 0; i < 50 && processIndex < processOrder.length; i++)
      exchangePixel();
      
    startImg.updatePixels();
    background(startImg);
    
    float percent = ((float)processIndex / processOrder.length) * 100;
    if(percent >= percentCounter) {
       //saveFrame(frameName);
       percentCounter += percentPerFrame;
       println(percent + " - frame saved!");
    } else { println(percent); }
  }
}

void exchangePixel() {  
  int targetIndex = processOrder[processIndex];
  color target = endImg.pixels[targetIndex];
  float targetHue = target >> HUE & 0xff,
        targetSaturation = target >> SATURATION & 0xff,
        targetBrightness = target >> BRIGHTNESS & 0xff;
  
  int bestFitIndex = 0;
  color bestFit = 0;
  float bestFitValue = 9999999;

  for(int i = processIndex + 1; i < processOrder.length; i+=2) {
    color cur = startImg.pixels[processOrder[i]];
    float curFit = 
      abs(targetHue - (cur >> HUE & 0xff)) +
      abs(targetSaturation - (cur >> SATURATION & 0xff)) +
      abs(targetBrightness - (cur & 0xff));//(cur >> BRIGHTNESS & 0xff)
    if(curFit < bestFitValue) {
      bestFitIndex = i;
      bestFit = cur;
      bestFitValue = curFit;
    }
  }
  
  startImg.pixels[bestFitIndex] = startImg.pixels[targetIndex];
  startImg.pixels[targetIndex] = bestFit;
  
  processIndex++;
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
