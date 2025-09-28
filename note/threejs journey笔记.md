

## P6 Transform objects

### 1. 容器宽高设置

- 通过 `webgl.value!.style.width = sizes.width + "px"` 和 `webgl.value!.style.height = sizes.height + "px"` 设置渲染容器 `<div>` 的宽高。
- 注意：不能用 `webgl.value!.width` 或 `webgl.value!.height`，因为 `<div>` 没有这两个属性，必须用 style。

### 2. Three.js 场景初始化

- 创建场景对象：`const scene = new THREE.Scene();`
- 创建几何体：`const geometry = new THREE.BoxGeometry(1, 1, 1);`
- 创建材质：`const material = new THREE.MeshBasicMaterial({ color: 0xff0000 });`
- 创建网格模型对象并设置属性：
  - 位置：`mesh.position.set(0, 0, 0);`
  - 缩放：`mesh.scale.set(2, 0.5, 0.5);`
  - 旋转顺序：`mesh.rotation.reorder("XYZ");`
  - 旋转角度：`mesh.rotation.set(Math.PI / 4, Math.PI / 6, Math.PI / 8);`
- 将网格模型添加到场景：`scene.add(mesh);`

### 3. 辅助对象与相机

- 添加坐标轴辅助器：`const axesHelper = new THREE.AxesHelper(); scene.add(axesHelper);`
- 创建透视相机并设置位置：  
  `const camera = new THREE.PerspectiveCamera(75, sizes.width / sizes.height);`  
  `camera.position.set(0, 0, 3);`

### 4. 渲染器设置

- 创建渲染器对象：`const renderer = new THREE.WebGLRenderer();`
- 设置渲染区域大小：`renderer.setSize(sizes.width, sizes.height);`
- 重置渲染器尺寸和像素比：` renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));`
- 将渲染器的 canvas 添加到 div：`webgl.value!.appendChild(renderer.domElement);`
- 渲染场景：`renderer.render(scene, camera);`

### 5. 旋转顺序与欧拉角理解

- 通过 `.reorder("XYZ")` 设置旋转顺序，`.set(x, y, z)` 始终是设置 x、y、z 三个轴的旋转角度，顺序影响多轴旋转时的效果。
- 如果只设置一个轴，旋转顺序影响不大，建议每个轴都设置不同值观察效果。

### 6. 使用 Group 对象进行分组

- 通过 `const group = new THREE.Group();` 创建组对象，可以统一管理一组 mesh 的变换（如平移、缩放）。

- 设置组的位置和缩放，影响组内所有子对象：

  ```js
  group.position.set(0, 1, 0);
  group.scale.set(1, 1.5, 1);
  scene.add(group);
  ```

---
### 7.初始的一个代码

```
<script setup lang="ts">
import { ref, useTemplateRef, onMounted } from "vue";
import * as THREE from "three";
defineProps<{ msg: string }>();
const sizes = {
  width: 800,
  height: 600,
};
const webgl = useTemplateRef("webgl");
onMounted(() => {
  // console.log(webgl);
  // 用 style 设置 div 的宽高
  webgl.value!.style.width = sizes.width + "px";
  webgl.value!.style.height = sizes.height + "px";

  // 创建3D场景对象Scene
  const scene = new THREE.Scene();

  const group = new THREE.Group(); //创建一个组对象
  group.position.set(0, 1, 0); //设置组对象在x、y、z轴上的位置
  group.scale.set(1, 1.5, 1); //设置组对象的缩放比例
  scene.add(group); //将组对象添加到场景中

  const cube1 = new THREE.Mesh(
    new THREE.BoxGeometry(1, 1, 1), //创建一个立方体几何体
    new THREE.MeshBasicMaterial({ color: 0xff0000 }) //创建一个红色材质
  );
  group.add(cube1); //将立方体添加到组对象中

  const cube2 = new THREE.Mesh(
    new THREE.BoxGeometry(1, 1, 1),
    new THREE.MeshBasicMaterial({ color: 0x00ff00 })
  );
  cube2.position.set(1.5, 0, 0); //设置立方体在x、y、z轴上的位置
  group.add(cube2); //将立方体添加到组对象中

  const cube3 = new THREE.Mesh(
    new THREE.BoxGeometry(1, 1, 1),
    new THREE.MeshBasicMaterial({ color: 0x0000ff })
  );
  cube3.position.set(-1.5, 0, 0); //设置立方体在x、y、z轴上的位置
  group.add(cube3); //将立方体添加到组对象中

  const axesHelper = new THREE.AxesHelper(); //创建一个坐标轴辅助对象
  scene.add(axesHelper); //将坐标轴辅助对象添加到网格模型中

  // 实例化一个透视投影相机对象
  const camera = new THREE.PerspectiveCamera(75, sizes.width / sizes.height);

  //相机在Three.js三维坐标系中的位置
  // 根据需要设置相机位置具体值
  camera.position.set(0, 0, 3);
  // camera.lookAt(0, 0, 0); // 让相机向下看向原点

  // 创建渲染器对象
  const renderer = new THREE.WebGLRenderer();
  renderer.setSize(sizes.width, sizes.height); //设置three.js渲染区域的尺寸(像素px)
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  webgl.value!.appendChild(renderer.domElement);

  renderer.render(scene, camera); //执行渲染操作
});
</script>

<template>
  <!-- <h1>{{ msg }}</h1> -->
  <div ref="webgl"></div>
</template>

<style scoped></style>
```



## P7 Animations

根据今天的 Git 提交记录，以下是您学习 Three.js 动画开发的核心内容总结：

### 1. 帧率FPS计算与基础旋转
- 使用 `Clock.getDelta()` 计算帧间隔时间
- 实现旋转立方体的基础动画
- 掌握帧率计算公式：`FPS = 1000 / 帧间隔(ms)`

```javascript
const clock = new THREE.Clock();
function render() {
  const spt = clock.getDelta() * 1000;
  console.log("帧间隔:", spt, "FPS:", 1000 / spt);
  mesh.rotateY(0.01);
  requestAnimationFrame(render);
}
```

[原理详解](#render 中`clock.getDelta()`输出 0 的问题)***核心原则：同一帧内，`getElapsedTime()`与`getDelta()`二选一，避免重复调用（前者已包含后者的逻辑）***

### 2. 帧率无关的旋转优化 

- **解决关键问题**：不同刷新率屏幕的动画速度不一致
- 实现帧率无关的恒定速度旋转：
  ```javascript
  const rotationSpeed = Math.PI / 180 / 100; // 每毫秒旋转0.01度
  mesh.rotateY(rotationSpeed * spt);
  ```
- 理解时间增量(`deltaTime`)在动画中的作用

### 3. 相机环绕与物体运动 
- 使用三角函数创建圆周运动：
  ```javascript
  camera.position.x = Math.cos(elapsedTime);
  camera.position.y = Math.sin(elapsedTime);
  ```
- 实现相机自动看向目标：`camera.lookAt(mesh.position)`
- 掌握 `Clock.getElapsedTime()` 获取动画运行总时间

### 4. GSAP 补间动画集成 
- 引入 GSAP 动画库：`npm install gsap`
- 创建平移动画序列：
  ```javascript
  gsap.to(mesh.position, {x: 2, duration: 1, delay: 1});
  gsap.to(mesh.position, {x: 0, duration: 1, delay: 2});
  ```
- 简化渲染循环：只需处理渲染，动画由 GSAP 管理
- 理解 GSAP 核心参数：duration（持续时间）、delay（延迟）、ease（缓动函数）

## P8 Cameras

### 1. 相机类型对比
- **透视相机**：模拟人眼视角，近大远小  
  ```javascript
  new THREE.PerspectiveCamera(45, width/height, 1, 1000)
  ```
- **正交相机**：无透视变形，保持尺寸  
  ```javascript
  new THREE.OrthographicCamera(width/-2, width/2, height/2, height/-2, 1, 1000)
  ```

![20200517225522434](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/20200517225522434.png)

### 2. 轨道控制器(OrbitControls)

- **功能**：实现相机环绕目标运动  
- **核心配置**：  
  
  ```javascript
  import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
  const controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true; // 启用惯性
  ```
- **动画循环要求**：  
  ```javascript
  function animate() {
    controls.update(); // 必须调用
    renderer.render(scene, camera);
    requestAnimationFrame(animate);
  }
  ```

### 3. 控制器对比
| 控制器                  | 交互方式      | 适用场景     |
| ----------------------- | ------------- | ------------ |
| **OrbitControls**       | 拖拽旋转/缩放 | 通用3D查看器 |
| **DragControls**        | 拖拽物体      | 物体编辑     |
| **TransformControls**   | Gizmo手柄操作 | 3D编辑器     |
| **PointerLockControls** | 键盘+鼠标锁定 | FPS游戏      |
| **FlyControls**         | 键盘+鼠标飞行 | 飞行模拟     |

### 4. 为什么正交相机比例不一致会导致物体变形？
- **原因**：视锥体宽高比 ≠ 画布宽高比  

在计算机图形学中，渲染过程本质上是将3D空间中的物体投影到2D屏幕上的过程。这个投影过程严格遵循数学映射关系，而**相机视锥体宽高比**和**画布宽高比**的关系直接决定了这个映射是否保持物体原始比例。

- #### 核心原理：归一化设备坐标 (NDC) 到屏幕坐标的映射

1. **投影阶段**：
   - 正交相机将视锥体内的3D点投影到**归一化设备坐标(NDC)**，这是一个[-1,1]×[-1,1]的立方体空间
   - 无论视锥体实际尺寸如何，所有点都会被线性映射到这个标准立方体
2. **视口变换阶段**：
   - 将NDC立方体映射到实际的屏幕像素坐标
   - 映射规则：`屏幕X = (NDC_X + 1) * 0.5 * canvasWidth`
   - 映射规则：`屏幕Y = (-NDC_Y + 1) * 0.5 * canvasHeight`（Y轴翻转）

## P9 Fullscreen and Resizing

### 1. 增加窗口调整全屏功能

#### 实现目标
- 实现渲染画面随窗口大小自适应
- 添加双击全屏/退出全屏功能
- 优化容器初始尺寸获取方式

#### 关键实现步骤
1. **容器尺寸动态获取**
   
   ```typescript
   sizes.width = webgl.value!.clientWidth;
   sizes.height = webgl.value!.clientHeight;
   ```
   - 替代硬编码的固定尺寸
   - 使用`clientWidth/clientHeight`获取容器实际尺寸
   
2. **窗口大小响应处理**
   ```typescript
   function handleResize() {
     if (!webgl.value) return;
     // 更新容器尺寸
     sizes.width = webgl.value.clientWidth;
     sizes.height = webgl.value.clientHeight;
     
     // 更新相机参数
     camera.aspect = sizes.width / sizes.height;
     camera.updateProjectionMatrix();
     
     // 更新渲染器
     renderer.setSize(sizes.width, sizes.height);
     renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
   }
   window.addEventListener("resize", handleResize);
   ```
   - 更新相机宽高比和投影矩阵
   - 重置渲染器尺寸和像素比
   - 限制最大像素比为2（平衡性能与画质）
   
3. **双击全屏功能**
   ```typescript
   function handleDoubleClick() {
     // 浏览器兼容性处理
     const fullscreenElement = document.fullscreenElement || 
         (document as any).webkitFullscreenElement || 
         (document as any).mozFullScreenElement;
     
     if (!fullscreenElement) {
       webgl.value!.requestFullscreen(); // 进入全屏
     } else {
       document.exitFullscreen(); // 退出全屏
     }
   }
   window.addEventListener("dblclick", handleDoubleClick);
   ```
   - 多浏览器前缀兼容处理
   - 安全检测当前全屏状态
   - 容器元素执行全屏/退出操作
   
4. **容器样式设置**
   ```css
   .webgl {
     width: 100vw;
     height: 100vh;
     background-color: #f00;
   }
   ```

---

### 2. 内存管理优化

#### 优化目标
- 防止内存泄漏
- 避免僵尸事件监听
- 安全释放Three.js资源

#### 关键优化点
1. **变量作用域提升**
   ```typescript
   let camera: THREE.PerspectiveCamera | null = null;
   let renderer: THREE.WebGLRenderer | null = null;
   let controls: OrbitControls | null = null;
   ```
   - 关键对象提升到组件作用域
   - 初始化为`null`并添加类型声明

4. **资源清理机制**
   ```typescript
   onUnmounted(() => {
     window.removeEventListener("resize", handleResize);
     window.removeEventListener("dblclick", handleDoubleClick);
     
     if (renderer) renderer.dispose();
     if (controls) controls.dispose();
     
     camera = null;
     renderer = null;
     controls = null;
   });
   ```
   - 移除事件监听器
   - 显式释放Three.js资源
   - 清除对象引用

## P10 BufferGeometry

### 1. BufferGeometry 实现
- 创建自定义几何体替代 BoxGeometry
- 使用 BufferAttribute 定义顶点数据
```javascript
const geometry = new THREE.BufferGeometry();
// 创建一个简单的矩形. 在这里我们左上和右下顶点被复制了两次。
// 因为在两个三角面片里，这两个顶点都需要被用到。
const vertices = new Float32Array( [
	-1.0, -1.0,  1.0,
	 1.0, -1.0,  1.0,
	 1.0,  1.0,  1.0,

	 1.0,  1.0,  1.0,
	-1.0,  1.0,  1.0,
	-1.0, -1.0,  1.0
] );

// itemSize = 3 因为每个顶点都是一个三元组。
geometry.setAttribute( 'position', new THREE.BufferAttribute( vertices, 3 ) );
const material = new THREE.MeshBasicMaterial( { color: 0xff0000, wireframe: true } );
const mesh = new THREE.Mesh( geometry, material );
```

## P11 GUI

### 1. GUI 控制面板集成

- 添加 dat-gui 控制库

- [dat-gui-API文档详情](#dat.GUI API)


```javascript
gui = new GUI();
// gui按键
gui.add(eventObj, "Fullscreen").name("全屏");
gui.add(eventObj, "ExitFullscreen").name("退出全屏");
gui.add(eventObj, "Spin").name("旋转一周");

// gui文件夹
const folder = gui.addFolder("立方体位置");
// 文件夹-gui滑块
folder.add(mesh.position, "x").min(-10).max(10).step(1).name("x轴位置");
// 文件夹-gui单选框
gui.add(parentMaterial, "wireframe").name("父元素线框模式");

//颜料盘
gui.addColor(colorParams, "meshColor").name("立方体颜色")
  .onChange(value => mesh.material.color.set(value));
```

### 2. 添加 GUI 销毁逻辑

gui需要手动销毁，不然会出现多次创建gui实例会出现组件重叠问题

例如，在onMounted生命周期中创建了gui实例，更新代码后，如果没有在onUnmounted中销毁，组件重新加载就会出现重叠问题

但是在单个js文件中不会有问题，因为需要刷新页面更新代码，当然生产环境也不会有这种问题

```javascript
onUnmounted(() => {
  if (gui) {
    gui.destroy();
    gui = null;
  }
});
```

## P12 textures

### 1. 纹理资源管理
- 添加棋盘格纹理（1024x1024和8x8两种分辨率）
- 添加门的PBR材质贴图（颜色/透明/高度/法线/AO/金属/粗糙）

- 使用image加载纹理

```
const image = new Image();
image.src = "/textures/door/color.jpg";
image.crossOrigin = "anonymous"; // 解决跨域问题
const textures = new THREE.Texture(image);
image.onload = () => {
  textures.needsUpdate = true; // 确保纹理更新
  console.log("Image loaded successfully", image);
};
```

- 使用`TextureLoader`加载纹理资源，添加加载管理器处理加载事件

```
const loadingManager = new THREE.LoadingManager();
loadingManager.onStart = () => {
  console.log("Loading started");
};
loadingManager.onLoad = () => {
  console.log("Loading complete");
};
loadingManager.onProgress = (url, itemsLoaded, itemsTotal) => {
  console.log(
    `Loading file: ${url}. Loaded ${itemsLoaded} of ${itemsTotal} files.`
  );
};
loadingManager.onError = (url) => {
  console.log(`There was an error loading ${url}`);
};

const texturesLoader = new THREE.TextureLoader(loadingManager);
const colorTextures = texturesLoader.load("/textures/door/color.jpg");
```

### 2. 纹理参数详解
- .[repeat](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/textures/Texture.repeat) : [Vector2](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/math/Vector2)

  决定纹理在表面的重复次数，两个方向分别表示U和V，如果重复次数在任何方向上设置了超过1的数值， 对应的Wrap需要设置为[THREE.RepeatWrapping](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/constants/Textures)或者[THREE.MirroredRepeatWrapping](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/constants/Textures)来 达到想要的平铺效果。

```
colorTextures.repeat.x = 2;
colorTextures.repeat.y = 3;
```

没添加RepeatWrapping

![截屏2025-08-05 15.49.11](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/截屏2025-08-05 15.49.11.png)

```
colorTextures.wrapS = THREE.RepeatWrapping; //U方向
colorTextures.wrapT = THREE.RepeatWrapping; //V方向
```

添加RepeatWrapping

![截屏2025-08-05 15.49.30](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/截屏2025-08-05 15.49.30.png)

```
colorTextures.wrapS = THREE.MirroredRepeatWrapping; //U方向
colorTextures.wrapT = THREE.MirroredRepeatWrapping; //V方向
```

添加MirroredRepeatWrapping

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/截屏2025-08-05 15.52.00.png)

- .[offset](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/textures/Texture.offset) : [Vector2](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/math/Vector2)

  贴图单次重复中的起始偏移量，分别表示U和V。 一般范围是由`0.0`到`1.0`。

```
colorTextures.offset.x = 0.5;//相当于左移动一半，如果设置了wrapS属性重复或者镜像，右侧会自动补齐，不然就是拉伸补齐
```

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/截屏2025-08-05 15.55.47.png)

- .[rotation](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/textures/Texture.rotation) : number

  纹理将围绕中心点旋转多少度，单位为弧度（rad）。正值为逆时针方向旋转，默认值为**0**。

```
colorTextures.rotation = Math.PI / 4; // 旋转45度
```

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/截屏2025-08-05 22.42.32.png)

- .[center](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/textures/Texture.center) : [Vector2](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/math/Vector2)

  旋转中心点。(0.5, 0.5)对应纹理的正中心。默认值为(0,0)，即左下角。

```
colorTextures.center.x = 0.5;
colorTextures.center.y = 0.5;
```

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/截屏2025-08-05 22.42.52.png)

### 3. 纹理参数-纹理过滤机制

- .[magFilter](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/textures/Texture.magFilter) : number

  当一个纹素覆盖大于一个像素时，贴图将如何采样。默认值为[THREE.LinearFilter](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/constants/Textures)， 它将获取四个最接近的纹素，并在他们之间进行双线性插值。 另一个选项是[THREE.NearestFilter](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/constants/Textures)，它将使用最接近的纹素的值。
  请参阅[texture constants](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/constants/Textures)页面来了解详细信息。

- .[minFilter](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/textures/Texture.minFilter) : number

  当一个纹素覆盖小于一个像素时，贴图将如何采样。默认值为[THREE.LinearMipmapLinearFilter](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/constants/Textures)， 它将使用mipmapping以及三次线性滤镜。

- .[generateMipmaps](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/textures/Texture.generateMipmaps) : Boolean

  是否为纹理生成mipmap（如果可用）。默认为true。 如果你手动生成mipmap，请将其设为false。

#### 1. **magFilter（放大过滤器）**
- **原理**：当纹理被放大时（一个纹素覆盖多个屏幕像素），决定如何插值采样
- **默认值**：`THREE.LinearFilter`

- **常见取值**：
  - `THREE.NearestFilter`：最近邻采样（Nearest Neighbor Sampling）（可能像素化）直接取**最接近的单个纹素**值（像素化效果）
  - `THREE.LinearFilter`：线性采样（双线性采样，Bilinear Sampling）（边缘更平滑）取4个最近纹素进行**双线性插值**（平滑过渡）
- **注意**：不支持 Mipmap 模式

**视觉影响**：
```javascript
// 平滑放大（适合真实感材质）
texture.magFilter = THREE.LinearFilter;

// 锐利放大（适合像素风/复古游戏）
texture.magFilter = THREE.NearestFilter;
```
- 纹理被放大

  - 默认`THREE.LinearFilter`

  ![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/checkerboard-8x8.png)

  - `THREE.NearestFilter`

  ![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/colorTextures.magFilter = THREE.NearestFilter; :: 设置纹理的放大过滤器.png)

#### 2. **minFilter（缩小过滤器）**
- **原理**：当纹理被缩小时（多个纹素对应一个屏幕像素），决定采样策略
- **默认值**：`THREE.LinearMipmapLinearFilter`

- **常见取值**：

  - `THREE.NearestFilter`：最近邻采样
  - `THREE.LinearFilter`：线性采样
  - 带 Mipmap 的模式（如`THREE.NearestMipmapNearestFilter`、`THREE.LinearMipmapLinearFilter`）

- 纹理被缩小

  - 默认`THREE.LinearMipmapLinearFilter`

  ![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/checkerboard-1024x1024.png)

  - `THREE.NearestFilter`

  ![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/colorTextures.minFilter = THREE.NearestFilter; :: 设置纹理的最小过滤器.png)

- **关键选项**：

  | 过滤器类型                   | 特点                                             | 性能消耗 |
  | ---------------------------- | ------------------------------------------------ | -------- |
  | `NearestFilter`              | 直接取最近纹素（锯齿明显）                       | ★☆☆☆☆    |
  | `LinearFilter`               | 4纹素平均（轻微模糊）                            | ★★☆☆☆    |
  | `NearestMipmapNearestFilter` | 选择最接近mip层级+最近采样                       | ★★★☆☆    |
  | `LinearMipmapNearestFilter`  | 选择最接近mip层级+线性采样                       | ★★★★☆    |
  | `NearestMipmapLinearFilter`  | 混合两个mip层级+NearestFilter最近邻采样          | ★★★★★    |
  | `LinearMipmapLinearFilter`   | 混合两个mip层级+LinearFilter双线性采样（最平滑） | ★★★★★    |

#### 3. **generateMipmaps（Mipmap生成）**

Mipmap 是优化纹理渲染的多级纹理技术，核心是生成一系列不同分辨率的纹理版本（纹理金字塔）。

- **原理**：预生成纹理的缩小版本链（原图→1/2→1/4→...→1x1）

- **默认开启**：`true`

- **工作流程**：

  ```mermaid
  graph LR
  A[原始纹理] --> B[1/2尺寸] 
  B --> C[1/4尺寸]
  C --> D[...]
  D --> E[1x1纹理]
  ```

##### a. 原理

- 预生成多级纹理：从原始尺寸（如 1024×1024）逐级缩小至 1×1 像素，每个层级经滤波处理。
- 实时选择层级：根据物体与相机距离自动匹配分辨率（近处用高分辨率，远处用低分辨率）。
- 什么时候用 Mipmap？：仅用于纹理**缩小**场景（对应 `minFilter`），当物体离相机较远、纹理在屏幕上的投影尺寸较小时启用，通过自动选择最合适分辨率的 Mipmap 层级提升效率和画质。

##### b. 作用

- **减少锯齿、闪烁和摩尔纹**
- 降低显存带宽占用，提升渲染性能

- **关键影响**：
  - ✅ 开启时：显著改善缩小时的渲染质量
  - ❌ 关闭时：
    - 节省33%显存
    - 必须使用非mipmap过滤器（如`NearestFilter`/`LinearFilter`）
    - 远处纹理可能出现闪烁/锯齿

#### 4. 采样方法选择原则

```javascript
// 方案1：默认高质量（适合通用场景）
texture.generateMipmaps = true;
texture.minFilter = THREE.LinearMipmapLinearFilter;
texture.magFilter = THREE.LinearFilter;

// 方案2：性能优化（适合小纹理UI）
texture.generateMipmaps = false;
texture.minFilter = THREE.LinearFilter;
texture.magFilter = THREE.LinearFilter;

// 方案3：像素风特效（Minecraft风格）
texture.generateMipmaps = false;
texture.minFilter = THREE.NearestFilter;  // 缩小保持锐利
texture.magFilter = THREE.NearestFilter;  // 放大保持锐利
```

#### 5. `minFilter` 或 `magFilter` 仅在对应缩放场景生效

`minFilter` 和 `magFilter` 分别只对**纹理缩小**和**纹理放大**场景起作用，若当前场景不满足缩放条件，设置自然不会有视觉变化：

- **`minFilter` 无效**：可能纹理尺寸 ≤ 模型表面需要的纹理尺寸（即纹理处于 “被放大” 或 “等比例” 状态），此时 `minFilter` 不参与计算，由 `magFilter` 主导。
- **`magFilter` 无效**：可能纹理尺寸 ≥ 模型表面需要的纹理尺寸（即纹理处于 “被缩小” 或 “等比例” 状态），此时 `magFilter` 不参与计算，由 `minFilter` 主导。
- 纹理的**宽度方向处于压缩状态**，**长度方向处于拉伸状态**，因此 `minFilter`（缩小过滤）和 `magFilter`（放大过滤）会**分别在两个方向上独立生效**，不存在单一 “主导”，而是各自作用于对应的缩放方向。

**举例**：

- 若导入的纹理是 1024×1024，而模型表面映射纹理的区域在屏幕上显示为 2048×2048（纹理被放大），此时只有 `magFilter` 的设置会影响效果，`minFilter` 无论设什么都看不出变化。
- 假设模型表面的实际尺寸为 **宽 100 × 长 200**，纹理尺寸为 **宽 200 × 长 100**：
  - **宽度方向**：纹理宽 200 → 模型宽 100 → 纹理被**压缩**（缩小到原来的 1/2）。
    此时，宽度方向的像素采样由 `minFilter` 控制（因为涉及纹理缩小）。
  - **长度方向**：纹理长 100 → 模型长 200 → 纹理被**拉伸**（放大到原来的 2 倍）。
    此时，长度方向的像素采样由 `magFilter` 控制（因为涉及纹理放大）。

#### 6. 纹理未开启 Mipmap 却使用了依赖 Mipmap 的 `minFilter` 模式

`minFilter` 的部分取值（如 `NearestMipmapNearestFilter`、`LinearMipmapLinearFilter` 等）依赖 Mipmap 技术，若纹理未生成 Mipmap，Three.js 会**自动降级为基础模式**（如 `NearestFilter` 或 `LinearFilter`），导致设置无效：

- **原因**：Mipmap 需要纹理在加载时生成多级缩放版本，若纹理的 `generateMipmaps` 属性为 `false`（默认值为 `true`，但可能被手动关闭），则无法使用带 Mipmap 的 `minFilter` 模式。
- **验证**：检查纹理的 `generateMipmaps` 是否为 `true`（开启 Mipmap 生成），且纹理尺寸为 **2 的幂次方**（如 256、512、1024，非 2 的幂次方纹理可能无法生成完整 Mipmap）。

## P13 Materials

### 1. Material 父类
所有材质均继承自 `THREE.Material`，提供以下通用属性：
- **透明度控制**：`transparent`（是否透明）、`opacity`（透明度值）

  - .[opacity](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/Material.opacity) : Float

    在0.0 - 1.0的范围内的浮点数，表明材质的透明度。值**0.0**表示完全透明，**1.0**表示完全不透明。
    如果材质的transparent属性未设置为**true**，则材质将保持完全不透明，此值仅影响其颜色。 默认值为**1.0**。

  - .[transparent](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/Material.transparent) : Boolean

    定义此材质是否透明。这对渲染有影响，因为透明对象需要特殊处理，并在非透明对象之后渲染。
    设置为true时，通过设置材质的opacity属性来控制材质透明的程度。
    默认值为**false**。


- **面渲染模式**：`side`（前面/后面/双面渲染）

  - .[side](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/Material.side) : Integer

    定义将要渲染哪一面 - 正面，背面或两者。 默认为[THREE.FrontSide](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/constants/Materials)。其他选项有[THREE.BackSide](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/constants/Materials) 和 [THREE.DoubleSide](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/constants/Materials)。

- **线框模式**：`wireframe`（是否显示为线框）

```
material = new THREE.MeshBasicMaterial();
material.color = new THREE.Color(0xff0000);// 直接设置颜色
material.wireframe = true;// 线框模式
material.side = THREE.DoubleSide; //两面可见
material.transparent = true; //开启透明度
material.opacity = 0.5; //设置透明度,使用时必须开启透明度
```

- **更新标记**：`needsUpdate`（材质修改后需设置为true）

  - .[needsUpdate](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/Material.needsUpdate) : Boolean

    指定需要重新编译材质。

***当设置这个属性为true，材质会自动更新，每次设置完材质属性，都要用这个来更新材质***

```
material.needsUpdate = true; //更新材质
```

### 2. MeshBasicMaterial (基础材质)

- **不受光照影响**

- **关键属性**：`map`（颜色贴图）、`alphaMap`（透明贴图）

  - .[alphaMap](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/MeshBasicMaterial.alphaMap) : [Texture](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/textures/Texture)

    alpha贴图是一张灰度纹理，用于控制整个表面的不透明度。（黑色：完全透明；白色：完全不透明）。 默认值为null。

  - .[map](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/MeshBasicMaterial.map) : [Texture](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/textures/Texture)

    颜色贴图。可以选择包括一个alpha通道，通常与[.transparent](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/Material.transparent) 或[.alphaTest](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/Material.alphaTest)。默认为null。


***map就是贴上一个图，alphaMap相当于设计时产生的另一个配套的图，用来裁剪map中的多余部分***

```javascript
material = new THREE.MeshBasicMaterial();
material.map = doorColorTextures;// 颜色贴图
material.transparent = true; //开启透明度
material.alphaMap = doorAlphaTextures; //设置透明贴图,使用时必须开启透明度
```

### 3. MeshNormalMaterial (法线材质)

***相当于贴图自带高度属性***

- **不受光照影响**
- **关键属性**：`flatShading`（平面着色，***即是否更顺滑而不是马赛克***）

```javascript
material = new THREE.MeshNormalMaterial(); //法线网格材质
material.flatShading = true; //定义材质是否使用平面着色进行渲染。默认值为false。
```

### 4. MeshMatcapMaterial (Matcap材质)

***matcap网格材质，模拟光照材质，即不需要光照就有真实的材质效果***

- **不受光照影响**
- **关键属性**：`matcap`（环境光照贴图）

```javascript
material = new THREE.MeshMatcapMaterial(); 
material.matcap = matcapTextures; //设置matcap贴图
```

### 5. MeshDepthMaterial (深度材质)

***深度网格材质，最直接的例子模拟雾气***

- **不受光照影响**

```javascript
material = new THREE.MeshDepthMaterial();
```

### 6. MeshLambertMaterial (朗伯材质)

***一种非光泽表面的材质，没有镜面高光。***

***该材质使用基于非物理的[Lambertian](https://en.wikipedia.org/wiki/Lambertian_reflectance)模型来计算反射率。 这可以很好地模拟一些表面（例如未经处理的木材或石材），但不能模拟具有镜面高光的光泽表面（例如涂漆木材）***

- **受光照影响**
- **关键属性**：`emissive`（自发光颜色）

```javascript
material = new THREE.MeshLambertMaterial(); //朗伯网格材质，非金属材质，受光照影响
```

### 7. MeshPhongMaterial (Phong材质)

***一种用于具有镜面高光的光泽表面的材质。***

- **受光照影响**

- **关键属性**：`shininess`（高光强度）、`specular`（高光颜色）

  - .[shininess](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/MeshPhongMaterial.shininess) : Float

    [.specular](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/MeshPhongMaterial.specular)高亮的程度，越高的值越闪亮。默认值为 **30**。

  - .[specular](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/MeshPhongMaterial.specular) : [Color](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/math/Color)

    材质的高光颜色。默认值为**0x111111**（深灰色）的颜色[Color](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/math/Color)。


```javascript
material = new THREE.MeshPhongMaterial(); //Phong网格材质，金属材质，受光照影响
material.shininess = 100; //设置材质的光泽度
material.specular = new THREE.Color(0xff0000); //设置材质的高光颜色
```

### 8. MeshToonMaterial (卡通材质)
- **受光照影响**

- **关键属性**：`gradientMap`（渐变贴图）

  - .[gradientMap](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/MeshToonMaterial.gradientMap) : [Texture](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/textures/Texture)

    卡通着色的渐变贴图。使用此类纹理时，需要将Texture.minFilter[Texture.minFilter](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/textures/Texture.minFilter)和Texture.magFilter[Texture.magFilter](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/textures/Texture.magFilter)设置为[THREE.NearestFilter](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/constants/Textures)。默认为空。


```javascript
material = new THREE.MeshToonMaterial(); //卡通网格材质，受光照影响
material.gradientMap = gradientTextures;
```

### 9. MeshStandardMaterial (PBR标准材质)
- **受光照影响**

- **核心贴图类型对比表**

  | 贴图属性            | 通俗作用                                                     | 关键特点                                                     |
  | ------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
  | **alphaMap**        | "透明蒙版"：用黑白贴图**控制物体哪里该消失**（黑透白不透）   | 不改变模型形状，只控制可见性，适合做树叶、栅栏等镂空效果     |
  | **aoMap**           | "**阴影增强器**"：在模型缝隙处添加自然阴影（如墙角、褶皱处） | 需要第二组UV坐标，强度用aoMapIntensity调节（0-1）            |
  | **displacementMap** | "真实变形器"：按贴图黑白值**推挤模型表面**（白凸黑凹）       | 实际改变几何形状，能投射真实阴影，性能消耗较大               |
  | **normalMap**       | "光影欺骗师"：通过RGB色值**模拟表面凹凸的光照效果（不改变实际几何形状）** | 紫色基调贴图，y轴方向可能需根据软件坐标系调整（如Unity导出的要y取反） |

- .[alphaMap](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/MeshStandardMaterial.alphaMap) : [Texture](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/textures/Texture)

  alpha贴图是一张灰度纹理，用于控制整个表面的不透明度。（黑色：完全透明；白色：完全不透明）。 默认值为null。

- .[aoMap](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/MeshStandardMaterial.aoMap) : [Texture](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/textures/Texture)

  该纹理的红色通道用作环境遮挡贴图。默认值为null。aoMap需要第二组UV。

- .[aoMapIntensity](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/MeshStandardMaterial.aoMapIntensity) : Float

  环境遮挡效果的强度。默认值为1。零是不遮挡效果。

- .[displacementMap](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/MeshStandardMaterial.displacementMap) : [Texture](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/textures/Texture)

  位移贴图会影响网格顶点的位置，与仅影响材质的光照和阴影的其他贴图不同，移位的顶点可以投射阴影，阻挡其他对象， 以及充当真实的几何体。位移纹理是指：网格的所有顶点被映射为图像中每个像素的值（白色是最高的），并且被重定位。

- .[displacementScale](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/MeshStandardMaterial.displacementScale) : Float

  位移贴图对网格的影响程度（黑色是无位移，白色是最大位移）。如果没有设置位移贴图，则不会应用此值。默认值为1。

- .[normalMap](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/MeshStandardMaterial.normalMap) : [Texture](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/textures/Texture)

  用于创建法线贴图的纹理。RGB值会影响每个像素片段的曲面法线，并更改颜色照亮的方式。法线贴图不会改变曲面的实际形状，只会改变光照。 

***这个材质相当于把一套的贴图全部应用，创造出很真实的效果***

```javascript
material = new THREE.MeshStandardMaterial(); //标准网格材质，受光照影响
material.metalness = 0.5; //设置材质的金属度
material.roughness = 0.5; //设置材质的粗糙
material.map = doorColorTextures; //设置颜色贴图
material.aoMap = doorAmbientOcclusionTextures; //设置环境光遮蔽贴图
material.aoMapIntensity = 1; //设置环境光遮蔽贴图强度
material.displacementMap = doorHeightTextures; //设置位移贴图
material.displacementScale = 0.1; //设置位移贴图缩放
material.metalnessMap = doorMetalnessTextures; //设置金属贴图
material.roughnessMap = doorRoughnessTextures; //设置粗糙贴图
material.normalMap = doorNormalTextures; //设置法线贴图
material.normalScale.set(0.5, 0.5); //设置法线贴图缩放
material.transparent = true; //开启透明度
material.alphaMap = doorAlphaTextures; //设置透明贴图,使用时必须开启透明度

const planeGeometry = new THREE.PlaneGeometry(1, 1, 100, 100);
const plane = new THREE.Mesh(planeGeometry, material);
plane.geometry.setAttribute(
  "uv2",
  new THREE.BufferAttribute(planeGeometry.attributes.uv.array, 2)
); //设置uv2属性，用于环境光遮蔽贴图
```

- 位移贴图（Displacement Map）与法线贴图（Normal Map）的区别

  - **位移贴图**：通过**改变模型顶点的几何位置**来模拟凹凸效果。

  - **法线贴图**：通过**修改表面法线方向**欺骗光照计算，模拟凹凸光影效果。

| **特性**       | **位移贴图**                   | **法线贴图**                     |
| :------------- | :----------------------------- | :------------------------------- |
| **几何变形**   | ✅ 真实改变模型轮廓（如深裂缝） | ❌ 轮廓不变，仅表面有“绘画感”     |
| **视角真实性** | ✅ 多角度观察均有立体感         | ❌ 侧面或边缘易穿帮（无真实凹凸） |
| **深度表现**   | ✅ 可模拟大幅凹凸（如砖墙）     | ❌ 仅适合浅层细节（如细纹）       |

- **envMap (环境特图)**

```javascript
material = new THREE.MeshStandardMaterial(); //标准网格材质，受光照影响
material.metalness = 0.7; //设置材质的金属度
material.roughness = 0.2; //设置材质的粗糙
material.envMap = environmentMapTexture; //设置环境贴图
```

## P14 Text

### 1. 导入字体

- 加载路径：`public/fonts/helvetiker_bold.typeface.json`(资源URL，需在本地添加静态资源（例如：根目录/public/fonts/helvetiker_bold.typeface.json）)

- a. promise加载: 使用`FontLoader`加载字体文件(`FontLoader`会返回`font`，但是加载字体过程为异步，所以这里的返回值要正常使用需要Promise)

```javascript
  // 加载字体
  const font = await new Promise<THREE.Font>((resolve, reject) => {
    fontLoader.load(
      "/fonts/helvetiker_bold.typeface.json",
      resolve,
      undefined,
      reject
    );
  });
```

- b. 回调加载：

```javascript
// 导入字体加载器
import { FontLoader } from "three/addons/loaders/FontLoader.js";

// 使用FontLoader加载字体
const fontLoader = new FontLoader();

  // 加载字体
  const loadedFont = fontLoader.load(
    // 资源URL，需在本地添加静态资源（根目录/public/fonts/helvetiker_bold.typeface.json）
    "fonts/helvetiker_bold.typeface.json",

    // onLoad回调
    function (loadedFont) {
      // do something with the font
      console.log(loadedFont);
      createText(); // 调用创建文本的函数
    },

    // onProgress回调
    function (xhr) {
      console.log((xhr.loaded / xhr.total) * 100 + "% loaded");
    },

    // onError回调
    function (err) {
      console.log("An error happened");
    }
  );
```

### 2. 创建文本几何体
- 使用`TextGeometry`创建三维文本

```javascript
  // 创建文本的函数
  const createText = (font) => {
    if (!font) return;

    // 创建新文本
    const textParameters = {
      font: font, // 使用加载的字体
      size: 0.5, // 字体大小
      height: 0.2, // 字体厚度
      curveSegments: 12, // 曲线段数
      bevelEnabled: true, // 启用斜角
      bevelThickness: 0.05, // 斜角厚度
      bevelSize: 0.02, // 斜角大小
      bevelOffset: 0, // 斜角偏移
      bevelSegments: 5, // 斜角段数
    };
    const textGeometry = new TextGeometry("Hello Three.js", textParameters);
    const material = new THREE.MeshMatcapMaterial();
    material.matcap = matcapTextures; //设置材质的matcap贴图
    textGeometry.center(); // ✅ 确保文本居中

    const textMesh = new THREE.Mesh(textGeometry, material);
    scene.add(textMesh);
  };
```

### 3. 字体参数特性
- **重要特性**：文本几何体创建后参数无法直接更新
- **更新机制**：必须销毁旧几何体并用新参数重建
- 更新流程：
  1. 移除场景中的旧文本网格
  2. 调用`geometry.dispose()`释放资源
  3. 使用新参数创建新几何体
  4. 重新添加到场景

```javascript
  const createText = () => {
    if (!font || !material || !scene) return;

    // 移除旧文本
    if (textMesh) {
      scene.remove(textMesh);
      textMesh.geometry.dispose(); // 释放旧几何体资源
    }

    // 创建新文本
    textParameters.font = font;
    const textGeometry = new TextGeometry("Hello Three.js", textParameters);
    textGeometry.center(); // ✅ 确保文本居中

    textMesh = new THREE.Mesh(textGeometry, material);
    scene.add(textMesh);
  };
```

### 4. `textGeometry.center()`(文本居中)原理
- 手动居中实现方式（等效代码）：

```javascript
    textGeometry.center()文本居中原理：
    textGeometry.computeBoundingBox(); // 计算文本几何体的边界框
    textGeometry.translate(
      -(textGeometry.boundingBox!.max.x - 0.02) / 2,// bevelSize 斜角大小
      -(textGeometry.boundingBox!.max.y - 0.02) / 2,// bevelSize 斜角大小
      -(textGeometry.boundingBox!.max.z - 0.05) / 2// bevelThickness 斜角厚度
    ); // 将文本几何体居中
    console.log("textGeometry.boundingBox", textGeometry.boundingBox);
    textGeometry.computeBoundingBox(); // 计算文本几何体的边界框
    console.log("textGeometry.boundingBox", textGeometry.boundingBox);
```

### 5. 大量几何体性能优化
- 如果将`const torusGeometry = new THREE.TorusGeometry(0.3, 0.2, 20, 45);`放在for循环内，整个过程耗费200多ms，但是如果放在循环外，耗时20多ms，所以***注意性能优化***

- 创建 `Geometry`（几何体）是**非常耗费性能**的操作，这也是循环内外性能差距巨大的核心原因。`TorusGeometry` 等几何体类的作用是**计算并生成顶点数据**（顶点位置、法线、UV 坐标等），这些数据是渲染 3D 模型的基础。

  ```javascript
  const torusGeometry = new THREE.TorusGeometry(0.3, 0.2, 20, 45);
  
  for (let i = 0; i < 1000; i++) {
    const mesh = new THREE.Mesh(torusGeometry, material);
    // 仅设置变换属性（位置/旋转/缩放）
    mesh.position.set(
      (Math.random() - 0.5) * 10,
      (Math.random() - 0.5) * 10,
      (Math.random() - 0.5) * 10
    );
    scene.add(mesh);
  }
  ```

## P16 Light

🔮<u>灯光**非常消耗性能**，所以在项目中尽量少用灯光，使用**烘焙**就是一个很好的解决办法，把光的信息事先**烘焙到纹理中**。</u>

### 1. 环境光 (AmbientLight)
- 均匀照亮所有物体表面
- 无方向性，无阴影效果
- 参数：颜色(`0xffffff`)，光照的强度(`0.5`)默认值为 1。
```javascript
const ambientLight = new THREE.AmbientLight(0xffffff, 0.5); //创建环境光对象
scene.add(ambientLight); //将环境光添加到场景中
```

### 2. 平行光 (DirectionalLight)
- 模拟太阳光，方向性光源
- 可投射清晰阴影
- 参数：颜色(`0x00fffc`)，强度(`0.5`)
- **辅助对象**：`DirectionalLightHelper`
```javascript
// 从上方照射的白色平行光，强度为 0.5。
const directionalLight = new THREE.DirectionalLight(0x00fffc, 0.5); //创建平行光对象
directionalLight.position.set(1, 0.25, 0); //设置平行光位置
scene.add(directionalLight); //将平行光添加到场景中

const directionalLightHelper = new THREE.DirectionalLightHelper(directionalLight, 0.2);
directionalLightHelper.visible = true; // 可见性控制
scene.add(directionalLightHelper);
```

### 3. 半球光 (HemisphereLight)
- 模拟天空和地面的环境光照
- 参数：天空色(`0xff0000`)，地面色(`0x0000ff`)，强度(`0.3`)
- **辅助对象**：`HemisphereLightHelper`
```javascript
// 半球光，参数1：天空颜色 参数2：地面颜色 参数3：光照强度
const hemisphereLight = new THREE.HemisphereLight(0xff0000, 0x0000ff, 0.3);
scene.add(hemisphereLight); //添加半球光

const hemisphereLightHelper = new THREE.HemisphereLightHelper(hemisphereLight, 0.1);
hemisphereLightHelper.visible = true; // 可见性控制
scene.add(hemisphereLightHelper);
```

### 4. 点光源 (PointLight)
- 向所有方向均匀发光
- 参数：颜色(`0xff9000`)，强度(`0.5`)，距离(`10`)，衰减(`2`)
- **辅助对象**：`PointLightHelper`
```javascript
// 点光源，参数1：光的颜色 参数2：光照强度 参数3：光照距离(范围) 参数4：衰减程度
const pointLight = new THREE.PointLight(0xff9000, 0.5, 10, 2);
pointLight.position.set(1, -0.5, 1);
scene.add(pointLight);

const pointLightHelper = new THREE.PointLightHelper(pointLight, 0.2);
pointLightHelper.visible = true; // 可见性控制
scene.add(pointLightHelper);
```

### 5. 矩形区域光 (RectAreaLight)
- 平面矩形光源
- 需额外导入`RectAreaLightHelper`
- 参数：颜色(`0x4e00ff`)，强度(`2`)，宽度(`1`)，高度(`1`)
```javascript
// 矩形区域光，参数1：光的颜色 参数2：光照强度 参数3：光照宽度 参数4：光照高度
const rectLight = new THREE.RectAreaLight(0x4e00ff, 2, 1, 1);
rectLight.position.set(-1.5, 0, 1.5);
rectLight.lookAt(0, 0, 0);
scene.add(rectLight);

// 导入RectAreaLightHelper
import { RectAreaLightHelper } from "three/addons/helpers/RectAreaLightHelper.js";
const rectLightHelper = new RectAreaLightHelper(rectLight);
rectLightHelper.visible = true; // 可见性控制
scene.add(rectLightHelper);
```

### 6. 聚光灯 (SpotLight)
- 锥形照射区域
- 参数：颜色(`0x78fff00`)，强度(`0.5`)，距离(`6`)，角度(`Math.PI*0.1`)，衰减(`0.25`)，半影(`1`)
- **目标对象**：需单独添加至场景
- **辅助对象**：`SpotLightHelper`
```javascript
// 聚光灯，参数1：光的颜色 参数2：光照强度 参数3：光照距离(范围) 参数4：光照角度(弧度) 参数5：边缘衰减程度 参数6：光照衰减程度
const spotLight = new THREE.SpotLight(
  0x78fff00,
  0.5,
  6,
  Math.PI * 0.1,
  0.25,
  1
);
spotLight.position.set(0, 2, 3);
// 设置聚光灯的目标位置
spotLight.target.position.x = -0.75;
scene.add(spotLight);
scene.add(spotLight.target); //将目标对象添加到场景中

const spotLightHelper = new THREE.SpotLightHelper(spotLight);
spotLightHelper.visible = true; // 可见性控制
scene.add(spotLightHelper);
```

### 7. **解决关键问题**：辅助对象批量显隐控制
- 使用统一变量`hideHelpers`管理所有辅助对象可见性
- 性能优化：灯光计算消耗资源，辅助对象仅在调试时显示
```javascript
let hideHelpers = true; // 全局控制开关

// 所有helper创建时统一设置可见性
directionalLightHelper.visible = hideHelpers;
hemisphereLightHelper.visible = hideHelpers;
pointLightHelper.visible = hideHelpers;
rectLightHelper.visible = hideHelpers;
spotLightHelper.visible = hideHelpers;
```

> **性能提示**：实际项目中应减少实时灯光使用，优先考虑光照烘焙技术（将光照信息预渲染到纹理），可显著提升渲染性能。

## P17 Shadows

### 1. 三种可以投射阴影的光源
- **平行光 (DirectionalLight)**: 模拟太阳光，整个场景投射相同方向阴影
- **聚光灯 (SpotLight)**: 圆锥形光源，产生有方向性的锥形阴影
- **点光源 (PointLight)**: 全方位光源，向所有方向投射阴影（性能消耗最大）

### 2. 阴影生效的条件

1. 设置产生阴影的模型 `sphere.castShadow = true;`
2. 设置产生阴影的光源 `directionalLight.castShadow = true;`
3. 设置接收阴影的模型 `plane.receiveShadow = true`
4. 渲染器启用阴影 `renderer.shadowMap.enabled = true`
5. 设置光源阴影渲染范围 `[光源].shadow.camera`

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/正投影可视空间.png)

### 3. 阴影预设类型

- `THREE.BasicShadowMap`: 基础模式（性能好，边缘锯齿）
- `THREE.PCFShadowMap`: 平滑边缘（中等质量）
- `THREE.PCFSoftShadowMap`: 高质量柔和阴影（默认推荐）

```javascript
renderer.shadowMap.type = THREE.PCFSoftShadowMap; // 推荐：柔和边缘阴影
```
### 4. 阴影质量精确控制

**通用参数**

```javascript
light.shadow.mapSize.width = 1024;  // 提高阴影清晰度（默认512）
light.shadow.mapSize.height = 1024; // 值越高越清晰，性能消耗越大
light.shadow.radius = 3;            // 阴影模糊半径（0-10）
```

**平行光参数**

```javascript
directionalLight.shadow.camera.near = 1;    // 近裁剪面（避免近处裁剪）
directionalLight.shadow.camera.far = 100;   // 远裁剪面（覆盖场景范围）
directionalLight.shadow.camera.left = -50;  // 左边界
directionalLight.shadow.camera.right = 50;  // 右边界
directionalLight.shadow.camera.top = 50;    // 上边界
directionalLight.shadow.camera.bottom = -50;// 下边界
```

**聚光灯参数**

```javascript
spotLight.shadow.camera.fov = 45;          // 视野角度（匹配光源角度）
spotLight.shadow.camera.near = 0.1;        // 近裁剪面
spotLight.shadow.camera.far = 100;         // 远裁剪面
```

**点光源参数**

```javascript
pointLight.shadow.camera.near = 0.1;       // 近距离裁剪
pointLight.shadow.camera.far = 500;        // 远距离裁剪
```

### 5. 阴影相机辅助
```javascript
// 创建阴影相机辅助对象
const helper = new THREE.CameraHelper(light.shadow.camera);
scene.add(helper);

// 控制显示/隐藏
directionalLightHelper.visible = true;  // 平行光辅助
spotLightHelper.visible = false;        // 聚光灯辅助
pointLightHelper.visible = false;       // 点光源辅助
```
### 6. GUI辅助调节光源阴影

- `updateProjectionMatrix()` 更新阴影相机
- `helper.update()` 刷新辅助对象显示

```javascript
// 初始化GUI
const gui = new dat.GUI();
const shadowFolder = gui.addFolder('阴影调节');
const cam = directionalLight.shadow.camera;

// 绑定参数变化监听
shadowFolder.add(cam, 'left', -100, 0).onChange(v => {
  cam.updateProjectionMatrix(); // 必须更新投影矩阵
  helper.update();             // 更新辅助对象显示
});

// 添加其他可调参数
shadowFolder.add(cam, 'right', 0, 100).onChange(/* 相同处理 */);
shadowFolder.add(cam, 'top', 0, 100).onChange(/* 相同处理 */);
shadowFolder.add(cam, 'bottom', -100, 0).onChange(/* 相同处理 */);
shadowFolder.add(cam, 'far', 10, 1000).onChange(/* 相同处理 */);

// 添加光源位置调节
shadowFolder.add(light.position, 'x', -100, 100).name('光源X轴');
```

## P18 Haunted House

### 1. 雾（Fog）

这个类中的参数定义了线性雾。也就是说，雾的密度是随着距离线性增大的。

```javascript
  const fog = new THREE.Fog("#262837", 1, 15); //雾化效果
  scene.fog = fog; //将雾化效果添加到场景中
```

### 2. 设置场景背景色的两种方式

**`setClearColor`性能比`scene.background`略好**

```javascript
scene.background = new THREE.Color("#262837"); //设置场景背景颜色
renderer.setClearColor(new THREE.Color("#262837")); //设置渲染器的背景颜色
```

1. **典型场景对比**‌

   | ‌**需求**‌                | ‌**推荐方法**‌             | ‌**说明**‌                          |
   | ----------------------- | ------------------------ | --------------------------------- |
   | 固定颜色/天空盒         | `scene.background`       | 简单高效，适合静态背景‌            |
   | 透明画布（叠加DOM元素） | `renderer.setClearColor` | 需启用`alpha: true`并禁用场景背景‌ |

2. 关键区别

   &zwnj;**渲染顺序**&zwnj;  
   `setClearColor`先执行（底层画布清除），`scene.background`后渲染（覆盖前者）

   &zwnj;**透明度实现**&zwnj;  
   必须组合使用：

   ```js
   renderer.setClearColor(0x000000, 0); // 透明清除
   scene.background = null;            // 禁用场景背景
   ```

4. 常见误区
- 仅用setClearColor会被scene.background覆盖
- 透明度参数只在setClearColor生效



## P19 Particles

### PointsMaterial( parameters : Object )

parameters - (可选)用于定义材质外观的对象，具有一个或多个属性。 材质的任何属性都可以从此处传入(包括从[Material](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/Material)继承的任何属性)。

属性color例外，其可以作为十六进制字符串传递，默认情况下为 **0xffffff**（白色），内部调用[Color.set](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/math/Color.set)(color)。

.[size](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/PointsMaterial.size) : **Number**

设置**点的大小**。默认值为1.0。
Will be capped if it exceeds the hardware dependent parameter [gl.ALIASED_POINT_SIZE_RANGE](https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/getParameter).

.[sizeAttenuation](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/PointsMaterial.sizeAttenuation) : **Boolean**

指定**点的大小是否因相机深度而衰减**。（仅限透视摄像头。）默认为true。

- **使用集合体创造粒子**

```javascript
  /**
   * Particles
   */
  // Grometry
  const particlesGeometry = new THREE.SphereGeometry(1, 32, 32);

  // Material
  const particlesMaterial = new THREE.PointsMaterial();
  particlesMaterial.size = 0.02;
  particlesMaterial.sizeAttenuation = false;

  // Points
  const particles = new THREE.Points(particlesGeometry, particlesMaterial);
  scene.add(particles);
```

- **BufferGeometry的方式创造粒子**

```javascript
  /**
   * Particles
   */
  // Grometry
  const particlesGeometry = new THREE.BufferGeometry();
  const count = 5000;

  const position = new Float32Array(count * 3);
  for (let index = 0; index < count; index++) {
    const i3 = index * 3;
    position[i3 + 0] = (Math.random() - 0.5) * 10;
    position[i3 + 1] = (Math.random() - 0.5) * 10;
    position[i3 + 2] = (Math.random() - 0.5) * 10;
  }

  particlesGeometry.setAttribute(
    "position",
    new THREE.BufferAttribute(position, 3)
  );

  // Material
  const particlesMaterial = new THREE.PointsMaterial();
  particlesMaterial.size = 0.02;
  particlesMaterial.sizeAttenuation = false;

  // Points
  const particles = new THREE.Points(particlesGeometry, particlesMaterial);
  scene.add(particles);
```

.[alphaTest](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/Material.alphaTest) : **Float**

设置运行alphaTest时要使用的alpha值。如果不透明度低于此值，则不会渲染材质。默认值为**0**。

.[depthTest](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/Material.depthTest) : **Boolean**

是否在渲染此材质时启用深度测试。默认为 **true**。

.[depthWrite](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/Material.depthWrite) : **Boolean**

渲染此材质是否对深度缓冲区有任何影响。默认为**true**。

该属性控制是否将粒子的深度信息写入深度缓冲区（Z-Buffer）。当设置为`false`时，粒子不会更新深度缓冲区中的深度值，即使它们被渲染到场景中。这常用于透明或半透明物体（如粒子效果），避免因深度测试导致后续渲染的物体被错误遮挡。例如，粒子与其他物体重叠时，关闭深度写入可确保粒子始终可见，但可能牺牲部分前后遮挡关系的准确性

**blending = THREE.AdditiveBlending**‌
此属性定义粒子的颜色混合模式。`AdditiveBlending`是一种叠加混合方式，将当前粒子的颜色值与背景颜色值相加，产生更明亮的发光效果。适用于火焰、星光等需要增强视觉冲击力的场景。其数学表达式为：`最终颜色 = 源颜色（粒子） + 目标颜色（背景）`。这种混合方式会忽略透明度（Alpha）通道，直接叠加RGB值，可能导致颜色过曝。

```
  const particlesMaterial = new THREE.PointsMaterial();
  particlesMaterial.size = 0.5;
  particlesMaterial.sizeAttenuation = true;
  particlesMaterial.color = new THREE.Color("#ffff00");
  particlesMaterial.map = particleTexture;
```

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/map.png)

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/map-cube.png)

```
  const particlesMaterial = new THREE.PointsMaterial();
  particlesMaterial.size = 0.5;
  particlesMaterial.sizeAttenuation = true;
  particlesMaterial.color = new THREE.Color("#ffff00");
  particlesMaterial.transparent = true;//有些透明，有些还是被遮盖
  particlesMaterial.alphaMap = particleTexture;
```

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/alphaMap.png)

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/alphaMap-cube.png)

```
  const particlesMaterial = new THREE.PointsMaterial();
  particlesMaterial.size = 0.5;
  particlesMaterial.sizeAttenuation = true;
  particlesMaterial.color = new THREE.Color("#ffff00");
  particlesMaterial.transparent = true;
  particlesMaterial.alphaMap = particleTexture;
  particlesMaterial.alphaTest = 0.001;//如果不透明度低于此值，则不会渲染材质。默认值为0。这里是把不透明度为0不渲染。边缘还是会有遮挡
```

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/alphaTest.png)

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/alphaTest-cube.png)

```
  const particlesMaterial = new THREE.PointsMaterial();
  particlesMaterial.size = 0.5;
  particlesMaterial.sizeAttenuation = true;
  particlesMaterial.color = new THREE.Color("#ffff00");
  // particlesMaterial.map = particleTexture;
  particlesMaterial.transparent = true;
  particlesMaterial.alphaMap = particleTexture;
  particlesMaterial.alphaTest = 0.001;
  particlesMaterial.depthTest = false;//关闭深度测试，相当于取消遮挡。但是立方体也无法遮盖粒子
```

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/depthTest.png)

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/depthTest-cube.png)



```
  const particlesMaterial = new THREE.PointsMaterial();
  particlesMaterial.size = 0.5;
  particlesMaterial.sizeAttenuation = true;
  particlesMaterial.color = new THREE.Color("#ff0000");
  // particlesMaterial.map = particleTexture;
  particlesMaterial.transparent = true;
  particlesMaterial.alphaMap = particleTexture;
  //alpha值修改为默认值0，打开深度测试，关闭深度写入
  // particlesMaterial.alphaTest = 0.001;
  // particlesMaterial.depthTest = false;
  particlesMaterial.depthWrite = false;//关闭深度写入
```

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/depthWrite-cube.png)

```
  const particlesMaterial = new THREE.PointsMaterial();
  particlesMaterial.size = 0.5;
  particlesMaterial.sizeAttenuation = true;
  particlesMaterial.color = new THREE.Color("#ff0000");
  // particlesMaterial.map = particleTexture;
  particlesMaterial.transparent = true;
  particlesMaterial.alphaMap = particleTexture;
  // particlesMaterial.alphaTest = 0.001;
  // particlesMaterial.depthTest = false;
  particlesMaterial.depthWrite = false;
  particlesMaterial.blending = THREE.AdditiveBlending;//使用AdditiveBlending增强粒子光效，如火花或能量场。需注意，过度使用AdditiveBlending可能影响性能，尤其在粒子数量较多时
```

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/blending-cube.png)

**为粒子添加定点颜色，需要开启 `particlesMaterial.vertexColors = true;`**

```
  /**
   * Particles
   */
  // Grometry
  const particlesGeometry = new THREE.BufferGeometry();
  const count = 500;

  const position = new Float32Array(count * 3);
  const color = new Float32Array(count * 3);
  for (let index = 0; index < count; index++) {
    const i3 = index * 3;
    position[i3 + 0] = (Math.random() - 0.5) * 10;
    position[i3 + 1] = (Math.random() - 0.5) * 10;
    position[i3 + 2] = (Math.random() - 0.5) * 10;

    color[i3 + 0] = Math.random();
    color[i3 + 1] = Math.random();
    color[i3 + 2] = Math.random();
  }

  particlesGeometry.setAttribute(
    "position",
    new THREE.BufferAttribute(position, 3)
  );

  particlesGeometry.setAttribute("color", new THREE.BufferAttribute(color, 3));

  // Material
  const particlesMaterial = new THREE.PointsMaterial();
  particlesMaterial.size = 0.5;
  particlesMaterial.sizeAttenuation = true;
  // particlesMaterial.color = new THREE.Color("#ff0000");
  // particlesMaterial.map = particleTexture;
  particlesMaterial.transparent = true;
  particlesMaterial.alphaMap = particleTexture;
  // particlesMaterial.alphaTest = 0.001;
  // particlesMaterial.depthTest = false;
  particlesMaterial.depthWrite = false;
  particlesMaterial.blending = THREE.AdditiveBlending;
  particlesMaterial.vertexColors = true;
```

**粒子波浪动画**

- **启用即时更新**`particlesGeometry.attributes.position.needsUpdate = true;`

```
    // update particles
    for (let index = 0; index < count; index++) {
      const i3 = index * 3;

      const x = particlesGeometry.attributes.position.array[i3];
      particlesGeometry.attributes.position.array[i3 + 1] = Math.sin(
        elapsedTime + x
      );
    }
    particlesGeometry.attributes.position.needsUpdate = true;
```

## P20 Galaxy Generator

### 星系对象

```
  const parameters = {
    count: 1000, // 粒子数量（性能敏感）
    size: 0.02, // 粒子基础大小
    radius: 5, // 星系半径
    branches: 3, // 旋臂数量
    spin: 3, // 螺旋扭曲系数（>0顺时针，<0逆时针）
    randomness: 0.2, //分支偏移量
    randomnessPower: 3, // 随机强度指数（值越大粒子越集中）
    color: "#ff6030", // 粒子色值
  };

```

### 星系构思过程

#### 一条星系分支，即线

```
      positions[i3 + 0] = Math.random() * radius;
      positions[i3 + 1] = 0;
      positions[i3 + 2] = 0;
```

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/Galaxy1.png)

#### 星系分支

branch = 3

| 0    | 1     | 2     | 3    | 4     | 5     | 6    | 7     | 8     | Index = count                          |
| ---- | ----- | ----- | ---- | ----- | ----- | ---- | ----- | ----- | -------------------------------------- |
| 0    | 1     | 2     | 0    | 1     | 2     | 0    | 1     | 2     | Index % branch                         |
| 0    | 0.33  | 0.66  | 0    | 0.33  | 0.66  | 0    | 0.33  | 0.66  | Index % branch / branch                |
| 0度  | 120度 | 240度 | 0度  | 120度 | 240度 | 0度  | 120度 | 240度 | Index % branch / branch * 2π           |
| 1    | -0.5  | -0.5  | 1    | -0.5  | -0.5  | 1    | -0.5  | -0.5  | Math.cos(Index % branch / branch * 2π) |
| 0    | 0.86  | -0.86 | 0    | 0.86  | -0.86 | 0    | 0.86  | -0.86 | Math.sin(Index % branch / branch * 2π) |

branch = 2

| 0    | 1     | 2    | 3     | 4    | 5     | 6    | 7     | 8    | Index = count                |
| ---- | ----- | ---- | ----- | ---- | ----- | ---- | ----- | ---- | ---------------------------- |
| 0    | 1     | 0    | 1     | 0    | 1     | 0    | 1     | 0    | Index % branch               |
| 0    | 0.5   | 0    | 0.5   | 0    | 0.5   | 0    | 0.5   | 0    | Index % branch / branch      |
| 0度  | 180度 | 0度  | 180度 | 0度  | 180度 | 0度  | 180度 | 0度  | Index % branch / branch * 2π |

```
      positions[i3 + 0] = Math.cos(
        ((index % parameters.branches) / parameters.branches) * Math.PI * 2
      );
      positions[i3 + 1] = 0;
      positions[i3 + 2] = Math.sin(
        ((index % parameters.branches) / parameters.branches) * Math.PI * 2
      );
```

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/Galaxy2.png)

增加branch数量如下效果：

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/Galaxy2-20.png)

**乘上半径，成为线**

```
      const radius = Math.random() * parameters.radius;
      const branchAngle =
        ((index % parameters.branches) / parameters.branches) * Math.PI * 2;

      positions[i3 + 0] = Math.cos(branchAngle) * radius;
      positions[i3 + 1] = 0;
      positions[i3 + 2] = Math.sin(branchAngle) * radius;
```

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/Galaxy2-2.png)

#### 星系分支螺旋扭曲

spinAngle:距离中心越远，偏移程度越大，也就弯的越厉害

```
      const radius = Math.random() * parameters.radius;
      const branchAngle =
        ((index % parameters.branches) / parameters.branches) * Math.PI * 2;
      const spinAngle = radius * parameters.spin;

      positions[i3 + 0] = Math.cos(branchAngle + spinAngle) * radius;
      positions[i3 + 1] = 0;
      positions[i3 + 2] = Math.sin(branchAngle + spinAngle) * radius;
```

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/Galaxy3.png)

#### 星系分支偏移量

```
      const randomX = Math.random() * parameters.randomness;
      const randomY = Math.random() * parameters.randomness;
      const randomZ = Math.random() * parameters.randomness;

      positions[i3 + 0] = Math.cos(branchAngle + spinAngle) * radius + randomX;
      positions[i3 + 1] = randomY;
      positions[i3 + 2] = Math.sin(branchAngle + spinAngle) * radius + randomZ;
```

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/Galaxy4.png)

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/Galaxy4-2.png)

```
      const randomX = (Math.random() - 0.5) * parameters.randomness;
      const randomY = (Math.random() - 0.5) * parameters.randomness;
      const randomZ = (Math.random() - 0.5) * parameters.randomness;

      positions[i3 + 0] = Math.cos(branchAngle + spinAngle) * radius + randomX;
      positions[i3 + 1] = randomY;
      positions[i3 + 2] = Math.sin(branchAngle + spinAngle) * radius + randomZ;
```

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/Galaxy4-3.png)

但是这个还是不好，增加粒子数量，发现偏移还是不够随机

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/Galaxy4-4.png)



接着改进，距离中心越近，分支偏移越小，距离中心越远，分支偏离越大

`Math.pow(Math.random(), parameters.randomnessPower)`图像表示

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/Galaxy4-5.png)

```
      const randomX =
        Math.pow(Math.random(), parameters.randomnessPower);
      const randomY =
        Math.pow(Math.random(), parameters.randomnessPower);
      const randomZ =
        Math.pow(Math.random(), parameters.randomnessPower);

      positions[i3 + 0] = Math.cos(branchAngle + spinAngle) * radius + randomX;
      positions[i3 + 1] = randomY;
      positions[i3 + 2] = Math.sin(branchAngle + spinAngle) * radius + randomZ;
```

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/Galaxy4-6.png)

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/Galaxy4-7.png)

增加随机性，同时将点分布在xy面两侧

```
      const randomX =
        Math.pow(Math.random(), parameters.randomnessPower) *
        (Math.random() < 0.5 ? 1 : -1);
      const randomY =
        Math.pow(Math.random(), parameters.randomnessPower) *
        (Math.random() < 0.5 ? 1 : -1);
      const randomZ =
        Math.pow(Math.random(), parameters.randomnessPower) *
        (Math.random() < 0.5 ? 1 : -1);

      positions[i3 + 0] = Math.cos(branchAngle + spinAngle) * radius + randomX;
      positions[i3 + 1] = randomY;
      positions[i3 + 2] = Math.sin(branchAngle + spinAngle) * radius + randomZ;
```

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/Galaxy4-8.png)

增加粒子数量就有效果了

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/Galaxy5.png)

#### 星系加上颜色

```
  const generateGalaxy = () => {
  	...

    /**
     * Grometry
     */
    geometry = new THREE.BufferGeometry();
    const positions = new Float32Array(parameters.count * 3);
    const color = new Float32Array(parameters.count * 3);

    for (let index = 0; index < parameters.count; index++) {
      const i3 = index * 3;
      ...

      /**
       * color
       */
      const mixedColor = colorInside.clone();
      mixedColor.lerp(colorOutside, radius / parameters.radius);

      color[i3 + 0] = 1;
      color[i3 + 1] = 0;
      color[i3 + 2] = 0;
    }
    geometry.setAttribute("position", new THREE.BufferAttribute(positions, 3));
    geometry.setAttribute("color", new THREE.BufferAttribute(color, 3));

    /**
     * material
     */
    material = new THREE.PointsMaterial({
      ...
      // color: '#ff5588', // 直接添加颜色
      vertexColors: true,
    });
```

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/Galaxy6.png)

**改进，添加混合颜色，`Color.lerp`**

**.[lerp](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/math/Color.lerp) ( color : [Color](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/math/Color), alpha : Float ) : this**

[color](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/math/Color) - 用于收敛的颜色。
alpha - 介于0到1的数字。

将该颜色的RGB值线性插值到传入参数的RGB值。alpha参数可以被认为是两种颜色之间的比例值，其中0是当前颜色和1.0是第一个参数的颜色。

**但是这个方法会改变color对象数值，所以使用clone方法先保持原本color对象不变，因为alpha是[0-1]，所以需要除以半径**

```
  const generateGalaxy = () => {
    ...

    /**
     * Grometry
     */
    geometry = new THREE.BufferGeometry();
    const positions = new Float32Array(parameters.count * 3);
    const color = new Float32Array(parameters.count * 3);
    const colorInside = new THREE.Color(parameters.insideColor);
    const colorOutside = new THREE.Color(parameters.outsideColor);
    
    for (let index = 0; index < parameters.count; index++) {
      const i3 = index * 3;
      ...

      /**
       * color
       */
      const mixedColor = colorInside
        .clone()
        .lerp(colorOutside, radius / parameters.radius);

      color[i3 + 0] = mixedColor.r;
      color[i3 + 1] = mixedColor.g;
      color[i3 + 2] = mixedColor.b;
    }
    geometry.setAttribute("position", new THREE.BufferAttribute(positions, 3));
    geometry.setAttribute("color", new THREE.BufferAttribute(color, 3));

    /**
     * material
     */
    material = new THREE.PointsMaterial({
      ...
      // color: '#ff5588', // 直接添加颜色
      vertexColors: true,
    });
```

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/Galaxy7.png)



## P21 Scroll based animation

一、基础样式与页面结构

1. 背景色统一

为避免滚动时出现白边，将页面背景色与 canvas 背景色保持一致：

```css
html {
  background-color: #1e1a20;
}
```

2. 页面结构设计

- 容器绑定滚动和鼠标移动事件
- 包含 3 个 section（与 3 个 3D 模型对应），文字背景透明以配合滚动效果

```html
<template>
  <div class="container" @scroll="handleScroll" @mousemove="handleMousemove">
    <div ref="webgl" class="webgl"></div>
    <section class="section">
      <h1>My Portfolio</h1>
    </section>
    <section class="section">
      <h2>My projects</h2>
    </section>
    <section class="section">
      <h2>Contact me</h2>
    </section>
  </div>
</template>
```

二、3D 元素创建与配置

1. 纹理与材质

- 加载梯度纹理，使用`NearestFilter`避免模糊
- 使用卡通材质（`MeshToonMaterial`），结合梯度纹理实现卡通阴影效果

```javascript
const texturesLoader = new THREE.TextureLoader(loadingManager);
const gradientTexture = texturesLoader.load(getTextureUrl("gradients/3.jpg"));
gradientTexture.magFilter = THREE.NearestFilter;

const material = new THREE.MeshToonMaterial({
  color: parameters.materialColor,
  gradientMap: gradientTexture,
});
```

2. 几何体创建

创建 3 种不同几何体（圆环、圆锥、环面结），共用同一材质：

```javascript
const mesh1 = new THREE.Mesh(new THREE.TorusGeometry(1, 0.4, 16, 60), material);
const mesh2 = new THREE.Mesh(new THREE.ConeGeometry(1, 2, 32), material);
const mesh3 = new THREE.Mesh(new THREE.TorusKnotGeometry(0.8, 0.35, 100, 16), material);
scene.add(mesh1, mesh2, mesh3);
```

3. **模型定位**

沿 Y 轴按固定距离排列 3 个模型（`objectsDistance`控制间距）：

```javascript
const objectsDistance = 4;
mesh1.position.y = -objectsDistance * 0; // 第一个模型位置
mesh2.position.y = -objectsDistance * 1; // 第二个模型位置
mesh3.position.y = -objectsDistance * 2; // 第三个模型位置
```

4. GUI 调试

添加材质颜色调整控件，同步更新模型和粒子颜色：

```javascript
const parameters = { materialColor: "#ffeded" };
gui.addColor(parameters, "materialColor")
  .name("材质颜色")
  .onChange(() => {
    material.color.set(parameters.materialColor);
    particlesMaterial.color.set(parameters.materialColor);
  });
```

三、交互逻辑实现

1. 滚动监听

记录滚动位置，用于控制相机和触发动画：

```javascript
const handleScroll = (event: Event) => {
  const target = event.target as HTMLElement | null;
  if (!target) return;
  scrollY = target.scrollTop; // 保存滚动距离
};
```

2. **相机随滚动移动**

根据滚动位置动态调整相机 Y 轴位置，实现 "滚动浏览 3D 模型" 效果：

```javascript
function render() {
  // 相机Y轴位置与滚动距离关联（滚动越远，相机越靠下）
  camera.position.y = (-scrollY / sizes.height) * objectsDistance;
  renderer.render(scene, camera);
  requestAnimationFrame(render);
}
render();
```

3. **鼠标交互优化**

使用相机组（`cameraGroup`）实现平滑视差效果，避免与滚动动画冲突：

```javascript
// 鼠标位置转化为视差偏移量
const parallaxX = -cursor.x;
const parallaxY = cursor.y;
const CAMERA_SPEED = 5; // 平滑速度系数

// 基于deltaTime（帧间隔时间）实现平滑移动
cameraGroup.position.x += (parallaxX - cameraGroup.position.x) * CAMERA_SPEED * deltaTime;
cameraGroup.position.y += (parallaxY - cameraGroup.position.y) * CAMERA_SPEED * deltaTime;
```

四、粒子背景效果

1. 粒子几何与材质

- 随机生成 200 个粒子的 3D 位置（分布在模型周围）
- 使用点材质（`PointsMaterial`），大小随距离衰减

```javascript
// 粒子位置数据（Float32Array存储3D坐标）
const particlesCount = 200;
const position = new Float32Array(particlesCount * 3);
for (let index = 0; index < particlesCount; index++) {
  const i3 = index * 3;
  position[i3 + 0] = (Math.random() - 0.5) * 10; // X轴随机范围
  position[i3 + 1] = (Math.random() - 0.5) * objectsDistance * 3 - objectsDistance; // Y轴范围（覆盖3个模型）
  position[i3 + 2] = (Math.random() - 0.5) * 10; // Z轴随机范围
}

// 创建粒子网格
const particlesGeometry = new THREE.BufferGeometry();
particlesGeometry.setAttribute("position", new THREE.BufferAttribute(position, 3));
const particlesMaterial = new THREE.PointsMaterial({
  color: parameters.materialColor,
  size: 0.03,
  sizeAttenuation: true, // 大小随距离衰减
});
const particlesMesh = new THREE.Points(particlesGeometry, particlesMaterial);
scene.add(particlesMesh);
```

五、**滚动触发动画**

当滚动切换到新 section 时，触发对应模型的旋转动画：

```javascript
const handleScroll = (event: Event) => {
  // ... 省略滚动位置更新代码 ...

  // 计算当前section（滚动高度 / 页面高度 取整）
  const newScetion = Math.round(scrollY / sizes.height);
  if (currentSection === newScetion) return; // 避免重复触发
  currentSection = newScetion;

  // 使用GSAP实现模型旋转动画
  gsap.to(meshArray[currentSection].rotation, {
    duration: 1.5, // 动画时长
    ease: "power2.inOut", // 缓动函数
    x: "+=6", // X轴旋转增加6弧度
    y: "+=3", // Y轴旋转增加3弧度
    z: "+=1.5", // Z轴旋转增加1.5弧度
  });
};

		// 更改mesh转动的赋值，由直接赋值改为增加变化
    // Animate meshes
    meshArray.forEach((mesh) => {
      // mesh.rotation.x = elapsedTime * 0.1;
      // mesh.rotation.y = elapsedTime * 0.12;
      mesh.rotation.x += deltaTime * 0.1;
      mesh.rotation.y += deltaTime * 0.12;
    });
```

## P22 Physics

### 物理引擎选择对比

我们使用的是 ` "cannon-es": "^0.15.1"`

| 引擎          | 特点                              | 适用场景         |
| ------------- | --------------------------------- | ---------------- |
| **cannon.js** | 轻量级，API 简洁，性能适中        | 中小型 3D 项目   |
| **ammo.js**   | 功能强大（Bullet 移植），性能优异 | 复杂物理效果需求 |
| **oimo.js**   | 体积小巧，性能优秀                | 简单物理模拟场景 |

### cannon.js核心概念

[Cannon.js 核心属性与方法速查表](#Cannon.js 核心属性与方法速查表)

#### 质量 (mass) 属性

- **质量为 0**：静止刚体，不受外力影响（地面、墙壁等）
- **质量 > 0**：动态刚体，受重力、碰撞力影响
- `mass: 1` 表示这个球体是动态物体，会在重力作用下下落，并且能与其他物体产生符合质量比例的碰撞反应（例如碰撞时，质量大的物体对质量小的物体的冲击力更大）。
- 如果将 `mass` 设为 0，这个球体就会悬浮在初始位置（0, 3, 0），不受重力和碰撞影响，成为一个固定点。

```javascript
// 动态刚体示例
const sphereBody = new CANNON.Body({
  mass: 1,  // 动态物体,质量为1单位
  position: new CANNON.Vec3(0, 3, 0),
  shape: sphereShape,
});
```

#### 物理世界步进 (step) 方法

`world.step(dt, [timeSinceLastCalled], [maxSubSteps=10])`[参数详解](#world.step() )

```javascript
// 简单模式（固定步长）
world.step(1/60);

// 插值模式（适应帧率波动）
let lastTime = 0;
function animate(currentTime) {
  const timeSinceLastCalled = (currentTime - lastTime) / 1000;
  lastTime = currentTime;
  world.step(1/60, timeSinceLastCalled, 5);
}
```

| 模式     | 参数                       | 特点       | 适用场景     |
| -------- | -------------------------- | ---------- | ------------ |
| 简单模式 | 只传 `dt`                  | 固定步长   | 帧率稳定场景 |
| 插值模式 | `dt + timeSinceLastCalled` | 动态子步骤 | 帧率波动场景 |

### 材质系统

#### 全局默认材质配置

展示了一种更简洁的 Cannon.js 材质配置方式，适合大多数简单场景，常规更复杂配置，详见 [材质配置方式](#材质配置方式 )

```javascript
// 1. 创建材质
const defaultMaterial = new CANNON.Material("default");

// 2. 创建碰撞规则
const defaultContactMaterial = new CANNON.ContactMaterial(
  defaultMaterial,    // 材质A：默认材质
  defaultMaterial,    // 材质B：默认材质（自身与自身碰撞）
  { 
    friction: 0.1,    // 全局默认摩擦系数
    restitution: 0.7  // 全局默认反弹系数
  }
);

// 3. 添加到世界
world.addContactMaterial(defaultContactMaterial); // 添加到世界
world.defaultContactMaterial = defaultContactMaterial; // 设为全局默认
```

### 力与冲量应用

#### 方法对比 [力与冲量方法详解](#力与冲量方法详解 )

| 方法                  | 类型     | 坐标系     | 应用场景           |
| --------------------- | -------- | ---------- | ------------------ |
| `applyForce()`        | 持续力   | 世界坐标系 | 风力、持续推力     |
| `applyImpulse()`      | 瞬时冲量 | 世界坐标系 | 碰撞、踢球         |
| `applyLocalForce()`   | 持续力   | 局部坐标系 | 物体自带推进器     |
| `applyLocalImpulse()` | 瞬时冲量 | 局部坐标系 | 从物体局部发射炮弹 |

#### 使用原则

- **持续效果**：写在 `render` 循环中
- **瞬时效果**：在事件中单次调用

```javascript
// 持续力（每帧调用）
function render() {
  sphereBody.applyForce(
    new CANNON.Vec3(0.1, 0, 0),
    sphereBody.position
  );
  // ...
}

// 瞬时力（事件触发）
document.addEventListener('click', () => {
  sphereBody.applyImpulse(
    new CANNON.Vec3(5, 0, 0),
    sphereBody.position
  );
});
```

### 旋转控制（四元数）

```javascript
// 创建旋转四元数
const quat = new CANNON.Quaternion().setFromAxisAngle(
  new CANNON.Vec3(1, 0, 0),  // 旋转轴（X轴）
  Math.PI / 2                // 旋转角度（弧度）
);

// 应用到物体
floorBody.quaternion = quat;
```

### Three.js 与 Cannon.js 集成

#### 统一参数创建方法

```typescript
interface Position {
  x: number;
  y: number;
  z: number;
}

interface UpdateObject {
  mesh: THREE.Mesh;
  body: CANNON.Body;
}

  const objectsToUpdate: UpdateObject[] = [];
  const sphereGeometry = new THREE.SphereGeometry(1, 20, 20);
  const sphereMaterial = new THREE.MeshStandardMaterial({
    metalness: 0.3,
    roughness: 0.4,
    envMap: environmentMapTexture,
  });

// 创建球体
const createSphere = (radius: number, position: Position): void => {
  // Three.js 网格
  const mesh = new THREE.Mesh(sphereGeometry, sphereMaterial);
  mesh.scale.set(radius, radius, radius);  // 通过缩放保持参数一致
  mesh.position.set(position.x, position.y, position.z);
  scene.add(mesh);

  // Cannon.js 刚体
  const shape = new CANNON.Sphere(radius);
  const body = new CANNON.Body({
    mass: 1,
    position: new CANNON.Vec3(position.x, position.y, position.z),
    shape,
  });

  world.addBody(body);

  // 保存更新对象
  objectsToUpdate.push({ mesh, body });
};

  createSphere(0.5, { x: 0, y: 3, z: 0 });
```

思考：[createSphere方法中为什么这么写`mesh.scale.set(radius, radius, radius);`](#createSphere方法优化)

#### 同步物理与渲染状态

```javascript
function render() {
  // ... 省略滚动位置更新代码 ...
  const deltaTime = clock.getDelta();
  const elapsedTime = clock.getElapsedTime(); //获取自创建时钟以来的时间
  
  // 更新物理世界
  world.step(1 / 60, deltaTime, 3);

  // 同步位置和旋转
  objectsToUpdate.forEach((element) => {
    element.mesh.position.set(
      element.body.position.x,
      element.body.position.y,
      element.body.position.z
    );
  });
  // ... 省略滚动位置更新代码 ...
}
```

#### 创建立方体

```typescript
const boxGeometry = new THREE.BoxGeometry(1, 1, 1);
const boxMaterial = new THREE.MeshStandardMaterial({
  metalness: 0.3,
  roughness: 0.4,
  envMap: environmentMapTexture,
});
const createBox = (
  width: number,
  height: number,
  depth: number,
  position: Position
): void => {
  // Three.js 网格
  const mesh = new THREE.Mesh(boxGeometry, boxMaterial);
  mesh.scale.set(width, height, depth);
  mesh.position.set(position.x, position.y, position.z);
  scene.add(mesh);

  // Cannon.js 刚体
  const shape = new CANNON.Box(
    new CANNON.Vec3(width / 2, height / 2, depth / 2)
  );
  const body = new CANNON.Body({
    mass: 1,
    position: new CANNON.Vec3(position.x, position.y, position.z),
    shape,
  });

  world.addBody(body);
  objectsToUpdate.push({ mesh, body });
};
```

思考：[立方体为什么不回翻滚倒下？](#为什么必须同步旋转（`quaternion.set`）)

### 性能优化

```javascript
// 使用 SAP 广义相位算法
world.broadphase = new CANNON.SAPBroadphase(world);

// 允许物体休眠
world.allowSleep = true;
```

### 声音效果

- 特别注意，这里添加的声音事件，是给**物理引擎的body属性**添加的，并**不是js中的元素body**

[更加真实的声音效果](#声音效果ai优化版本)

```javascript
// 碰撞声音
const hitSound = new Audio("./sounds/hit.mp3");

const playHitSound = (collision) => {
  const impactStrength = collision.contact.getImpactVelocityAlongNormal();
  if (impactStrength < 1.5) return;// 冲击力大小播放声音，更加真实，小于1.5部播放
  
  hitSound.volume = Math.random();  // 随机音量增加真实感
  hitSound.currentTime = 0;         // 重置播放，解决播放声音连续问题
  hitSound.play();
};

// 给刚体添加碰撞事件监听
const createBox = (
    width: number,
    height: number,
    depth: number,
    position: Position
  ): void => {
    // ... 省略滚动位置更新代码 ...

    // Cannon.js body
    const shape = new CANNON.Box(
      new CANNON.Vec3(width / 2, height / 2, depth / 2)
    );
    const body = new CANNON.Body({
      mass: 1,
      position: new CANNON.Vec3(position.x, position.y, position.z),
      shape,
    });
    body.addEventListener("collide", playHitSound);// 添加声音
    world.addBody(body);
  
    // ... 省略滚动位置更新代码 ...
  };
```

### 场景重置

```javascript
const resetScene = () => {
  objectsToUpdate.forEach((element) => {
    // 移除物理体
    element.body.removeEventListener("collide", playHitSound);
    world.removeBody(element.body);
    
    // 移除网格
    scene.remove(element.mesh);
  });

  // 清空更新数组
  objectsToUpdate.splice(0, objectsToUpdate.length);
};
```

### GUI 控制界面

```javascript
const gui = new GUI();
const debugObject = {
  createSphere: () => {
    createSphere(Math.random() * 0.5, {
      x: Math.random() * 3,
      y: 3,
      z: Math.random() * 3,
    });
  },
  createBox: () => {
    createBox(Math.random(), Math.random(), Math.random(), {
      x: (Math.random() - 0.5) * 3,
      y: 3,
      z: (Math.random() - 0.5) * 3,
    });
  },
  reset: resetScene
};

gui.add(debugObject, "createSphere");
gui.add(debugObject, "createBox");
gui.add(debugObject, "reset");
```



## P23 Imported models

### 一、glTF 格式核心认知

#### 1. 什么是 glTF

glTF（GL Transmission Format）被称为 “3D 界的 JPEG”，是 Khronos Group 制定的开源 3D 模型标准。其核心目标是**最小化传输体积**与**最大化加载效率**，本质是定义 3D 数据（模型结构、材质、动画等）组织方式的 “容器规范”，衍生出多种实现变体。

#### 2. 格式选择建议

[glTF四种格式区别详解](#glTF四种格式区别详解)

1. **开发 / 调试阶段**：优先用 **glTF（多文件）**，便于修改资源路径、调试材质参数。
2. **生产环境分发**：优先用 **glTF-Binary（GLB）**，单文件无依赖，加载效率高。
3. **大规模 / 带宽有限场景**：用 **glTF-Draco**（结合 GLB 打包），平衡体积与加载速度（需确保客户端支持 Draco 解码）。
4. **快速演示 / 嵌入场景**：用 **glTF-Embedded**，仅限小模型（避免体积过大影响性能）。

### 二、Three.js 加载 glTF 核心流程

#### 1. 基础加载（非压缩模型）

##### （1）核心依赖

导入 `GLTFLoader` 负责解析 glTF/GLB 格式：

```typescript
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";
```

##### （2）加载实现

```typescript
// 1. 初始化加载器
const gltfLoader = new GLTFLoader();

// 2. 定义模型路径（支持 gltf/glb 等格式）
const modelPath = `${import.meta.env.BASE_URL}models/模型路径`;// 文件路径：/public/models/Duck

// 3. 执行加载
gltfLoader.load(
  modelPath,
  // 加载成功回调
  (gltf) => {
    // 关键：添加整个模型场景（含完整层级，避免漏元素）
    scene.add(gltf.scene);
    
    // 可选：模型变换（缩放、位移等）
    gltf.scene.scale.set(0.5, 0.5, 0.5); // 缩放适配场景
  },
  // 加载进度回调
  (xhr) => {
    console.log((xhr.loaded / xhr.total) * 100 + "% loaded");
  },
  // 加载错误回调
  (error) => {
    console.error("加载失败：", error);
  }
);
```

#### 2. 加载 Draco 压缩模型（优化体积）

##### （1）额外依赖

需 `DRACOLoader` 解码 Draco 压缩的几何数据：

```typescript
import { DRACOLoader } from "three/addons/loaders/DRACOLoader.js";
```

##### （2）解码器配置

1. 复制解码器资源：将 `/node_modules/three/examples/jsm/libs/draco` 文件夹复制到 `/public/draco`；
2. 关联加载器：

```typescript
// 1. 初始化 Draco 解码器
const dracoLoader = new DRACOLoader();
// 设置解码器路径（对应 public 下的资源）
dracoLoader.setDecoderPath(`${import.meta.env.BASE_URL}draco/`);// 文件路径：/public/models/draco

// 2. 关联到 GLTFLoader
const gltfLoader = new GLTFLoader();
gltfLoader.setDRACOLoader(dracoLoader);

// 3. 加载 Draco 压缩模型（路径指向 glTF-Draco 格式文件）
gltfLoader.load(
  `${import.meta.env.BASE_URL}models/模型名/glTF-Draco/模型名.gltf`,
  (gltf) => {
    scene.add(gltf.scene);
  },
  // 进度/错误回调同上
);
```

### 三、glTF 加载结果核心属性解析

加载成功后返回的 `gltf` 对象包含关键资源：

| 属性                  | 类型                       | 说明                                 |
| --------------------- | -------------------------- | ------------------------------------ |
| `gltf.animations`     | Array<THREE.AnimationClip> | 模型动画片段数组（骨骼、形变等动画） |
| `gltf.scene`          | THREE.Group                | 主场景对象，含所有可视元素的层级结构 |
| `gltf.scene.children` | Array<Object3D>            | 主场景的直接子元素（网格、子组等）   |
| `gltf.scenes`         | Array<THREE.Group>         | 模型所有场景（通常仅一个）           |
| `gltf.cameras`        | Array<THREE.Camera>        | 模型自带相机（需手动添加到场景生效） |
| `gltf.asset`          | Object                     | 元数据（glTF 版本、生成工具等）      |

### 四、带动画的模型加载与播放

#### 1. 核心依赖与初始化

需 `AnimationMixer` 管理动画播放：

```typescript
// 1. 声明全局 mixer 变量（用于帧更新）
let mixer;

// 2. 加载动画模型（如 Fox 模型）
gltfLoader.load(
  `${import.meta.env.BASE_URL}models/Fox/glTF/Fox.gltf`,
  (gltf) => {
    scene.add(gltf.scene);
    gltf.scene.scale.set(0.025, 0.025, 0.025); // 适配场景

    // 3. 初始化动画混合器（绑定模型场景）
    mixer = new THREE.AnimationMixer(gltf.scene);

    // 4. 选择并播放动画片段（gltf.animations 数组存所有动画）
    const action = mixer.clipAction(gltf.animations[2]); // 选第3个动画
    action.play(); // 启动动画
  }
);
```

#### 2. 动画帧更新

在渲染循环中更新 `mixer` 确保动画运行：

```typescript
// 声明时间变量记录帧间隔
let previousTime = 0;

function render() {
  const deltaTime = clock.getDelta(); // 1. 计算帧间隔时间
  const elapsedTime = clock.getElapsedTime(); //获取自创建时钟以来的时间

  // 2. 更新动画混合器
  if (mixer) {
    mixer.update(deltaTime);
  }

  // 渲染场景
  renderer.render(scene, camera);
  requestAnimationFrame(render);
}
render();
```

### 五、实用技巧与注意事项

#### 1. 模型预处理与检查

- 查看模型信息：加载前通过 [glTF Viewer](https://gltf-viewer.donmccurdy.com/) 或本地 Three.js Editor 检查模型的位置、旋转、缩放及层级，避免导入后异常；
- 本地 Editor 使用：官网 Editor 若无法访问，可通过 Three.js 源码中的 `examples/editor` 文件夹启动本地版本，快速预览模型。



## P24 Raycaster and Mouse Events

### 1. Raycaster 基础概念

#### 创建射线

```javascript
const raycaster = new THREE.Raycaster();
const rayOrgin = new THREE.Vector3(-3, 0, 0);
const rayDirection = new THREE.Vector3(10, 0, 0);
rayDirection.normalize(); // 归一化很重要

raycaster.set(rayOrgin, rayDirection);
```

#### raycaster.set() 方法解析

- **作用**：设置射线的起点和方向
- **参数**：
  - `origin`：射线起点（Vector3）
  - `direction`：射线方向（Vector3）

#### 为什么需要归一化 rayDirection？

- **归一化**：将向量转换为单位向量（长度为1）
- **原因**：
  - 射线检测算法基于单位向量计算交点
  - 确保距离计算准确
  - 使方向向量的分量范围在 -1 到 1 之间

#### intersect 对象属性解析

```javascript
{
  distance: 2.5,           // 射线起点到相交点的距离（数值越小，物体越靠前）
  face: {                  // 相交的物体表面（包含顶点索引、法向量等）
    a: 136, b: 153, c: 154, // 面的顶点索引
    normal: Vector3,       // 面的法向量
    materialIndex: 0       // 材质索引
  },
  faceIndex: 241,          // 面的索引
  object: Mesh,            // 与射线相交的 3D 对象（如 Mesh）
  point: Vector3,          // 相交点在 3D 世界中的坐标（Vector3）
  uv: Vector2              // 相交点在物体纹理上的 UV 坐标（用于纹理交互）
}
```

### 2. 射线与模型交互

#### 基本交互实现

```javascript
function render() {
  // ... 其他代码
  // 重置所有物体颜色
	objectToTest.forEach((object) => {
	  object.material.color.set("#ff0000");
	});

	// 设置相交物体颜色
	intersects.forEach((intersect) => {
	  intersect.object.material.color.set("#0000ff");
	});
  // ... 其他代码
}
```

#### 优化建议

**问题**：在render循环中重复创建Raycaster效率低

**优化方案**：

```javascript
// 在循环外创建
const raycaster = new THREE.Raycaster();
const rayOrgin = new THREE.Vector3(-3, 0, 0);
const rayDirection = new THREE.Vector3(1, 0, 0);
rayDirection.normalize();

function render() {
  // 只更新必要的数据
  raycaster.set(rayOrgin, rayDirection);
  // ... 其他代码
}
```

### 3. 鼠标事件处理

#### 鼠标坐标转换

```javascript
const mouse = new THREE.Vector2();

const mouseMoveEvent = (e: MouseEvent) => {
  // 将屏幕坐标转换为标准化设备坐标（NDC）
  mouse.x = (e.clientX / sizes.width) * 2 - 1;   // [-1, 1]
  mouse.y = -(e.clientY / sizes.height) * 2 + 1; // [-1, 1]
};
```

#### raycaster.setFromCamera() vs raycaster.set()

- **`raycaster.set(origin, direction)`**：通用方法，需要手动指定射线的起点和方向（适用于自定义射线，如场景内固定方向的射线）。
- **`raycaster.setFromCamera(mouse, camera)`**：专为相机视角设计的快捷方法，自动将 2D 鼠标坐标（`mouse`，范围`-1`到`1`）转换为 3D 射线：
  - 起点：相机位置。
  - 方向：从相机指向鼠标在 3D 世界中对应的点。
- 场景差异：鼠标交互必须用 `setFromCamera`，因为需要将屏幕坐标映射到 3D 世界；自定义射线（如场景内的激光束）用 `set`。

#### 射线方向说明

射线是从**相机位置**射向**鼠标指向的3D空间点**，不是从鼠标射向相机。这是因为：

- 在3D图形中，相机是观察点
- 射线检测模拟的是"从眼睛看出去"的方向

### 4. 鼠标点击检测优化

#### 优化代码分析

```javascript
if (intersects.length) {
  currentIntersect = intersects[0];
} else {
  currentIntersect = null;
}
```

- **作用**：缓存当前鼠标下的第一个物体（`intersects[0]` 是距离最近的物体），避免在点击事件中重复执行射线检测。
- **不做这一步的区别**：点击时需要重新调用 `raycaster.intersectObjects`，增加重复计算；且无法在鼠标移动时提前记录物体状态（如悬停效果）。
- **普遍性**：这是通用优化方式，适用于所有需要 “鼠标 - 物体” 交互的场景（减少冗余计算，统一状态管理）。

#### 完整优化方案

```javascript
let currentIntersect = null;

function render() {
  const intersects = raycaster.intersectObjects(objectToTest);
  
  // 只在相交状态变化时更新
  if (intersects.length > 0) {
    if (currentIntersect !== intersects[0]) {
      currentIntersect = intersects[0];
      // 触发鼠标进入事件
    }
  } else if (currentIntersect !== null) {
    currentIntersect = null;
    // 触发鼠标离开事件
  }
}
```

### 5.  模型交互的优化写法（鼠标经过缩放）

#### 当前实现的问题

```javascript
// 每帧都检测和重置，效率低
if (model) {
  const modelIntersects = raycaster.intersectObject(model);
  if (modelIntersects.length) {
    model.scale.set(1.2, 1.2, 1.2);
  } else {
    model.scale.set(1, 1, 1);
  }
}
```

当前写法的问题：每帧执行缩放操作，即使鼠标未移动也会重复设置（浪费性能）。

优化方式：

1. 用状态变量记录是否悬停（避免重复设置相同状态）。
2. 只在鼠标移动时更新射线检测（而非每帧检测）。

```javascript
// 全局状态：记录是否悬停
let isModelHovered = false;
const raycaster = new THREE.Raycaster(); // 全局创建一次

// 鼠标移动时才更新射线检测
function handleMouseMove(e) {
  // 更新鼠标坐标
  mouse.x = (e.clientX / sizes.width) * 2 - 1;
  mouse.y = -(e.clientY / sizes.height) * 2 + 1;

  // 仅在鼠标移动时执行检测
  if (model) {
    raycaster.setFromCamera(mouse, camera);
    const intersects = raycaster.intersectObject(model);
    const newHoverState = intersects.length > 0;

    // 状态变化时才更新缩放（避免重复操作）
    if (newHoverState !== isModelHovered) {
      isModelHovered = newHoverState;
      model.scale.set(isModelHovered ? 1.2 : 1, isModelHovered ? 1.2 : 1, isModelHovered ? 1.2 : 1);
    }
  }
}

// 绑定事件（只在鼠标移动时触发）
window.addEventListener('mousemove', handleMouseMove);

// render中只保留必要的渲染逻辑
function render() {
  // ... 其他动画逻辑
  renderer.render(scene, camera);
  requestAnimationFrame(render);
}
```



# 附录

## render 中`clock.getDelta()`输出 0 的问题

**一、问题现象**

在第一个`render`函数中，先调用`clock.getElapsedTime()`，再调用`clock.getDelta()`，控制台打印的`deltaTime`始终为 0；而第二个仅调用`clock.getDelta()`的`render`函数，`deltaTime`首帧正常（非 0），后续也能稳定输出帧间隔时间。

关键代码对比：

```javascript
// 问题代码（deltaTime输出0）
const clock = new THREE.Clock();
function render() {
  const elapsedTime = clock.getElapsedTime(); // 先调用
  const deltaTime = clock.getDelta();        // 后调用，输出0
  console.log(deltaTime);
  requestAnimationFrame(render);
}

// 正常代码（deltaTime输出正常）
const clock = new THREE.Clock();
function render() {
  const deltaTime = clock.getDelta(); // 仅调用getDelta()，输出正常
  console.log(deltaTime);
  requestAnimationFrame(render);
}
```

**二、核心原因：`THREE.Clock`的方法依赖逻辑**

**问题本质**：第一个 render 中，`getElapsedTime()` 内部提前调用了 `getDelta()`，更新了 `oldTime`，导致后续手动调用 `getDelta()` 时时间差为 0。

**1. `Clock`内部关键变量与方法逻辑**

`Clock`维护两个核心变量：

- `oldTime`：上一次调用`getDelta()`时的时间戳（初始值 =`Clock`实例化时间）；
- `elapsedTime`：从`Clock`实例化到当前的总时间（初始值 = 0）。

两个方法的核心逻辑（简化版源码）：

```javascript
// 1. getDelta()：计算“当前时间 - oldTime”，并更新状态
getDelta() {
  const now = 当前时间（毫秒）;
  const diff = (now - this.oldTime) / 1000; // 转秒，即时间差
  this.oldTime = now; // 更新oldTime为当前时间
  this.elapsedTime += diff; // 累计总时间
  return diff;
}

// 2. getElapsedTime()：获取总时间，但先调用getDelta()
getElapsedTime() {
  // 关键！先执行getDelta()更新时间状态，再返回总时间
  return this.getDelta() + this.elapsedTime;
}
```

**2. 问题代码的执行流程（一步步拆解）**

在第一个`render`函数中，代码执行顺序触发 “时间差被提前消耗”：

1. **第一步：调用`clock.getElapsedTime()`**

   - 内部自动执行

     ```
     getDelta()
     ```

     - 计算`now（当前时间） - oldTime（初始值=实例化时间）`→ 得到正常时间差（如 0.01 秒）；
     - 更新`oldTime = now`（此时`oldTime`已变为 “当前时间”）；
     - 更新`elapsedTime += 0.01`→ 总时间变为 0.01 秒；

   - `getElapsedTime()`返回`0.01（getDelta()结果） + 0（初始elapsedTime）`→ 总时间 = 0.01 秒。

2. **第二步：调用`clock.getDelta()`**

   - 此时`oldTime`已被第一步的`getDelta()`更新为 “当前时间”；

   - 再次计算

     ```
     now（新当前时间） - oldTime（第一步的当前时间）
     ```

     - 因两步代码执行速度极快（微秒级），`now`与`oldTime`几乎完全相同；
     - 时间差`diff ≈ 0`→ `deltaTime`输出 0。

**三、解决方案：调整调用逻辑**

核心原则：**同一帧内，`getElapsedTime()`与`getDelta()`二选一，避免重复调用**（前者已包含后者的逻辑）。

**方案 1：先调用`getDelta()`，再读`elapsedTime`**

`getDelta()`会自动更新`elapsedTime`，直接读取`clock.elapsedTime`即可获取总时间，无需调用`getElapsedTime()`：

```javascript
const clock = new THREE.Clock();
function render() {
  // 1. 先调用getDelta()，获取正常时间差
  const deltaTime = clock.getDelta(); 
  // 2. 直接读取elapsedTime（已被getDelta()更新）
  const elapsedTime = clock.elapsedTime; 
  console.log(deltaTime); // 输出正常（如0.01~0.02秒）
  
  // 后续逻辑：用deltaTime做动画（帧率无关），用elapsedTime做时间相关逻辑
  mesh.rotation.y += 0.5 * deltaTime;
  requestAnimationFrame(render);
}
```

**方案 2：若需`getElapsedTime()`，则不手动调用`getDelta()`**

`getElapsedTime()`内部已执行`getDelta()`，可通过 “总时间差值” 间接获取时间差（适合需总时间的场景）：

```javascript
const clock = new THREE.Clock();
let prevElapsedTime = 0; // 记录上一帧的总时间

function render() {
  // 1. 调用getElapsedTime()，内部已更新时间
  const elapsedTime = clock.getElapsedTime(); 
  // 2. 时间差 = 当前总时间 - 上一帧总时间
  const deltaTime = elapsedTime - prevElapsedTime; 
  console.log(deltaTime); // 输出正常
  
  prevElapsedTime = elapsedTime; // 更新上一帧总时间
  requestAnimationFrame(render);
}
```

**四、核心原则总结**

1. **`getElapsedTime()`是`getDelta()`的 “超集”**：前者内部已包含后者的逻辑，无需在同一帧内重复调用；
2. **`getDelta()`的核心价值**：获取 “相邻两次调用的时间差”，用于实现帧率无关的动画（如`物体旋转 = 速度 × deltaTime`）；
3. **避免时间差被提前消耗**：同一帧内，优先调用`getDelta()`，再通过`clock.elapsedTime`获取总时间，是最安全的用法。

------

### world.step() 

```javascript
world.step(dt, [timeSinceLastCalled], [maxSubSteps=10])
```

1. **`dt`（必填）**

   - 类型：`Number`（秒）
   - 含义：**固定时间步长**（每个物理子步骤的时长）。
   - 作用：物理引擎内部计算时使用的固定时间间隔，决定了单次物理模拟的精度。
   - 示例：`dt = 1/60` 表示每个子步骤模拟 1/60 秒的物理过程。

2. **`timeSinceLastCalled`（可选）**

   - 类型：`Number`（秒）
   - 含义：自上一次调用 `step()` 方法以来，真实流逝的时间（即 “帧间隔时间”）。
   - 作用：用于启用 “插值模式”，当实际帧间隔大于 `dt` 时，将时间分解为多个 `dt` 子步骤，避免物理模拟跳跃。
   - 示例：如果浏览器卡顿，两帧间隔 0.1 秒（100ms），则 `timeSinceLastCalled = 0.1`。

3. **`maxSubSteps`（可选，默认值：10）**

   - 类型：`Number`

     含义：单次 `step()` 调用中允许的最大子步骤数量。

   - 作用：限制物理计算的最大工作量，防止因 `timeSinceLastCalled` 过大（如浏览器冻结后恢复）导致的性能崩溃。

### 两种工作模式

根据是否传入 `timeSinceLastCalled`，`step()` 有两种使用模式：

#### 1. 简单模式（无插值，固定步长）

只传入 `dt`，适用于帧率稳定的场景：

```javascript
// 每帧固定模拟 1/60 秒的物理过程
world.step(1/60); 
```

- 原理：忽略实际帧间隔，强制每帧按 `dt` 推进物理世界。
- 优点：简单直观，计算量固定。
- 缺点：若实际帧率波动（如低于 60fps），物理运动会显得 “卡顿” 或 “加速”。

#### 2. 插值模式（多子步骤，适应帧率波动）

传入 `dt` + `timeSinceLastCalled`（通常配合 `maxSubSteps`），适用于对物理稳定性要求高的场景：

```javascript
// 记录上一帧时间
let lastTime = 0;

function animate(currentTime) {
  // 计算当前帧与上一帧的时间差（秒）
  const timeSinceLastCalled = (currentTime - lastTime) / 1000;
  lastTime = currentTime;

  // 插值模式：将时间差分解为多个 dt 子步骤
  world.step(1/60, timeSinceLastCalled, 5); // 最多5个子步骤
  // ... 同步物理位置到渲染物体
  requestAnimationFrame(animate);
}
```

- 原理：
  当 `timeSinceLastCalled = 0.1` 秒，`dt = 1/60 ≈ 0.0167` 秒时，引擎会自动计算需要 `0.1 / 0.0167 ≈ 6` 个子步骤，但受限于 `maxSubSteps=5`，实际执行 5 个子步骤（共模拟 `5×0.0167≈0.0835` 秒），剩余时间累积到下一帧。
- 优点：物理模拟不受帧率波动影响，运动更平滑、稳定（尤其避免高速物体 “穿墙”）。
- 缺点：实现稍复杂，计算量随 `timeSinceLastCalled` 动态变化。

#### 关键区别总结

| 模式     | 参数使用                      | 适用场景                     | 核心特点                     |
| -------- | ----------------------------- | ---------------------------- | ---------------------------- |
| 简单模式 | 只传 `dt`                     | 帧率稳定、简单场景           | 固定步长，忽略实际时间差     |
| 插值模式 | 传 `dt + timeSinceLastCalled` | 帧率波动大、精度要求高的场景 | 动态分解时间为子步骤，更稳定 |

------

## 材质配置方式

### 常规材质配置方式

#### 1. 定义基础材质（Material）

创建具体材质实例，代表物体表面属性：

```javascript
// 定义两种材质：混凝土和塑料
const concreteMaterial = new CANNON.Material("concrete"); // 名称仅用于标识
const plasticMaterial = new CANNON.Material("plastic");
```

#### 2. 定义材质间的碰撞规则（ContactMaterial）

指定两种材质碰撞时的摩擦系数和反弹系数：

```javascript
// 定义"混凝土-塑料"碰撞规则
const concretePlasticContactMaterial = new CANNON.ContactMaterial(
  concreteMaterial,   // 材质A
  plasticMaterial,    // 材质B
  { 
    friction: 0.1,    // 摩擦系数：0.1表示低摩擦（塑料在混凝土上易滑动）
    restitution: 0.7  // 反弹系数：0.7表示中等弹性（碰撞后会反弹）
  }
);

// 将规则添加到物理世界
world.addContactMaterial(concretePlasticContactMaterial);
```

#### 3. 为物体绑定材质

给物理实体（Body）指定材质，使其遵循预设的碰撞规则：

```javascript
// 球体绑定"塑料"材质
const sphereBody = new CANNON.Body({
  // ...其他属性
  material: plasticMaterial, // 绑定材质
});

// 地面绑定"混凝土"材质
const floorBody = new CANNON.Body();
floorBody.material = concreteMaterial; // 绑定材质
```

#### 4. 实际效果

当球体（塑料材质）与地面（混凝土材质）碰撞时：

- 会应用 `friction: 0.1`：球体滚动时阻力小，能滑得更远
- 会应用 `restitution: 0.7`：球体会有明显反弹（但不会完全弹回原高度）



### 全局默认材质

#### 1. 核心配置逻辑

通过定义一个 "默认材质" 和对应的 "默认碰撞规则"，让所有未单独设置材质的物体自动遵循这套规则，省去为每个物体单独绑定材质的步骤。

#### 2. 具体步骤

##### （1）创建默认材质

```javascript
const defaultMaterial = new CANNON.Material("default"); // 通用材质
```

##### （2）创建默认碰撞规则

定义该材质与自身碰撞时的物理特性（摩擦、反弹）：

```javascript
const defaultContactMaterial = new CANNON.ContactMaterial(
  defaultMaterial,    // 材质A：默认材质
  defaultMaterial,    // 材质B：默认材质（自身与自身碰撞）
  { 
    friction: 0.1,    // 全局默认摩擦系数
    restitution: 0.7  // 全局默认反弹系数
  }
);
```

##### （3）设置为物理世界的默认规则

```javascript
world.addContactMaterial(defaultContactMaterial); // 添加到世界
world.defaultContactMaterial = defaultContactMaterial; // 设为全局默认
```

##### （4）创建物体时无需单独绑定材质

所有未指定`material`属性的物体，会自动使用全局默认材质和碰撞规则：

```javascript
// 球体和地面都未设置material，自动使用defaultMaterial
const sphereBody = new CANNON.Body({ /* 未指定material */ });
const floorBody = new CANNON.Body(); /* 未指定material */
```

------



## 力与冲量方法详解

### 1. 核心方法详解

#### （1）`applyForce(force, worldPoint)`

- **作用**：向物体施加一个**持续的力**（单位：牛顿），力的效果会随时间累积。

- 参数：

  - `force`：力的大小和方向（`CANNON.Vec3` 类型，如 `new CANNON.Vec3(10, 0, 0)` 表示沿 X 轴施加 10N 的力）。
  - `worldPoint`：力的作用点（世界坐标系中的位置，`CANNON.Vec3` 类型）。若传入物体质心，则仅产生平动；若偏离质心，会同时产生旋转。

- 示例：

  ```javascript
  // 向球体施加一个向右的持续力，作用点在球体质心
  sphereBody.applyForce(
    new CANNON.Vec3(5, 0, 0),  // 力的方向和大小
    sphereBody.position        // 作用点（质心位置）
  );
  ```

#### （2）`applyImpulse(impulse, worldPoint)`

- **作用**：向物体施加一个**瞬时冲量**（单位：牛顿・秒），直接改变物体的动量（类似碰撞瞬间的冲击力）。

- 参数：

  - `impulse`：冲量的大小和方向（`CANNON.Vec3` 类型）。
  - `worldPoint`：冲量的作用点（世界坐标系中的位置）。

- **特点**：效果是瞬时的，不会随时间累积，适合模拟一次性的撞击（如踢球、击球）。

- 示例：

  ```javascript
  // 给球体一个向右的瞬时冲量，使其立刻获得速度
  sphereBody.applyImpulse(
    new CANNON.Vec3(2, 0, 0),  // 冲量大小和方向
    sphereBody.position        // 作用点（质心）
  );
  ```

#### （3）`applyLocalForce(force, localPoint)`

- **作用**：与 `applyForce` 类似，但力的作用点基于**物体自身的局部坐标系**（而非世界坐标系）。

- 参数：

  - `force`：力的大小和方向（局部坐标系下的 `CANNON.Vec3`）。
  - `localPoint`：力的作用点（物体局部坐标系中的位置，如 `new CANNON.Vec3(0, 0.5, 0)` 表示物体顶部）。

- **适用场景**：需要相对于物体自身方向施力时（如推进器固定在物体的某个局部位置）。

- 示例：

  ```javascript
  // 从球体自身的右侧（局部坐标系 X 轴正方向）施加持续力
  sphereBody.applyLocalForce(
    new CANNON.Vec3(5, 0, 0),  // 局部 X 轴方向的力
    new CANNON.Vec3(0.5, 0, 0) // 作用点：球体右侧边缘（局部坐标）
  );
  ```

#### （4）`applyLocalImpulse(impulse, localPoint)`

- **作用**：与 `applyImpulse` 类似，但冲量的作用点基于**物体自身的局部坐标系**。

- 参数：

  - `impulse`：冲量的大小和方向（局部坐标系下的 `CANNON.Vec3`）。
  - `localPoint`：冲量的作用点（物体局部坐标系中的位置）。

- **适用场景**：需要相对于物体自身方向施加瞬时冲击力时（如炮弹从物体的局部位置发射）。

- 示例：

  ```javascript
  // 从球体自身的前方（局部 Z 轴正方向）施加瞬时冲量
  sphereBody.applyLocalImpulse(
    new CANNON.Vec3(0, 0, 3),  // 局部 Z 轴方向的冲量
    new CANNON.Vec3(0, 0, 0.5) // 作用点：球体前端（局部坐标）
  );
  ```

### 2. 关键区别总结

| 方法                | 力 / 冲量类型 | 坐标系         | 核心特点                                   | 典型应用场景           |
| ------------------- | ------------- | -------------- | ------------------------------------------ | ---------------------- |
| `applyForce`        | 持续力        | 世界坐标系     | 效果随时间累积，适合持续推动               | 火箭推进、风力         |
| `applyImpulse`      | 瞬时冲量      | 世界坐标系     | 效果瞬时生效，直接改变动量，适合一次性撞击 | 踢球、碰撞冲击         |
| `applyLocalForce`   | 持续力        | 物体局部坐标系 | 相对于物体自身方向施力，适合固定位置推力   | 物体自带推进器         |
| `applyLocalImpulse` | 瞬时冲量      | 物体局部坐标系 | 相对于物体自身方向施加瞬时力               | 从物体局部位置发射炮弹 |

### 3. 使用注意事项

- 若物体质量为 `0`（静止刚体，如地面 `floorBody`），施加力或冲量不会使其运动（符合物理规律）。
- 作用点偏离质心时，物体不仅会平动，还会产生旋转（扭矩效应）。
- 力和冲量的大小需要根据场景调试（过大会导致物体运动异常）。

这四种施加力 / 冲量的方式（`applyForce`、`applyImpulse`、`applyLocalForce`、`applyLocalImpulse`）是否写在 `render` 循环中，取决于你想要的效果：

- **如果需要持续施加力**（比如模拟持续的风力、推进器推力）：
  必须写在 `render` 循环里，每帧调用一次，让力随时间累积。
  类比：就像持续推箱子，需要一直用力才会持续加速。
- **如果只需施加一次力**（比如碰撞瞬间的冲击、踢一脚球）：
  不能写在 `render` 循环里，应该在特定事件中调用一次（比如点击按钮、检测到碰撞时）。
  类比：踢足球只需踢一次，球就会持续运动，不需要一直踢。

**示例代码结构**：

```javascript
function render() {
  // 1. 持续力（每帧调用）
  sphereBody.applyForce(
    new CANNON.Vec3(0.1, 0, 0),  // 小力持续推
    sphereBody.position
  );

  // 物理世界更新
  world.step(1/60);
  // 同步渲染...
  requestAnimationFrame(render);
}

// 2. 瞬时力（事件触发时调用一次）
document.addEventListener('click', () => {
  sphereBody.applyImpulse(
    new CANNON.Vec3(5, 0, 0),  // 一次大力冲击
    sphereBody.position
  );
});
```

------

## createSphere方法优化

### 1. 解决 “几何体复用” 与 “尺寸多样化” 的矛盾

代码中 `sphereGeometry` 是**全局复用的几何体**（`new THREE.SphereGeometry(1, 20, 20)`），其初始半径固定为 `1`。
如果直接使用这个几何体创建不同大小的球体（如半径 `0.5` 或 `2`），不缩放的话所有模型都会是半径 `1` 的固定大小，无法实现尺寸多样化。
通过 `scale.set(radius, radius, radius)` 可以基于初始几何体，按传入的 `radius` 比例缩放，快速不同尺寸的球体共享同一个几何体，既节省内存（避免重复创建几何体），又能灵活控制大小。

### 2. 保证渲染模型与物理碰撞体尺寸一致

Cannon.js 中创建碰撞体时直接使用 `new CANNON.Sphere(radius)`，其尺寸由参数 `radius` 决定。
如果 Three.js 模型不做对应缩放（仍保持初始半径 `1`），会导致**渲染的视觉大小与物理碰撞检测的尺寸不匹配**（例如：视觉上是小球，物理上却按大球碰撞）。
通过缩放模型，确保 `渲染尺寸 = 物理碰撞尺寸 = radius`，两者完全同步。

### 举例说明

- 当调用 `createSphere(0.5, ...)` 时：
  - Cannon 碰撞体：半径 `0.5`（物理碰撞物理碰撞按此尺寸计算）。
  - Three.js 模型：初始几何体半径 `1` → 缩放 `0.5` 倍 → 最终视觉半径 `0.5`（与物理尺寸一致）。
- 若不缩放，会出现：视觉上是半径 `1` 的大球，物理上却按半径 `0.5` 检测碰撞，导致 “穿模” 或 “碰撞判定异常”。

------

## 为什么必须同步旋转（`quaternion.set`）

立方体只会弹跳、不会倒下的问题，根源是**未同步物理旋转到视觉模型**：

1. **物理引擎已计算旋转，但视觉未更新**
   Cannon.js 中，立方体碰撞后会自然计算旋转（如被撞击后倾倒），但默认不会影响 Three.js 模型的视觉旋转。如果只同步位置（`position`）而不同步旋转（`quaternion`），就会出现 “物理上已倒下，视觉上仍直立” 的矛盾。

2. **旋转同步的关键代码**
   在渲染循环中添加：

   ```typescript
   function render() {
     // ... 省略滚动位置更新代码 ...
     const deltaTime = clock.getDelta();
     const elapsedTime = clock.getElapsedTime(); //获取自创建时钟以来的时间
     
     // 更新物理世界
     world.step(1 / 60, deltaTime, 3);
   
     // 同步位置（已有的代码）
     element.mesh.position.set(
       element.body.position.x,
       element.body.position.y,
       element.body.position.z
     );
     
     // 新增：同步旋转（解决立方体不倒下的问题）
     element.mesh.quaternion.set(
       element.body.quaternion.x,
       element.body.quaternion.y,
       element.body.quaternion.z,
       element.body.w
     );
     // ... 省略滚动位置更新代码 ...
   }
   ```

3. **实际效果**
   同步旋转后，立方体碰撞时会：

   - 受撞击力影响产生旋转（物理计算）
   - 视觉上实时显示倾倒、翻滚状态（与物理完全匹配）
   - 后续碰撞会基于当前旋转状态计算（如侧面撞击时更易翻滚）

------

## 声音效果ai优化版本

```typescript
/**
 * Sounds
 */
// const hitSound = new Audio(
// new URL("../assets/sounds/hit.mp3", import.meta.url).href
// );
// const playHitSound = (collision) => {
// const impactStrength = collision.contact.getImpactVelocityAlongNormal();
// if (impactStrength < 1.5) return;
// hitSound.volume = Math.random();
// hitSound.currentTime = 0;
// hitSound.play();
// };
// 1. 使用AudioBufferSourceNode替代Audio元素，提供更好的音效控制和多实例播放
/**
 * audioContext：Web Audio API 的核心对象，相当于一个 “音频处理工厂”，所有音频操作（播放、音量调整等）都需要通过它创建。
 * 全局只需要一个实例，所以定义为外部变量复用。
 * hitSoundBuffer：存储解码后的音频数据（二进制缓冲区）。
 * 音频文件加载后解码一次，后续播放时直接复用这个缓冲区，避免重复加载和解码，提升性能。
 */
let audioContext: AudioContext | null = null;
let hitSoundBuffer: AudioBuffer | null = null;

// 预加载音效（建议在初始化阶段调用）
const loadHitSound = async (): Promise<void> => {
  try {
    // 初始化AudioContext（处理浏览器兼容性和类型）
    if (!audioContext) {
      const AudioContextConstructor =
        audioContext ||
        window.AudioContext ||
        (window as any).webkitAudioContext;
      if (AudioContextConstructor) {
        audioContext = new AudioContextConstructor();
      } else {
        throw new Error("Web Audio API is not supported in this browser");
      }
    }

    // 加载并解码音频文件
    const response = await fetch(
      new URL("../assets/sounds/hit.mp3", import.meta.url).href
    );

    if (!response.ok) {
      throw new Error(`Failed to fetch sound: ${response.statusText}`);
    }

    const arrayBuffer = await response.arrayBuffer();
    hitSoundBuffer = await audioContext.decodeAudioData(arrayBuffer);

    console.log("碰撞音效加载完成");
  } catch (error) {
    console.error("音效加载失败:", error);
  }
};

// 定义碰撞参数的类型接口
interface Collision {
  contact: {
    getImpactVelocityAlongNormal: () => number;
  };
}

// 播放碰撞音效的优化版本
const playHitSound = (collision: Collision): void => {
  // 检查音效是否加载完成
  if (!audioContext || !hitSoundBuffer) return;

  // 计算碰撞强度（限制最大值，避免音量异常）
  /**
   * 作用：将碰撞强度（可能很大）压缩到 0~1 的范围，方便映射到音量等参数。
   * 原理：
   * impactStrength / 10：假设碰撞强度最大值可能达到 10，除以 10 后将其缩放到 0~1 范围。
   * Math.min(..., 1)：防止碰撞强度超过 10 时，结果大于 1（确保最大值为 1）。
   * 举例：若碰撞强度是 15，计算后为 15/10=1.5，再被 Math.min 限制为 1，避免音量过大。
   */
  const impactStrength = collision.contact.getImpactVelocityAlongNormal();
  const normalizedStrength = Math.min(impactStrength / 10, 1); // 归一化到0-1范围

  // 只播放足够强度的碰撞音效
  if (normalizedStrength < 0.15) return;

  try {
    // 创建新的音频源（支持同时播放多个音效）
    /**
     * BufferSource 作用：它是 “音频源节点”，用于播放 hitSoundBuffer 中的音频数据。
     * 为什么能多实例播放：
     * 每个 BufferSource 都是独立的播放实例，就像多个独立的 “播放器”。如果只用一个实例，再次播放时会中断上一次播放（比如连续碰撞时，后一次碰撞会打断前一次音效）。
     * 而创建新的 source 实例，就能同时播放多个音效（比如快速连续碰撞时，音效会叠加）。
     */
    const source = audioContext.createBufferSource();
    source.buffer = hitSoundBuffer;

    // 创建音量控制节点，根据碰撞强度调整音量
    /**
     * const gainNode = audioContext.createGain();
     * 作用：创建 “音量控制节点”，专门用于调整音频的音量（gain 意为 “增益”，即音量倍数）。
     * 如何控制音量：通过 gainNode.gain.value 设置，0 为静音，1 为原音量，大于 1 会放大（可能失真）。
     */
    const gainNode = audioContext.createGain();
    gainNode.gain.value = 0.3 + normalizedStrength * 0.7; // 音量范围0.3-1.0

    // 连接音频节点并播放
    /**
     * Web Audio API 的 “节点连接” 模型：音频处理像一条 “流水线”，数据从一个节点流向另一个节点，最终输出到扬声器。
     * source.connect(gainNode)：将音频源的输出连接到音量节点，让音频先经过音量调整。
     * gainNode.connect(...)：将音量节点的输出连接到 “最终目的地”（destination 代表扬声器 / 耳机）。
     * source.start(0)：启动音频源，从时间 0 开始播放（立即播放）。
     */
    source.connect(gainNode); // 1. 音频源 → 音量节点
    gainNode.connect(audioContext.destination); // 2. 音量节点 → 输出设备
    source.start(0); // 3. 开始播放
  } catch (error) {
    console.error("音效播放失败:", error);
  }
};

// 3. 初始化时预加载音效（建议在用户首次交互后调用，如点击事件）
document.addEventListener("click", loadHitSound, { once: true });
```

------



## Cannon.js 核心属性与方法速查表

### 一、世界（World）核心

物理世界是所有物理对象的容器，负责统一调度物理模拟、管理刚体与碰撞规则，是 Cannon.js 运行的基础环境。

| 属性 / 方法                                    | 作用                                                         | 示例                                                         |
| ---------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `new CANNON.World()`                           | 创建物理世界实例，初始化物理模拟上下文                       | `const world = new CANNON.World();`                          |
| `gravity`                                      | 设置全局重力加速度（`CANNON.Vec3` 类型），默认值为 `(0, -9.82, 0)`（模拟地球重力） | `world.gravity.set(0, -10, 0);`                              |
| `step(dt, timeSinceLastCalled?, maxSubSteps?)` | 推进物理模拟（核心方法，需在渲染循环中调用） - `dt`：固定时间步长（推荐 `1/60`，对应 60fps） - `timeSinceLastCalled`：距上次调用的实际时间（可选，用于补偿帧率波动） - `maxSubSteps`：最大子步数（可选，防止单次模拟时间过长导致卡顿） | `// 渲染循环中调用` `function update() {` `world.step(1/60);` `requestAnimationFrame(update);` `}` |
| `addBody(body)`                                | 向物理世界添加刚体（动态 / 静态物体）                        | `world.addBody(sphereBody);`                                 |
| `removeBody(body)`                             | 从物理世界移除刚体，释放资源                                 | `world.removeBody(obstacleBody);`                            |
| `addContactMaterial(cm)`                       | 添加两种材质的碰撞规则（`ContactMaterial` 实例），定义摩擦、反弹等交互特性 | `world.addContactMaterial(concretePlasticCM);`               |
| `defaultContactMaterial`                       | 设置全局默认碰撞材质，当两个刚体无匹配的 `ContactMaterial` 时生效 | `world.defaultContactMaterial = new CANNON.ContactMaterial(m1, m1, { friction: 0.3 });` |

### 二、刚体（Body）核心

代表物理世界中的可交互物体，分为动态刚体（`mass > 0`，受重力和力的影响）和静态刚体（`mass = 0`，固定不动，如地面）。

| 属性 / 方法                              | 作用                                                         | 示例                                                         |
| ---------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `new CANNON.Body(options)`               | 创建刚体实例，`options` 为配置对象 常用配置： - `mass`：质量（`0` 为静态） - `position`：初始位置（`CANNON.Vec3`） - `shape`：碰撞形状 - `material`：绑定的材质 | `const sphereBody = new CANNON.Body({` `mass: 1,` `position: new CANNON.Vec3(0, 5, 0),` `shape: new CANNON.Sphere(0.5),` `material: plasticMaterial` `});` |
| `mass`                                   | 刚体质量（数值类型），`0` 表示静态刚体，`>0` 表示动态刚体    | `floorBody.mass = 0; // 地面设为静态`                        |
| `position`                               | 刚体位置（`CANNON.Vec3` 类型），控制物体在世界中的坐标       | `sphereBody.position.set(2, 3, 1);`                          |
| `quaternion`                             | 刚体旋转（`CANNON.Quaternion` 类型），用于描述物体朝向，避免欧拉角万向锁问题 | `// 绕 X 轴旋转 90 度（弧度）` `floorBody.quaternion.setFromAxisAngle(` `new CANNON.Vec3(-1, 0, 0), Math.PI / 2` `);` |
| `velocity`                               | 线速度（`CANNON.Vec3` 类型），直接控制物体的平动速度         | `sphereBody.velocity.set(0, 2, 0); // 向上运动`              |
| `angularVelocity`                        | 角速度（`CANNON.Vec3` 类型），控制物体的旋转速度             | `sphereBody.angularVelocity.set(1, 0, 0); // 绕 X 轴旋转`    |
| `material`                               | 绑定的材质（`CANNON.Material` 实例），用于碰撞规则匹配       | `cubeBody.material = metalMaterial;`                         |
| `addShape(shape)`                        | 为刚体添加碰撞形状（单个刚体可添加多个形状，组合成复杂碰撞边界） | `// 为立方体添加盒子形状` `cubeBody.addShape(new CANNON.Box(new CANNON.Vec3(1,1,1)));` |
| `applyForce(force, worldPoint)`          | 施加持续力（世界坐标系） - `force`：力的大小和方向（`CANNON.Vec3`） - `worldPoint`：力的作用点（世界坐标，`CANNON.Vec3`） | `// 向球体质心施加向右的力` `sphereBody.applyForce(` `new CANNON.Vec3(5, 0, 0), sphereBody.position` `);` |
| `applyImpulse(impulse, worldPoint)`      | 施加瞬时冲量（世界坐标系），直接改变动量，适合模拟碰撞、撞击 | `// 给球体施加向右的瞬时冲量` `sphereBody.applyImpulse(` `new CANNON.Vec3(2, 0, 0), sphereBody.position` `);` |
| `applyLocalForce(force, localPoint)`     | 施加持续力（物体局部坐标系），力的方向随物体旋转同步变化     | `// 向球体自身前方施加力` `sphereBody.applyLocalForce(` `new CANNON.Vec3(0, 0, 3), new CANNON.Vec3(0, 0, 0.5)` `);` |
| `applyLocalImpulse(impulse, localPoint)` | 施加瞬时冲量（物体局部坐标系），冲量方向相对物体固定         | `// 从球体自身顶部施加向上冲量` `sphereBody.applyLocalImpulse(` `new CANNON.Vec3(0, 5, 0), new CANNON.Vec3(0, 0.5, 0)` `);` |

### 三、碰撞形状（Shape）

定义刚体的碰撞边界，决定碰撞检测的范围和精度，不同形状对应不同的物理模拟性能与适用场景。

| 形状类                                                       | 作用                                                         | 示例                                                         |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `CANNON.Sphere(radius)`                                      | 球体形状，适合圆形物体（如球、珠子），模拟效率最高           | `new CANNON.Sphere(0.5); // 半径 0.5 的球体`                 |
| `CANNON.Plane()`                                             | 无限大平面形状，适合地面、墙面等无限延伸的边界               | `new CANNON.Plane(); // 默认垂直平面，需旋转为水平`          |
| `CANNON.Box(halfExtents)`                                    | 立方体形状，适合方形物体（如箱子、砖块） - `halfExtents`：半边长向量（`CANNON.Vec3`），实际边长为该值的 2 倍 | `// 边长为 2x2x2 的立方体` `new CANNON.Box(new CANNON.Vec3(1, 1, 1));` |
| `CANNON.Cylinder(radiusTop, radiusBottom, height, segments?)` | 圆柱体形状，适合圆柱物体（如柱子、易拉罐） - `segments`：径向分段数（可选，默认 8，数值越高越接近圆形） | `// 顶面半径 0.3、底面半径 0.3、高 2 的圆柱体` `new CANNON.Cylinder(0.3, 0.3, 2);` |
| `CANNON.ConvexPolyhedron(vertices, faces)`                   | 凸多面体形状，适合自定义规则凸形物体（如金字塔、四面体） - `vertices`：顶点数组（`CANNON.Vec3[]`） - `faces`：面数组（每个面为顶点索引数组） | `// 正四面体（简化示例）` `const vertices = [new CANNON.Vec3(0,1,0), ...];` `const faces = [[0,1,2], [0,2,3], ...];` `new CANNON.ConvexPolyhedron(vertices, faces);` |

### 四、向量（Vec3）与四元数（Quaternion）

#### 4.1 Vec3（三维向量）

用于表示位置、方向、力、速度等三维物理量，是 Cannon.js 中最基础的数据结构之一。

| 方法                       | 作用                                          | 示例                                                         |
| -------------------------- | --------------------------------------------- | ------------------------------------------------------------ |
| `new CANNON.Vec3(x, y, z)` | 创建三维向量实例，`x/y/z` 为坐标分量          | `new CANNON.Vec3(0, 5, 0);`                                  |
| `set(x, y, z)`             | 设置向量的三个分量值                          | `const pos = new CANNON.Vec3(); pos.set(2, 3, 1);`           |
| `add(v)`                   | 与另一个向量相加（返回新向量，不修改原向量）  | `const v1 = new CANNON.Vec3(1,2,3);` `const v2 = new CANNON.Vec3(4,5,6);` `const v3 = v1.add(v2); // v3 = (5,7,9)` |
| `sub(v)`                   | 与另一个向量相减（返回新向量）                | `const v3 = v1.sub(v2); // v3 = (-3,-3,-3)`                  |
| `multiplyScalar(s)`        | 向量与标量相乘（放大 / 缩小向量，返回新向量） | `const v2 = v1.multiplyScalar(2); // v2 = (2,4,6)`           |
| `copy(v)`                  | 复制另一个向量的分量值到当前向量              | `const v2 = new CANNON.Vec3(); v2.copy(v1);`                 |

#### 4.2 Quaternion（四元数）

用于精确描述物体的三维旋转，避免欧拉角的 “万向锁” 问题，是 Cannon.js 中旋转表示的标准方式。

| 方法                                | 作用                                                         | 示例                                                         |
| ----------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `new CANNON.Quaternion(x, y, z, w)` | 创建四元数实例（`x/y/z/w` 为四元数分量，一般不直接手动设置） | `new CANNON.Quaternion(0, 0, 0, 1); // 初始无旋转`           |
| `setFromAxisAngle(axis, angle)`     | 从 “旋转轴 + 角度” 创建四元数 - `axis`：旋转轴（`CANNON.Vec3`） - `angle`：旋转角度（弧度） | `// 绕 Y 轴旋转 45 度` `new CANNON.Quaternion().setFromAxisAngle(` `new CANNON.Vec3(0,1,0), Math.PI/4` `);` |
| `setFromEuler(x, y, z)`             | 从欧拉角创建四元数（绕 X/Y/Z 轴的旋转角度，弧度）            | `// 绕 X 轴 30 度，绕 Y 轴 60 度` `quat.setFromEuler(Math.PI/6, Math.PI/3, 0);` |
| `copy(q)`                           | 复制另一个四元数的分量值                                     | `const q2 = new CANNON.Quaternion(); q2.copy(q1);`           |

### 五、材质与碰撞规则

控制物体碰撞时的物理特性（摩擦、反弹），通过 “材质定义 + 碰撞规则匹配” 实现差异化交互。

| 类 / 属性 / 方法                              | 作用                                                         | 示例                                                         |
| --------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `new CANNON.Material(name)`                   | 创建材质实例，`name` 为标识名称（仅用于调试和区分）          | `const concreteMaterial = new CANNON.Material("concrete");`  |
| `new CANNON.ContactMaterial(m1, m2, options)` | 定义两种材质的碰撞规则 - `m1/m2`：参与碰撞的两种材质 - `options`：配置对象，包含 `friction`（摩擦系数）和 `restitution`（反弹系数） | `const concretePlasticCM = new CANNON.ContactMaterial(` `concreteMaterial, plasticMaterial,` `{ friction: 0.1, restitution: 0.7 }` `);` |
| `friction`                                    | 摩擦系数（数值类型，范围 `0~1`） - `0`：无摩擦（物体滑动无阻力） - `1`：高摩擦（物体易静止） | `{ friction: 0.3 } // 中等摩擦`                              |
| `restitution`                                 | 反弹系数（数值类型，范围 `0~1`） - `0`：完全非弹性（碰撞后不反弹） - `1`：完全弹性（碰撞后反弹高度与原高度一致） | `{ restitution: 0.5 } // 中等反弹`                           |

### 六、碰撞事件

监听刚体的碰撞行为，用于触发音效、特效、逻辑判断等交互反馈。

| 事件 / 属性                                  | 作用                                                     | 示例                                                         |
| -------------------------------------------- | -------------------------------------------------------- | ------------------------------------------------------------ |
| `body.addEventListener('collide', callback)` | 为刚体添加碰撞事件监听器，碰撞发生时触发 `callback`      | `sphereBody.addEventListener('collide', handleCollision);`   |
| `event.contact`                              | 碰撞事件对象中的 “接触信息”，包含碰撞点、强度等数据      | `// 获取碰撞强度` `const impact = event.contact.getImpactVelocityAlongNormal();` |
| `event.other`                                | 碰撞事件对象中的 “另一刚体”，即与当前刚体碰撞的物体      | `// 检测是否与地面碰撞` `if (event.other === floorBody) { ... }` |
| `contact.getImpactVelocityAlongNormal()`     | 获取碰撞强度（沿法线方向的冲击速度），数值越大碰撞越剧烈 | `// 碰撞强度大于 1.5 时触发音效` `if (event.contact.getImpactVelocityAlongNormal() > 1.5) {` `playHitSound();` `}` |

### 七、基础示例：完整物理模拟流程

```javascript
// 1. 创建物理世界
const world = new CANNON.World();
world.gravity.set(0, -9.82, 0); // 设置重力

// 2. 定义材质与碰撞规则
const defaultMaterial = new CANNON.Material("default");
const defaultCM = new CANNON.ContactMaterial(
  defaultMaterial, defaultMaterial,
  { friction: 0.1, restitution: 0.7 }
);
world.addContactMaterial(defaultCM);
world.defaultContactMaterial = defaultCM;

// 3. 创建地面（静态刚体）
const floorBody = new CANNON.Body({ mass: 0, material: defaultMaterial });
floorBody.addShape(new CANNON.Plane());
floorBody.quaternion.setFromAxisAngle(new CANNON.Vec3(-1, 0, 0), Math.PI / 2);
world.addBody(floorBody);

// 4. 创建球体（动态刚体）
const sphereBody = new CANNON.Body({
  mass: 1,
  position: new CANNON.Vec3(0, 5, 0),
  shape: new CANNON.Sphere(0.5),
  material: defaultMaterial
});
world.addBody(sphereBody);

// 5. 监听碰撞事件
sphereBody.addEventListener('collide', (event) => {
  const impact = event.contact.getImpactVelocityAlongNormal();
  if (impact > 1.5) console.log("碰撞强度:", impact);
});

// 6. 渲染循环（同步物理与渲染）
function update() {
  world.step(1/60); // 推进物理模拟
  // 同步 Three.js 网格位置（示例）
  // mesh.position.copy(new THREE.Vector3(sphereBody.position.x, ...));
  requestAnimationFrame(update);
}
update();
```

------





## glTF四种格式区别详解

### 1. 四种格式的关键区别

| 特性维度            | glTF (通常指 glTF 2.0)                                       | glTF-Binary (GLB)                                            | glTF-Draco                                                   | glTF-Embedded                                                |
| ------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **文件结构**        | 多文件（.gltf + 外部资源）                                   | 单文件（.glb）                                               | 多文件 / 单文件（依赖基础格式）                              | 单文件（.gltf）                                              |
| **核心文件后缀**    | .gltf                                                        | .glb                                                         | .gltf / .glb                                                 | .gltf                                                        |
| **资源存储方式**    | 外部引用：二进制数据（顶点、纹理等）单独存储为.bin、.png 等文件，.gltf（JSON 格式）记录引用路径 | 内部集成：所有数据（JSON 结构、二进制资源、纹理）打包成一个二进制文件 | 基于 glTF/GLB，对**几何数据**（顶点、索引）进行 Draco 算法压缩 | 外部资源（纹理、二进制数据）编码为 Base64 字符串，嵌入到.gltf 的 JSON 中 |
| **体积大小**        | 中等（无压缩，仅拆分文件）                                   | 与原始 glTF 相近（仅打包，无压缩）                           | 最小（几何数据压缩率 30%-90%）                               | 最大（Base64 编码会增加 20%-30% 体积）                       |
| **加载效率**        | 中等：需多次 HTTP 请求（加载.gltf + 多个外部资源）           | 高：单次 HTTP 请求即可加载所有资源                           | 较高：体积小→传输快，但需客户端解码 Draco 数据（消耗 CPU）   | 低：体积大→传输慢，且 Base64 解码消耗 CPU                    |
| **易用性 / 兼容性** | 高：JSON 可读，便于编辑和调试，支持所有 glTF 特性            | 高：主流引擎（Three.js、Unity）均支持，适合分发              | 中等：需引擎集成 Draco 解码器（如 Three.js 需加载 Draco 库） | 高：无需处理外部资源路径，适合快速测试 / 嵌入网页            |
| **典型使用场景**    | 开发阶段（便于调试资源引用）、需要单独更新纹理 / 动画的场景  | 生产环境分发（避免资源路径错误）、游戏 / AR/VR 的独立资产    | 大规模 3D 场景（如城市模型、点云）、移动端 / 网页端（带宽有限） | 快速原型验证、嵌入文档 / 网页（无需额外资源文件）            |

### 2. 各格式的详细解析

#### （1）glTF（基础文本格式）

- **本质**：纯文本的 JSON 文件（.gltf），仅存储 3D 资产的 “元数据” 和 “资源引用”，不包含实际的几何、纹理等二进制数据。
- 配套文件：
  - `.bin`：二进制文件，存储顶点坐标、索引、动画关键帧等海量数据（避免 JSON 存储二进制的低效）；
  - 纹理文件：.png、.jpg 等，存储模型的材质贴图。
- **优点**：JSON 结构可读可编辑（直接用文本编辑器修改资源路径、材质参数），调试方便；资源可单独替换（如换纹理无需重新生成整个模型）。
- **缺点**：加载时需发起多次 HTTP 请求（.gltf + .bin + 纹理），可能导致网络延迟；依赖正确的文件路径，易出现 “资源缺失” 问题。

#### （2）glTF-Binary（GLB，二进制打包格式）

- **本质**：glTF 的 “单文件封装版”，将`.gltf`（JSON）、`.bin`（二进制）、纹理等**所有资源打包成一个二进制文件（.glb）**。
- **内部结构**：采用固定的二进制布局，包含 “文件头”“JSON 块”“二进制数据块”“纹理块” 等，确保引擎能快速解析各部分内容。
- 优点：
  - 分发便捷：仅需传输一个文件，避免 “多文件路径错误”；
  - 加载高效：单次 HTTP 请求即可获取所有资源，适合生产环境（如网页 3D、AR 应用）。
- **缺点**：二进制文件不可读，调试需专用工具（如[glTF Viewer](https://gltf-viewer.donmccurdy.com/)）；无法单独更新内部资源（如换纹理需重新打包整个 GLB）。

#### （3）glTF-Draco（Draco 压缩格式）

- **本质**：在 glTF/GLB 基础上，对**几何数据（顶点、索引）** 应用**Draco 压缩算法**（Khronos Group 开源的几何压缩库）的变体。
- **核心优化**：通过量化（减少坐标精度）、预测编码（推导顶点关系）等方式，大幅压缩几何数据体积（例如 100MB 的点云模型可压缩至 10MB 以内）。
- 文件形式：
  - 可基于多文件 glTF：.gltf + 压缩后的.bin（含 Draco 数据） + 纹理；
  - 可基于 GLB：压缩后的单文件.glb（内部集成 Draco 数据）。
- **优点**：体积极小，显著降低传输带宽和存储成本，是大规模 3D 场景（如数字孪生、城市建模）的首选。
- 缺点：
  - 需 “解码成本”：客户端加载时必须集成 Draco 解码器（如 Three.js 需额外引入`draco_decoder.js`），消耗 CPU 资源；
  - 仅压缩几何数据：纹理、动画等其他资源需单独优化（如纹理压缩为 Basis Universal 格式）。

#### （4）glTF-Embedded（嵌入式格式）

- **本质**：将所有外部资源（.bin、纹理）编码为**Base64 字符串**，直接嵌入到.gltf 的 JSON 文件中，形成一个独立的文本文件。
- **实现方式**：在.gltf 的`buffers`（二进制数据）或`images`（纹理）字段中，用`data:URI`格式存储 Base64 编码后的资源（例如`data:application/octet-stream;base64,AAABAA...`）。
- **优点**：彻底消除外部资源依赖，可直接嵌入 HTML、JSON 配置文件中，适合快速演示、原型验证或简单场景（如小图标、低多边形模型）。
- 缺点：
  - 体积膨胀：Base64 编码会使原始二进制数据体积增加约 33%；
  - 加载低效：解码 Base64 字符串比直接读取二进制文件更消耗 CPU，且 JSON 解析速度慢于二进制解析。

------



# dat.GUI API

Details about the classes, methods, and properties provided by dat.GUI. For more
hands-on examples, see the dat.GUI [tutorial](http://workshop.chromeexperiments.com/examples/gui).

<!--- API BEGIN --->

## Classes

<dl>
<dt><a href="#GUI">GUI</a></dt>
<dd><p>A lightweight controller library for JavaScript. It allows you to easily
manipulate variables and fire functions on the fly.</p>
</dd>
<dt><a href="#Controller">Controller</a></dt>
<dd><p>An &quot;abstract&quot; class that represents a given property of an object.</p>
</dd>
<dt><a href="#NumberController">NumberController</a> ⇐ <code>dat.controllers.Controller</code></dt>
<dd><p>Represents a given property of an object that is a number.</p>
</dd>
</dl>


<a name="GUI"></a>

## GUI

A lightweight controller library for JavaScript. It allows you to easily
manipulate variables and fire functions on the fly.

**Kind**: global class  

* [GUI](#GUI)
  * [new GUI([params])](#new_GUI_new)
  * [.domElement](#GUI+domElement) : <code>DOMElement</code>
  * [.parent](#GUI+parent) : <code>dat.gui.GUI</code>
  * [.autoPlace](#GUI+autoPlace) : <code>Boolean</code>
  * [.closeOnTop](#GUI+closeOnTop) : <code>Boolean</code>
  * [.preset](#GUI+preset) : <code>String</code>
  * [.width](#GUI+width) : <code>Number</code>
  * [.name](#GUI+name) : <code>String</code>
  * [.closed](#GUI+closed) : <code>Boolean</code>
  * [.load](#GUI+load) : <code>Object</code>
  * [.useLocalStorage](#GUI+useLocalStorage) : <code>Boolean</code>
  * [.add(object, property, [min], [max], [step])](#GUI+add) ⇒ [<code>Controller</code>](#Controller)
  * [.addColor(object, property)](#GUI+addColor) ⇒ [<code>Controller</code>](#Controller)
  * [.remove(controller)](#GUI+remove)
  * [.destroy()](#GUI+destroy)
  * [.addFolder(name)](#GUI+addFolder) ⇒ <code>dat.gui.GUI</code>
  * [.removeFolder(folder)](#GUI+removeFolder)
  * [.open()](#GUI+open)
  * [.close()](#GUI+close)
  * [.hide()](#GUI+hide)
  * [.show()](#GUI+show)
  * [.getRoot()](#GUI+getRoot) ⇒ <code>dat.gui.GUI</code>
  * [.getSaveObject()](#GUI+getSaveObject) ⇒ <code>Object</code>

<a name="new_GUI_new"></a>

### new GUI([params])

| Param               | Type                     | Default            | Description                                            |
| ------------------- | ------------------------ | ------------------ | ------------------------------------------------------ |
| [params]            | <code>Object</code>      |                    |                                                        |
| [params.name]       | <code>String</code>      |                    | The name of this GUI.                                  |
| [params.load]       | <code>Object</code>      |                    | JSON object representing the saved state of this GUI.  |
| [params.parent]     | <code>dat.gui.GUI</code> |                    | The GUI I'm nested in.                                 |
| [params.autoPlace]  | <code>Boolean</code>     | <code>true</code>  |                                                        |
| [params.hideable]   | <code>Boolean</code>     | <code>true</code>  | If true, GUI is shown/hidden by <kbd>h</kbd> keypress. |
| [params.closed]     | <code>Boolean</code>     | <code>false</code> | If true, starts closed                                 |
| [params.closeOnTop] | <code>Boolean</code>     | <code>false</code> | If true, close/open button shows on top of the GUI     |

**Example**  

```js
// Creating a GUI with options.
var gui = new dat.GUI({name: 'My GUI'});
```

**Example**  

```js
// Creating a GUI and a subfolder.
var gui = new dat.GUI();
var folder1 = gui.addFolder('Flow Field');
```

<a name="GUI+domElement"></a>

### gui.domElement : <code>DOMElement</code>

Outermost DOM Element

**Kind**: instance property of [<code>GUI</code>](#GUI)  
<a name="GUI+parent"></a>

### gui.parent : <code>dat.gui.GUI</code>

The parent <code>GUI</code>

**Kind**: instance property of [<code>GUI</code>](#GUI)  
<a name="GUI+autoPlace"></a>

### gui.autoPlace : <code>Boolean</code>

Handles <code>GUI</code>'s element placement for you

**Kind**: instance property of [<code>GUI</code>](#GUI)  
<a name="GUI+closeOnTop"></a>

### gui.closeOnTop : <code>Boolean</code>

Handles <code>GUI</code>'s position of open/close button

**Kind**: instance property of [<code>GUI</code>](#GUI)  
<a name="GUI+preset"></a>

### gui.preset : <code>String</code>

The identifier for a set of saved values

**Kind**: instance property of [<code>GUI</code>](#GUI)  
<a name="GUI+width"></a>

### gui.width : <code>Number</code>

The width of <code>GUI</code> element

**Kind**: instance property of [<code>GUI</code>](#GUI)  
<a name="GUI+name"></a>

### gui.name : <code>String</code>

The name of <code>GUI</code>. Used for folders. i.e
a folder's name

**Kind**: instance property of [<code>GUI</code>](#GUI)  
<a name="GUI+closed"></a>

### gui.closed : <code>Boolean</code>

Whether the <code>GUI</code> is collapsed or not

**Kind**: instance property of [<code>GUI</code>](#GUI)  
<a name="GUI+load"></a>

### gui.load : <code>Object</code>

Contains all presets

**Kind**: instance property of [<code>GUI</code>](#GUI)  
<a name="GUI+useLocalStorage"></a>

### gui.useLocalStorage : <code>Boolean</code>

Determines whether or not to use <a href="https://developer.mozilla.org/en/DOM/Storage#localStorage">localStorage</a> as the means for
<code>remember</code>ing

**Kind**: instance property of [<code>GUI</code>](#GUI)  
<a name="GUI+add"></a>

### gui.add(object, property, [min], [max], [step]) ⇒ [<code>Controller</code>](#Controller)

Adds a new [Controller](#Controller) to the GUI. The type of controller created
is inferred from the initial value of <code>object[property]</code>. For
color properties, see [addColor](addColor).

**Kind**: instance method of [<code>GUI</code>](#GUI)  
**Returns**: [<code>Controller</code>](#Controller) - The controller that was added to the GUI.  

| Param    | Type                | Description                                |
| -------- | ------------------- | ------------------------------------------ |
| object   | <code>Object</code> | The object to be manipulated               |
| property | <code>String</code> | The name of the property to be manipulated |
| [min]    | <code>Number</code> | Minimum allowed value                      |
| [max]    | <code>Number</code> | Maximum allowed value                      |
| [step]   | <code>Number</code> | Increment by which to change value         |

**Example**  

```js
// Add a string controller.
var person = {name: 'Sam'};
gui.add(person, 'name');
```

**Example**  

```js
// Add a number controller slider.
var person = {age: 45};
gui.add(person, 'age', 0, 100);
```

<a name="GUI+addColor"></a>

### gui.addColor(object, property) ⇒ [<code>Controller</code>](#Controller)

Adds a new color controller to the GUI.

**Kind**: instance method of [<code>GUI</code>](#GUI)  
**Returns**: [<code>Controller</code>](#Controller) - The controller that was added to the GUI.  

| Param    |
| -------- |
| object   |
| property |

**Example**  

```js
var palette = {
  color1: '#FF0000', // CSS string
  color2: [ 0, 128, 255 ], // RGB array
  color3: [ 0, 128, 255, 0.3 ], // RGB with alpha
  color4: { h: 350, s: 0.9, v: 0.3 } // Hue, saturation, value
};
gui.addColor(palette, 'color1');
gui.addColor(palette, 'color2');
gui.addColor(palette, 'color3');
gui.addColor(palette, 'color4');
```

<a name="GUI+remove"></a>

### gui.remove(controller)

Removes the given controller from the GUI.

**Kind**: instance method of [<code>GUI</code>](#GUI)  

| Param      | Type                                   |
| ---------- | -------------------------------------- |
| controller | [<code>Controller</code>](#Controller) |

<a name="GUI+destroy"></a>

### gui.destroy()

Removes the root GUI from the document and unbinds all event listeners.
For subfolders, use `gui.removeFolder(folder)` instead.

**Kind**: instance method of [<code>GUI</code>](#GUI)  
<a name="GUI+addFolder"></a>

### gui.addFolder(name) ⇒ <code>dat.gui.GUI</code>

Creates a new subfolder GUI instance.

**Kind**: instance method of [<code>GUI</code>](#GUI)  
**Returns**: <code>dat.gui.GUI</code> - The new folder.  
**Throws**:

- <code>Error</code> if this GUI already has a folder by the specified
  name


| Param |
| ----- |
| name  |

<a name="GUI+removeFolder"></a>

### gui.removeFolder(folder)

Removes a subfolder GUI instance.

**Kind**: instance method of [<code>GUI</code>](#GUI)  

| Param  | Type                     | Description           |
| ------ | ------------------------ | --------------------- |
| folder | <code>dat.gui.GUI</code> | The folder to remove. |

<a name="GUI+open"></a>

### gui.open()

Opens the GUI.

**Kind**: instance method of [<code>GUI</code>](#GUI)  
<a name="GUI+close"></a>

### gui.close()

Closes the GUI.

**Kind**: instance method of [<code>GUI</code>](#GUI)  
<a name="GUI+hide"></a>

### gui.hide()

Hides the GUI.

**Kind**: instance method of [<code>GUI</code>](#GUI)  
<a name="GUI+show"></a>

### gui.show()

Shows the GUI.

**Kind**: instance method of [<code>GUI</code>](#GUI)  
<a name="GUI+getRoot"></a>

### gui.getRoot() ⇒ <code>dat.gui.GUI</code>

**Kind**: instance method of [<code>GUI</code>](#GUI)  
**Returns**: <code>dat.gui.GUI</code> - the topmost parent GUI of a nested GUI.  
<a name="GUI+getSaveObject"></a>

### gui.getSaveObject() ⇒ <code>Object</code>

**Kind**: instance method of [<code>GUI</code>](#GUI)  
**Returns**: <code>Object</code> - a JSON object representing the current state of
this GUI as well as its remembered properties.  
<a name="Controller"></a>

## Controller

An "abstract" class that represents a given property of an object.

**Kind**: global class  

* [Controller](#Controller)
  * [new Controller(object, property)](#new_Controller_new)
  * [.domElement](#Controller+domElement) : <code>DOMElement</code>
  * [.object](#Controller+object) : <code>Object</code>
  * [.property](#Controller+property) : <code>String</code>
  * [.options(options)](#Controller+options) ⇒ [<code>Controller</code>](#Controller)
  * [.name(name)](#Controller+name) ⇒ [<code>Controller</code>](#Controller)
  * [.listen()](#Controller+listen) ⇒ [<code>Controller</code>](#Controller)
  * [.remove()](#Controller+remove) ⇒ [<code>Controller</code>](#Controller)
  * [.onChange(fnc)](#Controller+onChange) ⇒ [<code>Controller</code>](#Controller)
  * [.onFinishChange(fnc)](#Controller+onFinishChange) ⇒ [<code>Controller</code>](#Controller)
  * [.setValue(newValue)](#Controller+setValue)
  * [.getValue()](#Controller+getValue) ⇒ <code>Object</code>
  * [.updateDisplay()](#Controller+updateDisplay) ⇒ [<code>Controller</code>](#Controller)
  * [.isModified()](#Controller+isModified) ⇒ <code>Boolean</code>

<a name="new_Controller_new"></a>

### new Controller(object, property)

| Param    | Type                | Description                                |
| -------- | ------------------- | ------------------------------------------ |
| object   | <code>Object</code> | The object to be manipulated               |
| property | <code>string</code> | The name of the property to be manipulated |

<a name="Controller+domElement"></a>

### controller.domElement : <code>DOMElement</code>

Those who extend this class will put their DOM elements in here.

**Kind**: instance property of [<code>Controller</code>](#Controller)  
<a name="Controller+object"></a>

### controller.object : <code>Object</code>

The object to manipulate

**Kind**: instance property of [<code>Controller</code>](#Controller)  
<a name="Controller+property"></a>

### controller.property : <code>String</code>

The name of the property to manipulate

**Kind**: instance property of [<code>Controller</code>](#Controller)  
<a name="Controller+options"></a>

### controller.options(options) ⇒ [<code>Controller</code>](#Controller)

**Kind**: instance method of [<code>Controller</code>](#Controller)  

| Param   | Type                                      |
| ------- | ----------------------------------------- |
| options | <code>Array</code> \| <code>Object</code> |

<a name="Controller+name"></a>

### controller.name(name) ⇒ [<code>Controller</code>](#Controller)

Sets the name of the controller.

**Kind**: instance method of [<code>Controller</code>](#Controller)  

| Param | Type                |
| ----- | ------------------- |
| name  | <code>string</code> |

<a name="Controller+listen"></a>

### controller.listen() ⇒ [<code>Controller</code>](#Controller)

Sets controller to listen for changes on its underlying object.

**Kind**: instance method of [<code>Controller</code>](#Controller)  
<a name="Controller+remove"></a>

### controller.remove() ⇒ [<code>Controller</code>](#Controller)

Removes the controller from its parent GUI.

**Kind**: instance method of [<code>Controller</code>](#Controller)  
<a name="Controller+onChange"></a>

### controller.onChange(fnc) ⇒ [<code>Controller</code>](#Controller)

Specify that a function fire every time someone changes the value with
this Controller.

**Kind**: instance method of [<code>Controller</code>](#Controller)  
**Returns**: [<code>Controller</code>](#Controller) - this  

| Param | Type                  | Description                                                  |
| ----- | --------------------- | ------------------------------------------------------------ |
| fnc   | <code>function</code> | This function will be called whenever the value is modified via this Controller. |

<a name="Controller+onFinishChange"></a>

### controller.onFinishChange(fnc) ⇒ [<code>Controller</code>](#Controller)

Specify that a function fire every time someone "finishes" changing
the value wih this Controller. Useful for values that change
incrementally like numbers or strings.

**Kind**: instance method of [<code>Controller</code>](#Controller)  
**Returns**: [<code>Controller</code>](#Controller) - this  

| Param | Type                  | Description                                                  |
| ----- | --------------------- | ------------------------------------------------------------ |
| fnc   | <code>function</code> | This function will be called whenever someone "finishes" changing the value via this Controller. |

<a name="Controller+setValue"></a>

### controller.setValue(newValue)

Change the value of <code>object[property]</code>

**Kind**: instance method of [<code>Controller</code>](#Controller)  

| Param    | Type                | Description                                    |
| -------- | ------------------- | ---------------------------------------------- |
| newValue | <code>Object</code> | The new value of <code>object[property]</code> |

<a name="Controller+getValue"></a>

### controller.getValue() ⇒ <code>Object</code>

Gets the value of <code>object[property]</code>

**Kind**: instance method of [<code>Controller</code>](#Controller)  
**Returns**: <code>Object</code> - The current value of <code>object[property]</code>  
<a name="Controller+updateDisplay"></a>

### controller.updateDisplay() ⇒ [<code>Controller</code>](#Controller)

Refreshes the visual display of a Controller in order to keep sync
with the object's current value.

**Kind**: instance method of [<code>Controller</code>](#Controller)  
**Returns**: [<code>Controller</code>](#Controller) - this  
<a name="Controller+isModified"></a>

### controller.isModified() ⇒ <code>Boolean</code>

**Kind**: instance method of [<code>Controller</code>](#Controller)  
**Returns**: <code>Boolean</code> - true if the value has deviated from initialValue  
<a name="NumberController"></a>

## NumberController ⇐ <code>dat.controllers.Controller</code>

Represents a given property of an object that is a number.

**Kind**: global class  
**Extends**: <code>dat.controllers.Controller</code>  

* [NumberController](#NumberController) ⇐ <code>dat.controllers.Controller</code>
  * [new NumberController(object, property, [params])](#new_NumberController_new)
  * [.min(minValue)](#NumberController+min) ⇒ <code>dat.controllers.NumberController</code>
  * [.max(maxValue)](#NumberController+max) ⇒ <code>dat.controllers.NumberController</code>
  * [.step(stepValue)](#NumberController+step) ⇒ <code>dat.controllers.NumberController</code>

<a name="new_NumberController_new"></a>

### new NumberController(object, property, [params])

| Param         | Type                | Description                                |
| ------------- | ------------------- | ------------------------------------------ |
| object        | <code>Object</code> | The object to be manipulated               |
| property      | <code>string</code> | The name of the property to be manipulated |
| [params]      | <code>Object</code> | Optional parameters                        |
| [params.min]  | <code>Number</code> | Minimum allowed value                      |
| [params.max]  | <code>Number</code> | Maximum allowed value                      |
| [params.step] | <code>Number</code> | Increment by which to change value         |

<a name="NumberController+min"></a>

### numberController.min(minValue) ⇒ <code>dat.controllers.NumberController</code>

Specify a minimum value for <code>object[property]</code>.

**Kind**: instance method of [<code>NumberController</code>](#NumberController)  
**Returns**: <code>dat.controllers.NumberController</code> - this  

| Param    | Type                | Description                                         |
| -------- | ------------------- | --------------------------------------------------- |
| minValue | <code>Number</code> | The minimum value for <code>object[property]</code> |

<a name="NumberController+max"></a>

### numberController.max(maxValue) ⇒ <code>dat.controllers.NumberController</code>

Specify a maximum value for <code>object[property]</code>.

**Kind**: instance method of [<code>NumberController</code>](#NumberController)  
**Returns**: <code>dat.controllers.NumberController</code> - this  

| Param    | Type                | Description                                         |
| -------- | ------------------- | --------------------------------------------------- |
| maxValue | <code>Number</code> | The maximum value for <code>object[property]</code> |

<a name="NumberController+step"></a>

### numberController.step(stepValue) ⇒ <code>dat.controllers.NumberController</code>

Specify a step value that dat.controllers.NumberController
increments by.

**Kind**: instance method of [<code>NumberController</code>](#NumberController)  
**Default**: <code>if minimum and maximum specified increment is 1% of the
difference otherwise stepValue is 1</code>  
**Returns**: <code>dat.controllers.NumberController</code> - this  

| Param     | Type                | Description                                         |
| --------- | ------------------- | --------------------------------------------------- |
| stepValue | <code>Number</code> | The step value for dat.controllers.NumberController |

<!--- API END --->
