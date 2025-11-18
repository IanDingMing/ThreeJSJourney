#define PI 3.14159265358979323846

uniform vec3 uDepthColor;
uniform vec3 uSufaceColor;
uniform float uColorOffset;
uniform float uColorMultiplier;

varying vec2 vUv;
varying float vElevation;              // 传递给片元着色器的变量

void main() {
  float mixStrength = (vElevation + uColorOffset) * uColorMultiplier;
  vec3 color = mix(uDepthColor, uSufaceColor, mixStrength);

  gl_FragColor = vec4(color, 1.0);
}