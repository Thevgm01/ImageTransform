class RandomHelper {
  private int size;
  private float[] values;
  private int index = 0;
  
  RandomHelper(int num) {
    size = num;
    values = new float[size];
    
    for(int i = 0; i < size; ++i) {
      values[i] = random(1); 
    }
  }
  
  float next() {
    index = (index + 1) % size;
    return values[index];
  }
  
  float next(float max) {
    return next() * max; 
  }
  
  float next(float min, float max) {
    return next(max - min) + min;
  }
  
  int nextInt() {
    return (int)next();
  }
  
  int nextInt(int max) {
    return (int)next(max); 
  }
  
  int nextInt(int min, int max) {
    return (int)next(min, max);
  }
}
