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

