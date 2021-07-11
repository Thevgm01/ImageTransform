abstract class ComputeShaderBase {
  private static final int WORK_GROUP_SIZE = 1024;
  
  GL4 gl;
  int program;
  int ssbo;
  int[] vbo = new int[1];
  
  int workGroupsX, workGroupsY;
  
  int time_uniform;
  
  public ComputeShaderBase(int program) {
    this.program = program;
  }
    
  public void initialize(CustomImage img) {
    workGroupsX = ceil((float) img.width() / WORK_GROUP_SIZE);
    workGroupsY = ceil((float) img.height() / WORK_GROUP_SIZE);
  }
  
  protected void update(float t) {
    
  }
  
  public void draw(float t) {
    update(t);
    gl.glUseProgram(program);
    gl.glDispatchCompute(workGroupsX, workGroupsY, 1);
  }
}
