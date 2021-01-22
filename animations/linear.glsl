uniform mat4 transform;
uniform mat4 texMatrix;

attribute vec4 position;
attribute vec4 color;
attribute vec2 texCoord;

uniform vec2 startResolution;
uniform vec2 endResolution;
uniform sampler2D tex;
uniform float frac;

varying vec4 vertColor;
varying vec4 vertTexCoord;

void main() {
  vertTexCoord = texMatrix * vec4(texCoord, 1.0, 1.0);

  vec4 start = texture2D(tex, vertTexCoord.st) * 255;
  //vec4 start = vec4(0);
  
  //vec2 curPos = mix(start.xy, position.xy, frac);
  vec4 curPos = vec4(position.x + 10 * position.x, position.y + 10 * position.y, position.zw);

  //gl_Position = transform * vec4(curPos.xy, position.zw);
  gl_Position = transform * curPos;
    
  vertColor = color;
}