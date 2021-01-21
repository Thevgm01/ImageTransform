uniform mat4 transform;
uniform mat4 texMatrix;

attribute vec4 position;
attribute vec4 color;
attribute vec2 texCoord;

uniform vec2 startResolution;
uniform vec2 endResolution;
uniform sampler2D textureA;
uniform float frac;

varying vec4 vertTexCoord;
varying vec4 vertColor;


void main() {
  vertTexCoord = texMatrix * vec4(position.xy, 1.0, 1.0);

  //vec2 start = texture2D(startCoords, vec2(500, 500)).rg;  
  vec3 start = vec3(texture2D(textureA, vertTexCoord.st));
  //vec2 start = vec2(rand(position.xy), rand(position.xy + 100)) * 500;
  //vec2 start = texture2D(textureA, vec2(500, 500)).rg;
  //vec3 start = vec3(texture2D(startCoords, vertTexCoord.st * endResolution));  
  //vec2 start = vec2(vertTexCoord.st);
  //vec2 start = vec2(1000, 100);
  //vec3 color = vec3(texture2D(textureA, vertTexCoord.st));
  
  vec2 curPos = mix(start.rg, position.xy, frac);
  gl_Position = transform * vec4(curPos.xy, position.zw);
  //vertTexCoord = texMatrix * vec4(start.rg, 1.0, 1.0);
  
  vertColor = color;
}