## P27  Realistic render

### 问题背景

在P25 Custom models with Blender课程中，将 Blender 制作的汉堡模型导入 Three.js 后，发现渲染结果与 Blender 中存在明显差异。本节课旨在解决这些渲染差异，实现更真实的视觉效果。



### 1. 物理正确光照系统

#### 版本变迁与兼容性

- **旧版本**：使用 `renderer.physicallyCorrectLights = true`
- **r150版本**：使用 `renderer.useLegacyLights = false` 启用物理光照
- **r155+版本**：`useLegacyLights` 被弃用，r165+被移除
- **现状**：物理正确光照成为强制标准

#### 启用物理正确光照

```javascript
// 在 r150 版本中启用物理正确光照
renderer.useLegacyLights = false;
```

#### 光照强度调整

启用物理正确光照后，需要调整光源强度：

```javascript
// 传统强度 → 物理正确强度
const oldIntensity = 1;
const newIntensity = oldIntensity * Math.PI; // 约 3.1416

// 应用调整
const directionalLight = new THREE.DirectionalLight(0xffffff, newIntensity);
const ambientLight = new THREE.AmbientLight(0xffffff, newIntensity);
```

**受影响的光源类型**：

- 方向光 (DirectionalLight)
- 环境光 (AmbientLight)
- 半球光 (HemisphereLight)
- 光照贴图 (LightMap)

#### 点光源和聚光灯设置

```javascript
// 保持物理正确的衰减
const pointLight = new THREE.PointLight(0xffffff, intensity, 100, 2); // decay = 2
const spotLight = new THREE.SpotLight(0xffffff, intensity, 100, Math.PI/4, 0.5, 2); // decay = 2
```

### 2. 色调映射 (Tone Mapping)

#### 核心概念

- **HDR**：高动态范围，能表示极暗到极亮的广泛亮度
- **LDR**：低动态范围，普通显示器只能显示0-255的亮度
- **色调映射**：色调映射是将**高动态范围(HDR)**颜色值转换为**低动态范围(LDR)**显示设备能够显示的技术。

["色调映射在LDR设备上呈现HDR内容"的理解](#"色调映射在LDR设备上呈现HDR内容"的理解)

#### 实际例子说明

想象一个场景：

- **黑暗房间**：亮度接近0
- **窗外阳光**：亮度可能是1000+
- **人眼**：能同时看清房间细节和窗外景色 → **HDR能力**
- **普通相机**：要么房间全黑，要么窗外过曝 → **LDR限制**

#### 色调映射类型

```javascript
// 各种色调映射算法对比：
THREE.NoToneMapping          // 无处理，可能过曝
THREE.LinearToneMapping      // 线性压缩，简单快速  
THREE.ReinhardToneMapping    // 平衡算法，通用推荐
THREE.CineonToneMapping      // 电影胶片风格
THREE.ACESFilmicToneMapping  // 电影级，最佳亮部细节

// 配置示例
renderer.toneMapping = THREE.ReinhardToneMapping;
renderer.toneMappingExposure = 3; // 控制整体亮度
```

**解释**：

- **色调映射**：将 HDR（高动态范围）色彩映射到 LDR（低动态范围）显示设备
- **ReinhardToneMapping**：平衡的色调映射算法，保留细节同时防止过曝
- **曝光值**：控制整体亮度，值越大场景越亮

### 3. 色彩管理

```text
色彩管理 (Color Management)
├── 色彩空间管理 (Color Spaces)
├── 伽马校正 (Gamma Correction) ← 这是我们讨论的重点
├── 白平衡处理 (White Balance)
└── 色彩配置文件 (ICC Profiles)
```



#### 色彩空间管理

`renderer.outputEncoding = THREE.sRGBEncoding;` 是一个**色彩空间设置**，用于确保 Three.js 渲染的颜色在显示器上正确显示。**日常使用中，主要是在线性色彩空间和sRGB色彩空间之间选择**。

[什么是色彩空间？这个设置解决了什么问题？](#什么是色彩空间？)

[主要色彩空间类型](#主要色彩空间类型)

#### 不同版本的区别

```javascript
// Three.js r152之前
renderer.outputEncoding = THREE.sRGBEncoding;

// Three.js r152之后（新API）
renderer.outputColorSpace = THREE.SRGBColorSpace;
```

#### 实际应用场景

##### 必须设置的场景：

```javascript
// ✅ 所有真实感渲染项目
renderer.outputEncoding = THREE.sRGBEncoding;

// ✅ 使用纹理贴图的场景
const texture = new THREE.TextureLoader().load('image.jpg');
// 纹理也需要正确编码设置

// ✅ 需要与设计软件效果一致时
// （Photoshop、Blender、Substance Painter等都使用sRGB）
```

##### 可以不设置的场景：

```javascript
// ⚠️ 科学可视化（需要数学精度）
renderer.outputEncoding = THREE.LinearEncoding;

// ⚠️ 自定义后期处理管线
// （可能在自己着色器中处理色彩转换）
```



#### 伽马校正

**伽马校正是色彩管理的重要组成部分**，但**不等于完整的色彩管理**。

可以把它们的关系理解为：

```text
色彩管理 = 伽马校正 + 色彩空间转换 + 其他色彩处理
```

[什么是伽马校正？](#什么是伽马校正？)



#### 完整色彩管理配置

```javascript
// 1. 渲染器输出编码
renderer.outputEncoding = THREE.sRGBEncoding;

// 2. 纹理编码设置（如果使用HDR纹理）
texture.encoding = THREE.sRGBEncoding;

// 3. 色调映射配合
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.0;
```

**解释**：

- **sRGB编码**：现代显示器和图像文件普遍使用的色彩空间
- **伽马校正**：补偿显示设备的非线性响应，确保色彩正确显示
- **作用**：让 Three.js 渲染的色彩与 Blender 等软件保持一致



### 4. 抗锯齿 (Anti-aliasing)

**锯齿问题原因**：

- 数字渲染中的采样不足
- 边缘出现阶梯状锯齿
- 纹理细节出现闪烁或摩尔纹

#### 设置与使用建议

```javascript
// 基础抗锯齿
const renderer = new THREE.WebGLRenderer({ antialias: true });

// 使用场景建议：
// ✅ 开启：产品展示、建筑可视化、高质量渲染
// ⚠️ 酌情：性能敏感应用、移动端
// ❌ 关闭：实时游戏、复杂场景、低端设备
```



### 5. 阴影优化

#### 启用阴影

```javascript
// 渲染器支持阴影
renderer.shadowMap.enabled = true;

// 光源投射阴影
directionalLight.castShadow = true;

// 模型接收/投射阴影
model.traverse((child) => {
    if (child.isMesh) {
        child.castShadow = true;
        child.receiveShadow = true;
    }
});
```



#### 阴影Acne问题

**现象**：曲面物体表面出现条纹状自阴影
**原因**：深度贴图精度有限，曲面点产生精度误差



#### normalBias解决方案

**典型数值范围**：`0.001 - 0.1`

**normalBias 作用**：

- 解决阴影 acne（自阴影瑕疵）
- 轻微偏移阴影位置，避免表面自相交
- 对曲面物体（如面包胚）特别有效

```javascript
directionalLight.shadow.normalBias = 0.05;
```



#### 工作原理：

```
原始位置 P → 沿法线方向偏移 → 新位置 P' = P + N × normalBias
```



#### 调整指南：

```javascript
// 推荐数值范围：0.001 - 0.1
const recommendedValues = {
  '平面': 0.001,      // 几乎不需要
  '轻微曲面': 0.01,   // 微小偏移  
  '汉堡面包': 0.03,   // 中等曲面
  '球形': 0.05,       // 强曲面
};

// 调试方法
gui.add(directionalLight.shadow, 'normalBias', 0, 0.1).step(0.001);
```



#### 目标状态：

- ✅ **阴影Acne消失**：曲面表面干净
- ✅ **阴影接触正确**：接触点自然
- ❌ **避免阴影分离**：不产生明显间隙

### 6. 完整配置示例

#### 真实感渲染完整设置

```javascript
// 创建渲染器
const renderer = new THREE.WebGLRenderer({ 
  antialias: true  // 抗锯齿
});

// 物理光照设置
if (renderer.useLegacyLights !== undefined) {
  renderer.useLegacyLights = false;
}

// 色彩管理
renderer.outputEncoding = THREE.sRGBEncoding;

// 色调映射
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.0;

// 阴影设置
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;

// 光照配置
const directionalLight = new THREE.DirectionalLight(0xffffff, 1 * Math.PI);
directionalLight.castShadow = true;
directionalLight.shadow.normalBias = 0.03;
directionalLight.shadow.mapSize.set(2048, 2048);

// 纹理加载与编码
const textureLoader = new THREE.TextureLoader();
const diffuseMap = textureLoader.load('texture.jpg', (texture) => {
  texture.encoding = THREE.sRGBEncoding;
});
```



## P29 Shaders

### 1. 着色器基础概念

#### 什么是着色器？

- **着色器是运行在GPU上的程序**
- 负责处理几何体的顶点位置和像素颜色
- 分为**顶点着色器**和**片元着色器**

#### 两种着色器的作用

- **顶点着色器**：定位几何体的每个顶点
- **片元着色器**：为几何体的所有可见像素着色

### 2. Three.js 中的着色器材质

#### 两种主要材质类型

```javascript
// 1. ShaderMaterial - 自动包含常用uniforms和attributes
const material = new THREE.ShaderMaterial({
  vertexShader: vertexShaderCode,
  fragmentShader: fragmentShaderCode
});

// 2. RawShaderMaterial - 需要手动声明所有uniforms和attributes
const material = new THREE.RawShaderMaterial({
  vertexShader: vertexShaderCode,
  fragmentShader: fragmentShaderCode
});
```



### 3. 基础着色器示例

#### 最简单的着色器实现

```javascript
// 几何体
const geometry = new THREE.PlaneGeometry(1, 1, 32, 32);

// 材质
const material = new THREE.RawShaderMaterial({
  vertexShader: `
    uniform mat4 projectionMatrix;
    uniform mat4 viewMatrix;
    uniform mat4 modelMatrix;
    attribute vec3 position;

    void main(){
      gl_Position = projectionMatrix * viewMatrix * modelMatrix * vec4(position, 1.0);
    }
  `,
  fragmentShader: `
    precision mediump float;
    void main(){
      gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0); // 红色
    }
  `,
});

// 网格
const mesh = new THREE.Mesh(geometry, material);
scene.add(mesh);
```



### 4. 着色器文件组织

#### 分离GLSL文件

```javascript
// 使用Vite的静态资源处理
import testVertexShader from "@/shaders/test/vertex.glsl?raw";
import testFragmentShader from "@/shaders/test/fragment.glsl?raw";

const material = new THREE.RawShaderMaterial({
  vertexShader: testVertexShader,
  fragmentShader: testFragmentShader
});
```



### 5. 着色器语法详解

#### 顶点着色器结构

[为什么修改的是 `modelPosition`？](#为什么修改的是 `modelPosition`？)

```glsl
// vertex.glsl
uniform mat4 projectionMatrix;  // 投影矩阵
uniform mat4 viewMatrix;        // 视图矩阵
uniform mat4 modelMatrix;       // 模型矩阵
attribute vec3 position;        // 顶点位置
attribute vec2 uv;              // UV坐标

varying vec2 vUv;              // 传递给片元着色器的变量

void main() {
  vec4 modelPosition = modelMatrix * vec4(position, 1.0);
  
  // 顶点动画示例
  modelPosition.z = sin(modelPosition.x * 10.0) * 0.1;
  
  vec4 viewPosition = viewMatrix * modelPosition;
  vec4 projectedPosition = projectionMatrix * viewPosition;

  gl_Position = projectedPosition;
  vUv = uv; // 传递UV坐标
}
```



#### 片元着色器结构

[`precision mediump float;` 是什么](#`precision mediump float;` 是什么)

```glsl
// fragment.glsl
precision mediump float;        // 精度声明

uniform vec3 uColor;           // 自定义颜色uniform
uniform sampler2D uTexture;    // 纹理

varying vec2 vUv;              // 从顶点着色器接收的变量

void main() {
  vec4 textureColor = texture2D(uTexture, vUv);
  gl_FragColor = textureColor; // 输出最终颜色
}
```



### 6. 数据传递技术

#### 从JavaScript向着色器传递数据

##### 1. Uniforms 传递

```javascript
const material = new THREE.RawShaderMaterial({
  vertexShader: testVertexShader,
  fragmentShader: testFragmentShader,
  uniforms: {
    uFrequency: { value: new THREE.Vector2(10, 5) },
    uTime: { value: 0 },
    uColor: { value: new THREE.Color("pink") },
    uTexture: { value: flagTexture }
  }
});

// 在动画循环中更新uniforms
function animate() {
  material.uniforms.uTime.value = elapsedTime;
}
```



##### 2. Attributes 传递

```javascript
const geometry = new THREE.PlaneGeometry(1, 1, 32, 32);

// 创建自定义属性
const count = geometry.attributes.position.count;
const randoms = new Float32Array(count);

for (let i = 0; i < count; i++) {
  randoms[i] = Math.random();
}

// 设置属性
geometry.setAttribute("aRandom", new THREE.BufferAttribute(randoms, 1));
```



### 7. 进阶示例：飘动旗帜效果

#### 顶点着色器（旗帜动画）

```glsl
uniform mat4 projectionMatrix;
uniform mat4 viewMatrix;
uniform mat4 modelMatrix;
uniform vec2 uFrequency;
uniform float uTime;

attribute vec3 position;
attribute vec2 uv;
attribute float aRandom;

varying vec2 vUv;
varying float vElevation;

void main() {
  vec4 modelPosition = modelMatrix * vec4(position, 1.0);

  // 创建波浪效果
  float elevation = sin(modelPosition.x * uFrequency.x - uTime) * 0.1;
  elevation += sin(modelPosition.y * uFrequency.y - uTime) * 0.1;
  modelPosition.z += elevation;

  vec4 viewPosition = viewMatrix * modelPosition;
  vec4 projectedPosition = projectionMatrix * viewPosition;

  gl_Position = projectedPosition;
  vUv = uv;
  vElevation = elevation;
}
```



#### 片元着色器（纹理+光照效果）

```glsl
precision mediump float;

uniform vec3 uColor;
uniform sampler2D uTexture;

varying vec2 vUv;
varying float vElevation;

void main() {
  vec4 textureColor = texture2D(uTexture, vUv);
  
  // 根据高度调整颜色亮度（模拟光照）
  textureColor.rgb *= vElevation * 2.0 + 0.5;
  
  gl_FragColor = textureColor;
}
```



### 8. 重要区别：RawShaderMaterial vs ShaderMaterial

#### RawShaderMaterial

- **需要手动声明所有uniforms和attributes**
- 完全控制，但代码更冗长
- 必须包含基础矩阵和精度声明

#### ShaderMaterial

- **自动包含常用uniforms和attributes**
- 代码更简洁
- Three.js自动处理基础功能

#### 转换示例

```glsl
// RawShaderMaterial 需要
uniform mat4 projectionMatrix;
uniform mat4 viewMatrix;
uniform mat4 modelMatrix;
attribute vec3 position;
precision mediump float;

// ShaderMaterial 可以省略以上代码，Three.js会自动处理
```



## P30 Shaders patterns

### 1. 预定义

```glsl
#define PI 3.14159265358979323846
varying vec2 vUv;  // 纹理坐标变量
```

**核心工具函数：**

- `random(vec2)`: 伪随机数生成器（基于哈希函数）

[random代码](#random代码)

- `rotate(vec2, float, vec2)`: 2D坐标旋转

[rotate代码](#rotate代码)

- `cnoise(vec2)`: 2D Perlin噪声生成器

[Classic Perlin 2D Noise ](#Classic Perlin 2D Noise )



### 2. Pattern 详解

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-2/P30 Shaders patterns/patterns3.png)

***<u>更多Pattern图片参考本地图像，如图上地址相同文件夹中：note/images-2/P30 Shaders patterns/</u>***

#### 基础渐变模式 (Pattern 3-5)

```glsl
// Pattern 3: 水平渐变
float strength = vUv.x;

// Pattern 4: 垂直渐变  
float strength = vUv.y;

// Pattern 5: 反向垂直渐变
float strength = 1.0 - vUv.y;
```



#### 条纹模式 (Pattern 6-15)

```glsl
// Pattern 6-7: 连续条纹
float strength = vUv.y * 10.0;                    // 放大y坐标
float strength = mod(vUv.y * 10.0, 1.0);          // 取模形成重复条纹

// Pattern 8-10: 二值化条纹
float strength = step(.5, mod(vUv.y * 10.0, 1.0)); // step函数实现硬边

// Pattern 11: 网格叠加
float strength = strength1 + strength2;           // 水平和垂直条纹相加
```

**关键函数解析：**

- `mod(x, y)`: 取模运算，实现重复模式
- `step(edge, x)`: 阶梯函数，x≥edge返回1，否则返回0



#### 距离相关模式 (Pattern 16-40)

```glsl
// Pattern 16-18: 绝对距离
float strength = abs(vUv.x - .5);                 // 到中心x轴距离
float strength = min(strength1, strength2);       // 最小距离（菱形）
float strength = max(strength1, strength2);       // 最大距离（方形）

// Pattern 27-30: 欧氏距离
float strength = length(vUv);                     // 到原点距离
float strength = distance(vUv, vec2(.5));         // 到中心距离
float strength = .015 / distance(vUv, vec2(.5));  // 反比距离（光晕效果）
```

**距离计算要点：**

- `length(v)`: 计算向量长度
- `distance(a, b)`: 等价于 `length(a - b)`
- 使用减法是因为距离的数学定义基于向量差

[Pattern 28这两种区别在哪里，为什么使用length是减呢，不应该是加吗](#Pattern 28这两种区别在哪里，为什么使用length是减呢，不应该是加吗)

#### 离散化模式 (Pattern 21-26)

```glsl
// Pattern 21-22: 离散化网格
float strength = floor(vUv.x * 10.0) / 10.0;      // x轴离散化
float strength = strength1 * strength2;           // 网格效果

// Pattern 23-26: 随机化
float strength = random(vUv);                     // 连续随机
float strength = random(gridUv);                  // 网格随机
```



#### 角度相关模式 (Pattern 41-46)

```glsl
// Pattern 41-43: 角度计算和归一化
float angle = atan(vUv.x - .5, vUv.y - .5);       // 相对于中心的角度
angle /= PI * 2.0; angle += .5;                   // 归一化到[0,1]

// Pattern 44-46: 角度变形
angle *= 20.0; angle = mod(angle, 1.0);           // 径向条纹
angle = sin(angle * 100.0);                       // 径向正弦波
```

**atan函数详解：**

- `atan(y, x)`: 计算从正x轴到向量(x,y)的角度
- 范围：[-π, π]弧度
- 归一化技巧：`÷2π + 0.5` 将范围映射到[0,1]

[float angle = atan(vUv.x, vUv.y)详解](#float angle = atan(vUv.x, vUv.y)详解)

[Pattern 42 和 Pattern 43  的区别详解](#Pattern 42 和 Pattern 43  的区别详解)

#### 噪声模式 (Pattern 47-51)

```glsl
// Pattern 47-50: Perlin噪声应用
float strength = cnoise(vUv * 10.0);              // 基础噪声
float strength = step(.0, cnoise(vUv * 10.0));    // 噪声二值化
float strength = sin(cnoise(vUv * 10.0) * 20.0);  // 噪声变形

// Pattern 51: 高级噪声应用
float strength = step(.9, sin(cnoise(vUv * 10.0) * 20.0));
```



### 3. 核心概念解析

#### Clamp the strength

```glsl
strength = clamp(strength, .0, 1.0);
```

- **作用**: 将strength值限制在[0,1]范围内
- **必要性**: 确保颜色值合法，避免超出显示范围
- **clamp(x, min, max)**: 返回限制在min-max范围内的x值



#### Colored version vs Black and white version

```glsl
// 彩色版本：基于UV坐标的混合颜色
vec3 blackColor = vec3(.0);
vec3 uvColor = vec3(vUv, 1.0);        // RGB = (u, v, 1.0)
vec3 mixedColor = mix(blackColor, uvColor, strength);

// 黑白版本：直接使用strength作为灰度
gl_FragColor = vec4(vec3(strength), 1.0);
```

**mix函数**: `mix(a, b, t) = a*(1-t) + b*t` 线性插值



### 5. 重要函数总结

#### 数学函数

- `mod()`: 模运算，创建重复模式
- `step()`: 二值化，创建硬边效果
- `floor()`: 向下取整，用于离散化
- `abs()`: 绝对值，用于对称效果
- `min()/max()`: 最小值/最大值运算
- `sin()/cos()`: 三角函数，创建波形

#### 几何函数

- `length()`: 向量长度
- `distance()`: 两点距离
- `atan()`: 反正切，计算角度

#### 工具函数

- `random()`: 伪随机数生成
- `rotate()`: 坐标旋转
- `cnoise()`: Perlin噪声生成



## P31 Raging sea

### 1. **着色器材质系统**

```typescript
const waterMaterial = new THREE.ShaderMaterial({
  vertexShader: waterVertexShader,    // 顶点着色器：处理几何变形
  fragmentShader: waterFragmentShader, // 片元着色器：处理颜色渲染
  uniforms: { /* 控制参数 */ }         // 桥梁：JS ↔ GLSL数据传递
});
```

- 使用自定义的GLSL着色器替代标准材质
- 通过uniforms传递JavaScript参数到着色器



### 2. **波浪生成原理**

#### 大波浪 - 正弦波叠加

```glsl
float elevation = sin(
  modelPosition.x * uBigWavesFrenquency.x + uTime * uBigWavesSpeed
) * sin(
  modelPosition.z * uBigWavesFrenquency.y + uTime * uBigWavesSpeed
) * uBigWavesElevation;
```

- **数学原理**: 两个方向的正弦波相乘产生交错波浪
- **参数控制**:
  - `uBigWavesFrequency`: 控制X和Z方向的波浪密度
  - `uBigWavesSpeed`: 控制波浪移动速度
  - `uBigWavesElevation`: 控制波浪高度



#### 小波浪 - 3D柏林噪声

[2D噪声和3D噪声的区别是什么？](#2D噪声 vs 3D噪声)

[3D柏林噪声源码](#3D柏林噪声源码)

```glsl
for(float i = 1.0; i <= uSmallIterations; i++) {
  elevation -= abs(cnoise(vec3(modelPosition.xz * uSmallWavesFrequency * i, uTime * uSmallWavesSpeed)) * uSmallWavesElevation / i);
}
```

**参数作用详解**：

- `uSmallIterations`：噪声叠加次数
  - 1次：基础噪声
  - 2次：基础噪声 + 更密集的细节噪声
  - 3次：基础 + 密集 + 更密集的细节
  - 类似Photoshop中的图层叠加
- `uSmallWavesFrequency`：噪声频率
  - 控制噪声图案的"缩放"
  - 数值越大，噪声图案越小越密集
- `uSmallWavesSpeed`：噪声变化速度
  - 控制噪声图案随时间变化的快慢
  - 让水面看起来有细微的动态变化
- `uSmallWavesElevation`：噪声震动幅度，类似offset
  - 控制噪声对水面高度的**影响程度**
  - 类似调节音量大小

**分形噪声技巧**：

```glsl
// 频率倍增：每层频率都加倍，产生更细的细节
modelPosition.xz * uSmallWavesFrequency * i

// 振幅衰减：高频层的影响逐渐减小，避免过于杂乱
uSmallWavesElevation / i
```



### 3. **颜色混合系统**

```glsl
float mixStrength = (vElevation + uColorOffset) * uColorMultiplier;
vec3 color = mix(uDepthColor, uSufaceColor, mixStrength);
```

[这里的`vElevation`是什么，为什么用它？](#什么是 `vElevation`？)

[为什么使用 `(vElevation + uColorOffset) * uColorMultiplier`？](#为什么使用 `(vElevation + uColorOffset) * uColorMultiplier`？)



### 4. **GLSL数据类型重要问题**

#### 向量与整数的运算错误

```glsl
// ❌ 错误代码 - 不能将向量与整数直接相乘
modelPosition.xz * 3.0 * i  // i是int，modelPosition.xz是vec2

// ✅ 正确解决方案
modelPosition.xz * uSmallWavesFrequency * float(i)
```

**原因**: GLSL是强类型语言，不允许混合类型运算，需要显式类型转换。



### 5. **Three.js对象引用管理**

#### 颜色更新的正确方式

```typescript
// ✅ 正确：使用.set()方法更新现有对象
waterMaterial.uniforms.uDepthColor.value.set(debugObject.depthColor);

// ❌ 错误：直接赋值会破坏引用
waterMaterial.uniforms.uDepthColor.value = new THREE.Color(newColor);
```



## P32 Animated galaxy

### 1. `uSize` 优化写法解释

```typescript
uniforms: {
  uSize: { value: 8 * renderer.getPixelRatio() },
}
```

**为什么要乘以 `getPixelRatio()`：**

- `getPixelRatio()` 返回设备的像素比（如普通显示器是1，Retina显示器是2）
- 在高DPI屏幕上，需要更大的点大小才能看起来清晰
- 这样写确保在所有设备上粒子大小一致



### 2. 大小衰减公式详解

```glsl
gl_PointSize *= (1.0 / -viewPosition.z);
```

**解释：**

- `viewPosition.z` 是顶点在视图空间中的Z坐标（深度）
- 在视图空间中，相机看向-Z方向，所以离相机越远，Z值越负
- `-viewPosition.z` 就是顶点到相机的距离
- `1.0 / -viewPosition.z` 就是距离的倒数
- **效果**：距离相机越远的粒子越小，产生透视效果



### 3. `gl_PointCoord` 和内置属性

**`gl_PointCoord`：**

- 是片元着色器的内置变量
- 表示当前片元在点精灵内的坐标，范围 [0.0, 1.0]
- 只在绘制 `THREE.Points` 时有效

**其他重要内置属性：**

**顶点着色器：**

- `position` - 顶点位置
- `gl_Position` - 输出的裁剪空间坐标
- `gl_PointSize` - 点大小

**片元着色器：**

- `gl_FragCoord` - 片元在屏幕上的坐标
- `gl_FragColor` - 输出的颜色
- `gl_PointCoord` - 点在点精灵内的坐标



### 4. `blending: THREE.AdditiveBlending` 的作用

**注释掉会有什么改变：**

- **有 AdditiveBlending**：颜色叠加，重叠部分更亮，适合发光效果
- **无 AdditiveBlending**：使用默认混合，重叠部分可能变暗或不透明
- 对于星系效果，AdditiveBlending 能产生更好的发光星云效果



### 5. 三种点形状模式解释

```glsl
// Disc - 实心圆盘
float strength = distance(gl_PointCoord, vec2(.5));
strength = step(.5, strength);  // 距离>0.5返回0，否则返回1
strength = 1.0 - strength;      // 反转：中心1，边缘0

// Diffuse point - 渐变圆
float strength = distance(gl_PointCoord, vec2(.5));
strength *= 2.0;                // 扩大渐变范围
strength = 1.0 - strength;      // 反转：中心亮，边缘暗

// Light point - 光点
float strength = distance(gl_PointCoord, vec2(.5));
strength = 1.0 - strength;      // 中心1，边缘0
strength = pow(strength, 10.0); // 提高对比度，中心更亮
```

**为什么是2.0不是3.0：**

- 2.0是经验值，控制渐变范围
- 3.0会使边缘更暗，中心更小
- 可以根据视觉效果调整

**`pow(strength, 10.0)` 的作用：**

- 指数函数提高对比度
- 值越大，中心亮点越小越亮
- 10.0使得只有非常靠近中心的区域才亮



### 6. 为什么不在片元着色器中直接使用`attribute`，而是通过顶点着色器的 `varying` 传递

**原因：**

- `attribute` 只能在顶点着色器中使用
- `varying` 用于从顶点着色器向片元着色器传递数据
- 颜色需要在每个片元上进行插值





## P33 Modified materials

### 1. 为什么要学习材质效果提升？

在Three.js开发中，我们经常需要给内置材质添加自定义效果（如波浪、扭曲、溶解等），但直接修改Three.js源码是不可行的。本节课教你两种专业方法：

- **Hook注入法**：通过`onBeforeCompile`在材质编译前注入自定义代码
- **重建材质法**：完全重写材质（复杂但灵活）



### 2. 理解着色器修改(Hook注入法)核心思路

Three.js的着色器系统是**模块化**的。它不像一堆散装的代码，而是把不同的功能封装成了一个个的 **`ShaderChunk`（着色器代码块）** 。这就好比搭积木，Three.js在构建一个完整的着色器时，会按需组合这些模块。

所以，你问题的核心答案是：**你不需要去猜测或记忆应该修改哪个文件，而是要通过“打印”和“分析”的方式，找到对应材质着色器的结构，然后在正确的`ShaderChunk`里注入代码。**

具体来说：

- **定位方法**：通过在`material.onBeforeCompile`中打印`shader.vertexShader`和`shader.fragmentShader`，你可以看到当前材质**完整**的、已经组合好的着色器代码。这其中就包含了所有被引入的`ShaderChunk`（例如`#include <begin_vertex>`）。
- **修改逻辑**：你不是直接去`node_modules`里修改源文件，而是在`onBeforeCompile`的回调函数里，通过字符串替换（`replace`方法），在特定的`ShaderChunk`代码块前后**注入**你自己的逻辑。你提供的代码里替换`#include <common>`和`#include <begin_vertex>`等操作就是典型的例子。

下表总结了查找和修改着色器的核心思路：

| 步骤            | 核心方法                                                     | 目的与说明                                                   |
| :-------------- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| **1. 探查结构** | 在`onBeforeCompile`中**打印**`shader.vertexShader`和`shader.fragmentShader` | 获取**当前材质完整的着色器代码**，看清所有`#include`模块。   |
| **2. 选择模块** | **分析**打印出的代码，找到与目标效果相关的`ShaderChunk`      | 例如，做顶点动画，通常关注`begin_vertex`；需要新的Uniform，则需修改`common`。 |
| **3. 注入代码** | 使用`replace`方法，在选定的`ShaderChunk`前后**插入自定义GLSL代码** | 你并非直接修改`node_modules`里的文件，而是在运行时“注入”逻辑。 |

### 3. Hook注入法的常见应用案例

1. **旗帜飘动** - 基于时间的正弦波变换
2. **水面波动** - 复杂的噪声函数
3. **布料模拟** - 物理基础的顶点动画
4. **变形动画** - 形状过渡效果
5. **溶解效果** - 基于噪声的透明度变化



### 4. Hook注入法

#### 1. Three.js着色器系统架构

```text
ShaderLib (材质库)
    ↓
ShaderChunk (代码模块) 
    ↓
Material.onBeforeCompile (编译钩子)
    ↓
Custom Shader Code (自定义代码)
```

#### 2. 着色器注入工作流程

```javascript
// 步骤1：准备自定义uniforms
const customUniforms = { uTime: { value: 0 } };

// 步骤2：在编译前拦截并修改
material.onBeforeCompile = (shader) => {
  // 注入uniforms
  shader.uniforms.uTime = customUniforms.uTime;
  
  // 修改顶点着色器
  shader.vertexShader = modifyVertexShader(shader.vertexShader);
  
  // 修改片段着色器（如果需要）
  shader.fragmentShader = modifyFragmentShader(shader.fragmentShader);
};

// 步骤3：在动画循环中更新uniforms
function animate() {
  customUniforms.uTime.value = elapsedTime;
}
```

### 3. transformed vs position 的区别

```glsl
node_modules/three/src/renderers/shaders/ShaderChunk/begin_vertex.glsl.js

// begin_vertex.glsl.js 中的关键代码
vec3 transformed = vec3( position );
```

**区别**：

- `position`：顶点的**原始坐标**（模型空间），从不改变
- `transformed`：**处理中的顶点坐标**，会被各种变换修改（位移、旋转、缩放等）

**处理流程**：

```text
position (原始) → transformed (处理中) → gl_Position (最终)
```



### 5. 阴影Shadow与深度材质depthMaterial的关系

**关键理解**：

- **默认材质**：用于正常渲染，受光照影响
- **depthMaterial**：用于生成阴影贴图，只关心深度信息
- **Shadow只作用于默认材质**：因为阴影计算基于场景的视觉表现，而不是深度图的原始数据

```javascript
// 你的代码中正确设置了两个材质
const material = new THREE.MeshStandardMaterial({...}); // 视觉材质
const depthMaterial = new THREE.MeshDepthMaterial({...}); // 深度材质
mesh.customDepthMaterial = depthMaterial; // 为阴影指定专用材质
```

**depthMaterial**深度信息确实常用于雾效，但它**最根本的作用是判断“谁在前，谁在后”**。在Three.js的阴影系统里，这个过程分为两步：

1. **生成阴影贴图 (Shadow Map)**：从光源的视角渲染整个场景，但**不关心颜色**，只关心每个像素离光源的**深度**，这个结果就是阴影贴图。
2. **应用阴影**：从相机视角正常渲染时，将每个片元的位置与阴影贴图中的深度值比较，如果它比阴影贴图记录的值离光源更远，就意味着它在阴影里。

现在来看你代码中的两个材质：

- `material` (MeshStandardMaterial): 这是用于**主渲染**的，负责模型的颜色、光照、质感等所有视觉表现。
- `depthMaterial` (MeshDepthMaterial): 这是一个特殊的材质，它**只输出深度信息**。你将它赋值给`customDepthMaterial`，是**告诉Three.js在生成阴影贴图（第一步）时，请用这个材质来渲染我的模型**。

**为什么需要`customDepthMaterial`？**
当你通过着色器修改了顶点位置（比如波浪扭曲）后，用于主渲染的`material`的顶点变化了，但默认用于生成阴影贴图的材质**并不知道这个变化**。这会导致阴影还停留在模型原来的形状上，造成视觉错误。
通过指定一个同样应用了波浪扭曲顶点变换的`depthMaterial`，就能确保**生成阴影贴图时，模型的顶点位置与主渲染中保持一致**，阴影也就正确了。

`customDepthMaterial`是Three.js Mesh的一个**官方支持的属性**，正是为了解决此类问题。



### 6. Hook方法是官方推荐的吗？

**答案**：是的，这是官方支持的扩展方式！

**为什么规范**：

- `onBeforeCompile` 是Three.js**官方API**
- 允许在不修改源码的情况下扩展功能
- 遵循了**开闭原则**（对扩展开放，对修改关闭）
- 广泛应用于Three.js生态中的高级效果



### 7. 代码深度分析

#### 波浪效果实现原理

```javascript
// 1. 定义自定义uniform
const customUniforms = {
  uTime: { value: 0 }
};

// 2. 在材质编译前注入代码
material.onBeforeCompile = (shader) => {
  shader.uniforms.uTime = customUniforms.uTime;
  
  // 3. 注入旋转矩阵函数
  shader.vertexShader = shader.vertexShader.replace(
    "#include <common>",
    `#include <common>
    uniform float uTime;
    mat2 get2dRotateMatrix(float _angle) {
      return mat2(cos(_angle), -sin(_angle), sin(_angle), cos(_angle));
    }`
  );
  
  // 4. 修改法线计算（确保光照正确）
  shader.vertexShader = shader.vertexShader.replace(
    "#include <beginnormal_vertex>",
    `#include <beginnormal_vertex>
    float angle = (sin(position.y + uTime)) * 0.4;
    mat2 rotateMatrix = get2dRotateMatrix(angle);
    objectNormal.xz = rotateMatrix * objectNormal.xz;`
  );
  
  // 5. 修改顶点位置
  shader.vertexShader = shader.vertexShader.replace(
    "#include <begin_vertex>",
    `#include <begin_vertex>
    transformed.xz = rotateMatrix * transformed.xz;`
  );
};
```



### 8. 💡 为何通过材质修改模型形状

这确实是理解上的一个关键点。在3D图形编程中（尤其是在Three.js这类基于WebGL的引擎里），**模型的“形状”是由顶点着色器最终决定的**。

- **几何体 (Geometry)**：提供顶点的**初始数据**（位置、法线、UV等）。
- **顶点着色器 (Vertex Shader)**：负责在GPU上对每个顶点进行**最终的位置变换**。它可以移动顶点。
- **材质 (Material)**：它**包含着色器**（顶点着色器和片元着色器）以及控制着色器行为的**参数**（如Uniforms）。

所以，你的操作 `material.onBeforeCompile`，本质上是**修改了该材质所绑定的顶点着色器**。你在着色器里移动了顶点，自然就改变了模型的形状。这并非“花活”，而是**非常标准且强大的GPU驱动顶点动画的实现方式**。



## P34 Coffee Smoke Shader

### 核心概念理解

#### 噪声纹理 = 二维随机数场

```glsl
float twistPerlin = texture(uPerlinTexture, vec2(.5, uv.y * .2 - uTime * .005)).r;
```

**重要认知**：噪声纹理实际上是一个预计算的二维随机数场，每个纹理坐标对应一个固定的随机值(0-1范围)，通过UV坐标变化获取不同的"随机"数值。



### 资源与工具

#### 噪声纹理制作网站

- [Perlin Noise Maker](http://kitfox.com/projects/perlinNoiseMaker/)
- [Noise Textures](https://opengameart.org/content/700-noise-textures)
- [EffectTextureMaker](https://mebiusbox.github.io/contents/EffectTextureMaker/)

#### 噪声纹理选择规则

- **变化丰富度**：纹理需要足够的细节变化保证真实感
- **分辨率**：至少128×128像素，避免像素化
- **无缝重复**：就是复制一个纹理，放在上下左右都可以完美缝合，这样不会出现纹理突变，使用`THREE.RepeatWrapping`确保纹理边界平滑



### 1. 片元着色器特殊语句

```glsl
#include <tonemapping_fragment>
#include <colorspace_fragment>
```

- `tonemapping_fragment`：色调映射，将HDR颜色转换为显示范围
- `colorspace_fragment`：颜色空间转换，确保颜色显示一致
- 这两句是Three.js内置的着色器模块，不是标准GLSL语法

### 2. Uniforms的正确写法

```javascript
// 推荐写法 - 对象字面量
uniforms: {
    uTime: { value: 0 },
    uPerlinTexture: { value: perlinTexture }
}

// 等价写法 - Uniform构造函数
uniforms: {
    uTime: new THREE.Uniform(0),
    uPerlinTexture: new THREE.Uniform(perlinTexture)
}
```

**两种写法功能完全等效**，但对象字面量更简洁，是社区标准写法。

### 3. GLSL赋值特性

```glsl
vec2 smokeUv = vUv;  // 这是深拷贝
```

在GLSL中，基本类型和向量都是值传递，修改`smokeUv`不会影响原始的`vUv`。

### 4. smoothstep的具体用法和应用场景

**回答**：

- **语法**：`smoothstep(edge0, edge1, x)`

- **作用**：当x < edge0时返回0，x > edge1时返回1，在edge0和edge1之间平滑过渡

- **应用场景**：

  ```glsl
  // 1. 阈值处理：将噪声转换为清晰的形状
  smoke = smoothstep(0.4, 1.0, smoke);
  
  // 2. 边缘淡入淡出：创建自然边界
  smoke *= smoothstep(0.0, 0.1, vUv.x);  // 左边缘淡入
  smoke *= smoothstep(1.0, 0.9, vUv.x);  // 右边缘淡出
  ```

  

### 5. 临时覆盖变量法

```glsl
// Edges
// smoke = 1.0;  // 调试时取消注释，查看完整形状
smoke *= smoothstep(0.0, .1, vUv.x);
```

**调试价值**：

- 快速隔离问题：将复杂效果替换为简单值
- 可视化形状：看到完整的几何体形状
- 逐步调试：逐行测试每个效果



### 6. 透明材质深度写入问题

```javascript
const smokeMaterial = new THREE.ShaderMaterial({
    transparent: true,     // 启用透明度
    depthWrite: false,     // 避免透明物体深度冲突
    side: THREE.DoubleSide // 双面渲染
});
```

**为什么需要`depthWrite: false`**：

- 透明物体的渲染顺序会影响最终效果
- 如果开启深度写入，透明部分可能会错误地遮挡不透明物体
- 关闭深度写入可以避免透明物体之间的深度冲突



## P35















# 附录

## "色调映射在LDR设备上呈现HDR内容"的理解

```javascript
// Three.js内部处理流程：
HDR场景计算 → 色调映射压缩 → LDR显示器输出
```

**具体过程**：

1. **渲染计算**：Three.js在内部使用浮点数计算光照，亮度值可以远大于1.0
2. **范围压缩**：色调映射算法将这些宽范围的亮度值压缩到0-1范围内
3. **显示输出**：压缩后的值发送到只能显示0-255的LDR显示器

**即使没有真正的HDR光源**的含义：

- 在Three.js中，即使你没有显式使用HDR纹理或超强光源
- 渲染引擎内部的**光照计算仍然是浮点精度**的
- 多个光源叠加、反射、折射等效果可能产生>1.0的亮度值
- 因此仍然需要色调映射来处理这些"相对HDR"的内容

------



## 什么是色彩空间？

- **线性色彩空间**：数学上正确的颜色计算
- **sRGB色彩空间**：符合人眼感知和显示设备特性的颜色标准

### 这个设置解决了什么问题？

#### 不设置的情况：

```javascript
// 默认情况：线性色彩空间
renderer.outputEncoding = THREE.LinearEncoding; // 或未设置

// 问题表现：
// - 颜色看起来"发灰"、"褪色"
// - 与Photoshop、Blender等软件显示不一致
// - 暗部细节丢失，整体对比度低
```

#### 设置后的效果：

```javascript
// 设置为sRGB色彩空间
renderer.outputEncoding = THREE.sRGBEncoding;

// 改善效果：
// - 颜色鲜艳、饱和
// - 与设计软件显示一致
// - 更好的对比度和视觉冲击力
```

#### 只设置outputEncoding的问题：

```javascript
// 不完整的设置：
renderer.outputEncoding = THREE.sRGBEncoding;

// 可能的问题：
// - 输入纹理仍在sRGB空间，但被当作线性处理
// - 导致颜色计算错误（过饱和或过暗）
// - 双重伽马校正或缺少校正
```

------



## 主要色彩空间类型：

**但在日常使用中，主要是在线性色彩空间和sRGB色彩空间之间选择**。

```javascript
// Three.js 中的色彩空间选项
THREE.LinearEncoding      // 线性色彩空间
THREE.sRGBEncoding        // sRGB色彩空间 (最常用)
THREE.RGBEEncoding        // RGBE格式 (HDR)
THREE.RGBM7Encoding       // RGBM7格式 (HDR)
THREE.RGBDEncoding        // RGBD格式 (HDR)
THREE.GammaEncoding       // 自定义伽马编码
THREE.BasicDepthPacking   // 深度打包
THREE.RGBADepthPacking    // RGBA深度打包
```

------



## 什么是伽马校正？

伽马校正是一个**双向过程**：

```javascript
// 完整的伽马校正流程：
sRGB纹理 → [sRGB转线性] → 线性计算 → [线性转sRGB] → 显示器
    输入校正                 渲染         输出校正
```

------





## `precision mediump float;` 是什么

### 什么是精度限定符？

精度限定符定义了浮点数在GPU中的存储和计算精度，影响性能和质量。

### 三种精度级别

```glsl
// 高精度 - 32位浮点数，最精确但性能最低
precision highp float;

// 中精度 - 16位浮点数，平衡性能与质量
precision mediump float;

// 低精度 - 10位或更少，性能最高但精度最低
precision lowp float;
```



### 为什么需要声明精度？

- **移动设备兼容性**：有些设备要求显式声明精度
- **性能优化**：低精度计算更快，功耗更低
- **内存节省**：低精度变量占用更少内存

### 实际应用场景

```glsl
// 片元着色器必须声明默认精度
precision mediump float;

uniform sampler2D uTexture;
varying vec2 vUv;

void main() {
    // 颜色计算使用中精度足够
    vec4 color = texture2D(uTexture, vUv);
    gl_FragColor = color;
}
```

------



### 为什么修改的是 `modelPosition`？

### 图形渲染的坐标系转换流程

```text
局部坐标 → 世界坐标 → 视图坐标 → 裁剪坐标 → 屏幕坐标
    ↓         ↓         ↓          ↓          ↓
 position → modelMatrix → viewMatrix → projectionMatrix → gl_Position
```



#### 坐标转换链分析

```glsl
void main() {
    // 1. 局部坐标 → 世界坐标
    vec4 modelPosition = modelMatrix * vec4(position, 1.0);
    
    // ★ 在这里修改最合理！因为：
    // - 仍然在世界坐标系中，便于理解
    // - 不受相机视角影响
    // - 可以基于世界坐标进行物理模拟
    modelPosition.z += sin(modelPosition.x * 10.0) * 0.1;
    
    // 2. 世界坐标 → 视图坐标（相机空间）
    vec4 viewPosition = viewMatrix * modelPosition;
    
    // 3. 视图坐标 → 裁剪坐标
    vec4 projectedPosition = projectionMatrix * viewPosition;
    
    gl_Position = projectedPosition;
}
```



### 各坐标系详解

#### 1. 局部坐标 (Local Space / Model Space)

```glsl
// 顶点在模型自身的坐标系中的位置
attribute vec3 position;  // 例如：(0, 0, 0) 表示模型中心
```



**特点**：

- 相对于模型自身原点
- 不知道模型在场景中的位置
- 适合模型自身的变形动画

#### 2. 世界坐标 (World Space)

```glsl
vec4 modelPosition = modelMatrix * vec4(position, 1.0);
```



**modelMatrix 包含**：

- 平移：物体在场景中的位置
- 旋转：物体的朝向
- 缩放：物体的大小

**为什么在这里修改**：

```glsl
// 示例：基于世界坐标的波浪效果
float wave = sin(modelPosition.x * frequency + time);
modelPosition.y += wave * amplitude;

// 这样修改的好处：
// 1. 波浪基于世界位置，不受物体移动影响
// 2. 多个物体可以共享相同的波浪参数
// 3. 物理上更合理
```



#### 3. 视图坐标 (View Space / Camera Space)

```glsl
vec4 viewPosition = viewMatrix * modelPosition;
```



**viewMatrix 包含**：

- 相机位置和朝向
- 将世界坐标转换到以相机为原点的坐标系

**为什么不在这里修改**：

```glsl
// 如果在视图坐标中修改：
viewPosition.z += 1.0;  // 这会改变深度，但基于相机空间

// 问题：
// - 难以理解效果（相对于相机）
// - 不便于物理模拟
// - 相机移动时效果会变化
```



#### 4. 裁剪坐标 (Clip Space)

```glsl
vec4 projectedPosition = projectionMatrix * viewPosition;
```



**projectionMatrix 作用**：

- 应用透视或正交投影
- 将3D坐标映射到2D标准化设备坐标
- 定义视锥体（可见范围）

**绝对不要在这里修改**：

```glsl
// 错误示例：
projectedPosition.x += 0.1;  // 这会破坏投影变换

// 后果：
// - 透视失真
// - 深度测试错误
// - 可能超出裁剪范围
```

------



## random代码

```
// 假随机数，因为刷新并不会更新随机值
float random(vec2 st) {
  return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}
```

------



## rotate代码

```
vec2 rotate(vec2 uv, float rotation, vec2 mid) {
  return vec2(cos(rotation) * (uv.x - mid.x) + sin(rotation) * (uv.y - mid.y) + mid.x, cos(rotation) * (uv.y - mid.y) - sin(rotation) * (uv.x - mid.x) + mid.y);
}
```

------

## Classic Perlin 2D Noise 

[来源网站，但是有可能打不开](https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83)

```
//	Classic Perlin 2D Noise 
//	by Stefan Gustavson
//
vec4 permute(vec4 x) {
  return mod(((x * 34.0) + 1.0) * x, 289.0);
}

vec2 fade(vec2 t) {
  return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float cnoise(vec2 P) {
  vec4 Pi = floor(P.xyxy) + vec4(0.0, 0.0, 1.0, 1.0);
  vec4 Pf = fract(P.xyxy) - vec4(0.0, 0.0, 1.0, 1.0);
  Pi = mod(Pi, 289.0); // To avoid truncation effects in permutation
  vec4 ix = Pi.xzxz;
  vec4 iy = Pi.yyww;
  vec4 fx = Pf.xzxz;
  vec4 fy = Pf.yyww;
  vec4 i = permute(permute(ix) + iy);
  vec4 gx = 2.0 * fract(i * 0.0243902439) - 1.0; // 1/41 = 0.024...
  vec4 gy = abs(gx) - 0.5;
  vec4 tx = floor(gx + 0.5);
  gx = gx - tx;
  vec2 g00 = vec2(gx.x, gy.x);
  vec2 g10 = vec2(gx.y, gy.y);
  vec2 g01 = vec2(gx.z, gy.z);
  vec2 g11 = vec2(gx.w, gy.w);
  vec4 norm = 1.79284291400159 - 0.85373472095314 * vec4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11));
  g00 *= norm.x;
  g01 *= norm.y;
  g10 *= norm.z;
  g11 *= norm.w;
  float n00 = dot(g00, vec2(fx.x, fy.x));
  float n10 = dot(g10, vec2(fx.y, fy.y));
  float n01 = dot(g01, vec2(fx.z, fy.z));
  float n11 = dot(g11, vec2(fx.w, fy.w));
  vec2 fade_xy = fade(Pf.xy);
  vec2 n_x = mix(vec2(n00, n01), vec2(n10, n11), fade_xy.x);
  float n_xy = mix(n_x.x, n_x.y, fade_xy.y);
  return 2.3 * n_xy;
}
```



------

## Pattern 28这两种区别在哪里，为什么使用length是减呢，不应该是加吗

这两种写法在功能上**完全等价**，没有本质区别，最终都会计算`vUv`到中心点`(0.5, 0.5)`的欧氏距离。至于为什么用 “减” 而不是 “加”，核心是由 “距离的数学定义” 决定的。

### 1. 先明确两个函数的关系

GLSL 中：

- `distance(a, b)` 是专门计算两点距离的内置函数，其底层实现就是 `length(a - b)`（即先求两点的向量差，再计算该向量的长度）。
- `length(v)` 是计算向量`v`长度的函数（对二维向量而言，就是`sqrt(v.x² + v.y²)`）。

因此，`distance(vUv, vec2(0.5))` 等价于 `length(vUv - vec2(0.5))`。你代码中写的 `length(vUv - .5)` 其实是简写 —— 因为`vUv`是`vec2`类型（二维向量），`.5`会被**隐式转换**为`vec2(0.5, 0.5)`，所以和`length(vUv - vec2(0.5))`完全一样。

### 2. 为什么是 “减” 而不是 “加”？

距离的本质是 “两点之间的直线长度”，数学上需要通过**向量差**计算：

假设`vUv`是点`A(x1, y1)`，中心点是`B(0.5, 0.5)`，那么：

- 从`B`到`A`的向量是 `A - B = (x1 - 0.5, y1 - 0.5)`（向量减法）；
- 这个向量的长度（即`A`到`B`的距离）就是 `sqrt((x1-0.5)² + (y1-0.5)²)`，也就是`length(A - B)`。

如果用 “加”（`A + B`），得到的向量是`(x1+0.5, y1+0.5)`，其长度和 “两点距离” 毫无关系（比如两点重合时，加法结果的长度是`sqrt(0.5² + 0.5²)`，显然不是 0）。

------



## float angle = atan(vUv.x, vUv.y)详解

这行代码用于计算**纹理坐标点`vUv`相对于原点`(0,0)`的角度**，具体含义和细节如下：

### 1. `atan()`双参数版本的作用

GLSL 中的`atan(y, x)`是双参数反正切函数（等价于数学中的`atan2(y, x)`），用于计算**从正 x 轴到向量`(x, y)`的角度**（极坐标中的角度`θ`），返回值是弧度，范围通常为`[-π, π]`（即`[-180°, 180°]`）。

但你这里的参数是`atan(vUv.x, vUv.y)`，即**第一个参数是`x`，第二个参数是`y`**，相当于计算的是`atan2(x, y)`，角度的参考轴会发生变化：

- 此时角度是**从正 y 轴开始计算**的（而非正 x 轴），逆时针旋转为正方向。

### 2. 结合`vUv`的具体含义

`vUv`是纹理坐标（`vec2`类型），`vUv.x`是水平分量（x 轴），`vUv.y`是垂直分量（y 轴），默认范围通常是`[0, 1]`（即点`vUv`位于以`(0,0)`为左下角、`(1,1)`为右上角的单位矩形内）。

因此，`atan(vUv.x, vUv.y)`的本质是：计算从原点`(0,0)`到当前纹理坐标点`(vUv.x, vUv.y)`的向量，与**正 y 轴**之间的夹角（逆时针为正）。

### 3. 举例理解角度范围

假设`vUv`在单位矩形内（`x,y ∈ [0,1]`），几个典型点的角度如下：

- 当`vUv = (0, 1)`（正上方）：向量是`(0,1)`，与正 y 轴同向，角度`angle = 0`；
- 当`vUv = (1, 1)`（右上方）：向量是`(1,1)`，从正 y 轴逆时针转 45°，角度`angle = π/4`（45°）；
- 当`vUv = (1, 0)`（正右方）：向量是`(1,0)`，从正 y 轴逆时针转 90°，角度`angle = π/2`（90°）；
- 当`vUv = (0, 0)`（原点）：向量为零，角度无意义（通常返回 0 或未定义，需避免）。

### 关键区别：参数顺序的影响

- 标准`atan(y, x)`（即`atan2(y, x)`）：角度参考正 x 轴，常用于极坐标转换（`x = r·cosθ, y = r·sinθ`）；
- 你这里的`atan(x, y)`：角度参考正 y 轴，适合需要以垂直方向为基准的旋转计算（比如模拟径向对称的纹理，如漩涡、雷达扫描线等）。

总之，这行代码的核心是**获取纹理坐标点相对于原点的 “方向角”**，具体参考轴由参数顺序决定，常用于生成旋转对称的视觉效果（如环形渐变、扇形分区等）。

------



## Pattern 42 和 Pattern 43  的区别详解

这两个模式的核心区别在于对角度值的**范围处理**：Pattern 42 直接使用原始角度值，而 Pattern 43 通过数学变换将角度归一化到`[0, 1]`范围，更适合作为 “强度值”（如颜色、透明度等）使用。

### 先明确共同的起点：角度的原始范围

两行代码的第一句都是：`float angle = atan(vUv.x - .5, vUv.y - .5);`

这里的`vUv.x - .5`和`vUv.y - .5`是将纹理坐标从 “以`(0,0)`为原点” 转换为 “以`(0.5, 0.5)`为中心点”（即纹理中心），因此`angle`计算的是**当前像素到纹理中心的向量，与正 y 轴的夹角**（参考之前对`atan`的解释）。

这个原始`angle`的取值范围是 **`[-π, π]`**（约`[-3.14, 3.14]`弧度），对应从正 y 轴顺时针旋转 180° 到逆时针旋转 180° 的全范围。

### Pattern 42：直接使用原始角度作为`strength`

```
float strength = angle;
```

此时`strength`的范围和`angle`一致，即`[-π, π]`（约`[-3.14, 3.14]`）。

在着色器中，颜色 / 强度值通常需要在`[0, 1]`范围内（超出部分会被截断为 0 或 1），因此这个`strength`直接用于颜色时会出现问题：

- 负值部分（`[-π, 0)`）会被当作 0 处理；
- 正值部分（`[0, π]`）中，超过 1 的部分（约`[1, 3.14]`）会被当作 1 处理；
- 最终视觉上会丢失大部分角度信息，只保留`[0, 1]`区间内的微弱变化，效果不直观。

### Pattern 43：将角度归一化到`[0, 1]`范围

通过两步转换：

1. `angle /= PI * 2.0;`原始角度范围`[-π, π]`除以`2π`后，范围变为`[-0.5, 0.5]`（因为`π/(2π)=0.5`，`-π/(2π)=-0.5`）。
2. `angle += .5;`加上 0.5 后，范围从`[-0.5, 0.5]`偏移到`[0, 1]`。

最终`strength = angle`的范围是 **`[0, 1]`**，完美匹配着色器中颜色 / 强度的常用范围。

### 两者的视觉效果差异

- Pattern 42：由于原始角度范围超出`[0,1]`，直接显示会导致大部分区域颜色相同（被截断），只能看到角度在`[-1, 1]`附近的微弱变化，效果混乱。
- Pattern 43：角度被均匀映射到`[0,1]`，从纹理中心看，角度变化会对应`strength`从 0 到 1 的平滑过渡（例如：正上方为 0，顺时针旋转到正右方为 0.25，正下方为 0.5，正左方为 0.75，回到正上方为 1），适合生成环形渐变、雷达扫描线等有规律的径向效果。

------

## 2D噪声 vs 3D噪声

| 类型       | 输入        | 输出       | 应用场景             | 特点                   |
| :--------- | :---------- | :--------- | :------------------- | :--------------------- |
| **2D噪声** | (x,y)坐标   | 单一高度值 | 地形高度图、平面纹理 | 只能表现**表面**       |
| **3D噪声** | (x,y,z)坐标 | 空间密度值 | 云朵、烟雾、洞穴     | 表现**体积**和内部结构 |

**通俗理解**：

- 2D噪声就像在纸上画画，只有表面
- 3D噪声就像雕刻石头，有厚度和内部结构



------

## 3D柏林噪声源码

```
// Classic Perlin 3D Noise 
// by Stefan Gustavson
//
vec4 permute(vec4 x) {
  return mod(((x * 34.0) + 1.0) * x, 289.0);
}
vec4 taylorInvSqrt(vec4 r) {
  return 1.79284291400159 - 0.85373472095314 * r;
}
vec3 fade(vec3 t) {
  return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float cnoise(vec3 P) {
  vec3 Pi0 = floor(P); // Integer part for indexing
  vec3 Pi1 = Pi0 + vec3(1.0); // Integer part + 1
  Pi0 = mod(Pi0, 289.0);
  Pi1 = mod(Pi1, 289.0);
  vec3 Pf0 = fract(P); // Fractional part for interpolation
  vec3 Pf1 = Pf0 - vec3(1.0); // Fractional part - 1.0
  vec4 ix = vec4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
  vec4 iy = vec4(Pi0.yy, Pi1.yy);
  vec4 iz0 = Pi0.zzzz;
  vec4 iz1 = Pi1.zzzz;

  vec4 ixy = permute(permute(ix) + iy);
  vec4 ixy0 = permute(ixy + iz0);
  vec4 ixy1 = permute(ixy + iz1);

  vec4 gx0 = ixy0 / 7.0;
  vec4 gy0 = fract(floor(gx0) / 7.0) - 0.5;
  gx0 = fract(gx0);
  vec4 gz0 = vec4(0.5) - abs(gx0) - abs(gy0);
  vec4 sz0 = step(gz0, vec4(0.0));
  gx0 -= sz0 * (step(0.0, gx0) - 0.5);
  gy0 -= sz0 * (step(0.0, gy0) - 0.5);

  vec4 gx1 = ixy1 / 7.0;
  vec4 gy1 = fract(floor(gx1) / 7.0) - 0.5;
  gx1 = fract(gx1);
  vec4 gz1 = vec4(0.5) - abs(gx1) - abs(gy1);
  vec4 sz1 = step(gz1, vec4(0.0));
  gx1 -= sz1 * (step(0.0, gx1) - 0.5);
  gy1 -= sz1 * (step(0.0, gy1) - 0.5);

  vec3 g000 = vec3(gx0.x, gy0.x, gz0.x);
  vec3 g100 = vec3(gx0.y, gy0.y, gz0.y);
  vec3 g010 = vec3(gx0.z, gy0.z, gz0.z);
  vec3 g110 = vec3(gx0.w, gy0.w, gz0.w);
  vec3 g001 = vec3(gx1.x, gy1.x, gz1.x);
  vec3 g101 = vec3(gx1.y, gy1.y, gz1.y);
  vec3 g011 = vec3(gx1.z, gy1.z, gz1.z);
  vec3 g111 = vec3(gx1.w, gy1.w, gz1.w);

  vec4 norm0 = taylorInvSqrt(vec4(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
  g000 *= norm0.x;
  g010 *= norm0.y;
  g100 *= norm0.z;
  g110 *= norm0.w;
  vec4 norm1 = taylorInvSqrt(vec4(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
  g001 *= norm1.x;
  g011 *= norm1.y;
  g101 *= norm1.z;
  g111 *= norm1.w;

  float n000 = dot(g000, Pf0);
  float n100 = dot(g100, vec3(Pf1.x, Pf0.yz));
  float n010 = dot(g010, vec3(Pf0.x, Pf1.y, Pf0.z));
  float n110 = dot(g110, vec3(Pf1.xy, Pf0.z));
  float n001 = dot(g001, vec3(Pf0.xy, Pf1.z));
  float n101 = dot(g101, vec3(Pf1.x, Pf0.y, Pf1.z));
  float n011 = dot(g011, vec3(Pf0.x, Pf1.yz));
  float n111 = dot(g111, Pf1);

  vec3 fade_xyz = fade(Pf0);
  vec4 n_z = mix(vec4(n000, n100, n010, n110), vec4(n001, n101, n011, n111), fade_xyz.z);
  vec2 n_yz = mix(n_z.xy, n_z.zw, fade_xyz.y);
  float n_xyz = mix(n_yz.x, n_yz.y, fade_xyz.x);
  return 2.2 * n_xyz;
}
```

------



## 什么是 `vElevation`？

`vElevation` 是从顶点着色器传递到片元着色器的**水面高度数据**：

- 每个顶点都有不同的高度值
- 波峰处值较大，波谷处值较小
- 通过这个高度变化来决定颜色：高处用表面色，低处用深水色

------



## 为什么使用 `(vElevation + uColorOffset) * uColorMultiplier`？

**问题背景**: 原始高程值范围很小（如[-0.2, 0.2]），直接混合颜色变化不明显。

**解决方案分析**:

- **先加后乘 vs 先乘后加**:

  glsl

  ```glsl
  // 方案A：先加后乘（作者选择）
  (vElevation + uColorOffset) * uColorMultiplier
  
  // 方案B：先乘后加  
  vElevation * uColorMultiplier + uColorOffset
  ```

**为什么选择方案A**:

1. **物理意义更清晰**:
   - `uColorOffset`: 确定颜色开始变化的基准点（相当于"海平面"调整）
   - `uColorMultiplier`: 控制颜色过渡的剧烈程度
2. **视觉效果更自然**:
   - 保持原有的波形分布形状，只是平移并拉伸
   - 避免过度放大噪声产生不自然的硬边
3. **参数调节更直观**:
   - 偏移量控制颜色分层位置
   - 乘数控制分层对比度

------

