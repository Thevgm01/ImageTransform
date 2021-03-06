final String IMAGES_DIR =
null;
//"C:/Users/thevg/Desktop/Processing/Projects/Images/Spaceships";
//"C:/Users/thevg/Desktop/Processing/Projects/Images/Landscapes";
//"C:/Users/thevg/Pictures/Makoto Niijima Archive";
//"E:/Pictures/Wallpapers/Favorites";

final String IMAGES_LIST_FILE = 
//null;
"wallpapers.txt";

boolean nextImageLoaded = false;

int imagesListFileSize = 0;

String getRandomImageName(String exclude) {
  String result = "";
  
  do {
    if(IMAGES_LIST_FILE != null) result = getRandomImageNameFromFile(IMAGES_LIST_FILE);
    else if(IMAGES_DIR != null) result = getRandomImageNameFromDirectory(IMAGES_DIR);
    else result = getRandomImageNameFromDirectory(sketchPath("data"));
  } while(result.equals(exclude));
  
  return result;
}

String getRandomImageNameFromDirectory(String directory) {
  File[] files = new File(directory).listFiles();
  File randomFile;
  do {
    randomFile = files[(int)random(0, files.length)];
  } while(!(randomFile.getName().endsWith(".png") || 
            randomFile.getName().endsWith(".jpg") || 
            randomFile.getName().endsWith(".jpeg")));
  return files[(int)random(0, files.length)].getAbsolutePath();
}

String getRandomImageNameFromFile(String file) {
  try {
    
    BufferedReader reader;
    reader = createReader(file);
    String result = reader.readLine();

    if(imagesListFileSize == 0)
      imagesListFileSize = Integer.parseInt(result.trim());
    int desiredLine = (int)random(0, imagesListFileSize);

    String directoryPrefix = reader.readLine();

    for(int i = 0; i < desiredLine; ++i)
      reader.readLine(); 

    return directoryPrefix + reader.readLine();

  } catch(Exception e) { return null; }
}

void loadNextCustomImage() {
  nextImageLoaded = false;
  String exclude = endImg != null ? endImg.getName() : "";
  do {
    String nextImgName = getRandomImageName(exclude);
    nextImg = new CustomImage(nextImgName);
  } while(!nextImg.isValid());
  nextImageLoaded = true;
}
