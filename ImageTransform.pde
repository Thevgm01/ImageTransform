import java.util.BitSet;

import com.jogamp.opengl.*;
import com.jogamp.common.nio.Buffers;
import java.nio.FloatBuffer;

// INITIALIZATION //
final boolean FULLSCREEN = false;
      int //WIDTH = 1920, HEIGHT = 1080;
          WIDTH = 1600, HEIGHT = 900;
          //WIDTH = 800, HEIGHT = 450;
final float WIDTH_BY_HEIGHT = (float) WIDTH / HEIGHT;
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
final boolean preAnimate = false; //Dramatically slows loading speed, but required for maintaining high framerate at large resolutions
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
CustomImage startImg;
CustomImage endImg;
CustomImage nextImg;

color[] startColorsRandomized;
int[] startIndexesRandomized;

int[] analysisIndexes;
int[] backgroundIndexes;
int[] animationIndexes;
BitSet pixelsLegacyAnalyzed;

long analysisStartTime;
long analysisTime;
long averageAnalysisTime = 0;
int numAnalysisSamples = 0;

private enum State {
  RESET,
  ANALYSIS,
  ANIMATION,
  PAUSE1,
  FADE,
  PAUSE2,
  WAIT_FOR_IMAGE
}
//final int NUM_STATES = State.values().length;
State curState;

int curFrame;
boolean frameStepping = false;

boolean record = false;
String recordingFilename = "frames/frame_#####";

GL4 gl;
Animator animator;

void settings() {
  if(FULLSCREEN) fullScreen(P2D, 0);
  else size(WIDTH, HEIGHT, P2D); 
}

void setup() {
  frameRate(DESIRED_FRAMERATE);
  //colorMode(HSB);
  
  PGL pgl = ((PGraphicsOpenGL)g).pgl;
  gl = ((PJOGL)pgl).gl.getGL4();

  animator = new Animator(gl);
  
  if(NUM_ANALYSIS_THREADS > MAX_THREADS) MAX_THREADS = NUM_ANALYSIS_THREADS;
  if(NUM_ANIMATION_THREADS > MAX_THREADS) MAX_THREADS = NUM_ANIMATION_THREADS;
  analysisIndexes = new int[MAX_THREADS];
  backgroundIndexes = new int[MAX_THREADS];
  animationIndexes = new int[MAX_THREADS];
  
  startColorsRandomized = new color[TOTAL_SIZE];
  startIndexesRandomized = new int[TOTAL_SIZE];
  
  RGB_cube = new ArrayList<ArrayList<Integer>>();
  RGB_cube_recordedResults = new ArrayList<ArrayList<Integer>>();
  for(int i = 0; i < RGB_CUBE_TOTAL_SIZE; ++i) {
    RGB_cube.add(new ArrayList<Integer>());
    RGB_cube_recordedResults.add(new ArrayList<Integer>()); // change to map<int, arraylist<integer>>?
    if(!cacheAnalysisResults)
      RGB_cube_recordedResults.get(i).add(1);
  }
  
  loadNextCustomImage();
  endImg = nextImg;
  loadNextCustomImage();
  //endImg = nextImg;

  curState = State.RESET;
}

// necessary?
void dispose() {
  animator.release(); 
}

void mouseClicked() {
  if(curState != State.ANALYSIS) {
    curState = State.ANIMATION;
  }
  curFrame = 0;
  frameStepping = false;
  record = false;
}

void keyPressed() {
  if(key == 'a') {
    resetAll(); 
  } else if(key == ' ') {
    if(!frameStepping) frameStepping = true;
    else ++curFrame;
  }
}

void draw() {
  int numAnalyzed = 0;
  for(int i = 0; i < MAX_THREADS; i++) {
    numAnalyzed += analysisIndexes[i];
  }
  
  background(0);
  
  switch(curState) {
    
    case RESET:
      resetAll();
      curState = State.ANALYSIS;
      analysisStartTime = System.nanoTime();
      break;
      
    case ANALYSIS: // Determine where pixels in the start image should end up
      boolean stillAnalyzing = numAnalyzed < endImg.length();
      startImg.drawCentered();
      moveProgressBar(progressSlideSpeed);
      showAllInfo(numAnalyzed, endImg.length(), "Pixels analyzed");
      if(!stillAnalyzing) {
        analysisTime = System.nanoTime() - analysisStartTime;
        ++numAnalysisSamples;
        averageAnalysisTime += (analysisTime - averageAnalysisTime) / numAnalysisSamples;
        println("Analysis took " + analysisTime / 1000000f + " ms");
        println("Average analysis of " + numAnalysisSamples + " images is " + averageAnalysisTime / 1000000f + " ms");
        resetAverage();
        if(switchToLegacyAnalysisOnSlowdown) {
          if(!pixelsLegacyAnalyzed.isEmpty())
            println("Pixels analyzed with legacy method: " + pixelsLegacyAnalyzed.cardinality());
        }
        thread("loadNextCustomImage");
        animator.init(endImg);
        curState = State.ANIMATION;
        //curState = State.WAIT_FOR_IMAGE;
      } break;
      
    case ANIMATION: // Actively animate the transition
      if(curFrame < TOTAL_ANIMATION_FRAMES) {
        float frac = (float)curFrame / (TOTAL_ANIMATION_FRAMES - 1);
        animator.update(frac);
        animator.render();
        if(!frameStepping) ++curFrame; 
        if(record) saveFrame(recordingFilename);
        moveProgressBar(-progressSlideSpeed);
      } else if(cycle) {
        curFrame = 0;
        curState = State.PAUSE1;
      } break;
      
    case PAUSE1: // Pause for a moment to show the assembled image
      if(curFrame < TOTAL_DELAY_FRAMES) {
        if(!frameStepping) ++curFrame;
      } else { 
        //assembledImg = get();
        curFrame = 0;
        curState = State.FADE;
      } break;
      
    case FADE: // Fade gently between the assembled image and the true final image
      if(curFrame < TOTAL_FADE_FRAMES) {
        if(!frameStepping) ++curFrame;
        //if(!frameStepping) fadeToImage(assembledImg, endImg, (float)curFrame++ / TOTAL_FADE_FRAMES);
      } else {
        curFrame = 0;
        curState = State.PAUSE2;
      } break;
      
    case PAUSE2: // Pause for a moment on the final image, then restart the cycle
      //background(endImg);
      if(curFrame < TOTAL_DELAY_FRAMES) {
        moveProgressBar(progressSlideSpeed);
        if(!frameStepping) ++curFrame;
      } else {
        curState = State.WAIT_FOR_IMAGE;
      } break;
      
    case WAIT_FOR_IMAGE:
      if(nextImageLoaded){
        curState = State.RESET;
      }
      break;
  }
  
  if(ui_showProgress) showProgress(numAnalyzed);
  if(ui_showEndImage) showEndImage();
}

void resetAll() {
  startImg = endImg;
  endImg = nextImg;
  
  println(startImg.name);
  //randomizeImage(startImg.pixels, startColorsRandomized, startIndexesRandomized);

  for(int i = 0; i < MAX_THREADS; i++) {
    analysisIndexes[i] = 0;
    //frameIndexes[i] = 0;
    animationIndexes[i] = 0;
  }
  //pixelsLegacyAnalyzed = new BitSet(endImg.pixels.length);
  //animationFrames = new PImage[TOTAL_ANIMATION_FRAMES];

  //if(LEGACY_ANALYSIS) analyzeStartImage_legacy();
  //else analyzeStartImage();
  analyzeStartImage();
   
  curFrame = 0;
  
  resetAverage();
    
  //background(startImg);
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
