final String SHADER_FOLDER = "animations/";
final String[] SHADERS = {"linear"};

PShader shader;
PImage startCoords;

void resetAnimator() {
  String randomShader = SHADERS[(int)random(SHADERS.length)];
  
  shader = loadShader(SHADER_FOLDER + "frag.glsl", SHADER_FOLDER + randomShader + ".glsl");
  //shader.set("startResolution", float(startImg.width()), float(startImg.height()));
  //shader.set("endResolution", float(endImg.width()), float(endImg.height()));
  //shader.set("newOrder", newOrder);
  //shader.set("newOrder", new int[1920 * 1080]);
  
  startCoords = createImage(endImg.width(), endImg.height(), RGB);
  
  for(int i = 0; i < endImg.length(); ++i) {
    int j = newOrder[i];
    startCoords.pixels[i] = 
      ((j % startImg.width()) << RED) +   // Put the x coordinate into the red value
      ((j / startImg.width()) << GREEN) + // and the y coordinate in the green value
      (0 << BLUE);
    //startCoords.pixels[i] = color(random(255), random(255), random(255));
    //println(red(startCoords.pixels[i]) + ", " + green(startCoords.pixels[i]));
  }
  
  //shader.set("startCoords", startCoords);
  shader.set("textureA", startCoords);
}

void animate(float frac) {
  background(0);
  
  shader.set("frac", frac);
  shader(shader);  
  endImg.drawImageCentered();
  //image(startCoords, 0, 0);
  
  resetShader();
}
