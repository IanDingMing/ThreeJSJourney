

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

物理引擎

Ammo.js

Cannon.js

Oimo.js

1. **cannon.js**
   - 轻量级的 3D 物理引擎，API 设计简洁直观
   - 支持常见的物理效果：碰撞检测、刚体动力学、关节约束等
   - 性能适中，适合中小型 3D 项目使用
   - 社区活跃，文档相对完善
2. **ammo.js**
   - 是 Bullet 物理引擎的 JavaScript 移植版本（通过 Emscripten 编译）
   - 功能最强大，支持复杂的物理效果：软刚体、布料模拟、车辆物理等
   - 性能优异，适合对物理效果要求高的项目
   - 但体积较大，API 相对复杂
   - 通常与 Three.js 等 3D 库配合使用，实现高质量的物理模拟
3. **oimo.js**
   - 轻量级物理引擎，兼顾 2D 和 3D 物理模拟
   - 体积小巧，性能优秀，适合对文件大小有严格要求的项目
   - API 设计简洁，易于上手
   - 功能相对前两者较少，适合简单的物理模拟场景

# 附录

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
