final String SHADER_FOLDER = "animations/";
final String[] SHADERS = {"linear"};

PShader shader;
PImage startCoords;

PShape test;

void resetAnimator() {
  String randomShader = SHADERS[(int)random(SHADERS.length)];
  
  shader = loadShader(SHADER_FOLDER + "frag.glsl", SHADER_FOLDER + randomShader + ".glsl");
  //shader.set("startResolution", float(startImg.width()), float(startImg.height()));
  //shader.set("endResolution", float(endImg.width()), float(endImg.height()));
  //shader.set("newOrder", newOrder);
  //shader.set("newOrder", new int[1920 * 1080]);
  
  startCoords = createImage(endImg.width(), endImg.height(), RGB);
  
  //test = createShape(GROUP);
  test = createShape();
  test.beginShape(POINTS);
  test.strokeCap(PROJECT);
  for(int i = 0; i < endImg.length(); ++i) {
    //startCoords.pixels[i] = color(random(255), random(255), random(255));
    //println(red(startCoords.pixels[i]) + ", " + green(startCoords.pixels[i]));
    test.stroke(startImg.getPixel(retrieveCoordsFromImage(i)));
    test.vertex(i % endImg.width(), i / endImg.width());
    /*
    //PShape temp = createShape(RECT, i % endImg.width(), i / endImg.width(), 1, 1);
    PShape temp = createShape();
    
    temp.beginShape(POINTS);
    temp.vertex(i % endImg.width(), i / endImg.width());
    temp.endShape(CLOSE);

    test.addChild(temp);
    */
  }
  test.endShape();

  //shader.set("startCoords", startCoords);
  shader.set("textureA", startCoords);
}

void animate(float frac) {
  background(0);
  
  //shader.set("frac", frac);
  shader.set("frac", 0.99f);
  shader(shader);  
  shape(test);
  //endImg.drawImageCentered();
  //image(startCoords, 0, 0);
  
  resetShader();
}
