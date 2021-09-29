class ShaderCompute extends ShaderBase {

    private int computeShader;

    public ShaderCompute(GL4 gl, String computeFilename) {
        super(gl);

        computeShader = createAndCompileShader(GL4.GL_COMPUTE_SHADER, computeFilename);

        program = gl.glCreateProgram();

        gl.glAttachShader(program, computeShader);

        gl.glLinkProgram(program);
    }

    public void compute(int x, int y, int z) {
        gl.glDispatchCompute(x, y, z);
    }

    public void dispose() {
        gl.glDetachShader(program, computeShader);
        gl.glDeleteShader(computeShader);

        super.dispose();
    }
}
