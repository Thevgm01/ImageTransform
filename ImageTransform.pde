PImage startImg;
PImage endImg;

int[] processOrder;
int processIndex = 0;

final int HUE = 16, SATURATION = 8, BRIGHTNESS = 0;

void setup() {
  size(1600, 900);
  //size(800, 450);
  frameRate(30);
  colorMode(HSB);
  
  int size = width * height;
  
  startImg = loadImage("spaceship.jpg");
  startImg.resize(width, height);
  endImg = loadImage("cabin.jpg");
  endImg.resize(width, height);
  
  processOrder = new int[width * height];
  for(int i = 0; i < processOrder.length; i++)
    processOrder[i] = i;
  randomizeArrayOrder(processOrder);
  
  background(startImg);
}

void draw() {
  loadPixels();
  if(processIndex < processOrder.length) {
    for(int i = 0; i < 3000 && processIndex < processOrder.length; i++)
      exchangePixel();
  } else {
    PImage temp = startImg;
    startImg = endImg;
    endImg = temp;
    processIndex = 0;
  }
  updatePixels();
}

void exchangePixel() {  
  pixels[processOrder[processIndex]] = endImg.pixels[processOrder[processIndex]];
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
