varying vec2 vUv;              // 传递给片元着色器的变量

void main() {
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);

  vUv = uv;
}