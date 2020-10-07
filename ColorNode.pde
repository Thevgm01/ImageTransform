class ColorNode implements Comparable<ColorNode> {
  
  //public List<Integer> indexes;
  public int index;
  public color pixelColor;
  private int hue, sat, brt, sum;
  
  public ColorNode(color c, int i) {
     pixelColor = c;
     index = i;
     hue = c >> HUE & 0xff;
     sat = c >> SATURATION & 0xff;
     brt = c >> BRIGHTNESS & 0xff;
     sum = hue + sat + brt;
  }
  
  @Override
  public int compareTo(ColorNode other) {
    /*
    int hueDiff = abs(hue - other.hue),
        satDiff = abs(sat - other.sat),
        brtDiff = abs(brt - other.brt);
    
    if(hueDiff > satDiff && hueDiff > brtDiff) {
      if(hue > other.hue) return  1;
      if(hue < other.hue) return -1;
    } else if(satDiff > hueDiff && satDiff > brtDiff) {
      if(sat > other.sat) return  1;
      if(sat < other.sat) return -1;
    } else if(brtDiff > hueDiff && brtDiff > satDiff) {
      if(brt > other.brt) return  1;
      if(brt < other.brt) return -1;
    }
    */
    
    if(hue > other.hue) return  1;
    if(hue < other.hue) return -1;
    if(brt > other.brt) return  1;
    if(brt < other.brt) return -1;
    if(sat > other.sat) return  1;
    if(sat < other.sat) return -1;
    return  0;
  }
}
