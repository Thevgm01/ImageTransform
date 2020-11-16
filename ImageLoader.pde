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

void loadNextImage() {
  do {
    nextImgName = getRandomImageName(endImgName);
    nextImg = loadImage(nextImgName);
  } while(nextImg == null || nextImg.width < 0 || nextImg.height < 0);
  
  resizeImage(nextImg, width, height);
  nextImg = imageOnBlack(nextImg);
  
  nextImgSmall = nextImg.copy();
  nextImgSmall.resize(width/5, 0);
}

void resizeImage(PImage img, int w, int h) {
  img.resize(w, 0); 
  if(img.height > h) img.resize(0, h);
}

PImage imageOnBlack(PImage img) {
  PImage blackBack = createImage(width, height, RGB);
  color black = color(0, 0, 0, 255);
  for(int i = 0; i < blackBack.pixels.length; ++i)
    blackBack.pixels[i] = black;
  blackBack.set(HALF_WIDTH - img.width/2, HALF_HEIGHT - img.height/2, img);
  return blackBack;
}
