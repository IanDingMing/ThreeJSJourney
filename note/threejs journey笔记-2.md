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

