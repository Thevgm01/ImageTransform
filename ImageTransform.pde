import java.util.BitSet;

// INITIALIZATION //
final boolean FULLSCREEN = false;
      int //WIDTH = 1920, HEIGHT = 1080;
          WIDTH = 1600, HEIGHT = 900;
          //WIDTH = 800, HEIGHT = 450;
final int HALF_WIDTH = WIDTH / 2, HALF_HEIGHT = HEIGHT / 2;
final int TOTAL_SIZE = WIDTH * HEIGHT;
final int DESIRED_FRAMERATE = 60;
final int NUM_ANALYSIS_THREADS = 1;//The number of threads, up to 8
final int NUM_ANIMATION_THREADS = 6;//The number of threads, up to 8
      int MAX_THREADS = 0;
final int TOTAL_ANIMATION_FRAMES = DESIRED_FRAMERATE * 4;//4;
final int TOTAL_DELAY_FRAMES = DESIRED_FRAMERATE / 2;
final int TOTAL_FADE_FRAMES = DESIRED_FRAMERATE * 2;//3;

// CONFIGURATION //
final boolean ignoreBlack = true;
final boolean preAnimate = true; //Dramatically slows loading speed, but required for maintaining high framerate at large resolutions
final boolean cycle = true;
final boolean cacheAnalysisResults = true;
final boolean switchToLegacyAnalysisOnSlowdown = false;

final boolean ui_showCalculatedPixels = false;
final boolean ui_showAnalysisText = true;
final boolean ui_showAnalysisGraph = false;
final boolean ui_showProgress = true;
final boolean ui_showProgressBar = false;
final boolean ui_showProgressBorder = true;
final boolean ui_showEndImage = true;
final boolean ui_showEndImageCalculatedPixels = true;

// IMAGES IN MEMORY //
String startImgName;
String endImgName;
String nextImgName;
PImage startImg;
PImage endImg;
PImage nextImg;
PImage endImgSmall;
PImage nextImgSmall;
PImage assembledImg;
PImage[] animationFrames;
PImage[] nextAnimationFrames;

color[] startColorsRandomized;
int[] startIndexesRandomized;
int[] newOrder;

int[] analysisIndexes;
int[] backgroundIndexes;
int[] animationIndexes;
BitSet pixelsLegacyAnalyzed;

int curState;
int curFrame;

boolean record = false;
String recordingFilename = "frames/frame_#####";

void settings() {
  if(FULLSCREEN) fullScreen(0);
  else size(WIDTH, HEIGHT); 
}

void setup() {
  frameRate(DESIRED_FRAMERATE);
  //colorMode(HSB);
  
  initializeAnimator();
  
  if(NUM_ANALYSIS_THREADS > MAX_THREADS) MAX_THREADS = NUM_ANALYSIS_THREADS;
  if(NUM_ANIMATION_THREADS > MAX_THREADS) MAX_THREADS = NUM_ANIMATION_THREADS;
  analysisIndexes = new int[MAX_THREADS];
  backgroundIndexes = new int[MAX_THREADS];
  animationIndexes = new int[MAX_THREADS];
  
  startColorsRandomized = new color[TOTAL_SIZE];
  startIndexesRandomized = new int[TOTAL_SIZE];
  newOrder = new int[TOTAL_SIZE];
  
  RGB_cube = new ArrayList<ArrayList<Integer>>();
  RGB_cube_recordedResults = new ArrayList<ArrayList<Integer>>();
  for(int i = 0; i < RGB_CUBE_TOTAL_SIZE; ++i) {
    RGB_cube.add(new ArrayList<Integer>());
    RGB_cube_recordedResults.add(new ArrayList<Integer>());
    if(!cacheAnalysisResults)
      RGB_cube_recordedResults.get(i).add(1);
  }
  
  loadNextImage();
  startImgName = nextImgName;
  endImgName = nextImgName; // Prevent loading the same image twice in the beginning
  startImg = nextImg;
  loadNextImage();
  endImgName = nextImgName;
  endImg = nextImg;
  endImgSmall = nextImgSmall;
  thread("createStartBackgrounds");
      
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
  int numAnalyzed = 0, numBackgrounds = 0, numAnimated = 0;
  for(int i = 0; i < MAX_THREADS; i++) {
    numAnalyzed += analysisIndexes[i];
    numBackgrounds += backgroundIndexes[i];
    numAnimated += animationIndexes[i];
  }
  
 switch(curState) {
    case 0: // Determine where pixels in the start image should end up
      boolean stillAnalyzing = numAnalyzed < TOTAL_SIZE,
              stillMakingBackgrounds = preAnimate && numBackgrounds < TOTAL_ANIMATION_FRAMES;
      background(startImg);
      moveProgressBar(progressSlideSpeed);
      showAllInfo(numAnalyzed, TOTAL_SIZE, "Pixels analyzed");
      //if(stillProcessing) showAllInfo(numAnalyzed, TOTAL_SIZE, "Pixels analyzed");
      //else if(stillMakingBackgrounds) showAllInfo(numFrames, TOTAL_ANIMATION_FRAMES, "Backgrounds created");
      //else {
      if(!stillAnalyzing && !stillMakingBackgrounds) {
        resetAverage();
        //if(record) saveFrame(recordingFilename);
        if(switchToLegacyAnalysisOnSlowdown) {
          if(!pixelsLegacyAnalyzed.isEmpty())
            println("Pixels analyzed with legacy method: " + pixelsLegacyAnalyzed.cardinality());
        }
        if(preAnimate) {
          curState++;
          animationFrames = nextAnimationFrames;
          thread("loadNextImageAndBackgrounds");
          createTransitionAnimation();
        }
        curState++;
      }
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
        if(curAnimation == Animation.WIGGLE) {
          thread("randomizeNoise");
        }
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
    case 4: // Pause for a moment to show the assembled image
      if(curFrame < TOTAL_DELAY_FRAMES) {
        curFrame++;
      } else { 
        assembledImg = get();
        curFrame = 0;
        curState++;
      } break;
    case 5: // Fade gently between the assembled image and the true final image
      if(curFrame < TOTAL_FADE_FRAMES) {
        fadeToImage(assembledImg, endImg, (float)curFrame++ / TOTAL_FADE_FRAMES);
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
      endImg = nextImg;
      endImgSmall = nextImgSmall;
      
      numAnalyzed = 0;
      numAnimated = 0;
      
      resetAll();
  }
  if(ui_showProgress) showProgress(numAnalyzed, numAnimated);
}

void resetAll() {
  println(startImgName);
  randomizeImage(startImg.pixels, startColorsRandomized, startIndexesRandomized);

  for(int i = 0; i < MAX_THREADS; i++) {
    analysisIndexes[i] = 0;
    //frameIndexes[i] = 0;
    animationIndexes[i] = 0;
  }
  pixelsLegacyAnalyzed = new BitSet(endImg.pixels.length);
  animationFrames = new PImage[TOTAL_ANIMATION_FRAMES];

  if(LEGACY_ANALYSIS) analyzeStartImage_legacy();
  else analyzeStartImage();
 
  resetAnimator();
  
  curFrame = 0;
  curState = 0;
  
  resetAverage();
  
  background(startImg);
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
