// INITIALIZATION //
final boolean FULLSCREEN = false;
final int //WIDTH = 1920, HEIGHT = 1080;
          WIDTH = 1600, HEIGHT = 900;
          //WIDTH = 800, HEIGHT = 450;
final int HALF_WIDTH = WIDTH / 2, HALF_HEIGHT = HEIGHT / 2;
final int TOTAL_SIZE = WIDTH * HEIGHT;
final int NUM_TO_CHECK = 2000;
final int DESIRED_FRAMERATE = 60;
final int NUM_THREADS = 6;//The number of threads, up to 8
final int TOTAL_ANIMATION_FRAMES = DESIRED_FRAMERATE * 4;//4;
final int TOTAL_DELAY_FRAMES = DESIRED_FRAMERATE / 2;
final int TOTAL_FADE_FRAMES = DESIRED_FRAMERATE * 2;//3;

// CONFIGURATION //
final boolean ignoreBlack = true;
final boolean preAnimate = true; //Dramatically slows loading speed, but required for maintaining high framerate at large resolutions
final boolean cycle = true;

// ANALYSIS //
final boolean showCalculatedPixels = false;
final boolean showAnalysisText = false;
final boolean showProgress = true;
final boolean showProgressBar = false;
final boolean showProgressBorder = true;
final boolean showNextImage = false;

// IMAGES IN MEMORY //
String startImgName;
String endImgName;
String nextImgName;
PImage startImg;
PImage endImg;
PImage nextImg;
PImage nextImgSmall;
PImage assembledImg;
PImage[] animationFrames;

color[] startColorsRandomized;
int[] startIndexesRandomized;
int[] newOrder;

int[] analyzeIndexes;
int animationInitializer;
int[] animationIndexes;

int curState;
int curFrame;

int averageTrackerLastValue = 0;
int averageTrackerStartFrame = 0;
long averageTrackerStartTime = 0;
float averageTracker;
float progressSlide = 0f;
float progressSlideSpeed = PI / TOTAL_DELAY_FRAMES / 2f;

boolean record = false;
String recordingFilename = "frames/frame_#####";

void settings() {
  if(FULLSCREEN) fullScreen();
  else size(WIDTH, HEIGHT); 
}

void setup() {
  frameRate(DESIRED_FRAMERATE);
  colorMode(HSB);
  
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
  
  startColorsRandomized = new color[TOTAL_SIZE];
  startIndexesRandomized = new int[TOTAL_SIZE];
  newOrder = new int[TOTAL_SIZE];

  analyzeIndexes = new int[NUM_THREADS];
  animationIndexes = new int[NUM_THREADS];
  if(preAnimate) animationFrames = new PImage[TOTAL_ANIMATION_FRAMES];
  
  initializeAnimator();
  
  resetAll();
}

void mouseClicked() {
  if(curState > 3) progressSlide = PI;
  if(preAnimate && curState > 3)       curState = 3;
  else if(!preAnimate && curState > 1) curState = 1;
  curFrame = 0;
  record = false;
}

void draw() {
  int numAnalyzed = 0, numAnimated = 0;
  for(int i = 0; i < NUM_THREADS; i++) {
    numAnalyzed += analyzeIndexes[i];
    numAnimated += animationIndexes[i];
  }
  
 switch(curState) {
    case 0:
      boolean stillProcessing = numAnalyzed < TOTAL_SIZE,
              initializeAnimationFrame = preAnimate && animationInitializer < TOTAL_ANIMATION_FRAMES;
      if(stillProcessing || initializeAnimationFrame) {
        while(initializeAnimationFrame) {
          float frac = (float)animationInitializer / TOTAL_ANIMATION_FRAMES;
          fadeToBlack(startImg, frac);
          animationFrames[animationInitializer]   = get();
          animationFrames[animationInitializer+1] = get();
          animationInitializer += 2;
          if(stillProcessing || animationInitializer >= TOTAL_ANIMATION_FRAMES)
            initializeAnimationFrame = false;
        }
        background(startImg);
        moveProgressBar(progressSlideSpeed);
      } else {
        background(startImg);
        resetAverage();
        if(record) saveFrame(recordingFilename);
        if(preAnimate) {
          curState++;
          createTransitionAnimation();
        }
        curState++;
      }
      showAllInfo(numAnalyzed, TOTAL_SIZE, "Pixels analyzed");
      break;
    case 1:
      if(curFrame < TOTAL_ANIMATION_FRAMES) {
        float frac = (float)curFrame / TOTAL_ANIMATION_FRAMES;
        fadeToBlack(startImg, frac);
        //loadPixels();
        //createAnimationFrame(pixels, curFrame);
        //updatePixels();
        curFrame++; 
        if(record) saveFrame(recordingFilename);
        moveProgressBar(-progressSlideSpeed);
      } else if(cycle) {
        curFrame = 0;
        curState += 3;
      } break;
    case 2:
      if(numAnimated < TOTAL_SIZE) {
        background(startImg);
        //Fix this :)
        showAllInfo(numAnimated, TOTAL_SIZE, "Pixels animated");
      } else {
        curState++;
      } break;
    case 3:
      if(curFrame < TOTAL_ANIMATION_FRAMES) {
        background(animationFrames[curFrame]);
        curFrame++; 
        if(record) saveFrame(recordingFilename);
        moveProgressBar(-progressSlideSpeed);
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
      background(endImg);
      if(curFrame < TOTAL_DELAY_FRAMES) {
        moveProgressBar(progressSlideSpeed);
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
      
      numAnalyzed = 0;
      numAnimated = 0;
      resetAll();
  }
  if(showProgress) showProgress(numAnalyzed, numAnimated);
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
  randomizeImage(startImg.pixels, startColorsRandomized, startIndexesRandomized);

  for(int i = 0; i < NUM_THREADS; i++) {
    analyzeIndexes[i] = 0;
    animationIndexes[i] = 0;
    thread("analyzeStartImage" + i);
  }
  animationInitializer = 0;
  
  resetAnimator();
  
  curFrame = 0;
  curState = 0;
  
  resetAverage();
  
  background(startImg);
}

// Randomizes the order of the pixels in an image to provide a
// random sample for analysis. Remembers the original order
// for animating the pixels.
void randomizeImage(color[] start, color[] end, int[] order) {
  for(int i = 0; i < start.length; i++) {
    end[i] = start[i];
    order[i] = i;
  }
  for(int i = start.length - 1; i > 0; i--) {
    int index = (int)random(0, i+1);

    color c = end[index];
    end[index] = end[i];
    end[i] = c;
    
    int a = order[index];
    order[index] = order[i];
    order[i] = a;
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
  advanceAverageTracker(cur);
}

void showAnalysisText(int cur, int max, String label) {  
  String titles = label + "\n" + cur + "/" + max
                  + "\npercent:\nper frame:\nseconds:\nper second:\nframerate:";
  String values = "\n\n"
                  + round(((float)cur / max) * 1000)/10f + "\n"
                  + round(averageTracker) + "\n"
                  + (((float)millis() - averageTrackerStartTime)/1000f) + "\n"
                  + round(averageTracker * DESIRED_FRAMERATE) + "\n"
                  + round(frameRate*10)/10f;
  fill(255);
  text(titles, 5, 15);
  text(values, 75, 15);
}

void showProgress(int numAnalyzed, int numAnimated) {
  float frac = (float)numAnalyzed / TOTAL_SIZE;
  if(preAnimate && curState <= 3) frac = (
    (float)numAnalyzed / TOTAL_SIZE +
    (float)numAnimated / TOTAL_SIZE)/2f;
  else if(curState > 3)
    frac = 0f;
    
  if(showProgressBar) showProgressBar(frac);
  if(showProgressBorder) showProgressBorder(frac);
}

void moveProgressBar(float amount) {
  progressSlide -= amount;
  if(progressSlide < 0) progressSlide = 0;
  else if(progressSlide > PI) progressSlide = PI;
}

void showProgressBar(float frac) {
  final int barHeight = height/50;
  final int sideDistance = width/60;
  final int borderThickness = 2;
  
  int x = sideDistance, w = width - sideDistance*2,
      y = height - sideDistance - barHeight, h = barHeight;
      
  float animationY = (cos(progressSlide) - 1f) * (barHeight + sideDistance + borderThickness)/2f;
  
  if(y + animationY < height) {
    noFill();
    stroke(255);
    strokeWeight(borderThickness);
    rect(x, y - animationY, w, h);
    fill(255);
    noStroke();
    rect(x, y - animationY, w*frac, h);
  }
}

void showProgressBorder(float frac) {
  float progressSlideMult = (cos(progressSlide) + 1f) / 2f;
  stroke(255);
  strokeWeight(3f);
  //strokeWeight(progressSlideMult * 3f);
  frac *= progressSlideMult;
  
  if(frac == 0) return;
  
  line(-frac * 3f/2f * width + HALF_WIDTH, 0, frac * 3f/2f * width + HALF_WIDTH, 0);
  if(frac >= 0.33f) {
    line(0, 0, 0, (frac - 0.33f) * 3f * height);
    line(width - 1, 0, width - 1, (frac - 0.33f) * 3f * height);
  }
  if(frac >= 0.67f) {
    line(0, height - 1, (frac - 0.67f) * 3.1f/2f * width, height - 1);
    line(-(frac - 0.67f) * 3.1f/2 * width + width, height - 1, width, height - 1);
  }
}

void advanceAverageTracker(int nextVal) {
  increaseAverage(nextVal);
  averageTrackerLastValue = nextVal;
}

void resetAverage() {
  averageTrackerLastValue = 0;
  averageTrackerStartFrame = frameCount;
  averageTrackerStartTime = millis();
  averageTracker = 0;
}

void increaseAverage(float value) {
  averageTracker += (value - averageTrackerLastValue - averageTracker)/(frameCount - averageTrackerStartFrame + 1);
}
