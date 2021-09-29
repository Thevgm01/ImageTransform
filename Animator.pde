class Animator {
  GL4 gl;
  
  FloatList particleAttribList = new FloatList();
  float[] particlesBuffer;
  float[] particlesColorBuffuer;
  FloatBuffer fbParticles;
  FloatBuffer fbParticleColors;
  
  int numParticles;
  int x, y;

  ShaderVertFrag shader;
  ShaderCompute compute;

  Animator(GL4 gl) {
    this.gl = gl;    
    shader = new ShaderVertFrag(gl, "shaders/vert.glsl", "shaders/frag.glsl");
    compute = new ShaderCompute(gl, "shaders/animations/linear.glsl");
  }
  
  void init(CustomImage img) {
    numParticles = img.length();
    
    x = ceil(img.length() / 1024f);
    //x = ceil(img.width() / gl.GL_WORK_GROUP_SIZE);
    //y = img.height();
    y = 1;
    
    particlesBuffer = new float[numParticles * 2];
    for (int i = 0; i < numParticles; ++i) {
      particlesBuffer[i * 2 + 0] = random(-1, 1); // pos X
      particlesBuffer[i * 2 + 1] = random(-1, 1); // pos Y
    }

    fbParticles = Buffers.newDirectFloatBuffer(particlesBuffer);
        
    int[] vbo = new int[1];
    gl.glGenBuffers(1, vbo, 0);
    gl.glBindBuffer(GL4.GL_ARRAY_BUFFER, vbo[0]);
    gl.glBufferData(GL4.GL_ARRAY_BUFFER, fbParticles.limit() * 4, fbParticles, GL4.GL_DYNAMIC_DRAW);
    gl.glEnableVertexAttribArray(0);
    gl.glEnableVertexAttribArray(1);
    gl.glVertexAttribPointer(0, 2, GL4.GL_FLOAT, false, 8, 0);

    int ssbo = vbo[0];
    gl.glBindBufferBase(GL4.GL_SHADER_STORAGE_BUFFER, 0, ssbo);    
  }

  void update(float time) {
    compute.begin();
    gl.glUniform1f(compute.getUniformLocation("time"), time);
    compute.compute(x, y, 1);
    compute.end(); // necessary?
    shader.begin();
  }

  void render() {
    //updateUniform2f("hue_range", 0.34, -0.45);
    gl.glDrawArrays(GL4.GL_POINTS, 0, numParticles);
  }

  void release() {
    shader.dispose();
    compute.dispose();
  }
}
