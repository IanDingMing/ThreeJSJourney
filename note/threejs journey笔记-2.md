## P27  Realistic render 真实渲染

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



## P30 Shaders patterns 着色器图案

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

[`mod(x, y)`详解](#`mod(x, y)`详解)

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



## P31 Raging sea 海洋

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



## P32 Animated galaxy 转动星系

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





## P33 Modified materials 材质修改

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



## P34 Coffee Smoke Shader 一杯咖啡

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



## P35 Hologram Shader 全息材质

### 1. 菲涅耳效应详解

### **核心原理**

菲涅耳效应描述：**观察角度越倾斜，表面反射越强**

#### 在着色器中的实现

```glsl
// Fresnel 计算
// 计算视线与法线的夹角
vec3 viewDirection = normalize(vPosition - cameraPosition);
float fresnel = dot(viewDirection, vNormal);  // 范围[-1, 1]
fresnel = pow(fresnel, 2.0);  // 调整效果强度
```

#### **参数控制效果**

```glsl
// 指数越小（如1.0）：发光边缘越宽，效果柔和
fresnel = pow(fresnel, 1.0);

// 指数越大（如3.0）：发光边缘越窄，效果锐利
fresnel = pow(fresnel, 3.0);
```

#### **可视化理解**

```text
视线方向与表面法线关系：
- 正面观察：夹角0°，fresnel=1，反射最弱
- 侧面观察：夹角90°，fresnel=0，反射中等
- 边缘观察：夹角接近180°，fresnel→1，反射最强
```

#### 使用场景

1. **边缘发光效果** - 物体边缘产生光晕
2. **水材质** - 模拟水面反射随角度变化
3. **玻璃材质** - 实现真实的折射反射变化
4. **全息效果** - 当前场景的主要应用



### 2. 法向量变换中的 0.0 与 1.0 区别

```glsl
// 法向量变换 - 使用 0.0
vec4 modelNormal = modelMatrix * vec4(normal, 0.0);

// 位置变换 - 使用 1.0  
vec4 modelPosition = modelMatrix * vec4(position, 1.0);
```

**区别说明：**

- **0.0**：表示方向向量，不受平移变换影响
- **1.0**：表示位置坐标，受完整变换矩阵影响

**数学原理：**

```text
变换矩阵 M = [旋转/缩放 | 平移]
            [  0 0 0   |  1  ]

vec4(normal, 0.0) × M = 只受旋转/缩放影响
vec4(position, 1.0) × M = 受完整变换影响
```



### 3. normalize() 使用场景详解

#### 基本概念

`normalize()` 将向量转换为**单位向量**（长度为1），保持方向不变。

```glsl
vec3 unitVector = normalize(originalVector);
```

#### 主要使用场景

##### 3.1 光照计算（最常用）

```glsl
// 光照方向
vec3 lightDir = normalize(lightPosition - fragmentPosition);

// 视线方向  
vec3 viewDir = normalize(cameraPosition - fragmentPosition);

// 法向量标准化
vec3 normal = normalize(vNormal);

// 点积计算光照
float diffuse = max(dot(normal, lightDir), 0.0);
```

##### 3.2 菲涅耳效应计算

```glsl
vec3 viewDirection = normalize(vPosition - cameraPosition);
float fresnel = dot(viewDirection, normal);
```

##### 3.3 反射/折射计算

```
vec3 reflectDir = normalize(reflect(incidentDir, normal));
vec3 refractDir = normalize(refract(incidentDir, normal, refractiveIndex));
```



#### 为什么需要 normalize？

##### 点积计算的准确性

```glsl
// 错误示例：向量长度影响结果
vec3 A = vec3(2.0, 0.0, 0.0);  // 长度=2
vec3 B = vec3(1.0, 0.0, 0.0);  // 长度=1  
float wrongDot = dot(A, B);     // 结果=2，不是纯角度关系

// 正确示例：单位向量确保准确
vec3 A_norm = normalize(A);     // 变成(1.0, 0.0, 0.0)
vec3 B_norm = normalize(B);     // 变成(1.0, 0.0, 0.0)
float correctDot = dot(A_norm, B_norm); // 结果=1，准确反映同方向
```

#### normalize 使用指南

##### 需要 normalize 的情况：

✅ **所有方向向量**（光照、视线、反射方向）
✅ **插值后的法向量**（顶点→片段插值会改变长度）
✅ **任意需要纯方向信息的场合**

##### 不需要 normalize 的情况：

❌ **位置坐标**（本身就是绝对位置）
❌ **颜色值**（RGB已经是0-1范围）
❌ **纯标量计算**（不涉及角度关系）
❌ **长度本身就有意义的情况**（如距离计算）

##### 性能优化：

```glsl
// 方案1：顶点着色器提前计算
varying vec3 vNormal;

void main() {
    vNormal = normalize(modelNormal.xyz); // 提前normalize
}

// 方案2：片段着色器按需计算
void main() {
    vec3 normal = normalize(vNormal); // 确保插值后准确性
}
```



## P36 Fireworks Shaders 落日烟花

### 1. 点精灵（Point Sprites）系统

#### 1.1 为什么使用 gl_PointCoord 而不是 uv 坐标？

在点精灵中，我们使用内置的`gl_PointCoord`来获取纹理坐标，而不是传统的uv坐标。

**着色器中的区别：**

```glsl
// ❌ 错误：点精灵没有传统uv坐标
vec4 color = texture2D(uTexture, vUv);

// ✅ 正确：使用点精灵专用坐标
vec4 color = texture(uTexture, gl_PointCoord);
```

**原因：**

- `gl_PointCoord`：点精灵内置，范围[0,1]，表示当前片元在点精灵内的相对位置
- `vUv`：需要手动计算传递，适用于普通网格



#### 1.2 点精灵是什么？

**点精灵**是图形学中的一种特殊渲染技术：

```javascript
// Three.js 中的点精灵就是 Points 对象
const points = new THREE.Points(geometry, material);
```

**特点：**

- 每个"点"实际上是一个始终面向相机的四边形
- 不需要复杂的几何体，性能高效
- 内置纹理坐标系统（gl_PointCoord）
- 常用于粒子系统、星空、雨雪效果

**示例：**

```javascript
// 创建点精灵粒子系统
const geometry = new THREE.BufferGeometry();
const positions = new Float32Array(particleCount * 3);
// ... 设置位置数据
geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));

const material = new THREE.PointsMaterial({
  size: 10,
  map: texture,  // 每个点都会显示这个纹理
  transparent: true
});

const particles = new THREE.Points(geometry, material);
```



### 2. 纹理采样函数区别

### texture2D vs texture

```glsl
// WebGL 1.0 ( ES 1.0)
texture2D(sampler2D, coord)
textureCube(samplerCube, coord)

// WebGL 2.0 ( ES 3.0) - 统一语法
texture(sampler2D, coord)
texture(samplerCube, coord)
texture(sampler3D, coord)
```

**现代开发建议使用统一的`texture`函数。**



### 3. Spherical 和 Sphere 的区别

#### 3.1 Spherical（球面坐标系统）

```javascript
// 球面坐标用三个参数描述三维空间中的点：
const spherical = new THREE.Spherical(
  radius,    // 半径 - 距离原点的距离
  phi,       // 极角 - 从Y轴正方向开始的角度（0 到 π）
  theta      // 方位角 - 在XZ平面上的角度（0 到 2π）
);
```

**为什么 phi 的范围是 0 到 π？**

- `phi = 0`：在Y轴正方向（北极）
- `phi = π/2`：在赤道平面
- `phi = π`：在Y轴负方向（南极）

这覆盖了整个球面的上下方向。



#### 3.2 Sphere（球体对象）

```javascript
// 这是一个实际的3D几何体
const sphere = new THREE.SphereGeometry(radius, widthSegments, heightSegments);
```

**总结区别：**

- **Spherical**：坐标系统，用于在球面上定位点
- **Sphere**：3D几何体，用于创建可视的球体模型



### 4. 动画系统：GSAP + Three.js + 着色器

#### 4.1 GSAP 工作原理

```javascript
gsap.to(target, {
  value: 1,        // 目标值
  duration: 3,     // 持续时间
  ease: "linear",  // 缓动函数
  onUpdate: function() {
    // 每帧回调 - 这里可以更新uniform
    console.log(target.value); // 这个值在3秒内从当前值线性变化到1
  }
});
```



#### 4.2 完整的动画流程

```javascript
// 1. GSAP 更新  层面的 uniform 值
gsap.to(material.uniforms.uProgress, {
    value: 1,
    duration: 3,
    ease: "linear"
});

// 2. Three.js 的渲染循环检测到 uniform 变化
function animate() {
    requestAnimationFrame(animate);
    
    // Three.js 自动：
    // - 检测 material.uniforms 的变化
    // - 将更新的 uniform 值发送到 GPU
    // - 触发重新渲染
    renderer.render(scene, camera);
}

// 3. 在着色器中，使用更新的 uniform 计算新位置
// 顶点着色器：
void main() {
    float progress = uProgress; // 这个值每帧都在变化
    vec3 newPosition = position * progress;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(newPosition, 1.0);
}
```



#### 4.3 各组件的作用

**GSAP 的作用：**

```javascript
// GSAP 只做这一件事：
material.uniforms.uProgress.value = 当前动画值; // 随时间从0变到1
```

**Three.js 的作用：**

```javascript
// 在 render() 调用时，Three.js 自动：
if (material.uniformsNeedUpdate) {
    // 将  中的 uniform 值发送到 GPU
    gl.uniform1f(uProgressLocation, material.uniforms.uProgress.value);
}
```

**着色器的作用：**

```glsl
// GPU 每帧执行着色器，使用最新的 uniform 值
// 这就是动画发生的根本原因！
```

#### 为什么说"Three.js 没有应用这种更新"？

**Three.js 负责传递更新，但动画逻辑在着色器中**

```javascript
// ❌ 错误理解：Three.js 直接移动顶点
// ✅ 正确理解：Three.js 传递数值，着色器计算移动
```



### 5. remap 函数详解

#### 5.1 remap 函数定义

```glsl
float remap(float value, float originMin, float originMax, float destinationMin, float destinationMax) {
    return destinationMin + (value - originMin) * (destinationMax - destinationMin) / (originMax - originMin);
}
```



#### 5.2 remap 的核心功能：值域转换

```glsl
// 示例1：将 [0,1] 映射到 [0,100]
float result = remap(uProgress, 0.0, 1.0, 0.0, 100.0);

// 示例2：将 [0.5,1] 映射到 [0,1] - 延迟启动效果
float delayedProgress = remap(uProgress, 0.5, 1.0, 0.0, 1.0);

// 示例3：反向映射 [0,1] 到 [1,0]
float reverseProgress = remap(uProgress, 0.0, 1.0, 1.0, 0.0);
```



#### 5.3 在烟花代码中的具体作用

```glsl
// 将 uProgress 的 [0,0.1] 范围映射到 [0,1] 范围
float explodingProgress = remap(uProgress, .0, .1, .0, 1.0);
```

这意味着：

- 当动画进行到 10% 时，爆炸效果就已经完成了 100%
- 这是一种"快速启动"的效果，不是均匀的渐变

**要获得真正的渐变效果，可以：**

```glsl
// 方法1：直接使用原始进度
float explodingProgress = uProgress;

// 方法2：使用完整的重映射范围
float explodingProgress = remap(uProgress, 0.0, 1.0, 0.0, 1.0);

// 方法3：使用缓动函数获得更自然的效果
float explodingProgress = sin(uProgress * 3.14159 * 0.5); // 缓入效果
```



### 6. 烟花效果阶段分解

#### 6.1 时间分段控制

```glsl
// 爆炸阶段：只在 progress 的 [0, 0.1] 范围内生效
float explodingProgress = remap(progress, .0, .1, .0, 1.0);
explodingProgress = clamp(explodingProgress, .0, 1.0);

// 下落阶段：只在 progress 的 [0.1, 1.0] 范围内生效  
float fallingProgress = remap(progress, .1, 1.0, .0, 1.0);
fallingProgress = clamp(fallingProgress, .0, 1.0);
```



#### 6.2 为什么不会叠加？

**因为每个阶段只在特定的时间区间内有效：**

```text
时间轴: 0.0 --------- 0.1 --------- 0.2 --------- 0.8 --------- 1.0
        |             |             |             |             |
       爆炸阶段        下落阶段开始    闪烁阶段开始    闪烁阶段结束    动画结束
       ↓             ↓             ↓             ↓             ↓
       exploding     falling       twinkling     twinkling     done
       only         active        active        ends
```

**具体分析：**

```glsl
// 当 progress = 0.05 时：
explodingProgress = remap(0.05, 0.0, 0.1, 0.0, 1.0) = 0.5  // ✅ 生效
fallingProgress = remap(0.05, 0.1, 1.0, 0.0, 1.0) = -0.055... // ❌ clamp后=0

// 当 progress = 0.5 时：
explodingProgress = remap(0.5, 0.0, 0.1, 0.0, 1.0) = 5.0 // ❌ clamp后=1.0
fallingProgress = remap(0.5, 0.1, 1.0, 0.0, 1.0) = 0.444... // ✅ 生效
```



#### 6.3 各阶段详细时间线

```glsl
// 爆炸阶段 (0.0 - 0.1)
// 粒子从中心向外扩散
newPosition *= explodingProgress;  // 0 → 1

// 下落阶段 (0.1 - 1.0)  
// 粒子受重力下落
newPosition.y -= fallingProgress * 0.2;  // 0 → -0.2

// 缩放阶段 (全程，但有峰值)
// 0.0-0.125: 逐渐变大
// 0.125-1.0: 逐渐变小
float sizeProgress = min(sizeOpeningProgress, sizeClosingProgress);

// 闪烁阶段 (0.2 - 0.8)
// 粒子大小闪烁变化
float sizeTwinkling = 1.0 - sizeTwinkling * twinklingProgress;
```



#### 6.4 视觉上的"续接"效果

**这是因为每个阶段处理不同的属性：**

- **爆炸阶段**：只影响 `position`（位置扩散）
- **下落阶段**：只影响 `position.y`（垂直下落）
- **缩放阶段**：只影响 `gl_PointSize`（粒子大小）
- **闪烁阶段**：只影响 `gl_PointSize`（大小闪烁）

**它们不是数学叠加，而是逻辑上的接力：**

```text
时间: 0.0-0.1    | 0.1-0.2       | 0.2-0.8         | 0.8-1.0
     ↓           ↓              ↓                ↓
     爆炸完成     下落开始+缩放    下落+缩放+闪烁     下落+缩放
     位置固定     位置继续下落     位置下落+大小闪烁   位置继续下落
```



#### 6.5 关键设计思想

**状态机思维：**

```glsl
// 伪代码表示状态转换
if (progress < 0.1) {
    // 状态1: 爆炸
    position = explode(position);
} else if (progress < 0.2) {
    // 状态2: 下落开始
    position = fall(position);
    size = scale(size);
} else if (progress < 0.8) {
    // 状态3: 下落+闪烁
    position = fall(position); 
    size = scale(size) * twinkle();
} else {
    // 状态4: 下落结束
    position = fall(position);
    size = scale(size);
}
```



#### 6.6 为什么不是叠加？

如果是叠加，代码会是这样：

```glsl
// ❌ 错误示例：所有效果全程叠加
newPosition *= progress;           // 爆炸全程
newPosition.y -= progress * 0.2;   // 下落全程  
// 这样会导致混乱的效果
```

而正确的代码是：

```glsl
// ✅ 正确示例：分时段生效
newPosition *= explodingProgress;  // 只在0-10%生效
newPosition.y -= fallingProgress * 0.2; // 只在10-100%生效
```



### 7. 缩放阶段的巧妙设计

#### 7.1 为什么 `sizeClosingProgress` 映射到 1-0？

```glsl
float sizeClosingProgress = remap(progress, .125, 1.0, 1.0, .0);
```

**这是为了创建"先放大后缩小"的效果：**

**数学原理：**

```text
当 progress = 0.125 时：remap(0.125, 0.125, 1.0, 1.0, 0.0) = 1.0
当 progress = 0.5 时：   remap(0.5, 0.125, 1.0, 1.0, 0.0) = 0.57
当 progress = 1.0 时：   remap(1.0, 0.125, 1.0, 1.0, 0.0) = 0.0
```

**视觉效果：**

```text
时间: 0.0 → 0.125 → 0.5 → 1.0
大小: 0 →  1.0  → 0.57 → 0.0
      ↑        ↑       ↑     ↑
      开始     最大    缩小   消失
```

**这样设计的原因是模拟真实烟花：**

- 爆炸瞬间：粒子快速放大
- 后续阶段：粒子逐渐缩小直到消失



#### 7.2 为什么取 `min(sizeOpeningProgress, sizeClosingProgress)`？

```glsl
float sizeProgress = min(sizeOpeningProgress, sizeClosingProgress);
```

**这是创建"山峰形"动画曲线的巧妙技巧：**

**两个进度变量的行为：**

```glsl
// sizeOpeningProgress: 从 0 到 1 (0.0-0.125)
// sizeClosingProgress: 从 1 到 0 (0.125-1.0)

时间:   0.0    0.0625    0.125    0.5    1.0
open:   0.0     0.5      1.0     1.0    1.0
close:  1.0     1.0      1.0     0.57   0.0
min:    0.0     0.5      1.0     0.57   0.0
```

**为什么不用 if-else？**

```glsl
// ❌ 传统方式（需要条件判断）
float sizeProgress;
if (progress < 0.125) {
    sizeProgress = sizeOpeningProgress;
} else {
    sizeProgress = sizeClosingProgress;
}

// ✅ 优雅方式（数学技巧）
float sizeProgress = min(sizeOpeningProgress, sizeClosingProgress);
```

**min() 的妙处：**

- 在 `progress < 0.125` 时：`sizeOpeningProgress` 较小，所以取它
- 在 `progress > 0.125` 时：`sizeClosingProgress` 较小，所以取它
- 在 `progress = 0.125` 时：两者都是 1.0

这样就自动实现了平滑的峰值转换！



### 8. clamp 函数的重要性

#### 8.1 为什么都要限制到 0-1？

```glsl
twinklingProgress = clamp(twinklingProgress, .0, 1.0);
```

**clamp 的作用是确保数值在有效范围内.**



#### 8.2 防止超出边界的问题：

**没有 clamp 的情况：**

```glsl
// 当 progress < 0.2 时：
float twinklingProgress = remap(0.1, 0.2, 0.8, 0.0, 1.0) = -0.5
// 负数会导致不可预测的行为！

// 当 progress > 0.8 时：  
float twinklingProgress = remap(0.9, 0.2, 0.8, 0.0, 1.0) = 1.17
// 大于1的值可能产生过度效果！
```

**有 clamp 的情况：**

```glsl
// 确保数值始终在 [0, 1] 范围内
twinklingProgress = clamp(twinklingProgress, 0.0, 1.0);
```



#### 8.3 各阶段 clamp 的具体作用：

```glsl
// 爆炸阶段：确保在 0.1 之后保持最大值 1.0
explodingProgress = clamp(explodingProgress, 0.0, 1.0);

// 下落阶段：确保在 0.1 之前保持最小值 0.0
fallingProgress = clamp(fallingProgress, 0.0, 1.0);

// 闪烁阶段：确保在 0.2-0.8 之外保持边界值
twinklingProgress = clamp(twinklingProgress, 0.0, 1.0);

// 缩放阶段：确保不会出现负值或超值
sizeProgress = clamp(sizeProgress, 0.0, 1.0);
```





## P37 Lights Shading Shaders 着色器实现光照

### 难点1：光照模型实现

#### 环境光 (Ambient Light)

```glsl
// 环境光函数
// 参数：
//   lightColor (vec3) - 环境光颜色，RGB值范围0.0-1.0
//   lightIntensity (float) - 环境光强度，控制整体亮度
// 返回值：
//   vec3 - 计算得到的环境光颜色值
vec3 ambientLight(vec3 lightColor, float lightIntensity) {
    return lightColor * lightIntensity;
}
```

- 最简单的光照，模拟环境漫反射
- 无方向性，均匀照亮所有表面



#### 平行光 (Directional Light)

```glsl
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
vec3 directionalLight(vec3 lightColor, float lightIntensity, 
                     vec3 normal, vec3 lightPosition, 
                     vec3 viewDirection, float specularPower) {
    // 计算光线方向
    vec3 lightDirection = normalize(lightPosition);
    
    // 漫反射计算 (Lambert模型)
    float shading = dot(normal, lightDirection);
    shading = max(.0, shading);
    
    // 镜面反射计算 (Phong模型)
    vec3 lightReflection = reflect(-lightDirection, normal);
    float specular = -dot(lightReflection, viewDirection);
    specular = max(.0, specular);
    specular = pow(specular, specularPower);
    
    return lightColor * lightIntensity * (shading + specular);
}
```



#### 点光源 (Point Light)

```glsl
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
vec3 pointLight(vec3 lightColor, float lightIntensity, 
               vec3 normal, vec3 lightPosition, 
               vec3 viewDirection, float specularPower, 
               vec3 position, float lightDecay) {
    // 计算光线方向和距离
    vec3 lightDelta = lightPosition - position;
    float lightDistance = length(lightDelta);
    vec3 lightDirection = normalize(lightDelta);
    
    // 漫反射和镜面反射计算
    // ... (同平行光)
    
    // 衰减计算
    float decay = 1.0 - lightDistance * lightDecay;
    decay = max(.0, decay);
    
    return lightColor * lightIntensity * decay * (shading + specular);
}
```



### 难点2：向量计算与坐标系转换

#### 1. 光线方向计算

```glsl
// 平行光（方向固定）
vec3 lightDirection = normalize(lightPosition);

// 点光源（方向随位置变化）
vec3 lightDelta = lightPosition - position;
float lightDistance = length(lightDelta);
vec3 lightDirection = normalize(lightDelta);
```

#### 2. 反射向量计算

```glsl
vec3 lightReflection = reflect(-lightDirection, normal);
```

- `reflect(I, N)` 函数：计算入射向量 I 在法线 N 上的反射
- `-lightDirection`：因为需要从表面指向光源的方向

#### 3. 漫反射计算（Lambert模型）

```glsl
float shading = dot(normal, lightDirection);
shading = max(0.0, shading);
```

- `dot(normal, lightDirection)`：计算余弦值
- `max(0.0, shading)`：确保不会出现负值（背面不受光）

#### 4. 镜面反射计算（Phong模型）

```glsl
float specular = -dot(lightReflection, viewDirection);
specular = max(0.0, specular);
specular = pow(specular, specularPower);
```

- `-dot(lightReflection, viewDirection)`：视线与反射方向的夹角
- `pow(specular, specularPower)`：控制高光的锐利程度



### 难点3：光照叠加与颜色混合

```glsl
// 环境光 - 基础照明
light += ambientLight(vec3(1.0), 0.03);

// 蓝色平行光 - 从z轴方向照射
light += directionalLight(
    vec3(0.1, 0.1, 1.0), // 蓝色光
    1.0,                  // 强度
    normal,               // 表面法线
    vec3(0.0, 0.0, 3.0), // 光的方向（实际当作方向使用）
    viewDirection,        // 视线方向
    20.0                  // 高光锐度
);

// 红色点光源 - 在y轴2.5位置
light += pointLight(
    vec3(1.0, 0.1, 0.1), // 红色光
    1.0,                  // 强度
    normal,               // 表面法线
    vec3(0.0, 2.5, 0.0), // 光源位置
    viewDirection,        // 视线方向
    20.0,                 // 高光锐度
    vPosition,            // 表面点位置
    0.25                  // 衰减系数
);

color *= light;
```



## P38 Raging Sea Shading Shaders 狂暴水面

### 为什么必须在片元着色器中进行归一化，而不是在顶点着色器传入时候直接计算好传入，这有什么区别吗？

```glsl
片元着色器：  vec3 normal = normalize(vNormal);

顶点着色器：  vNormal = normalize(computedNormal);
```

答：**有区别，必须在片元着色器中进行归一化。**因为仅在顶点着色器中归一化，片元着色器直接使用，会导致大量点没有归一化，**顶点着色器的点传入片元着色器，会进行插值计算**。

#### 数据流与插值机制

```text
顶点着色器输出 → 光栅化插值 → 片元着色器输入
```

**关键理解**：

- **顶点着色器**：在模型的每个顶点执行
- **片元着色器**：在渲染的每个像素执行
- **插值过程**：GPU自动在**三角形顶点之间生成过渡值**

#### 顶点 vs 片元的数量关系

```glsl
// 顶点着色器：执行次数 = 模型顶点数
// 例如：一个三角形只执行3次

// 片元着色器：执行次数 = 屏幕像素数  
// 例如：一个三角形可能覆盖成百上千个像素
```

**关键区别**：

- 顶点着色器处理的是**稀疏的顶点数据**
- 片元着色器处理的是**密集的像素数据**
- 两者之间通过**光栅化插值**连接

#### 归一化问题的本质

**写法对比**：

```glsl
// ❌ 错误做法：只在顶点归一化
顶点着色器：vNormal = normalize(computedNormal);
片元着色器：vec3 normal = vNormal;  // 直接使用

// ✅ 正确做法：在片元重新归一化  
顶点着色器：vNormal = computedNormal;  // 传递原始向量
片元着色器：vec3 normal = normalize(vNormal);  // 重新归一化
```



### 水面法线计算技术详解

#### 动态法线计算原理

```glsl
// 1. 计算当前点高度
float elevation = waveElevation(modelPosition.xyz);

// 2. 计算相邻点高度（微小偏移）
vec3 modelPositionA = modelPosition.xyz + vec3(shift, .0, .0);
vec3 modelPositionB = modelPosition.xyz + vec3(.0, .0, -shift);
float elevationA = waveElevation(modelPositionA);
float elevationB = waveElevation(modelPositionB);

// 3. 构建切线向量
vec3 toA = normalize(modelPositionA - modelPosition.xyz);
vec3 toB = normalize(modelPositionB - modelPosition.xyz);

// 4. 叉积计算法线
vec3 computedNormal = cross(toA, toB);
```

#### 技术要点解析

**为什么需要动态计算**：

- 水面高度实时变化，无法使用预计算的法线
- 每个帧都需要根据当前波浪状态重新计算

**微小偏移的作用**：

- 模拟表面局部曲率
- 通过相邻点的高度差计算表面倾斜度
- 偏移量越小，计算的法线越精确

#### 实际应用建议

性能优化考虑

```glsl
// 权衡：精度 vs 性能
const float shift = 0.01;  // 偏移量调节
// 较小值：更精确但可能数值不稳定
// 较大值：更稳定但精度降低
```

调试技巧

```glsl
// 法线可视化调试
#ifdef DEBUG_NORMALS
    color = normal * 0.5 + 0.5;  // 将法线映射到颜色空间
#endif

// 长度检查
float normalLength = length(vNormal);
if(normalLength < 0.9 || normalLength > 1.1) {
    color = vec3(1.0, 0.0, 0.0);  // 标记异常区域
}
```



## P39 Halftone Shading Shaders 半色调

### 一、内置变量：gl_FragCoord vs gl_PointCoord

#### 1.1 核心区别

| 变量              | 含义                               | 坐标系                               | 有效条件                | 主要用途                       |
| :---------------- | :--------------------------------- | :----------------------------------- | :---------------------- | :----------------------------- |
| **gl_FragCoord**  | 当前像素在**屏幕窗口**的绝对坐标   | 窗口坐标系，原点在左下角             | 始终有效                | 屏幕空间效果、后处理、深度计算 |
| **gl_PointCoord** | 当前像素在**点精灵**内部的相对坐标 | 纹理坐标系，原点在左上角(0,0)到(1,1) | 仅绘制`GL_POINTS`时有效 | 点精灵贴图、内部形状生成       |

#### 1.2 关键要点

- **gl_FragCoord**：用于知道"这个像素在屏幕哪里"
- **gl_PointCoord**：用于知道"这个像素在当前点图案里的位置"
- 点精灵示例：绘制圆形粒子

```glsl
float dist = distance(gl_PointCoord, vec2(0.5));
if(dist > 0.5) discard;
```



### 二、mod(x, y)函数详解

#### 2.1 数学定义

- 计算公式：`mod(x, y) = x - y * floor(x/y)`
- 返回x除以y的余数

#### 2.2 主要用途

1. **创建重复图案（平铺）**

```glsl
vec2 tiledUV = mod(uv * repeatCount, 1.0);
```

2. **循环动画**

```glsl
float progress = mod(time, duration) / duration;
```

3. **限制范围**

```glsl
float angle = mod(theta, 2.0 * PI);  // 限制在[0, 2π)
```

#### 2.3 与其他取余函数的区别

##### `mod` vs `fract`

```glsl
// mod(x, 1.0) 等价于取小数部分
float a = mod(3.7, 1.0);     // a = 0.7
float b = fract(3.7);        // b = 0.7 （fract 返回小数部分）

// 但 fract(x) 更高效，因为它等价于 x - floor(x)
```

##### `mod` vs `step` 模式

```glsl
// 使用 mod 创建步进模式
void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    // 创建 10 个垂直条纹
    float stripe = mod(uv.x * 10.0, 1.0);
    float stripePattern = step(0.5, stripe);  // 当 stripe >= 0.5 时返回 1
    
    fragColor = vec4(vec3(stripePattern), 1.0);
}
```

#### 2.4 性能优化

- 用`fract(x)`代替`mod(x, 1.0)`更高效
- 避免在片段着色器循环中频繁使用



### 三、smoothstep的非线性映射

#### 3.1 函数原理

```glsl
smoothstep(low, high, x)：
- x ≤ low：返回 0
- x ≥ high：返回 1
- 中间：平滑的三次Hermite插值
```

#### 3.2 参数设置意义

```glsl
// 示例：创建胶片曲线效果
float low = -0.8;   // 暗部截断点
float high = 1.5;   // 亮部压缩点
intensity = smoothstep(low, high, intensity);  // intensity范围[-1,1]
```

#### 3.3 视觉影响分析

| 参数设置                   | 暗部处理         | 亮部处理        | 整体效果             |
| :------------------------- | :--------------- | :-------------- | :------------------- |
| `smoothstep(-1.0, 1.0, x)` | 完整保留         | 完整保留        | 线性映射，对比度不变 |
| `smoothstep(-0.8, 1.5, x)` | 压缩(-1到-0.8→0) | 压缩(1.0→0.878) | 暗部提升，亮部压暗   |
| `smoothstep(-1.2, 0.8, x)` | 扩展(暗部更暗)   | 扩展(亮部更亮)  | 高对比度，HDR风格    |



## P40 Earth Shaders 地球

[太阳系各大行星3D展开贴图资源](https://www.solarsystemscope.com/)

### 一、关于球面坐标系统的困惑与理解

**我的提问：**

> "看来它是设置了一个半径为1的球面系统上的点，通过setFromSpherical获取了这个点的方向向量，然后将方向向量放大了5倍。那么，为什么不直接设置一个半径为5的球面系统的点，而是要这么麻烦？另外，假如我设置的是半径5的球面系统，怎么转化坐标"

**老师解答后的理解：**

#### 1. **球面坐标(Spherical)的本质**

- **不是球体，而是球面坐标系** - 一种用角度描述位置的坐标系统
- **三个参数**：半径(r)、极角(φ-纬度)、方位角(θ-经度)
- **与笛卡尔坐标的区别**：
  - **笛卡尔坐标系 (x,y,z):** 适合表示直线运动、碰撞检测等
  - **球面坐标系 (r,φ,θ):** 适合处理旋转、轨道、行星运动等**球面相关的计算**

#### 2. **为什么用单位球面再放大**

```javascript
// 当前做法：半径为1的单位球面
const sunSpherical = new THREE.Spherical(1, Math.PI * 0.5, 0.5);
sunDirection.setFromSpherical(sunSpherical); // 得到长度为1的方向向量
debugSun.position.copy(sunDirection).multiplyScalar(5); // 放大到5倍距离

// 替代做法：直接设置半径为5
const sunSpherical = new THREE.Spherical(5, Math.PI * 0.5, 0.5);
sunDirection.setFromSpherical(sunSpherical); // 直接得到长度为5的向量
debugSun.position.copy(sunDirection); // 直接使用
```

**为什么要用第一种方式？**

1. **分离关注点：**

   - `sunSpherical` 主要定义**方向**（角度）
   - `sunDirection` 是**标准化方向向量**
   - 距离用 `multiplyScalar(5)` 单独控制

2. **便于修改和计算：**

   ```javascript
   // 场景1：需要改变太阳距离
   const sunDistance = 5; // 可在GUI中调整
   debugSun.position.copy(sunDirection).multiplyScalar(sunDistance);
   
   // 场景2：需要计算光照强度（与距离平方成反比）
   const lightIntensity = 1.0 / (sunDistance * sunDistance);
   ```

3. **着色器需要单位向量：**
   在着色器中计算光照时，需要的是**方向**而不是位置：

   ```glsl
   // 正确：使用单位向量计算点积
   float sunOrientation = dot(uSunDirection, normal);
   
   // 错误：如果uSunDirection长度不为1，点积结果会被距离影响
   ```

**这样设计的好处：**

- **关注点分离**：方向与距离独立控制
- **着色器需要**：光照计算需要单位向量
- **便于修改**：距离可在GUI中单独调整

#### 3. **如果设置半径5如何转换**

```javascript
// 直接转换，方法相同
const sunSpherical = new THREE.Spherical(5, Math.PI*0.5, 0.5);
const sunDirection = new THREE.Vector3();
sunDirection.setFromSpherical(sunSpherical); // 长度=5

// 需要单位向量时再归一化
const normalizedDirection = sunDirection.clone().normalize();
```



### 二、各向异性过滤(Anisotropy)的困惑

**我的提问：**

> "还是不太明白各向异性的意思？有啥用，我看不出效果"

**老师解答后的理解：**

#### 1. **各向异性解决什么问题**

- **纹理倾斜时的模糊问题**：当纹理平面与视线不垂直时
- **高频细节纹理**：文字、线条、图案在倾斜时更明显

**无各向异性过滤（anisotropy = 1）：**

```text
视线方向：  /
           /
纹理采样： □□□  // 只采样单一方向，远处像素被拉伸
```

**有各向异性过滤（anisotropy = 16）：**

```text
视线方向：  /
           /
纹理采样： ▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣  // 沿着倾斜方向多次采样
```

#### 2. **测试方法**

```javascript
// 设置各向异性
earthDayTexture.anisotropy = renderer.capabilities.getMaxAnisotropy();
// 或指定一个值（2、4、8、16）
earthDayTexture.anisotropy = 8;
```

#### 3. **实际应用**

```javascript
// 地球纹理设置
earthDayTexture.anisotropy = 8; // 或16
earthDayTexture.colorSpace = THREE.SRGBColorSpace;
```



### 三、纹理通道使用分析

#### 1. **为什么只使用rg通道**

```glsl
vec2 specularCloudsColor = texture(uSpecularCloudsTexture, vUv).rg;
```

**纹理打包技巧：** 一张纹理存储多个信息

- **r通道（红色）：** 存储**高光强度**（specular intensity）
- **g通道（绿色）：** 存储**云层遮罩**（clouds mask）
- **b/a通道：** 可能未使用，或存储其他信息

**后续使用：**

```glsl
// 使用r通道控制高光
specular *= specularCloudsColor.r;

// 使用g通道控制云层
float cloudsMix = smoothstep(.5, 1.0, specularCloudsColor.g);
```



### 四、THREE.BackSide的深度理解

**我的提问：**

> "也就是说不是把球体分成了二分之一，而是使用BackSide，表面的球体被隐藏了，相当于我只能看到内部的表面，所以看起来像是切了一半是吗"

**老师解答后的理解：**

#### 1. **你的理解基本正确，但更准确地说：**

**对于球体：**

```javascript
const geometry = new THREE.SphereGeometry(1, 32, 32);
```

**球体有两层"表面"：**

1. **外表面（FrontSide）：** 法线指向外部
2. **内表面（BackSide）：** 法线指向内部

#### 2. **渲染机制图解**

```text
相机位置：◎（在球外）

球体：⚪
- 外表面：→ 法线向外
- 内表面：← 法线向内

正常渲染（THREE.FrontSide，默认）：
相机看到：外表面（→）✅ 可见
          内表面（←）❌ 不可见（背面剔除）

大气层渲染（THREE.BackSide）：
相机看到：外表面（→）❌ 不可见（设置为背面）
          内表面（←）✅ 可见（因为设置了BackSide）
```

#### 3. **为什么看起来像"切了一半"**

实际上**不是切了一半**，而是：

1. **内表面始终面向球心**
2. **从球外看内表面时**，你看到的是球体的"内侧"
3. **由于内表面是连续的**，所以看起来像一个完整的球

**关键区别：**

```javascript
// 如果设置双面渲染
side: THREE.DoubleSide
// 会看到内外两层，可能出现z-fighting（深度冲突）

// 如果设置背面渲染
side: THREE.BackSide
// 只看到内层，外层被隐藏
```

**原因：** 无论相机如何旋转，球体内表面始终存在且面向相机（因为我们在球体内部看内壁）



## P41 Particles Cursor Animation Shader 图片粒子化

### 一、`discard` 关键字详解

#### 1. 什么是 `discard`？

- `discard` 是中的关键字，用于在片段着色器中**立即丢弃当前像素**
- 当调用 `discard` 时，该片段**不会写入颜色缓冲区、深度缓冲区或模板缓冲区**
- 相当于让这个像素"消失"，完全不渲染

#### 2. 使用场景

```glsl
// 示例：绘制圆形点精灵
varying vec3 vColor;

void main() {
    vec2 uv = gl_PointCoord;
    float distanceToCenter = length(uv - vec2(.5));
    
    // 场景1：绘制圆形（丢弃方形角落）
    if(distanceToCenter > .5) {
        discard;  // 丢弃非圆形区域的像素
    }
    
    // 场景2：基于alpha的裁剪
    float alpha = texture(uTexture, uv).a;
    if(alpha < 0.1) {
        discard;  // 丢弃透明像素
    }
    
    // 场景3：基于深度的裁剪
    if(gl_FragCoord.z > maxDepth) {
        discard;  // 丢弃超出深度的像素
    }
    
    gl_FragColor = vec4(vColor, 1.0);
}
```

#### 3. 性能影响

##### ✅ 优点：

- **减少过度绘制**：提前终止不需要的片段处理
- **节省带宽**：减少不必要的帧缓冲写入

##### ⚠️ 性能问题：

1. **破坏早期深度测试**：

   ```javascript
   // 问题：现代GPU的优化流程
   // 1. 早期深度测试（Early Z）-> 深度测试先于片段着色器执行
   // 2. 使用discard后，GPU无法提前进行深度测试
   // 3. 导致更多片段需要执行完整的着色器计算
   ```

2. **分支预测失效**：

   - GPU并行处理多个片段（如32个一组）
   - 如果组内有的片段discard，有的不discard，组内所有片段都需要执行完整代码

3. **内存访问模式变差**：

   - 不连贯的内存访问可能导致缓存未命中

#### 4. 最佳实践

```javascript
// 替代方案1：使用alpha测试（某些平台有硬件支持）
material.alphaTest = 0.5;

// 替代方案2：使用深度预渲染（Depth Prepass）
// 第一步：只写入深度
// 第二步：渲染颜色（自动通过深度测试的片段）

// 替代方案3：合理的LOD和剔除
// 在几何阶段就剔除不需要的物体
```

#### 5. 何时使用 `discard`

```javascript
// ✅ 适合使用的情况：
// 1. 像素级裁剪（如本例的圆形点）
// 2. 需要完全透明（不是半透明混合）
// 3. 被丢弃的像素比例很高（>30%）
// 4. 简单条件判断（避免复杂分支）

// ❌ 避免使用的情况：
// 1. 需要半透明混合（使用alpha blending）
// 2. 大部分像素都需要渲染
// 3. 复杂的逐像素条件判断
```



### 二、HTML5 Canvas Cheat Sheet 链接作用

这是一个HTML5 Canvas API的速查表，包含：

- Canvas 2D上下文的所有方法和属性
- 绘制形状、文本、图像的API
- 变换、合成、样式设置
- 动画和交互处理

在你的代码中，用于创建2D位移贴图：

```javascript
// 创建Canvas元素
displacement.canvas = document.createElement("canvas");
displacement.canvas.width = 128;
displacement.canvas.height = 128;

// 获取2D上下文（这就是Canvas API的核心）
displacement.context = displacement.canvas.getContext("2d");

// 使用Canvas API绘制
displacement.context.fillRect(0, 0, displacement.canvas.width, displacement.canvas.height);
```



### 三、Canvas操作详细解释

#### 1. Canvas基础概念

```javascript
// Canvas是一个画布，提供2D绘图API
const canvas = document.createElement("canvas");
const ctx = canvas.getContext("2d");  // 获取2D上下文

// 坐标系：左上角(0,0)，右下角(width,height)
// 单位：像素
```

#### 2. 你的代码中Canvas操作解析

```javascript
// 1. 创建Canvas元素
displacement.canvas = document.createElement("canvas");
displacement.canvas.width = 128;   // 设置画布宽度（像素）
displacement.canvas.height = 128;  // 设置画布高度（像素）

// 2. 获取2D上下文
displacement.context = displacement.canvas.getContext("2d");

// 3. 填充整个画布
displacement.context.fillRect(0, 0, displacement.canvas.width, displacement.canvas.height);
// fillRect(x, y, width, height) - 绘制填充矩形

// 4. 设置混合模式
displacement.context.globalCompositeOperation = "source-over";
// 合成操作类型：
// - 'source-over': 默认，新图像绘制在旧图像之上
// - 'lighten': 取两者中较亮的颜色
// - 'multiply': 颜色相乘
// - 等等...

// 5. 设置全局透明度
displacement.context.globalAlpha = 0.02;
// 影响后续所有绘制操作的透明度

// 6. 绘制图像
displacement.context.drawImage(
    displacement.glowImage,        // 源图像
    displacement.canvasCursor.x - glowSize * 0.5,  // 目标x坐标
    displacement.canvasCursor.y - glowSize * 0.5,  // 目标y坐标
    glowSize,                      // 目标宽度
    glowSize                       // 目标高度
);
```

#### 3. 具体流程解析

```javascript
// 每帧执行的Canvas操作：
function updateCanvas() {
    // 步骤1：淡出效果（模拟残影）
    // 用带透明度的黑色覆盖整个画布，让之前的内容逐渐消失
    displacement.context.globalCompositeOperation = "source-over";
    displacement.context.globalAlpha = 0.02;  // 2%透明度
    displacement.context.fillRect(0, 0, displacement.canvas.width, displacement.canvas.height);
    
    // 步骤2：绘制光晕
    // 根据鼠标移动速度计算光晕强度
    const cursorDistance = displacement.canvasCursorPrevious.distanceTo(
        displacement.canvasCursor
    );
    const alpha = Math.min(cursorDistance * 0.1, 1);  // 速度越快，光晕越亮
    
    displacement.context.globalCompositeOperation = "lighten";  // 变亮混合模式
    displacement.context.globalAlpha = alpha;  // 动态透明度
    
    // 在光标位置绘制光晕图像
    displacement.context.drawImage(
        displacement.glowImage,
        x - size/2, y - size/2,  // 居中绘制
        size, size
    );
}
```

#### 4. Canvas作为Three.js纹理

```javascript
// 将Canvas转换为Three.js纹理
displacement.texture = new THREE.CanvasTexture(displacement.canvas);

// 在着色器中使用
uniform sampler2D uDisplacementTexture;

// 重要：需要手动更新纹理
displacement.texture.needsUpdate = true;
```



### 四、`particlesGeometry.setIndex(null)` 详解

#### 1. Three.js几何体索引系统

```javascript
// Three.js默认使用索引化几何体
// 顶点数据共享，通过索引引用

// 示例：一个矩形（2个三角形）使用索引
const vertices = [
    // 4个顶点
    [0,0,0], [1,0,0], [1,1,0], [0,1,0]
];
const indices = [
    0,1,2,  // 第一个三角形
    0,2,3   // 第二个三角形
];
// 总共：4个顶点，6个索引（2个三角形）
```

#### 2. 为什么要设置 `setIndex(null)`？

```javascript
// 对于粒子系统，每个粒子应该是独立的点
const particlesGeometry = new THREE.PlaneGeometry(10, 10, 128, 128);

// 默认情况：平面几何体使用索引优化
// 顶点数：129×129 = 16641个顶点
// 索引数：128×128×6 = 98304个索引（用于组成三角形）

// 设置null后：
particlesGeometry.setIndex(null);
// 效果：几何体变成"非索引"的
// 每个三角形单独存储顶点数据
// 顶点数据会重复，但每个顶点可以独立处理
```

#### 3. 为什么会"点多出来"？

```javascript
// 原因1：索引化的几何体会复用顶点
// 例如：一个顶点被多个三角形共享
// 在粒子系统中，这会导致多个粒子共享同一位置

// 原因2：Three.Points 使用顶点作为粒子位置
// 非索引几何体：每个三角形有自己的3个顶点
// 对于128×128细分平面：
// - 索引化：16641个顶点
// - 非索引：98304个顶点（128×128×6）
// 粒子数量大大增加！

// 原因3：几何体属性需要与顶点数匹配
// 设置自定义属性（如aIntensity）时，需要为每个顶点提供值
// 非索引化确保每个粒子有独立的属性值
```

#### 4. 验证代码

```javascript
const geometry = new THREE.PlaneGeometry(1, 1, 2, 2);
console.log('顶点数:', geometry.attributes.position.count);  // 9
console.log('索引数:', geometry.index.count);               // 24

geometry.setIndex(null);
console.log('设置null后顶点数:', geometry.attributes.position.count);  // 24
// 注意：实际位置数据还是9个，但Three.js会复制数据
```



### 五、完整代码流程梳理

#### 1. 项目结构

```text
粒子光标动画效果
├── 2D Canvas层 (光晕绘制)
├── 3D粒子层 (Three.js粒子系统)
└── 交互层 (鼠标跟踪)
```

#### 2. 核心流程

```javascript
// 步骤1：初始化
1. 创建2D Canvas用于绘制光晕
2. 创建Three.js粒子几何体（非索引化）
3. 加载图片纹理和创建着色器材质
4. 设置相机和渲染器

// 步骤2：交互处理
1. 监听鼠标移动，计算归一化屏幕坐标(-1到1)
2. 使用Raycaster将屏幕坐标转换为3D坐标
3. 将3D坐标映射到2D Canvas坐标

// 步骤3：渲染循环
1. 更新2D Canvas：淡出旧痕迹 + 绘制新光晕
2. 更新粒子着色器：使用Canvas纹理作为位移贴图
3. 渲染Three.js场景
```

#### 3. 着色器工作流程

```glsl
// 顶点着色器
1. 从位移纹理获取当前UV位置的强度
2. 根据强度计算位移偏移
3. 应用位移到顶点位置
4. 计算粒子大小（基于图片纹理强度）

// 片段着色器
1. 获取点在精灵坐标系中的位置(gl_PointCoord)
2. 计算到中心的距离
3. 使用discard丢弃非圆形区域的像素
4. 输出颜色
```



### 六、Canvas淡出效果实现机制

#### 1. 不是"清空画布"，而是"渐进覆盖"

```javascript
// 你的代码片段
displacement.context.globalCompositeOperation = "source-over";
displacement.context.globalAlpha = 0.02;
displacement.context.fillRect(0, 0, displacement.canvas.width, displacement.canvas.height);
```

#### 2. 详细分解

```javascript
// 模拟每一帧的过程：
let canvasContent = []; // 想象这是一个像素数组

// 第一帧：绘制光晕
canvasContent = [亮色, 亮色, 亮色, 亮色, ...];

// 第二帧：淡出覆盖
// 1. 设置混合模式为"覆盖"
displacement.context.globalCompositeOperation = "source-over";

// 2. 设置透明度为2%
displacement.context.globalAlpha = 0.02;

// 3. 用黑色覆盖整个画布
// 效果：每个像素 = 原像素 × 0.98 + 黑色 × 0.02
// 黑色是 [0,0,0]，所以结果 = 原像素 × 0.98
canvasContent = [稍暗色, 稍暗色, 稍暗色, 稍暗色, ...];

// 第三帧：再次覆盖
canvasContent = [更暗色, 更暗色, 更暗色, 更暗色, ...];

// 随着时间的推移，所有像素都逐渐接近黑色
```

#### 3. 数学原理

```javascript
// Canvas的颜色混合公式：
// 结果颜色 = (原颜色 × (1 - alpha)) + (新颜色 × alpha)

// 假设原像素是白色 [255, 255, 255]，alpha=0.02
// 新颜色是黑色 [0, 0, 0]
// 计算结果：
// R = 255 * (1-0.02) + 0 * 0.02 = 255 * 0.98 = 249.9 ≈ 250
// G = 255 * 0.98 = 250
// B = 255 * 0.98 = 250

// 每次覆盖都会让颜色值乘以0.98
// 经过n帧后：颜色值 = 原始值 × (0.98)^n
// 所以亮度呈指数衰减
```

#### 4. 可视化演示

```text
时间轴：每一帧都执行一次淡出覆盖

第0帧：██████ 原始光晕（很亮）
        ^
        | 黑色覆盖(2%透明度)
第1帧：▆▆▆▆▆▆ 亮度降到98%
        ^
        | 再次覆盖
第2帧：▅▅▅▅▅▅ 亮度降到96.04% (0.98×0.98)
        ^
        | 持续覆盖
第10帧：▁▁▁▁▁▁ 亮度降到81.7% (0.98^10)
        ^
        | ...
第50帧：     亮度降到36.4% (0.98^50)
```



### 七、光晕效果实现详解

#### 1. 完整光晕绘制代码

```javascript
// 1. 设置变亮混合模式
displacement.context.globalCompositeOperation = "lighten";

// 2. 根据鼠标速度计算透明度
const cursorDistance = displacement.canvasCursorPrevious.distanceTo(
    displacement.canvasCursor
);
const alpha = Math.min(cursorDistance * 0.1, 1);

// 3. 设置透明度
displacement.context.globalAlpha = alpha;

// 4. 绘制光晕图片
const glowSize = displacement.canvas.width * 0.25;
displacement.context.drawImage(
    displacement.glowImage,                    // 光晕图片
    displacement.canvasCursor.x - glowSize * 0.5,  // x坐标（居中）
    displacement.canvasCursor.y - glowSize * 0.5,  // y坐标（居中）
    glowSize,                                // 宽度
    glowSize                                 // 高度
);
```

#### 2. 关键点解析

##### 点1：混合模式 `"lighten"`

```javascript
// "lighten" 模式：取两个颜色中较亮的那个
// 公式：结果颜色 = max(源颜色, 目标颜色)

// 示例1：源颜色=红色(255,0,0)，目标颜色=黑色(0,0,0)
// 结果 = max([255,0,0], [0,0,0]) = [255,0,0]（红色）

// 示例2：源颜色=灰色(100,100,100)，目标颜色=黑色(0,0,0)
// 结果 = max([100,100,100], [0,0,0]) = [100,100,100]（灰色）

// 作用：光晕只会"变亮"画布，不会"变暗"
```

##### 点2：鼠标速度计算透明度

```javascript
// 计算当前帧和上一帧光标位置的距离
const cursorDistance = displacement.canvasCursorPrevious.distanceTo(
    displacement.canvasCursor
);

// 为什么使用距离？
// 距离大 → 鼠标移动快 → 光晕应该更明显
// 距离小 → 鼠标移动慢 → 光晕应该更淡
// 距离0 → 鼠标静止 → 光晕几乎消失

// 转换公式：alpha = Math.min(距离 * 0.1, 1)
// *0.1：调节敏感度，值越大，相同距离产生的alpha越大
// Math.min(..., 1)：限制最大值为1（不透明）
```

##### 点3：光晕图片绘制

```javascript
// glowImage是一张中心亮、边缘渐变的圆形图片
// 类似这样的图片：
// 中心：白色，不透明
// 边缘：渐变到透明

// 绘制时居中：
const glowSize = displacement.canvas.width * 0.25;  // 光晕大小为画布的1/4
const centerX = displacement.canvasCursor.x - glowSize * 0.5;
const centerY = displacement.canvasCursor.y - glowSize * 0.5;

// 这样绘制时光晕中心正好在光标位置
```



### 八、整体效果如何配合

#### 1. 每帧执行顺序

```javascript
function updateCanvas() {
    // 第一步：淡出覆盖（让所有像素变暗2%）
    // 混合模式：source-over（覆盖）
    // 透明度：0.02
    // 效果：整个画布逐渐变暗
    
    // 第二步：绘制新光晕
    // 混合模式：lighten（变亮）
    // 透明度：根据鼠标速度计算
    // 效果：在光标位置添加明亮光晕
    
    // 第三步：更新纹理，供Three.js使用
    displacement.texture.needsUpdate = true;
}
```



### 四、完整代码注释版

```javascript
// 创建Canvas元素
displacement.canvas = document.createElement("canvas");
displacement.canvas.width = 128;  // 小尺寸，性能好
displacement.canvas.height = 128;

// 获取2D上下文
displacement.context = displacement.canvas.getContext("2d");

// 加载光晕图片（中心亮边缘渐变的圆形图片）
displacement.glowImage = new Image();
displacement.glowImage.src = glowPath;

// 初始填充为黑色
displacement.context.fillRect(0, 0, displacement.canvas.width, displacement.canvas.height);

// 在渲染循环中
function render() {
    // ...其他代码...
    
    // ============== 淡出效果 ==============
    // 设置混合模式：新内容覆盖旧内容
    displacement.context.globalCompositeOperation = "source-over";
    
    // 设置透明度：2%，非常低的透明度
    displacement.context.globalAlpha = 0.02;
    
    // 用当前填充色（默认黑色）覆盖整个画布
    // 由于alpha=0.02，这会让所有现有像素变暗2%
    displacement.context.fillRect(
        0, 0, 
        displacement.canvas.width, 
        displacement.canvas.height
    );
    
    // ============== 光晕效果 ==============
    // 计算鼠标移动距离（当前帧与上一帧的距离）
    const cursorDistance = displacement.canvasCursorPrevious.distanceTo(
        displacement.canvasCursor
    );
    
    // 保存当前位置，用于下一帧计算
    displacement.canvasCursorPrevious.copy(displacement.canvasCursor);
    
    // 根据移动距离计算光晕透明度
    // 距离越大（移动越快），alpha越大（光晕越亮）
    // 限制最大值不超过1
    const alpha = Math.min(cursorDistance * 0.1, 1);
    
    // 设置混合模式：变亮，只增加亮度，不减暗
    displacement.context.globalCompositeOperation = "lighten";
    
    // 设置计算出的透明度
    displacement.context.globalAlpha = alpha;
    
    // 计算光晕大小（画布宽度的1/4）
    const glowSize = displacement.canvas.width * 0.25;
    
    // 在光标位置绘制光晕图片（居中绘制）
    displacement.context.drawImage(
        displacement.glowImage,  // 光晕图片
        displacement.canvasCursor.x - glowSize * 0.5,  // x位置（居中）
        displacement.canvasCursor.y - glowSize * 0.5,  // y位置（居中）
        glowSize,  // 宽度
        glowSize   // 高度
    );
    
    // 告诉Three.js纹理需要更新
    displacement.texture.needsUpdate = true;
    
    // ...继续渲染...
}
```



### 五、调试技巧

如果想看到实际效果，可以添加调试代码：

```javascript
// 1. 查看Canvas内容
console.log(displacement.canvas);  // 可以在控制台查看Canvas

// 2. 可视化显示Canvas（在页面中显示）
displacement.canvas.style.border = "1px solid red";
displacement.canvas.style.position = "fixed";
displacement.canvas.style.top = "0";
displacement.canvas.style.left = "0";
displacement.canvas.style.zIndex = "1000";

// 3. 打印调试信息
console.log("光标距离:", cursorDistance);
console.log("光晕透明度:", alpha);
console.log("光标位置:", displacement.canvasCursor.x, displacement.canvasCursor.y);

// 4. 修改参数看效果
// 尝试修改淡出透明度：
// displacement.context.globalAlpha = 0.1;  // 更快的淡出
// displacement.context.globalAlpha = 0.005; // 更慢的淡出

// 尝试修改光晕敏感度：
// const alpha = Math.min(cursorDistance * 0.05, 1);  // 更不敏感
// const alpha = Math.min(cursorDistance * 0.2, 1);   // 更敏感
```



### 六、常见问题解答

**Q：为什么用黑色覆盖，不是其他颜色？**
A：黑色在"变亮"模式下不会影响亮度，但在"覆盖"模式下会让像素变暗。黑色是[0,0,0]，让像素乘以(1-alpha)后变暗。

**Q：为什么光晕大小是画布的1/4？**
A：这是经验值。太大可能模糊，太小可能不明显。可以根据需要调整：

```javascript
// 尝试不同比例
const glowSize = displacement.canvas.width * 0.15;  // 更小
const glowSize = displacement.canvas.width * 0.35;  // 更大
```

**Q：淡出透明度0.02是怎么确定的？**
A：通过试验得到的平衡值。太小淡出太慢，太大淡出太快：

```javascript
// 不同效果的尝试：
// 0.01: 淡出很慢，痕迹持续很久
// 0.02: 适中，推荐值
// 0.05: 淡出很快，痕迹很快消失
// 0.1:  淡出非常快，几乎瞬间消失
```

**Q：为什么鼠标移动距离要乘以0.1？**
A：这是缩放因子，将像素距离转换为透明度(0-1)。如果不乘以0.1：

```javascript
// 假设移动了10像素
cursorDistance = 10;
alpha = Math.min(10 * 1, 1) = 1;  // 总是1，没有渐变
alpha = Math.min(10 * 0.1, 1) = 1;  // 移动10像素就达到最大
alpha = Math.min(10 * 0.05, 1) = 0.5; // 需要移动20像素才达到最大
```



## P42 Particles Morphing Shader 模型粒子化切换

### 一、为什么需要每个模型的顶点数相同？

#### 1. 粒子系统的本质限制

```javascript
// THREE.Points 需要固定数量的顶点
particles.points = new THREE.Points(particles.geometry, particles.material);
```

**核心原因：**

- 粒子系统（THREE.Points）使用**固定缓冲区大小**
- GPU并行处理需要**预定义的顶点数量**
- 变形动画需要**一一对应的顶点映射**

#### 2. 顶点不对应的后果

假设：

- 模型A：1000个顶点
- 模型B：2000个顶点

**问题：**

1. **无法建立映射关系**：A的第1001个顶点没有对应的B顶点
2. **动画断裂**：部分顶点突然出现或消失
3. **渲染错误**：GPU不知道如何处理多余或缺失的顶点

#### 3. 解决方案：填充到相同数量

```javascript
// 填充不足的顶点
if (i3 < originalArray.length) {
    // 使用原顶点
} else {
    // 从原顶点中随机复制一个
    const randomIndex = Math.floor(position.count * Math.random()) * 3;
    newArray[i3 + 0] = originalArray[randomIndex + 0];
    newArray[i3 + 1] = originalArray[randomIndex + 1];
    newArray[i3 + 2] = originalArray[randomIndex + 2];
}
```

**优势：**

- 保证所有模型都有相同顶点数
- 平滑的动画过渡
- GPU友好的内存布局

------



### 二、特别注意噪声输出的值区间

#### 1. 噪声的本质：值映射函数

```glsl
// Simplex噪声是一种确定性映射
float noise = simplexNoise3d(position);
// 输入：3D坐标
// 输出：[-1.0, 1.0]范围内的值（理论上）
```

**关键理解：**

- 噪声函数是**确定性**的：相同输入 → 相同输出
- 但输出区间**可能变化**：不同实现/输入范围可能不同
- 必须**验证和重映射**输出区间

#### 2. 输出区间的陷阱

```javascript
// 假设噪声函数实际输出：
// 理论：[-1.0, 1.0]
// 实际：[-0.7, 0.8] 或 [0.1, 0.9]

// 如果不检查，会导致：
// 1. 动画时序错误
// 2. 颜色混合异常
// 3. 视觉效果不一致
```

#### 3. 为什么必须关注值区间？

**场景示例：用噪声控制延迟**

```glsl
float delay = (1.0 - duration) * noise;

// 假设duration = 0.4
// 期望：delay ∈ [0, 0.6]（因为noise ∈ [0, 1]）

// 但如果noise ∈ [-0.5, 0.5]
// 实际：delay ∈ [-0.3, 0.3]
// 问题：负延迟导致动画逻辑错误！
```

#### 4. 标准化处理

```glsl
// 方法1：使用smoothstep强制重映射
float normalizedNoise = smoothstep(-1.0, 1.0, noise);

// 方法2：手动线性映射
float minNoise = -1.0; // 需要实际测试确定
float maxNoise = 1.0;  // 需要实际测试确定
float normalizedNoise = (noise - minNoise) / (maxNoise - minNoise);

// 方法3：clamp限制范围
float normalizedNoise = clamp(noise, 0.0, 1.0);
```

**[smoothstep(-1.0, 1.0, noise) 的映射详解](#smoothstep(-1.0, 1.0, noise) 的映射详解)**



#### 5. 2D噪声 vs 3D噪声的值区间

```glsl
// 2D噪声：输入(x,y)，输出通常[-1,1]
float noise2D = simplexNoise(vec2(x, y));

// 3D噪声：输入(x,y,z)，输出通常[-1,1]  
float noise3D = simplexNoise3d(vec3(x, y, z));

// 但！不同实现可能不同：
// - Classic Perlin噪声：[-1, 1]
// - Simplex噪声：[-1, 1]
// - Value噪声：[0, 1]
// - 某些库的实现：[-0.5, 0.5]
```

**必须测试你的具体噪声函数！**

------



### 三、延迟动画的数学原理

#### 1. 代码解析

```glsl
float duration = .4;                // 单个粒子动画持续时间
float delay = (1.0 - duration) * noise;  // 开始延迟时间
float end = delay + duration;            // 结束时间
float progress = smoothstep(delay, end, uProgress);
```

#### 2. 逐行数学解释

#### 第1行：`float duration = .4;`

- 每个粒子从开始变形到完成需要0.4秒
- 这个时间单位是相对于总动画时间`uProgress`的

#### 第2行：`float delay = (1.0 - duration) * noise;`

```javascript
// 分解计算：
// duration = 0.4
// 1.0 - duration = 0.6  ← 这是最大可用延迟时间
// noise ∈ [0, 1]（经过smoothstep重映射后）
// 所以：delay ∈ [0, 0.6]
```

**为什么是`(1.0 - duration)`？**

- 总动画时间：1.0
- 动画本身需要：duration（0.4）
- 剩余可用于延迟的时间：1.0 - duration = 0.6
- 确保所有粒子都能在总时间内完成动画

#### 第3行：`float end = delay + duration;`

- 粒子动画结束时间 = 开始时间 + 持续时间
- 确保：delay ≤ end ≤ 1.0

#### 第4行：`float progress = smoothstep(delay, end, uProgress);`

**smoothstep函数的作用：**

```glsl
// smoothstep(a, b, x) 返回值：
// 0.0，当 x ≤ a
// 1.0，当 x ≥ b
// 平滑过渡值，当 a < x < b
```

**应用场景：**

```
时间轴：0.0 --------------------------- 1.0
uProgress: 全局动画进度

粒子A (noise=0.0):
  delay=0.0, end=0.4
  在uProgress=0.0时开始，0.4时完成

粒子B (noise=0.5):
  delay=0.3, end=0.7  
  在uProgress=0.3时开始，0.7时完成

粒子C (noise=1.0):
  delay=0.6, end=1.0
  在uProgress=0.6时开始，1.0时完成
```

#### 3. 动画效果可视化

##### 无延迟的动画（所有粒子同时）：

```
时间： 0.0    0.2    0.4    0.6    0.8    1.0
所有粒子：████████████████████████████████
```

##### 有延迟的动画（粒子分批）：

```
时间： 0.0    0.2    0.4    0.6    0.8    1.0
粒子A：████████████████
粒子B：        ████████████████
粒子C：                ████████████████
```

#### 4. 预期效果

1. **波浪状变形**：不是所有粒子同时开始
2. **错落有致**：基于噪声值，形成自然的扩散效果
3. **视觉丰富度**：比同时变形更有层次感
4. **物理真实感**：模仿自然界中的传播现象

------



### 四、两次噪音计算的区别

#### 1. 原始代码

```glsl
float noiseOrigin = simplexNoise3d(position);
float noiseTarget = simplexNoise3d(aPositionTarget);
float noise = mix(noiseOrigin, noiseTarget, uProgress);
```

#### 2. 这不是位置混合，是噪声混合！

**常见的误解**：认为这是在混合位置
**实际**：这是在混合**噪声值**，然后用噪声值控制**动画时序**

#### 3. 两种方法的对比

##### 方法A：只使用起始噪声（错误方式）

```glsl
float noise = noiseOrigin;  // 始终使用起始模型的噪声
// 问题：动画结束时，粒子的延迟分布仍是起始模型的模式
// 可能不适合目标模型的形状
```

##### 方法B：只使用目标噪声（错误方式）

```
float noise = noiseTarget;  // 始终使用目标模型的噪声
// 问题：动画开始时，粒子的延迟分布已是目标模型的模式
// 可能不适合起始模型的形状
```

##### 方法C：混合两种噪声（正确方式）

```glsl
float noise = mix(noiseOrigin, noiseTarget, uProgress);
// 优势：
// - uProgress=0: noise = noiseOrigin（适合起始模型）
// - uProgress=1: noise = noiseTarget（适合目标模型）
// - 中间值：平滑过渡，同时适应两种形状
```

#### 4. 实际动画效果差异

假设场景：从兔子（小）变形到大象（大）

##### 只使用起始噪声：

- **开始**：兔子形状的延迟分布 ✓（好）
- **结束**：兔子形状的延迟分布用于大象 ✗（不好）
- **结果**：大象的变形动画看起来奇怪，某些区域动画不协调

##### 混合两种噪声：

- **开始**：兔子形状的延迟分布 ✓
- **中间**：逐步过渡到中间状态 ✓
- **结束**：大象形状的延迟分布 ✓
- **结果**：整个动画过程都保持合理的延迟分布

#### 5. 老师说的"动画开始和结尾的动画更加优化了"

指的是：

1. **开始优化**：使用适合起始模型的噪声模式
2. **结束优化**：使用适合目标模型的噪声模式
3. **过渡平滑**：中间状态自然过渡

------



### 五、坐标缩放的作用

#### 1. 代码变化

```glsl
// 修改前
float noiseOrigin = simplexNoise3d(position);
float noiseTarget = simplexNoise3d(aPositionTarget);

// 修改后  
float noiseOrigin = simplexNoise3d(position * .2);
float noiseTarget = simplexNoise3d(aPositionTarget * .2);
```

#### 2. 这不是缩小模型！

**关键理解**：这是在调整**噪声的频率**，不是模型大小。

#### 3. 噪声频率的概念

```javascript
// 噪声函数可以看作一种"图案生成器"
// 输入坐标决定图案的"位置"
// 坐标缩放影响图案的"密度"

// 举例：
simplexNoise3d(vec3(1.0, 2.0, 3.0))   → 图案中的某个点
simplexNoise3d(vec3(2.0, 4.0, 6.0))   → 图案中相距较远的点
// 快速变化 = 高频噪声

simplexNoise3d(vec3(0.2, 0.4, 0.6))   → 图案中的某个点
simplexNoise3d(vec3(0.22, 0.44, 0.66)) → 图案中相距较近的点
// 缓慢变化 = 低频噪声
```

#### 4. 缩放系数的影响

##### 系数 = 1.0（原始）

```glsl
float noise = simplexNoise3d(position * 1.0);
// 高频噪声
// 视觉：细碎的、颗粒状的、快速变化的图案
// 适合：细节丰富的效果
```

##### 系数 = 0.2（缩小5倍）

```glsl
float noise = simplexNoise3d(position * 0.2);
// 低频噪声
// 视觉：大块的、平缓的、缓慢变化的图案
// 适合：整体形状的、云状的效果
```

##### 系数 = 0.05（缩小20倍）

```
float noise = simplexNoise3d(position * 0.05);
// 极低频噪声
// 视觉：非常大的、几乎均匀的区域
// 适合：渐变效果
```

#### 5. 为什么说"变化加大"？

这里的"变化"指的是**视觉上可辨认的变化幅度**：

```javascript
// 视觉变化对比：
高频噪声 (系数=1.0):
  相邻粒子: 噪声值可能差异很大
  视觉: 每个粒子看起来都不同 → 变化"细碎"

低频噪声 (系数=0.2):
  相邻粒子: 噪声值相似
  视觉: 形成连续的、大块的图案 → 变化"明显"
```

**简单说**：

- 高频：很多小变化，但每个变化不明显
- 低频：较少的大变化，每个变化很显著

#### 6. 实际应用选择

```glsl
// 根据不同需求选择系数：
float noise;

// 1. 想要明显的、大块的图案
noise = simplexNoise3d(position * 0.1);

// 2. 想要中等颗粒度
noise = simplexNoise3d(position * 0.3);

// 3. 想要精细的、随机的效果
noise = simplexNoise3d(position * 1.0);

// 4. 动态调整（根据进度）
float scale = mix(0.1, 0.5, uProgress);
noise = simplexNoise3d(position * scale);
```

------



### 六、视锥裁剪问题

#### 1. 问题现象

```
切换模型动画后，模型边界一直是第一模型
这样会导致，模型移出视锥时突然消失
```

#### 2. 根本原因：THREE.js的边界框（BoundingBox）机制

#### 默认行为：

```javascript
// THREE.js为每个几何体计算边界框
geometry.computeBoundingBox();
// 用于视锥裁剪：检查物体是否在相机视野内
```

##### 粒子系统的特殊情况：

```javascript
// 粒子在变形过程中位置变化
// 但边界框可能没有更新

// 假设：
// 模型1（兔子）：边界框小
// 模型2（大象）：边界框大

// 从兔子变形到大象时：
// 粒子逐渐移动到更大的范围
// 但边界框仍是兔子的
// 当粒子飞出兔子边界框 → 被裁剪 → 突然消失
```

#### 3. 代码解决方案

```javascript
particles.points.frustumCulled = false;
```

##### 这行代码的作用：

1. **禁用视锥裁剪**：物体永远被渲染，无论是否在相机视野内
2. **绕过边界框检查**：不检查物体边界框与视锥体的交集

#### 4. 其他可能的解决方案

##### 方案A：动态更新边界框

```javascript
// 在动画循环中更新
function animate() {
    particles.geometry.computeBoundingBox();
    particles.geometry.computeBoundingSphere();
    // 缺点：性能消耗大
}
```

##### 方案B：使用最大边界框

```javascript
// 预先计算所有模型的合并边界框
const bigBoundingBox = new THREE.Box3();
// 扩展为所有模型的最大范围
particles.geometry.boundingBox = bigBoundingBox;
// 缺点：可能过度渲染
```

##### 方案C：自定义裁剪逻辑

```javascript
// 在着色器中处理
// 优点：更精确
// 缺点：复杂
```

#### 5. 为什么选择 `frustumCulled = false`？

**权衡考虑：**

```javascript
// 粒子系统的特性：
1. 粒子数量多，但每个粒子渲染成本低
2. 粒子可能飞到任何位置
3. 频繁更新边界框成本高
4. 过度渲染的影响相对较小

// 结论：
// 禁用裁剪是粒子系统的常见做法
```

#### 6. 性能影响分析

```javascript
// 启用裁剪时：
// CPU：计算边界框与视锥体交集
// GPU：只渲染可见粒子
// 内存：正常

// 禁用裁剪时：
// CPU：无裁剪计算
// GPU：渲染所有粒子（包括视锥体外）
// 内存：正常

// 对于粒子系统，GPU渲染所有粒子通常开销不大
// 因为粒子是简单的点或小精灵
```

#### 7. 优化建议

如果担心性能，可以：

```javascript
// 1. 使用LOD（Level of Detail）
// 远离相机时减少粒子数量

// 2. 手动管理可见性
if (camera.position.distanceTo(particles.position) > 100) {
    particles.visible = false;
}

// 3. 使用自定义裁剪着色器
// 在顶点着色器中早期丢弃不可见粒子
```



## P43 GPGPU Glow Field Particles Shaders 粒子船

### 课程核心目标

通过GPGPU技术实现一个由粒子组成的船模型，模拟粒子随风飘动的流体效果，涉及大规模粒子计算和实时物理模拟。

------

### 一、基础概念与架构设计

#### **Q1: 为什么要使用GPGPU而不是传统着色器？**

**我的思考**：既然Three.js已经有顶点和片元着色器，为什么还要额外引入复杂的GPGPU架构？

**详细解答**：
这是架构层面的根本选择，传统渲染着色器与GPGPU计算有本质区别：

| 维度           | 传统顶点/片元着色器      | GPGPU计算                        |
| :------------- | :----------------------- | :------------------------------- |
| **设计目的**   | 为单帧渲染服务           | 跨帧状态维护与迭代计算           |
| **数据持久性** | 数据在渲染调用后丢弃     | 数据在纹理中持久保存（帧间记忆） |
| **计算范式**   | "函数式"：输入→处理→输出 | "进程式"：读取→更新→写入→迭代    |
| **交互能力**   | 难以实现粒子间相互作用   | 轻松采样邻居数据实现复杂物理     |

**课程中的应用**：

```javascript
// GPGPU架构的核心优势：状态持久化
const gpgpu = {
    size: Math.ceil(Math.sqrt(vertexCount)),  // 计算纹理尺寸
    computation: new GPUComputationRenderer(), // 专用计算渲染器
    particlesVariable: null // 存储粒子状态的变量
};
```



粒子船模拟需要：

1. **记住每个粒子的上一帧位置**（传统着色器无法做到）
2. **计算粒子间的流体相互作用**（需要全局数据访问）
3. **多步骤物理计算**（密度→压力→速度→位置）

这些需求决定了必须使用GPGPU架构。

------

### 二、GPGPU使用时机判断标准

#### **核心决策标准**

1. **数据并行性**

   - **适合**：对大量独立数据单元执行相同或类似操作（10,000个粒子各自计算位置）
   - **不适合**：强顺序依赖、复杂分支逻辑、递归算法

2. **计算密度**（计算操作数 ÷ 内存访问量）

   - **高密度（用GPGPU）**：每个数据元素至少需要50-100次浮点运算
   - **低密度（可能不适合）**：计算少，内存访问多

3. **状态持久化和迭代需求**

   - **需要GPGPU**：模拟系统（物理、流体、粒子系统）、机器学习、优化算法
   - **不需要**：静态变换、实时滤镜（每帧独立）

4. **数据量大小**

   - <1,000单元：CPU或传统着色器

   - 1,000-10,000：考虑GPGPU（你的粒子船在此范围）

   - > 10,000单元：强烈推荐GPGPU

   - > 1,000,000单元：必须用GPGPU

#### **具体应用场景**

| 应该使用GPGPU                    | 可能不需要GPGPU                  |
| :------------------------------- | :------------------------------- |
| 大规模粒子系统（流体、群体行为） | 传统3D渲染（网格变换、基础光照） |
| 物理模拟（布料、流体动力学）     | 简单后处理（颜色校正、简单模糊） |
| 图像处理与计算机视觉             | UI/2D渲染                        |
| 通用计算（矩阵运算、排序）       |                                  |

------

### 三、GPGPU核心机制

#### **Q2: FBO是什么？为什么需要乒乓缓冲？**

**我的思考**：如果只是为了存储数据，一个纹理不够吗？

**详细解答**：
**FBO（Framebuffer Object）** 是离屏的帧缓冲对象，用于渲染到纹理而非屏幕。

**乒乓缓冲的必要性**（解决GPU读写冲突）：

javascript

```
// 错误的单纹理方案：
texture.write(currentData); // 写入新数据
nextData = texture.read();  // ❌ 读到的是刚写入的数据！

// 正确的乒乓缓冲：
frame1: 从FBO_A读取 → 计算 → 写入FBO_B
frame2: 从FBO_B读取 → 计算 → 写入FBO_A
frame3: 从FBO_A读取 → 计算 → 写入FBO_B
```



**课程实现**：

glsl

```
// particles.glsl中
void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec4 particle = texture(uParticles, uv); // 从纹理A读取
    // ... 计算新状态 ...
    gl_FragColor = particle; // 写入纹理B
}
// GPUComputationRenderer自动处理纹理交换
```



#### **关键概念解析**

**`setVariableDependencies` 的意义**：

javascript

```
gpgpu.computation.setVariableDependencies(gpgpu.particlesVariable, [
    gpgpu.particlesVariable,
]);
```



- 实现**状态迭代**：新值基于当前值计算
- 类比：`position = position + velocity * deltaTime`

**`setDrawRange` 的作用**：

javascript

```
particles.geometry.setDrawRange(0, baseGeometry.count);
```



- 告诉渲染器只绘制前 `baseGeometry.count` 个顶点
- 避免绘制多余顶点（计算纹理尺寸可能大于实际粒子数）

**`setAttribute` 与 `uniforms` 的区别**：

| 特性         | `attribute`                | `uniform`             |
| :----------- | :------------------------- | :-------------------- |
| **数据维度** | 逐顶点变化                 | 全局常量              |
| **用途**     | 顶点的特性数据（如UV坐标） | 着色器的环境/状态数据 |
| **类比**     | 电话簿中一个人的名字       | 整本电话簿            |

------

### 四、坐标系统理解

#### **Q3: `gl_FragCoord` vs `gl_PointCoord`的区别？**

**我的思考**：两者都是坐标，为什么在GPGPU计算中用`gl_FragCoord`？

**详细解答**：
这是**计算上下文**与**渲染上下文**的根本区别：

| 坐标类型            | 所在上下文    | 坐标范围                  | 用途                   |
| :------------------ | :------------ | :------------------------ | :--------------------- |
| **`gl_FragCoord`**  | GPGPU计算Pass | `(0,0)`到`(width,height)` | 标识当前处理的数据单元 |
| **`gl_PointCoord`** | 最终渲染Pass  | `(0.0,0.0)`到`(1.0,1.0)`  | 绘制点精灵的内部坐标   |

**关键理解**：

- `particles.glsl` 中的 `gl_FragCoord` **不是屏幕坐标**，而是**当前计算纹理（FBO）的像素坐标**。这个FBO是后台的、离屏的、正方形的纹理，专门用来存储粒子数据
- 而`gl_PointCoord`只在将粒子绘制为点精灵时才存在。
- GPGPU计算阶段在渲染一个覆盖整个计算纹理的正方形

#### **`resolution`的来源与作用**

**Q**：`particles.glsl`中的`resolution`是哪来的？
**A**：`GPUComputationRenderer` 内部在创建计算着色器程序时，自动为你添加并传递了这个 `uniform` 变量。

- **来源**：当你调用 `gpgpu.computation.addVariable(“uParticles”, gpgpuParticlesShader, baseParticlesTexture)` 时，`GPUComputationRenderer` 会读取你提供的 `gpgpuParticlesShader` 字符串，并**在背后悄悄地做了一次“包装”**。它会识别你的代码，并自动为你补全一个完整的着色器程序。
- **目的**：这个 `resolution` 统一指代了你初始化 `GPUComputationRenderer` 时设定的**计算纹理的尺寸** (`gpgpu.size`, `gpgpu.size`)。在着色器中，你需要用它来将屏幕像素坐标 `gl_FragCoord.xy` 转换为归一化的纹理坐标 `uv`。

**为什么用正方形纹理**：

1. **GPU效率**：方形、2的幂次方尺寸效率最高
2. **简化寻址**：`index = y * size + x`公式最简单
3. **容量保证**：`size = ceil(sqrt(N))`确保足够存储槽位

------

### 五、噪声流场生成技术

#### **Q4: SimplexNoise 2D/3D/4D的区别？**

**我的思考**：为什么流体计算要用4D噪声？

**详细解答**：
噪声维度决定动画复杂性和真实性：

| 维度   | 输入            | 输出特点       | 流体应用           |
| :----- | :-------------- | :------------- | :----------------- |
| **2D** | `vec2(x,y)`     | 静态平面场     | 2D纹理效果         |
| **3D** | `vec3(x,y,z)`   | 静态体积场     | 3D云朵、大理石纹理 |
| **4D** | `vec4(x,y,z,t)` | **动态体积场** | **流体模拟核心**   |

**4D噪声的关键作用**：

glsl

```
vec3 flowField = vec3(
    simplexNoise4d(vec4(position.xyz, uTime)),     // X分量
    simplexNoise4d(vec4(position.xyz + 100.0, uTime)), // Y分量
    simplexNoise4d(vec4(position.xyz + 200.0, uTime))  // Z分量
);
```



- **输出 ≈ [-1, 1]**，需要乘以强度系数
- **第四维（时间）**：确保流场随时间平滑演变
- **空间连续性**：相邻位置获得相似噪声值
- **时间连续性**：相邻时间获得相似噪声值

#### **Q5: 为什么给xyz加上0、1、2就解决了整体斜角移动？**

**我的思考**：只是简单加几个数字，为什么能改变运动方向？

**详细解答**：
解决**向量分量相关性**问题：

glsl

```
// 错误：三个分量采样几乎相同的噪声值
vec3 flow = vec3(
    noise(vec4(pos, time)),     // 采样点A
    noise(vec4(pos, time)),     // 还是采样点A
    noise(vec4(pos, time))      // 还是采样点A
);
// 结果：flow ≈ (v, v, v) → 方向接近对角线(1,1,1)

// 正确：采样不同区域的噪声
vec3 flow = vec3(
    noise(vec4(pos + 1.0, time)),  // 采样点A+1.0
    noise(vec4(pos + 2.0, time)),  // 采样点A+2.0
    noise(vec4(pos + 3.0, time))   // 采样点A+3.0
);
// 结果：flow ≈ (v1, v2, v3) → 方向真正随机
```



#### **Q6: 为什么加上uTime就可以无限循环？**

**我的思考**：时间不断增加，噪声函数不会重复吗？

**详细解答**：
Simplex噪声在实数域上是**非周期、无限连续**的函数：

text

```
对于任意 t1 ≠ t2，noise(x,y,z,t1) ≠ noise(x,y,z,t2)
且当 Δt → 0，Δnoise → 0（连续性）
```



**为什么无限**：

- 噪声函数定义域是整个实数空间
- `uTime`单调递增到无穷大
- 每个`uTime`值对应噪声函数的**唯一切片**

------

### 六、粒子生命周期管理

#### **Q7: particle.a的作用和生命周期设计**

**我的思考**：为什么需要生命周期？直接让粒子一直运动不行吗？

**详细解答**：
生命周期解决**形态保持**与**持续运动**的矛盾：

text

```
没有生命周期：
粒子受流场影响不断运动 → 船形状逐渐消散 → 最终变成一团乱麻

有生命周期：
粒子运动一段时间 → 重置回原始位置 → 船形状保持但粒子更新
```



**课程实现**：

glsl

```
// 粒子数据格式：vec4(x, y, z, a)
// a ∈ [0, 1) 表示生命周期进度
if(particle.a >= 1.0) {          // 粒子"死亡"
    particle.a = mod(particle.a, 1.0); // 重置生命周期
    particle.xyz = base.xyz;           // 重置位置
} else {                          // 粒子"活着"
    particle.xyz += flowField * uDeltaTime; // 运动
    particle.a += uDeltaTime * 0.3;        // 年龄增长
}
```



#### **Q8: 为什么不直接`particle.a = 0.0`而用`mod()`？**

**我的思考**：重置为0不是更简单吗？

**详细解答**：
这是**同步重置** vs **错峰重生**的选择：

javascript

```
// 模拟5个粒子的生命周期
const particles = [
    { a: 0.95 }, { a: 0.80 }, { a: 0.65 }, { a: 0.50 }, { a: 0.35 }
];
// 所有粒子增加0.3寿命后...

// 方案A：直接置0（同步重生）
// 结果：粒子1,2的a=0.0；粒子3,4,5的a=0.95,0.80,0.65
// 视觉效果：脉冲式、心跳式的集体行为

// 方案B：取模（错峰重生）
// 结果：粒子1的a=0.25；粒子2的a=0.10；粒子3,4,5不变
// 视觉效果：连续平滑的水流效果
```



**选择`mod()`的原因**：

1. **流体连续性**：真实流体粒子不会集体消失又出现
2. **视觉平滑性**：避免"闪烁"或"脉冲"效果
3. **计算稳定性**：保证结果在`[0,1)`，避免负值

#### **Q9: 为什么decay也要乘以uDeltaTime？**

**我的思考**：粒子运动乘uDeltaTime理解，但年龄增长为什么也要？

**详细解答**：
这是**帧率无关模拟**的基本原则：

glsl

```
// 错误：基于帧数的decay（帧率依赖）
particle.a += 0.01;
// 60FPS：每秒a增加60×0.01 = 0.6
// 30FPS：每秒a增加30×0.01 = 0.3
// 同样的3秒，年龄差一倍！

// 正确：基于真实时间的decay（帧率无关）
particle.a += uDeltaTime * 0.3;
// 60FPS：uDeltaTime≈0.0167，每秒增加60×0.0167×0.3≈0.3
// 30FPS：uDeltaTime≈0.0333，每秒增加30×0.0333×0.3≈0.3
// 结果一致！
```



**物理模拟的黄金法则**：

text

```
凡是随时间变化的量（位置、速度、年龄、能量...）
必须乘以时间增量（uDeltaTime）
```



------

### 七、局部流动控制技术

#### **Q10: influence如何影响粒子运动范围？**

**我的思考**：influence只是一个随机阈值，怎么能控制流动范围？

**详细解答**：
`influence`不是随机数，而是**选择性阈值**：

glsl

```
// 1. 计算基础噪声强度
float strength = simplexNoise4d(vec4(base.xyz * 0.2, time + 1.0));
// strength ∈ [-1.0, 1.0]，表示该位置的"流动倾向"

// 2. 计算动态阈值
float influence = (uFlowFieldInfluence - 0.5) * (-2.0);
// uFlowFieldInfluence ∈ [0.0, 1.0] 是GUI可调参数
// 映射关系：
//   0.0 → 1.0   (高阈值，只有强噪声点动)
//   0.5 → 0.0   (中阈值，中等以上点动)
//   1.0 → -1.0  (低阈值，几乎所有点动)

// 3. 应用阈值过滤
strength = smoothstep(influence, 1.0, strength);
// smoothstep(influence, 1.0, x) 效果：
//   x < influence → 0.0  (完全不动)
//   x > 1.0 → 1.0        (完全运动)
//   influence < x < 1.0 → 平滑过渡值
```



**阈值控制效果**：

text

```
噪声强度分布:  [-1.0  -0.5   0.0   0.5   1.0]
                |-----|-----|-----|-----|
                
当influence=0.8时:
受影响区域:               [0.8   ...   1.0] ← 仅最强20%的区域
strength值:                0.0→1.0平滑过渡

当influence=0.0时:
受影响区域:          [0.0   ...   1.0] ← 中等以上50%的区域

当influence=-0.8时:
受影响区域:  [-0.8   ...   1.0] ← 几乎全部90%的区域
```



**艺术控制**：

- 低`uFlowFieldInfluence`：只有"特征明显"的区域流动，保持船形状
- 高`uFlowFieldInfluence`：大部分区域流动，获得整体消散效果

------

### 八、课程技术演进总结

![GPGPU粒子船流体模拟课程思路](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-2/GPGPU粒子船流体模拟课程思路.png)

#### **阶段演进路径**

##### 阶段一：基础流场建立

- **目标**：让粒子动起来
- **技术**：Simplex噪声生成3D向量场
- **问题**：粒子朝相似方向(斜角)运动
- **突破**：XYZ分量分别添加偏移(0,1,2)，破坏相关性，获得真正随机方向

##### 阶段二：打破时间循环

- **现象**：粒子运动轨迹重复
- **洞察**：静态噪声场导致有限状态空间
- **方案**：引入`uTime`作为第四维输入，创造无限演化的动态场

##### 阶段三：形态保持机制

- **核心矛盾**：粒子扩散 vs 形状保持
- **创新设计**：`particle.a`生命周期系统
- **重生锚点**：`uBase`纹理存储原始位置
- **GPU特性**：纹理只读访问，无数据拷贝开销

##### 阶段四：优化视觉连续性

- **问题识别**：同步重生产生不自然的“心跳效应”
- **解决方案**：随机化初始年龄，创造错峰重生
- **效果提升**：从脉冲式动画变为连续流动

##### 阶段五：物理正确性

- **核心原则**：基于真实时间而非渲染帧数
- **实现方式**：所有累积变化量乘以`uDeltaTime`
- **意义**：确保60FPS和30FPS设备体验一致

##### 阶段六：边缘情况修复

- **触发场景**：页面切换后返回
- **问题本质**：`uDeltaTime`突增导致年龄同步
- **优雅方案**：`mod()`运算维持错峰分布
- **设计哲学**：异常情况下的健壮性

##### 阶段七：艺术化控制

- **需求升级**：从技术实现到艺术表达
- **关键技术**：
  1. 基于位置的噪声强度映射(`strength`)
  2. 重映射到[0,1]范围(`smoothstep`)
  3. 可调阈值控制(`influence`)
- **控制维度**：从“整体消散”到“局部流动”的连续调节



## P44 Wobbly  Sphere Shader 流体球 曲面法线计算

### 📦 核心概念

[**Custom Shader Material**](https://www.npmjs.com/package/three-custom-shader-material)是一个用于在 Three.js 标准材质基础上添加自定义着色器代码的工具，通过**扩展而非替换**的方式工作，保留原材质的光照、阴影、PBR等特性，同时实现自定义效果。

### 🔍 核心问题与解决方案

#### 1. 表面波动与阴影问题

**问题根源**：

- 顶点通过噪声函数形变后，**几何形状改变**
- 但**原始法线未更新**，仍指向原方向
- 导致**光照计算错误**，阴影显示为原始表面状态

**完整解决思路**：

##### ① 表面波动实现

glsl

```
// 应用噪声函数产生波动
float wobble = getWobble(csm_Position);
csm_Position += wobble * normal;  // 沿法线方向偏移
```



##### ② 法线重新计算（核心）

关键突破：**曲面不能直接用xz平面计算**，需要局部坐标系

数学原理：

当表面函数为 `P(x,y) = (x, y, f(x,y))` 时：

- 切线向量：`T = ∂P/∂x`
- 副法线向量：`B = ∂P/∂y`
- 法线向量：`N = T × B`（叉乘）

glsl

```
// 步骤1：获取基础向量
vec3 biTangent = cross(normal, tangent.xyz);

// 步骤2：计算相邻点（数值微分）
float shift = 0.01;
vec3 positionA = csm_Position + tangent.xyz * shift;
vec3 positionB = csm_Position + biTangent.xyz * shift;

// 步骤3：对每个点应用相同的形变函数
float wobble = getWobble(csm_Position);
csm_Position += wobble * normal;  // 形变当前点
positionA += getWobble(positionA) * normal;  // 形变切线方向点
positionB += getWobble(positionB) * normal;  // 形变副切线方向点

// 步骤4：计算新的切平面向量
vec3 toA = normalize(positionA - csm_Position);  // 近似∂P/∂x
vec3 toB = normalize(positionB - csm_Position);  // 近似∂P/∂y

// 步骤5：叉乘得到新法线并归一化
csm_Normal = normalize(cross(toA, toB));
```



**为什么需要切线和副切线**：

- 切线和副切线是**单位向量**，构成曲面局部坐标系
- 乘以 `shift = 0.01` 实现**数值微分**：
  - 微小偏移获取相邻点位置
  - 近似计算表面导数
  - 平衡精度与浮点稳定性

##### ③ 阴影修复

问题：阴影映射使用**深度材质**，未包含波动计算

javascript

```
const depthMaterial = new CustomShaderMaterial({
    baseMaterial: THREE.MeshDepthMaterial,
    vertexShader: wobbleVertexShader,  // 使用相同的波动着色器
    uniforms,
    depthPacking: THREE.RGBADepthPacking  // 提高深度精度
});

wobble.customDepthMaterial = depthMaterial;
```



#### 2. depthPacking: THREE.RGBADepthPacking

##### **作用与区别**

| 设置                 | 渲染结果     | 存储方式                 | 精度             |
| :------------------- | :----------- | :----------------------- | :--------------- |
| **无/默认**          | 单通道灰度图 | R通道存储深度            | 8位/通道         |
| **RGBADepthPacking** | RGBA四通道图 | 32位深度拆分为4个8位分量 | 等效32位浮点精度 |

##### **工作原理**

glsl

```
// 编码过程（Three.js内部处理）
vec4 packDepthToRGBA(float depth) {
    const vec4 bitShift = vec4(1.0, 256.0, 256.0 * 256.0, 256.0 * 256.0 * 256.0);
    const vec4 bitMask = vec4(1.0/256.0, 1.0/256.0, 1.0/256.0, 0.0);
    vec4 res = fract(depth * bitShift);
    res -= res.xxyz * bitMask;
    return res;
}
```

##### **实际应用场景**：

1. **阴影映射**：需要高精度深度比较时
2. **自定义深度材质**：如示例中的 `MeshDepthMaterial`
3. **后期处理**：需要精确深度信息的特效（如景深、雾效）
4. **几何重建**：从深度纹理重建世界位置

**在示例中的用途**：

javascript

```
const depthMaterial = new CustomShaderMaterial({
    baseMaterial: THREE.MeshDepthMaterial,
    vertexShader: wobbleVertexShader,
    uniforms,
    depthPacking: THREE.RGBADepthPacking,  // 启用高精度深度打包
});
```

#### 

#### 3. csm_DiffuseColor 与 csm_FragColor 区别

##### **光照管线差异**

text

```
csm_DiffuseColor 路径：
自定义颜色 → 基础材质光照计算 → 阴影、反射、折射 → 最终输出

csm_FragColor 路径：
自定义颜色 → 直接输出（绕过所有材质计算）
```



##### **技术实现对比**

| 特性         | csm_DiffuseColor     | csm_FragColor          |
| :----------- | :------------------- | :--------------------- |
| **光照计算** | 保留，基于物理       | 完全绕过               |
| **PBR支持**  | 支持金属度、粗糙度等 | 不支持                 |
| **阴影**     | 自动计算             | 需要手动实现           |
| **性能**     | 较重（完整管线）     | 较轻（直接输出）       |
| **使用场景** | 需要真实感材质       | 全屏特效、UI、卡通渲染 |

### 

### 📊 GLSL向量运算核心

#### dot（点积）与 cross（叉积）对比

| 特性         | 点积（dot）       | 叉积（cross）        |
| :----------- | :---------------- | :------------------- |
| **结果类型** | 标量（float）     | 向量（vec3）         |
| **输入维度** | 任意相同维度      | 仅三维向量           |
| **几何意义** | 相似度/投影       | 垂直方向/面积        |
| **交换律**   | 可交换：a·b = b·a | 不可交换：a×b = -b×a |

#### 关键应用场景

点积典型用途

glsl

```
// 光照计算
float diffuse = max(dot(normal, lightDir), 0.0);

// 菲涅尔效应
float fresnel = pow(1.0 - dot(viewDir, normal), 5.0);

// 边缘检测
float rim = 1.0 - dot(normal, viewDir);
```



叉积典型用途

glsl

```
// 构建切线空间
vec3 bitangent = cross(normal, tangent.xyz);

// 计算表面法线
csm_Normal = normalize(cross(toA, toB));

// 计算三角形面积
float area = 0.5 * length(cross(edge1, edge2));
```





## P45 Sliced Model Shader 截面展示

### 一、核心思路：动态切割3D模型

#### 目标效果

创建一个动态的扇形切割效果，让模型的一部分被"切除"，可以看到内部结构，类似于机械模型的截面展示。

------

### 二、实现步骤详解

#### 第1步：基本角度计算与丢弃

glsl

```
// 使用atan计算每个片元的极坐标角度
float angle = atan(vPosition.y, vPosition.x);
// 直接丢弃特定角度范围内的片元
if(angle > uSliceStart && angle < uSliceStart + uSliceArc) {
    discard;
}
```



**问题**：直接这样写会遇到角度循环问题（-π和π表示同一个方向）。

------

#### 第2步：解决角度计算问题 - 基准点平移

##### 关键理解：`angle -= uSliceStart;`

**几何意义**：

1. 假设原始坐标系中，X轴正方向是0度
2. `uSliceStart` 是我们想要开始切割的位置（比如115°）
3. 执行 `angle -= uSliceStart` 相当于：
   - **将所有的点顺时针旋转 uSliceStart 角度**
   - **等价于将坐标轴逆时针旋转 uSliceStart 角度**

##### 举例说明：

假设 `uSliceStart = 2.0`（约115°）：

- 原本在115°的点 → 现在在0°
- 原本在150°的点 → 现在在35°
- 原本在60°的点 → 现在在-55°

**这样做的目的**：把切割起始点变成新的"0度参考点"，使后续判断变得简单。

------

#### 第3步：角度归一化处理

##### 问题：负角度的处理

- 平移后，有些点角度变为负值（如-55°）
- 但在圆周上，-55°和305°是同一个点

##### 解决方案：`angle = mod(angle, PI2);`

**作用**：将所有角度映射到 [0, 2π) 区间

- -55° → 305°（360° - 55°）
- 370° → 10°（370° - 360°）

**最终代码**：

glsl

```
float angle = atan(vPosition.y, vPosition.x);
angle -= uSliceStart;    // 基准点平移（坐标轴逆时针旋转）
angle = mod(angle, PI2); // 角度归一化到[0, 2π)

if(angle < uSliceArc) {  // 判断是否在切割范围内
    discard;
}
```



**现在只需要判断是否在 [0, uSliceArc] 范围内！**

------

### 三、解决模型空心显示问题

#### 问题：切割后内部不可见

当模型被切割后，内部是空的，但通常我们希望看到内部结构。

#### 初始方案：背面着色

glsl

```
if(!gl_FrontFacing) {
    csm_FragColor = vec4(.75, .15, .3, 1.0); // 给背面设置红色
}
```



**新问题**：这样设置会跳过Three.js的正常渲染流程，导致阴影、光照等效果丢失。

------

#### 最终方案：使用patchMap

**原理**：在Three.js的着色器编译过程中插入自定义代码，而不影响原有渲染管线。

javascript

```
const patchMap = {
    csm_Slice: {
        "#include <colorspace_fragment>": `
            #include <colorspace_fragment>
            
            // 在颜色空间转换后，添加背面颜色
            if(!gl_FrontFacing) {
                gl_FragColor = vec4(0.75, 0.15, 0.3, 1.0);
            }
        `,
    },
};
```



**优势**：

1. 保留了Three.js原有的光照、阴影计算
2. 只在最终颜色输出阶段修改背面颜色
3. 不影响深度测试、模板测试等渲染流程

------

### 四、完整实现流程

#### 1. 顶点着色器（vertex.glsl）

glsl

```
varying vec3 vPosition;
void main() {
    vPosition = csm_Position.xyz; // 传递模型空间位置
    // 其他顶点变换代码...
}
```



#### 2. 片段着色器（fragment.glsl）

glsl

```
uniform float uSliceStart;
uniform float uSliceArc;
varying vec3 vPosition;

#define PI2 6.28318530718

void main() {
    // 计算并处理角度
    float angle = atan(vPosition.y, vPosition.x);
    angle -= uSliceStart;    // 关键：基准点平移
    angle = mod(angle, PI2); // 归一化
    
    // 切割判断
    if(angle < uSliceArc) {
        discard;
    }
    
    // 注意：不再直接设置csm_FragColor
    // 背面颜色通过patchMap处理
    // 正面的正常材质颜色由Three.js自动处理
}
```



#### 3. JavaScript材质配置

javascript

```
const uniforms = {
    uSliceStart: { value: 1.75 },
    uSliceArc: { value: 1.25 }
};

const slicedMaterial = new CustomShaderMaterial({
    baseMaterial: THREE.MeshStandardMaterial,
    vertexShader: slicedVertexShader,
    fragmentShader: slicedFragmentShader,
    uniforms: uniforms,
    patchMap: patchMap, // 关键：插入背面颜色逻辑
    side: THREE.DoubleSide, // 双面渲染
    // 其他材质属性...
});
```





## P46 Procedural Terrain Shader 山峦

### 📚 课程核心思路概览

本课程通过 **5个关键技术环节** 构建完整的程序化地形系统：

text

```
1. 模型操作 → 2. 地形生成 → 3. 阴影优化 → 4. 材质效果 → 5. 视觉美化
   ↓           ↓           ↓           ↓           ↓
three-bvh-csg 噪声叠加   法线计算    水面材质    颜色混合
 布尔运算     分形地形   customDepth 透射效果    高度分层
```



### 🎯 一、利用 [three-bvh-csg](https://www.npmjs.com/package/three-bvh-csg) 实现模型的拉伸切除



#### 1.1 创建"画框"效果

javascript

```
// 1. 创建两个基础几何体作为刷子
const boardFill = new Brush(new THREE.BoxGeometry(11, 2, 11));  // 外框填充
const boardHole = new Brush(new THREE.BoxGeometry(10, 2.1, 10)); // 内部挖空

// 2. 关键：调整挖空位置，实现底部保留
boardHole.position.y = 0.2  // 向上偏移，保留底部
boardHole.updateMatrixWorld()  // 必须调用，更新世界矩阵

// 3. 执行布尔减法运算（挖空效果）
const evaluator = new Evaluator();
const board = evaluator.evaluate(boardFill, boardHole, SUBTRACTION);

// 4. 清理分组并设置材质
board.geometry.clearGroups();
board.material = new THREE.MeshStandardMaterial({
    color: "#ffffff",
    metalness: 0,
    roughness: 0.3,
});
```



#### 1.2 技术要点解析

- **布尔运算**：使用减法(SUBTRACTION)创建边框
- **位置偏移**：通过 `position.y = 0.2` 保留底部厚度
- **矩阵更新**：`updateMatrixWorld()` 确保变换生效
- **分组清理**：`clearGroups()` 避免材质分组干扰

### 🌄 二、叠加噪声创造地形（分形噪声详解）

#### 2.1 分形噪声叠加原理

glsl

```
// 核心代码解析：
float getElevation(vec2 position) {
    // 1. 基础噪声层（低频，决定大结构）
    elevation += simplexNoise2d(position * uPositionFrequency) / 2.0;
    
    // 2. 细节噪声层（中频，添加山脊等特征）
    elevation += simplexNoise2d(position * uPositionFrequency * 2.0) / 4.0;
    
    // 3. 精细噪声层（高频，表面纹理）
    elevation += simplexNoise2d(position * uPositionFrequency * 4.0) / 8.0;
    
    return elevation;
}
```



#### 2.2 分形噪声可视化解释

text

```
频率/振幅关系：
第1层：频率×1，振幅×1/2  → 控制大型山脉山谷
第2层：频率×2，振幅×1/4  → 添加中等山脊丘陵
第3层：频率×4，振幅×1/8  → 提供表面粗糙细节

最终地形 = 大型地形 + 中型特征 + 微小细节
```



#### 2.3 为什么要这样叠加？

1. **自相似性**：在不同尺度上都有类似的结构
2. **计算效率**：3-5层就能获得很好的自然效果
3. **可控性**：通过权重系数精确控制各层贡献
4. **避免平铺感**：多频率叠加打破重复模式

### ⚡ 三、更新法线修正阴影

#### 3.1 法线计算原理

glsl

```
// 手动计算法线（因为顶点位置被程序修改）
void main() {
    // 1. 获取当前点相邻的两个点
    vec3 positionA = position.xyz + vec3(shift, .0, .0);
    vec3 positionB = position.xyz + vec3(.0, .0, -shift);
    
    // 2. 计算相邻点的海拔
    positionA.y = getElevation(positionA.xz);
    positionB.y = getElevation(positionB.xz);
    
    // 3. 计算方向向量并叉积得到法线
    vec3 toA = normalize(positionA - csm_Position);
    vec3 toB = normalize(positionB - csm_Position);
    csm_Normal = cross(toA, toB);
}
```



#### 3.2 为什么必须手动计算法线？

- **原始法线失效**：顶点位置被噪声函数修改
- **光照依赖法线**：法线决定表面如何反射光线
- **阴影准确性**：错误的法线会导致阴影异常
- **视觉真实感**：正确的法线提供立体感和深度感

### 🎭 四、更新 customDepthMaterial 修正整体阴影

#### 4.1 深度材质配置

javascript

```
// 创建自定义深度材质（用于阴影计算）
const depthMaterial = new CustomShaderMaterial({
    baseMaterial: THREE.MeshDepthMaterial,  // 基础深度材质
    vertexShader: terrainVertexShader,      // 使用相同顶点着色器
    uniforms,
    depthPacking: THREE.RGBADepthPacking    // 深度打包方式
});

// 应用到地形网格
terrain.customDepthMaterial = depthMaterial;
```



#### 4.2 深度材质的重要性

text

```
默认阴影计算：
地形平面 → 原始几何体 → 错误阴影

自定义深度材质：
地形平面 → 程序化几何体 → 正确阴影

原因：Three.js的阴影系统需要知道顶点的实际位置
```



#### 4.3 技术实现细节

1. **复用顶点着色器**：确保深度计算与渲染一致
2. **深度打包**：`RGBADepthPacking` 优化精度
3. **性能考虑**：深度材质仅用于阴影计算，不参与渲染

### 💧 五、Water 为什么用 MeshPhysicalMaterial

#### 5.1 材质选择对比

javascript

```
// 方案1：MeshPhysicalMaterial（正确选择）
const waterMaterial = new THREE.MeshPhysicalMaterial({
    transmission: 1,      // 物理透射效果
    roughness: 0.3,       // 水面粗糙度
    // 支持折射、菲涅尔效应等
});

// 方案2：MeshStandardMaterial（次选）
const waterMaterial2 = new THREE.MeshStandardMaterial({
    opacity: 0.5,         // 简单透明度
    // 缺乏物理透射，水看起来不真实
});

// 方案3：MeshBasicMaterial（错误选择）
const waterMaterial3 = new THREE.MeshBasicMaterial({
    color: 0x66a8ff,
    transparent: true,
    opacity: 0.7
    // 无光照交互，像彩色玻璃
});
```



#### 5.2 MeshPhysicalMaterial 的核心优势

1. **物理透射(transmission)**：模拟光线穿过水体的物理行为
2. **折射效果**：自动计算折射，无需手动编写着色器
3. **菲涅尔效应**：不同角度反射率不同（水面特征）
4. **与PBR系统集成**：与其他PBR材质光照一致
5. **性能优化**：相比自定义ShaderMaterial更高效

#### 5.3 水的物理特性实现

javascript

```
// 完整的水面材质配置示例
const waterMaterial = new THREE.MeshPhysicalMaterial({
    color: 0x66a8ff,           // 基础颜色
    transmission: 0.95,        // 透射率（0-1）
    roughness: 0.1,            // 表面粗糙度
    ior: 1.33,                 // 水的折射率
    thickness: 0.5,            // 材质厚度
    specularIntensity: 1,      // 镜面反射强度
    envMap: environmentMap,    // 环境贴图（必须）
    envMapIntensity: 1         // 环境贴图强度
});
```



### 🎨 六、颜色混合实现地形

#### 6.1 基于高度的颜色分层

glsl

```
// 核心混合策略
void main() {
    vec3 color = vec3(1.0);
    
    // 1. 水体深度渐变（平滑过渡）
    float surfaceWaterMix = smoothstep(-1.0, -.1, vPosition.y);
    color = mix(uColorWaterDeep, uColorWaterSurface, surfaceWaterMix);
    
    // 2. 沙滩边界（硬过渡）
    float sandMix = step(-.1, vPosition.y);
    color = mix(color, uColorSand, sandMix);
    
    // 3. 草地边界（硬过渡）
    float grassMix = step(-.06, vPosition.y);
    color = mix(color, uColorGrass, grassMix);
    
    // 4. 岩石（基于坡度）
    float rockMix = vUpDot;  // 法线与上方向的点积（坡度）
    rockMix = 1.0 - step(.8, rockMix);  // 坡度>0.8显示岩石
    rockMix *= grassMix;  // 只在草地上显示岩石
    color = mix(color, uColorRock, rockMix);
    
    // 5. 雪地（带噪声扰动的边界）
    float snowThreshold = .45;
    snowThreshold += simplexNoise2d(vPosition.xz * 15.0) * .1;
    float snowMix = step(snowThreshold, vPosition.y);
    color = mix(color, uColorSnow, snowMix);
}
```



#### 6.2 混合函数详解

#### smoothstep - 平滑过渡

glsl

```
// 适合：水体深度渐变
float mixValue = smoothstep(min, max, height);
color = mix(colorA, colorB, mixValue);
// 效果：min到max之间平滑过渡
```



#### step - 硬边界

glsl

```
// 适合：沙滩/草地边界
float mixValue = step(threshold, height);
color = mix(colorA, colorB, mixValue);
// 效果：height>threshold时使用colorB
```



##### 基于坡度的混合

glsl

```
// 法线与垂直方向的点积
float vUpDot = dot(normal, vec3(0,1,0));
// 值1.0 = 完全水平，值0.0 = 垂直

// 岩石混合逻辑
if (vUpDot < 0.8) {  // 坡度较陡
    color = mix(color, rockColor, 1.0);
}
```



#### 6.3 颜色配置文件

javascript

```
// GUI可调的颜色配置
const debugObject = {
    colorWaterDeep: '#002b3d',     // 深水区颜色
    colorWaterSurface: '#66a8ff',  // 水面颜色
    colorSand: '#ffe894',          // 沙滩颜色
    colorGrass: '#85d534',         // 草地颜色
    colorSnow: '#ffffff',          // 雪地颜色
    colorRock: '#bfbd8d',          // 岩石颜色
};

// 实时更新Uniforms
gui.addColor(debugObject, 'colorGrass')
   .onChange(() => {
       uniforms.uColorGrass.value.set(debugObject.colorGrass);
   });
```



### 🔄 七、完整工作流程总结

#### 7.1 从零到完整地形的步骤

text

```
1. 基础几何体准备
   ↓
2. 分形噪声生成地形
   ↓
3. 计算正确法线
   ↓
4. 配置深度材质（阴影）
   ↓
5. 添加水面（物理材质）
   ↓
6. 实现颜色分层
   ↓
7. 添加边框（CSG）
   ↓
8. 优化和调试
```





## P47 Post processing 后期处理

### 一、核心概念

#### 1. 什么是后期处理

- **定义**：在场景渲染完成后，对渲染图像进行二次处理的技术
- **类比**：类似Photoshop的滤镜效果，在3D渲染后应用
- **优势**：高性能、可组合、实时调整

#### 2. 核心组件[EffectComposer](http://www.yanhuangxueyuan.com/threejs/docs/index.html?q=EffectComposer#examples/en/postprocessing/EffectComposer)

javascript

```
EffectComposer  // 效果合成器（核心控制器）
RenderPass      // 渲染通道（基础渲染）
ShaderPass      // 着色器通道（自定义效果）
其他效果Pass    // 各种内置效果通道
```



### 二、基础设置流程

#### 1. 创建EffectComposer

javascript

```
// 步骤1：创建效果合成器
effectComposer = new EffectComposer(renderer);

// 步骤2：设置尺寸
effectComposer.setSize(sizes.width, sizes.height);
effectComposer.setPixelRatio(sizes.pixelRatio);
```

[使用RenderTarget改善锯齿问题](#使用RenderTarget改善锯齿问题)



#### 2. 添加基础渲染通道

javascript

```
const renderPass = new RenderPass(scene, camera);
effectComposer.addPass(renderPass);
```



#### 3. 渲染循环

javascript

```
// 替换原来的 renderer.render(scene, camera)
effectComposer.render();
```



### 三、常用后期处理效果

#### 1. 点阵效果 (DotScreen)

javascript

```
import { DotScreenPass } from 'three/examples/jsm/postprocessing/DotScreenPass.js';

const dotScreenPass = new DotScreenPass();
dotScreenPass.enabled = false;  // 默认关闭
effectComposer.addPass(dotScreenPass);
```



#### 2. 故障效果 (Glitch)

javascript

```
import { GlitchPass } from 'three/examples/jsm/postprocessing/GlitchPass.js';

const glitchPass = new GlitchPass();
glitchPass.goWild = false;  // 是否狂暴模式
glitchPass.enabled = false;
effectComposer.addPass(glitchPass);
```



#### 3. RGB位移效果 (RGB Shift)

javascript

```
import { ShaderPass } from 'three/examples/jsm/postprocessing/ShaderPass.js';
import { RGBShiftShader } from 'three/examples/jsm/shaders/RGBShiftShader.js';

const rgbShiftPass = new ShaderPass(RGBShiftShader);
rgbShiftPass.enabled = false;
effectComposer.addPass(rgbShiftPass);
```



#### 4. 泛光效果 (Bloom)

javascript

```
import { UnrealBloomPass } from 'three/examples/jsm/postprocessing/UnrealBloomPass.js';

const bloomPass = new UnrealBloomPass(
  new THREE.Vector2(width, height),  // 分辨率
  strength,    // 强度 (0-2)
  radius,      // 半径 (0-2)
  threshold    // 阈值 (0-1)
);

effectComposer.addPass(bloomPass);
```



#### 5. 伽马校正

javascript

```
import { GammaCorrectionShader } from 'three/examples/jsm/shaders/GammaCorrectionShader.js';

const gammaPass = new ShaderPass(GammaCorrectionShader);
effectComposer.addPass(gammaPass);
```



### 四、自定义后期处理效果

#### 1. 创建自定义着色器

javascript

```
const CustomShader = {
  uniforms: {
    tDiffuse: { value: null },     // 输入纹理
    uTime: { value: 0 },           // 时间
    uTint: { value: new THREE.Vector3() }  // 自定义参数
  },
  
  vertexShader: `
    varying vec2 vUv;
    
    void main() {
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
      vUv = uv;
    }
  `,
  
  fragmentShader: `
    uniform sampler2D tDiffuse;
    uniform vec3 uTint;
    uniform float uTime;
    
    varying vec2 vUv;
    
    void main() {
      vec4 color = texture2D(tDiffuse, vUv);
      color.rgb += uTint;  // 应用色调
      
      // 添加动态效果
      color.rgb *= sin(uTime * 2.0) * 0.1 + 0.9;
      
      gl_FragColor = color;
    }
  `
};
```



#### 2. 使用自定义着色器

javascript

```
const customPass = new ShaderPass(CustomShader);
customPass.material.uniforms.uTime.value = 0;
effectComposer.addPass(customPass);

// 在动画循环中更新时间
function animate() {
  const elapsedTime = clock.getElapsedTime();
  customPass.material.uniforms.uTime.value = elapsedTime;
}
```



### 五、抗锯齿处理方案

[各种抗锯齿技术的区别](#各种抗锯齿技术的区别)

#### 1. 多重采样抗锯齿 (MSAA)

javascript

```
// 在WebGLRenderer中启用
const renderer = new THREE.WebGLRenderer({ 
  antialias: true 
});

// 在RenderTarget中设置采样数
const renderTarget = new THREE.WebGLRenderTarget(width, height, {
  samples: 4  // 采样数越高效果越好，性能越低
});
```



#### 2. 后期处理抗锯齿 (SMAA)

[WebGL 2.0浏览器版本兼容信息](https://caniuse.com/webgl2)

javascript

```
import { SMAAPass } from 'three/examples/jsm/postprocessing/SMAAPass.js';

// 在设备像素比为1且不支持WebGL2时使用
if (renderer.getPixelRatio() === 1 && !renderer.capabilities.isWebGL2) {
  const smaaPass = new SMAAPass();
  effectComposer.addPass(smaaPass);
}
```



#### 3. 像素比策略

javascript

```
// 高分屏（Retina）通常不需要额外抗锯齿
const pixelRatio = Math.min(window.devicePixelRatio, 2);
const needsAntialiasing = pixelRatio === 1;  // 普通屏幕需要抗锯齿
```

[为什么pixelRatio大于1时不需要抗锯齿？](#为什么pixelRatio大于1时不需要抗锯齿？)

### 六、性能优化技巧

#### 1. 合理启用/禁用效果

javascript

```
// 动态控制效果开关
const effects = {
  bloom: { pass: bloomPass, enabled: false },
  glitch: { pass: glitchPass, enabled: false }
};

// 根据场景需要启用
function enableEffect(name, enabled) {
  effects[name].pass.enabled = enabled;
  effects[name].enabled = enabled;
}
```



#### 2. 分辨率优化

javascript

```
// 根据性能调整分辨率
function setEffectResolution(scale = 1) {
  const width = sizes.width * scale;
  const height = sizes.height * scale;
  
  effectComposer.setSize(width, height);
}
```



#### 3. 各类型 Pass 的正确顺序

**核心原则：先处理内容，再处理显示**

text

```
渲染顺序很重要：
1. RenderPass（必须第一个）
2. 色彩/色调调整（色调、饱和度、对比度）
3. 几何/位移效果（扭曲、波纹、位移）
4. 模糊/发光类（Bloom、景深、运动模糊）
5. 风格化效果（点阵、故障、素描）
6. 抗锯齿（SMAA、FXAA）
7. 伽马校正（Gamma Correction）
8. 色调映射（Tone Mapping）*
```

> *注：色调映射有时在渲染器中设置，有时作为单独的Pass

### 七、常见问题与解决方案

#### 1. 窗口大小变化模糊

**问题**：改变窗口大小后图像变模糊
**原因**：EffectComposer的渲染目标尺寸未更新
**解决**：

javascript

```
function handleResize() {
  // 更新所有尺寸相关对象
  camera.aspect = sizes.width / sizes.height;
  camera.updateProjectionMatrix();
  
  renderer.setSize(sizes.width, sizes.height);
  renderer.setPixelRatio(sizes.pixelRatio);
  
  effectComposer.setSize(sizes.width, sizes.height);
  effectComposer.setPixelRatio(sizes.pixelRatio);
}
```



#### 2. 性能下降

**解决**：

- 减少RenderTarget的samples数量
- 降低Bloom等效果的分辨率
- 按需启用效果（不是所有效果都需要一直开启）
- 使用更简单的着色器

#### 3. 效果叠加问题

**解决**：调整Pass顺序，注意每个Pass对上一个Pass结果的影响



### 八、实战示例代码结构

javascript

```
// 1. 导入依赖
import { EffectComposer, RenderPass } from 'three/examples/jsm/postprocessing/EffectComposer.js';
import { UnrealBloomPass } from 'three/examples/jsm/postprocessing/UnrealBloomPass.js';
import { ShaderPass } from 'three/examples/jsm/postprocessing/ShaderPass.js';

// 2. 初始化
let composer;
let bloomPass;

function initPostProcessing() {
  // 创建效果合成器
  const renderTarget = new THREE.WebGLRenderTarget(
    window.innerWidth, 
    window.innerHeight,
    { samples: 2 }
  );
  
  composer = new EffectComposer(renderer, renderTarget);
  
  // 添加基础渲染通道
  const renderPass = new RenderPass(scene, camera);
  composer.addPass(renderPass);
  
  // 添加泛光效果
  bloomPass = new UnrealBloomPass(
    new THREE.Vector2(window.innerWidth, window.innerHeight),
    1.5,  // strength
    0.4,  // radius
    0.85  // threshold
  );
  composer.addPass(bloomPass);
  
  // 设置尺寸
  composer.setSize(window.innerWidth, window.innerHeight);
  composer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
}

// 3. 动画循环
function animate() {
  // ... 更新场景
  
  // 渲染后期处理
  composer.render();
  
  requestAnimationFrame(animate);
}

// 4. 窗口大小调整
window.addEventListener('resize', () => {
  // ... 更新相机和渲染器
  
  composer.setSize(window.innerWidth, window.innerHeight);
  composer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
});
```





















## P48



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



## `mod(x, y)`详解

`mod(x, y)` 是 GLSL 中的一个**内置数学函数**，用于计算**模运算**（取余数）。它返回 `x` 除以 `y` 的余数。

### 基本语法

```glsl
float mod(float x, float y)      // 用于浮点数
vec2 mod(vec2 x, vec2 y)         // 用于二维向量
vec3 mod(vec3 x, vec3 y)         // 用于三维向量
vec4 mod(vec4 x, vec4 y)         // 用于四维向量
```



### 数学定义

```glsl
mod(x, y)` 等价于：`x - y * floor(x/y)
```



### 示例和用途

#### 1. **基本取余运算**

```glsl
float a = mod(7.0, 3.0);    // a = 1.0 (7 ÷ 3 = 2 余 1)
float b = mod(5.5, 2.0);    // b = 1.5 (5.5 ÷ 2 = 2 余 1.5)
float c = mod(2.0, 1.5);    // c = 0.5 (2.0 ÷ 1.5 = 1 余 0.5)
```

#### 2. **负数的模运算**

```glsl
float d = mod(-1.0, 3.0);   // d = 2.0
float e = mod(1.0, -3.0);   // e = -2.0
float f = mod(-2.0, 3.0);   // f = 1.0
```

#### 3. **创建重复图案（平铺效果）**

这是 `mod` 在着色器中最常见的用途：

```glsl
// 创建 5x5 的平铺网格
vec2 uv = gl_FragCoord.xy / resolution.xy;
vec2 tiledUV = mod(uv * 5.0, 1.0);
vec3 color = texture2D(texture, tiledUV).rgb;
```

#### 4. **制作棋盘格效果**

```glsl
void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 grid = floor(mod(uv * 10.0, 2.0));
    float checker = mod(grid.x + grid.y, 2.0);
    vec3 color = mix(vec3(1.0), vec3(0.0), checker);
    fragColor = vec4(color, 1.0);
}
```

#### 5. **周期性动画**

```glsl
uniform float time;

void main() {
    // 使用 mod 让动画循环（0-1 循环）
    float progress = mod(time, 3.0) / 3.0;  // 每3秒循环一次
    
    // 或使用 sin 结合 mod 创建更复杂的循环
    float pulse = sin(mod(time, 2.0 * 3.14159));
}
```

#### 6. **限制范围**

```glsl
// 将角度限制在 [0, 2π) 范围内
float angle = mod(theta, 2.0 * 3.14159);

// 将坐标限制在 [0, size) 范围内
float wrappedX = mod(position.x, size);
```



### 与其他取余函数的区别

#### `mod` vs `fract`

```glsl
// mod(x, 1.0) 等价于取小数部分
float a = mod(3.7, 1.0);     // a = 0.7
float b = fract(3.7);        // b = 0.7 （fract 返回小数部分）

// 但 fract(x) 更高效，因为它等价于 x - floor(x)
```

#### `mod` vs `step` 模式

```glsl
// 使用 mod 创建步进模式
void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    // 创建 10 个垂直条纹
    float stripe = mod(uv.x * 10.0, 1.0);
    float stripePattern = step(0.5, stripe);  // 当 stripe >= 0.5 时返回 1
    
    fragColor = vec4(vec3(stripePattern), 1.0);
}
```



### 向量版本的特殊用法

#### 分量独立取余

```glsl
vec2 pos = vec2(7.5, 4.3);
vec2 divisor = vec2(2.0, 1.5);
vec2 remainder = mod(pos, divisor);  // vec2(1.5, 1.3)

// 解释：
// x分量：mod(7.5, 2.0) = 1.5
// y分量：mod(4.3, 1.5) = 1.3
```

#### 统一除数

```glsl
vec3 pos = vec3(5.0, 7.0, 9.0);
vec3 remainder = mod(pos, 3.0);  // vec3(2.0, 1.0, 0.0)
```



### 实际应用示例

#### 1. **制作无限滚动的背景**

```glsl
uniform float scrollSpeed;
uniform float time;

void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    // 创建滚动的UV坐标
    vec2 scrollingUV = uv;
    scrollingUV.y += time * scrollSpeed;
    
    // 使用 mod 让纹理无限重复
    vec2 repeatedUV = mod(scrollingUV, 1.0);
    
    vec3 color = texture2D(backgroundTexture, repeatedUV).rgb;
    fragColor = vec4(color, 1.0);
}
```

#### 2. **制作伪随机分布**

```glsl
// 使用 mod 和 sin 创建伪随机数
float random(vec2 st) {
    return fract(sin(dot(st, vec2(12.9898, 78.233))) * 43758.5453123);
}

// 创建网格化随机分布
vec2 gridPos = floor(uv * 10.0);  // 分成10x10网格
float rand = random(gridPos);     // 每个网格有自己的随机值
```

#### 3. **限制顶点动画范围**

```glsl
// 顶点着色器中限制位移范围
void main() {
    vec3 pos = position;
    
    // 在x方向创建波浪效果，但限制在 [-1, 1] 范围内
    pos.x += sin(time + pos.y) * amplitude;
    pos.x = mod(pos.x + 1.0, 2.0) - 1.0;  // 映射到 [-1, 1)
    
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}
```



### 性能注意事项

1. **`mod` 比 `fract` 慢**：如果只是需要取小数部分，使用 `fract(x)` 而不是 `mod(x, 1.0)`
2. **避免在循环中大量使用**：特别是在片段着色器中，每个像素都会计算
3. **考虑使用 `step` 或 `smoothstep`**：对于某些模式，可以用条件判断替代 `mod`

### 常见错误

```glsl
// 错误：除数为0
float a = mod(x, 0.0);  // 未定义行为，可能导致NaN或inf

// 正确做法：添加保护
float safeMod(float x, float y) {
    return y == 0.0 ? x : mod(x, y);
}
```

`mod` 是 GLSL 中非常实用的函数，特别适合创建重复图案、周期效果和各种网格化视觉效果。

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



## smoothstep(-1.0, 1.0, noise) 的映射详解

### 一、smoothstep函数的基本原理

#### 1. 数学定义

```glsl
// GLSL中的smoothstep函数定义
float smoothstep(float edge0, float edge1, float x) {
    // 第一步：将x限制在[edge0, edge1]范围内，并归一化到[0,1]
    float t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    
    // 第二步：应用平滑曲线 t² * (3 - 2t)
    return t * t * (3.0 - 2.0 * t);
}
```

#### 2. 可视化理解

```
输入x范围:       -2.0   -1.0   0.0   1.0   2.0
              |-----|-----|-----|-----|-----|
smoothstep(-1,1,x):  0.0    0.0   0.5   1.0   1.0
              |     |-----|-----|-----|     |
              固定0       平滑过渡        固定1
```

------



### 二、smoothstep(-1.0, 1.0, noise) 的具体映射

#### 1. 不同输入值的输出结果

##### 情况1：输入在[-1, 1]范围内

```javascript
// 测试一些关键点
const testPoints = [
    { x: -1.0, result: 0.0 },
    { x: -0.75, result: 0.15625 },
    { x: -0.5, result: 0.5 },      // 注意：-0.5映射到0.5！
    { x: 0.0, result: 0.5 },       // 中点
    { x: 0.5, result: 0.5 },       // 注意：0.5也映射到0.5！
    { x: 0.75, result: 0.84375 },
    { x: 1.0, result: 1.0 }
];
```

**关键发现**：

- `-0.5` → `0.5`
- `0.0` → `0.5`
- `0.5` → `0.5`

这意味着**中间区域被压缩**了！

#### 2. 为什么中间值都变成0.5？

```javascript
// 计算过程示例：
x = -0.5:
t = (-0.5 - (-1.0)) / (1.0 - (-1.0)) = 0.5 / 2.0 = 0.25
结果 = 0.25² * (3 - 2*0.25) = 0.0625 * 2.5 = 0.15625
// 我之前的计算有误，这里重新计算

// 正确计算：
x = -0.5:
t = (-0.5 + 1.0) / 2.0 = 0.5 / 2.0 = 0.25
结果 = 0.25² * (3 - 0.5) = 0.0625 * 2.5 = 0.15625

x = 0.0:
t = (0.0 + 1.0) / 2.0 = 1.0 / 2.0 = 0.5
结果 = 0.5² * (3 - 1.0) = 0.25 * 2.0 = 0.5

x = 0.5:
t = (0.5 + 1.0) / 2.0 = 1.5 / 2.0 = 0.75
结果 = 0.75² * (3 - 1.5) = 0.5625 * 1.5 = 0.84375
```

**正确映射表**：

```
x:     -1.0  -0.75  -0.5   0.0   0.5   0.75   1.0
结果:   0.0   0.156  0.156  0.5   0.844 0.844  1.0
```

#### 3. 实际效果：非线性重映射

```javascript
// 原始噪声分布（假设）：
// [-1.0, -0.5]: 25%的粒子
// [-0.5, 0.5]:  50%的粒子（中间密集）
// [0.5, 1.0]:   25%的粒子

// 经过smoothstep(-1,1,x)后：
// [0.0, 0.156]: 25%的粒子（原[-1.0, -0.5]）
// [0.156, 0.844]: 50%的粒子（原[-0.5, 0.5]）
// [0.844, 1.0]: 25%的粒子（原[0.5, 1.0]）
```

**关键效果**：

1. **中间区域被拉伸**：[-0.5, 0.5] → [0.156, 0.844]
2. **两端区域被压缩**：边界附近的值被推向0或1
3. **整体分布更均匀**：减少了中间聚集现象

------



## 使用RenderTarget改善锯齿问题

**原理：**
`WebGLRenderTarget`可以创建一个离屏渲染缓冲区，可以：

1. **设置多重采样抗锯齿（MSAA）：**

   javascript

   ```
   // 步骤1：创建渲染目标
   const renderTarget = new THREE.WebGLRenderTarget(800, 600, {
     samples: renderer.getPixelRatio() === 1 ? 2 : 0, // 普通屏幕使用2倍采样
   });
   
   // 步骤2：创建效果合成器
   effectComposer = new EffectComposer(renderer, renderTarget);
   
   // 步骤3：设置尺寸
   effectComposer.setSize(sizes.width, sizes.height);
   effectComposer.setPixelRatio(sizes.pixelRatio);
   ```

   

2. **为后期处理链提供中间缓冲**

   - 每个处理pass都能在前一个pass的输出上操作
   - 避免直接渲染到屏幕带来的限制

------



## 各种抗锯齿技术的区别

#### **SSAA (超级采样抗锯齿)**

- **原理**：以更高分辨率渲染，然后下采样
- **效果**：最好
- **性能**：最差（4x SSAA需要4倍像素计算）
- **适用**：静态场景，对质量要求极高

#### **MSAA (多重采样抗锯齿)**

- **原理**：仅在边缘进行多重采样
- **效果**：很好
- **性能**：中等
- **适用**：Three.js默认支持，硬件加速

#### **FXAA (快速近似抗锯齿)**

- **原理**：基于后处理的边缘检测和模糊
- **效果**：一般，可能会使纹理变模糊
- **性能**：很好
- **适用**：移动端，性能敏感场景

#### **SMAA (增强型子像素形态学抗锯齿)**

- **原理**：结合模式检测和形态学滤波
- **效果**：比FXAA更好，更少模糊
- **性能**：较好
- **适用**：平衡质量和性能

#### **TAA (时间性抗锯齿)**

- **原理**：利用多帧信息进行累积
- **效果**：优秀，能减少闪烁
- **性能**：中等
- **缺点**：可能导致运动模糊和重影

------



## 为什么pixelRatio大于1时不需要抗锯齿？

**物理原理：**

- **devicePixelRatio > 1**：表示设备是"Retina"或高DPI屏幕
  - 例如：devicePixelRatio = 2 表示1个CSS像素对应4个物理像素
- **像素密度足够高**：锯齿在人眼感知中已不明显

**技术实现：**

javascript

```
// 代码中的逻辑
samples: renderer.getPixelRatio() === 1 ? 2 : 0
// 解释：
// - pixelRatio = 1: 普通屏幕，开启MSAA(2x)
// - pixelRatio > 1: 高分屏，关闭MSAA（已足够清晰）
```



**性能考虑：**

1. **高分屏**：渲染分辨率已经翻倍，再开抗锯齿性能开销大
2. **普通屏**：像素密度低，需要抗锯齿提升视觉质量

------

