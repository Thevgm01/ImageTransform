class ColorNode implements Comparable<ColorNode> {
  
  public ArrayList<Integer> indexes;
  public color pixelColor;
  private int hue, sat, brt, sum;
  
  public ColorNode(color c, int i) {
     pixelColor = c;
     indexes = new ArrayList<Integer>();
     indexes.add(i);
     hue = c >> HUE & 0xff;
     sat = c >> SATURATION & 0xff;
     brt = c >> BRIGHTNESS & 0xff;
     sum = hue + sat + brt;
  }
  
  public int randomIndex() {
    return indexes.get((int)random(0, indexes.size())); 
  }
  
  @Override
  public int compareTo(ColorNode other) {
    for(int i = 0; i < 3; i++) {
      switch(sortOrder[i]) {
        case HUE:
          if(hue > other.hue) return  1;
          if(hue < other.hue) return -1; break;
        case SATURATION:
          if(sat > other.sat) return  1;
          if(sat < other.sat) return -1; break;
        case BRIGHTNESS:
          if(brt > other.brt) return  1;
          if(brt < other.brt) return -1; break;
      }
    }
    return  0;
  }
  
  @Override
  public boolean equals(Object obj) {
     if(this == obj) return true;
     if(obj == null) return false;
     //if(this.getClass() != obj.getClass()) return false;
     ColorNode other = (ColorNode) obj;
     return this.hue == other.hue && 
            this.sat == other.sat && 
            this.brt == other.brt;
  }
}
