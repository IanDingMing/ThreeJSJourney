

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

- 添加 lil-gui 控制库
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

