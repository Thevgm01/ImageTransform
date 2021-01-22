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
  
  test = createShape(GROUP);
  //test = createShape();
  //test.beginShape(POINTS);
  //test.strokeWeight(1);
  //test.strokeCap(PROJECT);
  for(int i = 0; i < endImg.length(); ++i) {
    int x = i % endImg.width(),
        y = i / endImg.width();
    //test.stroke(startImg.getPixel(retrieveCoordsFromImage(i)));
    //test.vertex(x, y, x, y);

    //PShape temp = createShape(RECT, x, y, 1, 1);
    //PShape temp = createShape();
    
    //temp.beginShape(POINTS);
    //temp.vertex(x, y, x, y);
    //temp.endShape();

    //test.addChild(temp);
  }
  test.endShape();

  //shader.set("startCoords", startCoords);
  shader.set("tex", startCoords);
}

void animate(float frac) {
  background(0);
  
  //shader.set("frac", frac);
  shader.set("frac", frac);
  shader(shader);  
  shape(test);
  //endImg.drawImageCentered();
  //image(startCoords, 0, 0);
  
  resetShader();
}
