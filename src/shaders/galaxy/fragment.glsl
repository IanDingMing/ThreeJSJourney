varying vec3 vColor;

void main() {

  // // Disc
  // float strength = distance(gl_PointCoord, vec2(.5));
  // strength = step(.5, strength);
  // strength = 1.0 - strength;

  // // Diffuse point
  // float strength = distance(gl_PointCoord, vec2(.5));
  // strength *= 2.0;
  // strength = 1.0 - strength;

  // Light point 光点效果
  float strength = distance(gl_PointCoord, vec2(.5));// 计算到中心距离
  strength = 1.0 - strength;// 反转：中心1，边缘0  
  strength = pow(strength, 10.0);// 提高对比度，中心更亮

  // gl_FragColor = vec4(vec3(strength), 1.0);
  // Final color - 混合颜色
  vec3 color = mix(vec3(.0), vColor, strength);// 根据强度混合颜色
  gl_FragColor = vec4(color, 1.0);// 输出最终颜色

}