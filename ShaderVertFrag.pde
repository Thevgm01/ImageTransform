class ShaderVertFrag extends ShaderBase {

  private int vertShader;
  private int fragShader;

  public ShaderVertFrag(GL4 gl, String vertexFilename, String fragmentFilename) {
    super(gl);

    vertShader = createAndCompileShader(GL4.GL_VERTEX_SHADER, vertexFilename);
    fragShader = createAndCompileShader(GL4.GL_FRAGMENT_SHADER, fragmentFilename);

    program = gl.glCreateProgram();

    gl.glAttachShader(program, vertShader);
    gl.glAttachShader(program, fragShader);

    gl.glLinkProgram(program);
  }

  public void dispose() {
    gl.glDetachShader(program, vertShader);
    gl.glDeleteShader(vertShader);
    gl.glDetachShader(program, fragShader);
    gl.glDeleteShader(fragShader);

    super.dispose();
  }
}
