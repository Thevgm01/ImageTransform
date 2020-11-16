// INITIALIZATION //
final boolean FULLSCREEN = false;
      int //WIDTH = 1920, HEIGHT = 1080;
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

// UI //
final boolean showCalculatedPixels = false;
final boolean showAnalysisText = true;
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

boolean legacyAnalysis = false;
boolean defaultLegacyAnalysis = legacyAnalysis;
final boolean SWITCH_TO_LEGACY_ON_SLOWDOWN = false;

final int RGB_CUBE_VALUE_BIT_SHIFT = 2; // The number of times to halve each RGB value (for performance reasons)
final int RGB_CUBE_DIMENSIONS_BIT_SHIFT = 8 - RGB_CUBE_VALUE_BIT_SHIFT; // Max 256
final int RGB_CUBE_DIMENSIONS = 1 << RGB_CUBE_DIMENSIONS_BIT_SHIFT;

final int RGB_CUBE_MAX_RANDOM_SAMPLES_BIT_SHIFT = 11;
final int RGB_CUBE_MAX_RANDOM_SAMPLES = 1 << RGB_CUBE_MAX_RANDOM_SAMPLES_BIT_SHIFT;

final int RGB_CUBE_X_SHIFT = RGB_CUBE_MAX_RANDOM_SAMPLES_BIT_SHIFT;
final int RGB_CUBE_Y_SHIFT = RGB_CUBE_X_SHIFT + RGB_CUBE_DIMENSIONS_BIT_SHIFT;
final int RGB_CUBE_Z_SHIFT = RGB_CUBE_Y_SHIFT + RGB_CUBE_DIMENSIONS_BIT_SHIFT;
final int RGB_CUBE_LENGTH_SHIFT = RGB_CUBE_Z_SHIFT + RGB_CUBE_DIMENSIONS_BIT_SHIFT;
int[] startImage_RGB_cube = new int[1 << RGB_CUBE_LENGTH_SHIFT];

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
final int AVERAGE_TRACKER_LENGTH = DESIRED_FRAMERATE;
int[] averageTrackerFrames = new int[AVERAGE_TRACKER_LENGTH];
float averageTracker = 0;
float progressSlide = 0f;
float progressSlideSpeed = PI / DESIRED_FRAMERATE;

boolean record = false;
String recordingFilename = "frames/frame_#####";

void settings() {
  if(FULLSCREEN) fullScreen(0);
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

void keyPressed() {
  if(key == 'a') {
    resetAll(); 
  }
}

void draw() {
  int numAnalyzed = 0, numAnimated = 0;
  for(int i = 0; i < NUM_THREADS; i++) {
    numAnalyzed += analyzeIndexes[i];
    numAnimated += animationIndexes[i];
  }
  
 switch(curState) {
    case 0: // Determine where pixels in the start image should end up
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
        if(SWITCH_TO_LEGACY_ON_SLOWDOWN && !legacyAnalysis && averageTracker > 0 && averageTracker < 500) {
          legacyAnalysis = true;
          resetAll();
        }
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
    case 1: // Actively animate the transition
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
    case 2: // Animate the transition in the background, storing the frames for later
      if(numAnimated < TOTAL_SIZE) {
        background(startImg);
        //Fix this :)
        moveProgressBar(progressSlideSpeed);
        showAllInfo(numAnimated, TOTAL_SIZE, "Pixels animated");
      } else {
        curState++;
      } break;
    case 3: // Play the pre-animated transition as a sort of movie
      if(curFrame < TOTAL_ANIMATION_FRAMES) {
        background(animationFrames[curFrame]);
        curFrame++; 
        if(record) saveFrame(recordingFilename);
        moveProgressBar(-progressSlideSpeed);
      } else if(cycle) {
        curFrame = 0;
        curState++;
      } break;
    case 4: // Pause for a moment to show the assembled image, then start loading the next image in the background
      if(curFrame < TOTAL_DELAY_FRAMES) {
        curFrame++;
      } else { 
        assembledImg = get();
        if(nextImg == null) thread("loadNextImage");
        curFrame = 0;
        curState++;
      } break;
    case 5: // Fade gently between the assembled image and the true final image
      if(curFrame < TOTAL_FADE_FRAMES) {
        float frac = (float)curFrame / TOTAL_FADE_FRAMES;
        fadeToImage(assembledImg, endImg, frac);
        curFrame++;
      } else {
        curFrame = 0;
        curState++;
      } break;
    case 6: // Pause for a moment on the final image, then restart the cycle
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
      
      legacyAnalysis = defaultLegacyAnalysis;
      
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
  }
  animationInitializer = 0;

  if(legacyAnalysis) analyzeStartImage_legacy();
  else analyzeStartImage();
  
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
