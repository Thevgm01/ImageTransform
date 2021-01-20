final String IMAGES_DIR =
null;
//"C:/Users/thevg/Desktop/Processing/Projects/Images/Spaceships";
//"C:/Users/thevg/Desktop/Processing/Projects/Images/Landscapes";
//"C:/Users/thevg/Pictures/Makoto Niijima Archive";
//"E:/Pictures/Wallpapers/Favorites";

final String IMAGES_LIST_FILE = 
//null;
"C:/Users/thevg/Pictures/Wallpapers/list.txt";

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
    for(int i = 0; i < desiredLine; ++i)
      reader.readLine(); 

    return reader.readLine();

  } catch(Exception e) { return null; }
}

void loadNextCustomImage() {
  do {
    String nextImgName = getRandomImageName("");
    nextImg = new CustomImage(nextImgName);
  } while(!nextImg.isValid());
}
