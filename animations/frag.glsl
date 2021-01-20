#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform sampler2D textureA;

varying vec4 vertTexCoord;

void main() {
  vec3 color = vec3(texture2D(textureA, vertTexCoord.st));
  gl_FragColor = vec4(color.rgb, 1);
}