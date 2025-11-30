#define PI 3.14159265358979323846

uniform vec3 uDepthColor;
uniform vec3 uSufaceColor;
uniform float uColorOffset;
uniform float uColorMultiplier;

varying vec2 vUv;
varying float vElevation;              // 传递给片元着色器的变量
varying vec3 vNormal;
varying vec3 vPosition;

// 平行光函数
// 参数：
//   lightColor (vec3) - 平行光颜色，RGB值范围0.0-1.0
//   lightIntensity (float) - 平行光强度，控制亮度
//   normal (vec3) - 表面法线向量，必须归一化
//   lightPosition (vec3) - 平行光方向向量，实际作为方向使用
//   viewDirection (vec3) - 视线方向向量，从表面指向相机
//   specularPower (float) - 高光强度系数，值越大高光越集中
// 返回值：
//   vec3 - 计算得到的平行光颜色值（包含漫反射和镜面反射）
vec3 directionalLight(vec3 lightColor, float lightIntensity, vec3 normal, vec3 lightPosition, vec3 viewDirection, float specularPower) {
  vec3 lightDirection = normalize(lightPosition);
  vec3 lightReflection = reflect(-lightDirection, normal);

    // Shading
  float shading = dot(normal, lightDirection);
  shading = max(.0, shading);

    // Specular 反射
  float specular = -dot(lightReflection, viewDirection);
  specular = max(.0, specular);
  specular = pow(specular, specularPower);

  return lightColor * lightIntensity * (shading + specular);
    // return vec3(specular);
}

// 点光源函数
// 参数：
//   lightColor (vec3) - 点光源颜色，RGB值范围0.0-1.0
//   lightIntensity (float) - 点光源强度，控制亮度
//   normal (vec3) - 表面法线向量，必须归一化
//   lightPosition (vec3) - 点光源实际位置坐标
//   viewDirection (vec3) - 视线方向向量，从表面指向相机
//   specularPower (float) - 高光强度系数，值越大高光越集中
//   position (vec3) - 当前表面点的世界坐标位置
//   lightDecay (float) - 光线衰减系数，控制随距离衰减的速度
// 返回值：
//   vec3 - 计算得到的点光源颜色值（包含衰减、漫反射和镜面反射）
vec3 pointLight(vec3 lightColor, float lightIntensity, vec3 normal, vec3 lightPosition, vec3 viewDirection, float specularPower, vec3 position, float lightDecay) {
  vec3 lightDelta = lightPosition - position;
  float lightDistance = length(lightDelta);
  vec3 lightDirection = normalize(lightDelta);
  vec3 lightReflection = reflect(-lightDirection, normal);

    // Shading
  float shading = dot(normal, lightDirection);
  shading = max(.0, shading);

    // Specular 反射
  float specular = -dot(lightReflection, viewDirection);
  specular = max(.0, specular);
  specular = pow(specular, specularPower);

    // Decay 衰减
  float decay = 1.0 - lightDistance * lightDecay;// 这种方式并不合理，只能算是简单处理
  decay = max(.0, decay);

  return lightColor * lightIntensity * decay * (shading + specular);
    // return vec3(decay);
}

void main() {
  vec3 viewDirection = normalize(vPosition - cameraPosition);
  vec3 normal = normalize(vNormal);

  // Base color 
  float mixStrength = (vElevation + uColorOffset) * uColorMultiplier;
  mixStrength = smoothstep(.0, 1.0, mixStrength);
  vec3 color = mix(uDepthColor, uSufaceColor, mixStrength);

  // Light
  vec3 light = vec3(.0);
  // light += directionalLight(vec3(1.0), 1.0, normal, vec3(-1.0, .5, .0), viewDirection, 30.0);
  light += pointLight(vec3(1.0), 10.0, normal, vec3(.0, .25, .0), viewDirection, 30.0, vPosition, .95);
  color *= light;

  // Final color 
  gl_FragColor = vec4(color, 1.0);
  #include <tonemapping_fragment>
  #include <colorspace_fragment>
}