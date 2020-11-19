final String IMAGES_DIR =
"";
//"C:/Users/thevg/Desktop/Processing/Projects/Images/Spaceships";
//"C:/Users/thevg/Desktop/Processing/Projects/Images/Landscapes";
//"C:/Users/thevg/Pictures/Makoto Niijima Archive";
//"E:/Pictures/Wallpapers/Favorites";

final String IMAGES_LIST_FILE = 
//"";
//"C:/Users/thevg/Pictures/Wallpapers/list.txt";
"H:/Pictures/Wallpapers/list.txt";

int imagesListFileSize = 0;

String getRandomImageName(String exclude) {
  if(IMAGES_LIST_FILE.equals("")) {
    File[] files = new File(IMAGES_DIR).listFiles();
    File result;
    do {
      result = files[(int)random(0, files.length)];
    } while(result.getAbsolutePath().equals(exclude));
    return result.getAbsolutePath();
  } else {
    try {
      BufferedReader reader;
      if(imagesListFileSize == 0) {
        reader = createReader(IMAGES_LIST_FILE);
        while(reader.readLine() != null)
          imagesListFileSize++;
        reader.close();
      }
      String result = "";
      do {
        int line = (int)random(0, imagesListFileSize);
        reader = createReader(IMAGES_LIST_FILE);
        for(int i = 0; i < line; i++)
          result = reader.readLine(); 
        reader.close();
      } while(result.equals(exclude));
      return result;
    } catch(Exception e) { println("Images list file not found"); }
  }
  return null;
}

void loadNextImageAndBackgrounds() {
  loadNextImage();
  createBackgroundsFromImage(endImg);
}

void loadNextImage() {
  do {
    nextImgName = getRandomImageName(endImgName);
    nextImg = loadImage(nextImgName);
  } while(nextImg == null || nextImg.width < 0 || nextImg.height < 0 || nextImgName.equals(endImgName));
  
  resizeImage(nextImg, width, height);
  nextImg = imageOnBlack(nextImg, 1);
  
  nextImgSmall = nextImg.copy();
  nextImgSmall.resize(width/5, 0);
}

void createStartBackgrounds() { createBackgroundsFromImage(startImg); }
void createBackgroundsFromImage(PImage img) {
  nextAnimationFrames = new PImage[TOTAL_ANIMATION_FRAMES];
  nextAnimationFrames[0] = img.copy();
  nextAnimationFrames[1] = img.copy();
  backgroundIndexes[0] = 2;
  for(int i = 2; i < TOTAL_ANIMATION_FRAMES; i += 2) {
    PImage curFrame = imageOnBlack(img, 1 - easing[i][LINEAR]);
    nextAnimationFrames[i] = curFrame;
    nextAnimationFrames[i+1] = curFrame.copy();
    backgroundIndexes[0] += 2;
  }
}

void resizeImage(PImage img, int w, int h) {
  img.resize(w, 0); 
  if(img.height > h) img.resize(0, h);
}

PImage imageOnBlack(PImage img, float alpha) {
  PImage newImage = createImage(width, height, RGB);
  newImage.set(HALF_WIDTH - img.width/2, HALF_HEIGHT - img.height/2, img);
  color black = color(0, 0, 0, 255);
  for(int i = 0; i < newImage.pixels.length; ++i) {
    if(newImage.pixels[i] == 0) newImage.pixels[i] = black;
    else newImage.pixels[i] = lerpColor(black, newImage.pixels[i], alpha);
  }
  /*
  for(int i = 0; i < newImage.pixels.length; ++i) {
    int x = i % width, y = i / width;
    if(x >= HALF_WIDTH - img.width/2 && x < HALF_WIDTH + img.width/2 &&
       y >= HALF_HEIGHT - img.height/2 && y < HALF_HEIGHT + img.height/2) {
      newImage.pixels[i] = lerpColor(black, img.pixels[y * img.width + x], alpha);
    }
    else {
      newImage.pixels[i] = black;
    }
  }
  */
  return newImage;
}
