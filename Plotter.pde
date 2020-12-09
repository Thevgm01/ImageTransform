void plot(int x, int y, color c, int f) {
  animationFrames[f].pixels[y * width + x] = c;
}

void roundAndPlot(float x, float y, color c, int f) {
  plot(round(x), round(y), c, f);
}

void roundAndPlotIfInBounds(float x, float y, color c, int f) {
  int xi = round(x);
  int yi = round(y);
  if(inBounds(xi, yi)) plot(xi, yi, c, f);
}

boolean inBounds(int x, int y) {
  return x >= 0 && x < WIDTH && y >= 0 && y < HEIGHT;
}

void plotLine(int x0, int y0, int x1, int y1, color c, int f) {
  if (abs(y1 - y0) < abs(x1 - x0)) {
    if (x0 > x1)
      plotLineLow(x1, y1, x0, y0, c, f);
    else
      plotLineLow(x0, y0, x1, y1, c, f);
  } else {
    if (y0 > y1)
      plotLineHigh(x1, y1, x0, y0, c, f);
    else
      plotLineHigh(x0, y0, x1, y1, c, f);
  }
}

// Bresenham's line algorithm
// https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm
void plotLineLow(int x0, int y0, int x1, int y1, color c, int f) {
  int dx = x1 - x0;
  int dy = y1 - y0;
  int yi = 1;
  if (dy < 0) {
    yi = -1;
    dy = -dy;
  }
  int D = 2*dy - dx;
  int y = y0;

  for (int x = x0; x < x1; x++) {
    plot(x, y, c, f);
    if (D > 0) {
       y = y + yi;
       D = D - 2*dx;
    }
    D = D + 2*dy;
  }
}

void plotLineHigh(int x0, int y0, int x1, int y1, color c, int f) {
  int dx = x1 - x0;
  int dy = y1 - y0;
  int xi = 1;
  if (dx < 0) {
    xi = -1;
    dx = -dx;
  }
  int D = 2*dx - dy;
  int x = x0;

  for (int y = y0; y < y1; y++) {
    plot(x, y, c, f);
    if (D > 0) {
       x = x + xi;
       D = D - 2*dy;
    }
    D = D + 2*dx;
  }
}
