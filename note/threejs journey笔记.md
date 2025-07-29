

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
