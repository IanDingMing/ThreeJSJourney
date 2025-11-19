<script setup lang="ts">
import { ref, useTemplateRef, onMounted, onUnmounted } from "vue";
import * as THREE from "three";
import gsap from "gsap";
// 导入OrbitControls
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
// 导入lil.gui
import { GUI } from "three/addons/libs/lil-gui.module.min.js";
// 导入字体加载器
import { FontLoader } from "three/addons/loaders/FontLoader.js";
// 导入文本几何体
import { TextGeometry } from "three/addons/geometries/TextGeometry.js";
// 导入自定义的纹理工具函数
import { getTextureUrl } from "@/utils/texturesUtils";
// 导入RectAreaLightHelper
import { RectAreaLightHelper } from "three/addons/helpers/RectAreaLightHelper.js";
import { update } from "three/examples/jsm/libs/tween.module.js";
import { parameter } from "three/tsl";

// 使用FontLoader加载字体
const fontLoader = new FontLoader();

// 使用TextureLoader加载纹理
const loadingManager = new THREE.LoadingManager();
loadingManager.onStart = () => {
  // console.log("Loading started");
};
loadingManager.onLoad = () => {
  // console.log("Loading complete");
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
const cubeTextureLoader = new THREE.CubeTextureLoader(loadingManager);
// 加载纹理
const particleTexture = texturesLoader.load(getTextureUrl("particles/2.png"));

const sizes = {
  width: 800,
  height: 600,
};
const webgl = useTemplateRef("webgl");

// 1. 声明需要复用的变量
let camera: THREE.PerspectiveCamera | null = null;
let renderer: THREE.WebGLRenderer | null = null;
let controls: OrbitControls | null = null;
let gui: GUI | null = null;
const meshArray: THREE.Mesh[] = [];

// 2. 声明事件处理函数
const handleResize = () => {
  if (!webgl.value || !camera || !renderer) return;

  // 更新容器尺寸
  const container = webgl.value;
  sizes.width = container.clientWidth;
  sizes.height = container.clientHeight;

  // 更新相机和渲染器
  camera.aspect = sizes.width / sizes.height;
  camera.updateProjectionMatrix();
  renderer.setSize(sizes.width, sizes.height);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));

  // 更新控制器（如果存在）
  if (controls) controls.update();
};

const handleDoubleClick = () => {
  if (!webgl.value) return;

  const fullscreenElement =
    document.fullscreenElement ||
    (document as any).webkitFullscreenElement ||
    (document as any).mozFullScreenElement;

  if (!fullscreenElement) {
    webgl.value.requestFullscreen();
  } else {
    document.exitFullscreen();
  }
};

onMounted(() => {
  // console.log(webgl, webgl.value?.clientHeight, webgl.value?.clientWidth);
  sizes.width = webgl.value!.clientWidth;
  sizes.height = webgl.value!.clientHeight;

  // 创建3D场景对象Scene
  const scene = new THREE.Scene();
  // scene.background = new THREE.Color("#262837"); //设置场景背景颜色

  // 模型mesh==========================
  const cube = new THREE.Mesh(
    new THREE.BoxGeometry(5, 5, 5),
    new THREE.MeshBasicMaterial()
  );
  // scene.add(cube);

  /**
   * Galaxy
   */
  const parameters = {
    count: 100000, // 粒子数量（性能敏感）
    size: 0.02, // 粒子基础大小
    radius: 5, // 星系半径
    branches: 3, // 旋臂数量
    spin: 3, // 螺旋扭曲系数（>0顺时针，<0逆时针）
    randomness: 0.2, //分支偏移量
    randomnessPower: 3, // 随机强度指数（值越大粒子越集中）
    insideColor: "#ff6030", // 粒子色值
    outsideColor: "#1b3984", // 粒子色值
  };

  let geometry: THREE.BufferGeometry | null = null;
  let material: THREE.PointsMaterial | null = null;
  let points: THREE.Points | null = null;

  const generateGalaxy = () => {
    /**
     * Destroy old galaxy
     */
    if (points !== null) {
      geometry?.dispose();
      material?.dispose();
      scene.remove(points);
    }

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
      /**
       * position
       */
      const radius = Math.random() * parameters.radius;
      const branchAngle =
        ((index % parameters.branches) / parameters.branches) * Math.PI * 2;
      const spinAngle = radius * parameters.spin;

      // const randomX = (Math.random() - 0.5) * parameters.randomness;
      // const randomY = (Math.random() - 0.5) * parameters.randomness;
      // const randomZ = (Math.random() - 0.5) * parameters.randomness;

      const randomX =
        Math.pow(Math.random(), parameters.randomnessPower) *
        (Math.random() < 0.5 ? 1 : -1) *
        parameters.randomness *
        radius;
      const randomY =
        Math.pow(Math.random(), parameters.randomnessPower) *
        (Math.random() < 0.5 ? 1 : -1) *
        parameters.randomness *
        radius;
      const randomZ =
        Math.pow(Math.random(), parameters.randomnessPower) *
        (Math.random() < 0.5 ? 1 : -1) *
        parameters.randomness *
        radius;

      positions[i3 + 0] = Math.cos(branchAngle + spinAngle) * radius + randomX;
      positions[i3 + 1] = randomY;
      positions[i3 + 2] = Math.sin(branchAngle + spinAngle) * radius + randomZ;

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
      size: parameters.size,
      sizeAttenuation: true,
      depthWrite: false,
      blending: THREE.AdditiveBlending,
      vertexColors: true,
    });

    /**
     * Galaxy
     */
    points = new THREE.Points(geometry, material);
    scene.add(points);
  };
  generateGalaxy();
  // 模型mesh==========================

  const axesHelper = new THREE.AxesHelper(); //创建一个坐标轴辅助对象
  scene.add(axesHelper); //将坐标轴辅助对象添加到网格模型中

  // 添加灯光
  const ambientLight = new THREE.AmbientLight("#b9d5ff", 0.3); //创建环境光对象
  scene.add(ambientLight); //将环境光添加到场景中

  // 实例化一个透视投影相机对象
  camera = new THREE.PerspectiveCamera(75, sizes.width / sizes.height, 1, 1000);
  camera.position.set(5, 5, 5);
  camera.lookAt(new THREE.Vector3(0, 0, 0)); //设置相机方向(指向的场景对象)

  // 创建渲染器对象
  renderer = new THREE.WebGLRenderer();
  renderer.setSize(sizes.width, sizes.height); //设置three.js渲染区域的尺寸(像素px)
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  // renderer.setClearColor(new THREE.Color("#262837")); //设置渲染器的背景颜色
  webgl.value!.appendChild(renderer.domElement);

  // 创建轨道控制器
  controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true; // 添加惯性效果

  const clock = new THREE.Clock(); //创建一个时钟对象，用于计算时间差
  function render() {
    if (!camera || !renderer || !controls) return;

    const elapsedTime = clock.getElapsedTime(); //获取自创建时钟以来的时间差

    // update particles

    controls.update();

    renderer.render(scene, camera); //执行渲染操作
    requestAnimationFrame(render); //请求再次执行函数render
  }
  render();

  // 添加事件监听
  window.addEventListener("resize", handleResize);

  // 创建GUI===================
  gui = new GUI();

  gui
    .add(parameters, "count", 100, 1000000, 100)
    .name("粒子数量")
    .onFinishChange(generateGalaxy);
  gui
    .add(parameters, "size", 0.001, 0.01, 0.001)
    .name("粒子基础大小")
    .onFinishChange(generateGalaxy);

  gui
    .add(parameters, "radius", 0.01, 20, 0.01)
    .name("星系半径")
    .onFinishChange(generateGalaxy);
  gui
    .add(parameters, "branches", 2, 20, 1)
    .name("旋臂数量")
    .onFinishChange(generateGalaxy);
  gui
    .add(parameters, "spin", -5, 5, 0.001)
    .name("螺旋扭曲系数")
    .onFinishChange(generateGalaxy);
  gui
    .add(parameters, "randomness", 0, 2, 0.001)
    .name("分支偏移量")
    .onFinishChange(generateGalaxy);

  gui
    .add(parameters, "randomnessPower", 1, 10, 0.001)
    .name("随机强度指数")
    .onFinishChange(generateGalaxy);
  gui
    .addColor(parameters, "insideColor")
    .name("里粒子色值")
    .onFinishChange(generateGalaxy);
  gui
    .addColor(parameters, "outsideColor")
    .name("外粒子色值")
    .onFinishChange(generateGalaxy);
  // 添加按钮
  // gui.add(eventObj, "hideHelpers").name("隐藏灯光辅助对象");

  // 创建GUI===================
});
// 组件卸载时移除事件监听
onUnmounted(() => {
  // 移除事件监听
  window.removeEventListener("resize", handleResize);
  // 清理资源
  if (renderer) {
    renderer.dispose();
    renderer = null;
  }
  if (controls) {
    controls.dispose();
    controls = null;
  }
  if (gui) {
    gui.destroy();
    gui = null;
  }
  camera = null;
  // 清空前释放材质/几何体
  meshArray.forEach((mesh) => {});
  meshArray.length = 0; // 再清空数组
});
</script>

<template>
  <div ref="webgl" class="webgl"></div>
</template>

<style scoped>
.webgl {
  width: 100vw;
  height: 100vh;
  background-color: #f00;
}
</style>
