uniform float uTime;
uniform float uSize;

attribute float aScale;
attribute vec3 aRandomness;

varying vec3 vColor;

void main() {
  vec4 modelPosition = modelMatrix * vec4(position, 1.0);

  // Spin - 星系旋转
  float angle = atan(modelPosition.x, modelPosition.z);// 计算当前角度
  float distanceToCenter = length(modelPosition.xz);// 计算到中心距离
  float angleOffset = (1.0 / distanceToCenter) * uTime * 0.2;// 计算角度偏移
  angle += angleOffset;// 应用偏移
  modelPosition.x = cos(angle) * distanceToCenter;// 重新计算X坐标
  modelPosition.z = sin(angle) * distanceToCenter;// 重新计算Z坐标

  //Randomness - 随机位置偏移
  modelPosition.xyz += aRandomness;

  vec4 viewPosition = viewMatrix * modelPosition;
  vec4 projectedPosition = projectionMatrix * viewPosition;
  gl_Position = projectedPosition;

  // Size - 粒子大小计算
  gl_PointSize = uSize * aScale;// 基础大小 × 随机缩放
  gl_PointSize *= (1.0 / -viewPosition.z);// 距离衰减

  // Color - 传递颜色到片元着色器
  vColor = color;
}