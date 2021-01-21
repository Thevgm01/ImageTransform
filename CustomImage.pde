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
  public color getPixel(int x, int y) { return img.pixels[y * img.width + x]; }
  public color getPixel(int[] coords) { return img.pixels[coords[1] * img.width + coords[0]]; }
  //public PImage getImage() { return img; }
  public boolean isValid() { return img.width > 0 && img.height > 0; }
  
  CustomImage(PImage img) {
    this.img = img;
  }
  
  CustomImage(String name, int w, int h) {
    this.name = name;
    this.img = loadImage(name);
    resizeImage(w, h);
  }
  
  CustomImage(String name) {
    this(name, width, height);
  }
  
  public CustomImage copy() {
    return new CustomImage(name); 
  }
  
  public CustomImage copy(int w, int h) {
    return new CustomImage(name, w, h);
  }

  public void resizeImage(int w, int h) {
    if(!isValid()) return;
    
    img.resize(w, 0); 
    if(img.height > h) img.resize(0, h);
    
    imgx = width/2 - img.width/2;
    imgy = height/2 - img.height/2;
  }
  
  public void drawImageCentered() {
    image(img, imgx, imgy);
  }
  
  public void draw(int x, int y) {
    image(img, x, y);
  }
}
