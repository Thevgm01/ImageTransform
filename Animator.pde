int counter1 = 0;
final int X1 = counter1++;
final int Y1 = counter1++;
final int X2 = counter1++;
final int Y2 = counter1++;
final int COLOR = counter1++;

private enum Animation {
  LINEAR,
  CIRCLE,
  SPIRAL,
  ELLIPSE,
  BURST_PHYSICS,
  LURCH,
  FALLING_SAND,
  LASER,
  EVAPORATE,
  EVAPORATE_CIRCLE,
  WIGGLE,
  ARC_TO_EDGE
}
final int NUM_ANIMATIONS = Animation.values().length;
Animation curAnimation;

int startFrame = 0;

int LARGEST_DIM;

void initializeAnimator() {
  initializeEasing();  
  initializeTrigTable();
  initializeSand();
  thread("randomizeNoise");
  
  LARGEST_DIM = WIDTH;
  if(HEIGHT > WIDTH) LARGEST_DIM = HEIGHT;
}

void resetAnimator() {
  
  do curAnimation = Animation.values()[(int)random(NUM_ANIMATIONS)];
  while(false
    || curAnimation == Animation.FALLING_SAND
    || curAnimation == Animation.ELLIPSE 
    || curAnimation == Animation.WIGGLE 
  );
  
  easeMethodX = (int)random(3) + 1;
  do easeMethodY = (int)random(3) + 1;
  while(easeMethodX == easeMethodY); // Ensure you can't have two of the same polynomial easing
  
  direction = random(1) > 0.5f ? 1 : -1;
    
  startFrame = 0;
    
  // OVERRIDES //
  //curAnimation = Animation.WIGGLE;
  //curAnimation = Animation.FALLING_SAND;
  curAnimation = Animation.ARC_TO_EDGE;
  //curAnimation = Animation.SPIRAL;
  //easeMethodX = 2;
}

int[] getCoords(int i, int j) {
  return new int[] {
    j % WIDTH,
    j / WIDTH,
    i % WIDTH,
    i / WIDTH,
    startImg.pixels[j] };
}

void createTransitionAnimation() {
  switch(curAnimation) {
    case FALLING_SAND:
      thread("animate_fallingSand");
      break;
    default:
      for(int i = 0; i < NUM_ANIMATION_THREADS; ++i)
        thread("createAnimationFrames" + i);
      break;
  }
}

void createAnimationFrames0() { createAnimationFrames(0); }
void createAnimationFrames1() { createAnimationFrames(1); }
void createAnimationFrames2() { createAnimationFrames(2); }
void createAnimationFrames3() { createAnimationFrames(3); }
void createAnimationFrames4() { createAnimationFrames(4); }
void createAnimationFrames5() { createAnimationFrames(5); }
void createAnimationFrames6() { createAnimationFrames(6); }
void createAnimationFrames7() { createAnimationFrames(7); }

void createAnimationFrames(int offset) {
  for(int i = offset; i < TOTAL_SIZE; i += NUM_ANIMATION_THREADS) {
    ++animationIndexes[offset];

    int[] coords;
    int j = newOrder[i];
    if(j == -1) continue;
    coords = getCoords(i, j);

    switch(curAnimation) {
      case LINEAR: 
        animatePixel_linear(coords); break;
      case CIRCLE: 
        animatePixel_circle(coords); break;
      case SPIRAL: 
        animatePixel_spiral(coords); break;
      case ELLIPSE: 
        animatePixel_ellipse(coords); break;
      case BURST_PHYSICS: 
        animatePixel_burstPhysics(coords); break;
      case LURCH: 
        animatePixel_lurch(coords); break;
      case FALLING_SAND:
        break;
      case LASER: 
        animatePixel_laser(coords); break;
      case EVAPORATE: 
        animatePixel_evaporate(coords); break;
      case WIGGLE: 
        animatePixel_noisefield(coords); break;
      case ARC_TO_EDGE: 
        animatePixel_arcToEdge(coords); break;
      //case ANIMATION_CIRCLE_AXIS: 
      //  animatePixel_circleAxis(c, coords); break;
    }
  }
}
