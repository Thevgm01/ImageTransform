abstract class ShaderBase {
  protected GL4 gl;
  
  protected int program;
  
  private HashMap<String, Integer> uniformLocations = new HashMap<String, Integer>();
  private HashMap<String, Integer> attribLocations = new HashMap<String, Integer>();

  public ShaderBase(GL4 gl) {
    this.gl = gl;
  }

  public int getUniformLocation(String uniform) {
    Integer result = uniformLocations.get(uniform);

    if (result == null) {
      result = gl.glGetUniformLocation(program, uniform);

      uniformLocations.put(uniform, result);
    }

    return result;
  }

  public int getAttribLocation(String attrib) {
    Integer result = attribLocations.get(attrib);

    if (result == null) {
      result = gl.glGetAttribLocation(program, attrib);

      attribLocations.put(attrib, result);
    }

    return result;
  }

  public void bindAttributeLocation(int location, String name) {
    gl.glBindAttribLocation(program, location, name);
  }
  
  int createAndCompileShader(int type, String filename) {
    int shader = gl.glCreateShader(type);

    String shaderString = String.join("\n", loadStrings(filename));
    String[] vlines = new String[]{shaderString};
    int[] vlengths = new int[]{vlines[0].length()};

    gl.glShaderSource(shader, vlines.length, vlines, vlengths, 0);
    gl.glCompileShader(shader);

    int[] compiled = new int[1];
    gl.glGetShaderiv(shader, GL4.GL_COMPILE_STATUS, compiled, 0);

    if (compiled[0] == 0) {
      int[] logLength = new int[1];
      gl.glGetShaderiv(shader, GL4.GL_INFO_LOG_LENGTH, logLength, 0);

      byte[] log = new byte[logLength[0]];
      gl.glGetShaderInfoLog(shader, logLength[0], (int[]) null, 0, log, 0);

      throw new IllegalStateException("Error compiling the shader: " + new String(log));
    }

    return shader;
  }
  
  public void begin() {
    gl.glUseProgram(program);
  }

  public void end() {
    gl.glUseProgram(0);
  }

  protected void dispose() {
    gl.glDeleteProgram(program);
  }
}
