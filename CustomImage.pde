class CustomImage {
  private String name;
  private PImage img;
  private int imgx;
  private int imgy;
  
  public int width() { return img.width; }
  public int height() { return img.height; }
  public int length() { return img.pixels.length; }
  public color[] pixels() { return img.pixels; }
  public color getPixel(int index) { return img.pixels[index]; }
  public PImage getImage() { return img; }
  public boolean isValid() { return img.width > 0 && img.height > 0; }
  
  public void drawImageCentered() {
    image(img, imgx, imgy);
  }
  
  CustomImage(String name) {
    this.name = name;
    this.img = loadImage(name);
    resizeImage(img, width, height);
  }

  private void resizeImage(PImage img, int w, int h) {
    if(!isValid()) return;
    
    img.resize(w, 0); 
    if(img.height > h) img.resize(0, h);
    
    imgx = width/2 - img.width/2;
    imgy = height/2 - img.height/2;
  }
}
