

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
```vue
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


```vue
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

```vue
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

1. MeshBasicMaterial (基础材质)



2. MeshNormalMaterial (法线材质)





### 材质使用示例代码

```typescript
// 1. MeshBasicMaterial (基础材质)
material = new THREE.MeshBasicMaterial({
  map: doorColorTextures, // 颜色贴图
  color: new THREE.Color(0xff0000), // 直接设置颜色
  wireframe: true, // 线框模式
  side: THREE.DoubleSide, // 双面渲染
  transparent: true, // 开启透明度
  opacity: 0.5, // 透明度值
  alphaMap: doorAlphaTextures // 透明贴图(需配合transparent)
});

// 2. MeshNormalMaterial (法线材质)
material = new THREE.MeshNormalMaterial({
  flatShading: true // 平面着色(棱角分明)
});

// 3. MeshMatcapMaterial (Matcap材质)
material = new THREE.MeshMatcapMaterial({
  matcap: matcapTextures // 预渲染的环境贴图
});

// 4. MeshDepthMaterial (深度材质)
material = new THREE.MeshDepthMaterial(); // 常用于雾效/景深

// 5. MeshLambertMaterial (朗伯材质-漫反射)
material = new THREE.MeshLambertMaterial({
  color: 0x00ff00 // 适合非金属物体
});

// 6. MeshPhongMaterial (Phong材质-高光)
material = new THREE.MeshPhongMaterial({
  shininess: 100, // 光泽度 (0-100)
  specular: new THREE.Color(0xff0000) // 高光颜色
});

// 7. MeshToonMaterial (卡通材质)
material = new THREE.MeshToonMaterial({
  gradientMap: gradientTextures // 渐变贴图
});

// 8. MeshStandardMaterial (PBR标准材质)
material = new THREE.MeshStandardMaterial({
  metalness: 0.7, // 金属度 (0-1)
  roughness: 0.2, // 粗糙度 (0-1)
  map: doorColorTextures, // 颜色贴图
  aoMap: doorAmbientOcclusionTextures, // 环境光遮蔽贴图
  aoMapIntensity: 1, // AO强度
  displacementMap: doorHeightTextures, // 位移贴图
  displacementScale: 0.1, // 位移强度
  metalnessMap: doorMetalnessTextures, // 金属贴图
  roughnessMap: doorRoughnessTextures, // 粗糙贴图
  normalMap: doorNormalTextures, // 法线贴图
  normalScale: new THREE.Vector2(0.5, 0.5), // 法线强度
  envMap: environmentMapTexture // 环境反射贴图
});
```

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

  - .[aoMap](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/MeshBasicMaterial.aoMap) : [Texture](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/textures/Texture)

    该纹理的红色通道用作环境遮挡贴图。默认值为null。aoMap需要第二组UV。

  - .[map](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/MeshBasicMaterial.map) : [Texture](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/textures/Texture)

    颜色贴图。可以选择包括一个alpha通道，通常与[.transparent](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/Material.transparent) 或[.alphaTest](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/Material.alphaTest)。默认为null。


***map就是贴上一个图，alphaMap相当于设计时产生的另一个配套的图，用来裁剪map中的多余部分***

```vue
material = new THREE.MeshBasicMaterial();
material.map = doorColorTextures;// 颜色贴图
material.alphaMap = doorAlphaTextures; //设置透明贴图,使用时必须开启透明度

const planeGeometry = new THREE.PlaneGeometry(1, 1, 100, 100);
const plane = new THREE.Mesh(planeGeometry, material);
plane.geometry.setAttribute(
  "uv2",
  new THREE.BufferAttribute(planeGeometry.attributes.uv.array, 2)
); //设置uv2属性，用于环境光遮蔽贴图
```

### 3. MeshNormalMaterial (法线材质)

***相当于贴图自带高度属性***

- **不受光照影响**
- **关键属性**：`flatShading`（平面着色，***即是否更顺滑而不是马赛克***）

```vue
material = new THREE.MeshNormalMaterial(); //法线网格材质
material.flatShading = true; //定义材质是否使用平面着色进行渲染。默认值为false。
```

### 4. MeshMatcapMaterial (Matcap材质)

***matcap网格材质，模拟光照材质，即不需要光照就有真实的材质效果***

- **不受光照影响**
- **关键属性**：`matcap`（环境光照贴图）

```vue
material = new THREE.MeshMatcapMaterial(); 
material.matcap = matcapTextures; //设置matcap贴图
```

### 5. MeshDepthMaterial (深度材质)

***深度网格材质，最直接的例子模拟雾气***

- **不受光照影响**

```vue
material = new THREE.MeshDepthMaterial();
```

### 6. MeshLambertMaterial (朗伯材质)

***一种非光泽表面的材质，没有镜面高光。***

***该材质使用基于非物理的[Lambertian](https://en.wikipedia.org/wiki/Lambertian_reflectance)模型来计算反射率。 这可以很好地模拟一些表面（例如未经处理的木材或石材），但不能模拟具有镜面高光的光泽表面（例如涂漆木材）***

- **受光照影响**
- **关键属性**：`emissive`（自发光颜色）

```vue
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


```vue
material = new THREE.MeshPhongMaterial(); //Phong网格材质，金属材质，受光照影响
material.shininess = 100; //设置材质的光泽度
material.specular = new THREE.Color(0xff0000); //设置材质的高光颜色
```

### 8. MeshToonMaterial (卡通材质)
- **受光照影响**

- **关键属性**：`gradientMap`（渐变贴图）

  - .[gradientMap](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/materials/MeshToonMaterial.gradientMap) : [Texture](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/textures/Texture)

    卡通着色的渐变贴图。使用此类纹理时，需要将Texture.minFilter[Texture.minFilter](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/textures/Texture.minFilter)和Texture.magFilter[Texture.magFilter](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/textures/Texture.magFilter)设置为[THREE.NearestFilter](http://www.yanhuangxueyuan.com/threejs/docs/index.html#api/zh/constants/Textures)。默认为空。


```vue
material = new THREE.MeshToonMaterial(); //卡通网格材质，受光照影响
material.gradientMap = gradientTextures;
```

### 9. MeshStandardMaterial (PBR标准材质)
- **受光照影响**

***这个材质相当于把一套的贴图全部应用，创造出很真实的效果***

```vue
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

```
material = new THREE.MeshStandardMaterial(); //标准网格材质，受光照影响
material.metalness = 0.7; //设置材质的金属度
material.roughness = 0.2; //设置材质的粗糙
material.envMap = environmentMapTexture; //设置环境贴图
```







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
