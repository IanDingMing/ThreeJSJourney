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
const gradientTexture = texturesLoader.load(getTextureUrl("gradients/3.jpg"));
gradientTexture.magFilter = THREE.NearestFilter;

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
let scrollY: number = -1;
let currentSection = 0;

const cursor = {
  x: 0,
  y: 0,
};

const parameters = {
  materialColor: "#ffeded",
};

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
const handleScroll = (event: Event) => {
  const target = event.target as HTMLElement | null;
  if (!target) return;
  // console.log("滚动位置:", event.target.scrollTop);
  scrollY = target.scrollTop;

  const newScetion = Math.round(scrollY / sizes.height);
  if (currentSection === newScetion) return;
  currentSection = newScetion;
  console.log("changed", currentSection);

  gsap.to(meshArray[currentSection].rotation, {
    duration: 1.5,
    ease: "power2.inOut",
    x: "+=6",
    y: "+=3",
    z: "+=1.5",
  });
};

const handleMousemove = (event: MouseEvent) => {
  cursor.x = event.clientX / sizes.width - 0.5;
  cursor.y = event.clientY / sizes.height - 0.5;
  // console.log(event.clientX, event.clientY, cursor);
};

onMounted(() => {
  // console.log(webgl, webgl.value?.clientHeight, webgl.value?.clientWidth);
  sizes.width = webgl.value!.clientWidth;
  sizes.height = webgl.value!.clientHeight;

  // 创建3D场景对象Scene
  const scene = new THREE.Scene();
  // scene.background = new THREE.Color("#262837"); //设置场景背景颜色

  // 模型mesh==========================
  /**
   * Test cube
   */
  const cube = new THREE.Mesh(
    new THREE.BoxGeometry(1, 1, 1),
    new THREE.MeshBasicMaterial({ color: "#ff0000" })
  );
  // scene.add(cube);

  /**
   * Objects
   */
  const objectsDistance = 4;
  const material = new THREE.MeshToonMaterial({
    color: parameters.materialColor,
    gradientMap: gradientTexture,
  });
  const mesh1 = new THREE.Mesh(
    new THREE.TorusGeometry(1, 0.4, 16, 60),
    material
  );
  const mesh2 = new THREE.Mesh(new THREE.ConeGeometry(1, 2, 32), material);
  const mesh3 = new THREE.Mesh(
    new THREE.TorusKnotGeometry(0.8, 0.35, 100, 16),
    material
  );

  // mesh1.position.y = 2;
  // mesh1.scale.set(0.5, 0.5, 0.5);

  // mesh2.visible = false;

  // mesh3.position.y = -2;
  // mesh3.scale.set(0.5, 0.5, 0.5);

  mesh1.position.y = -objectsDistance * 0;
  mesh2.position.y = -objectsDistance * 1;
  mesh3.position.y = -objectsDistance * 2;

  mesh1.position.x = 2;
  mesh2.position.x = -2;
  mesh3.position.x = 2;

  meshArray.push(mesh1, mesh2, mesh3);
  scene.add(mesh1, mesh2, mesh3);

  /**
   * Particles
   */
  //Geometry
  const particlesCount = 200;
  const position = new Float32Array(particlesCount * 3);
  for (let index = 0; index < particlesCount; index++) {
    const i3 = index * 3;

    position[i3 + 0] = (Math.random() - 0.5) * 10;
    position[i3 + 1] =
      (Math.random() - 0.5) * objectsDistance * meshArray.length -
      objectsDistance;
    position[i3 + 2] = (Math.random() - 0.5) * 10;
  }
  const particlesGeometry = new THREE.BufferGeometry();
  particlesGeometry.setAttribute(
    "position",
    new THREE.BufferAttribute(position, 3)
  );
  // Material
  const particlesMaterial = new THREE.PointsMaterial({
    color: parameters.materialColor,
    size: 0.03,
    sizeAttenuation: true,
  });
  // Point
  const particlesMesh = new THREE.Points(particlesGeometry, particlesMaterial);
  scene.add(particlesMesh);
  // 模型mesh==========================

  const axesHelper = new THREE.AxesHelper(); //创建一个坐标轴辅助对象
  scene.add(axesHelper); //将坐标轴辅助对象添加到网格模型中

  // 添加灯光
  const directionalLight = new THREE.DirectionalLight("#ffffff", 1);
  directionalLight.position.set(1, 1, 0);
  scene.add(directionalLight);

  // 实例化一个透视投影相机对象
  const cameraGroup = new THREE.Group();
  scene.add(cameraGroup);

  camera = new THREE.PerspectiveCamera(
    35,
    sizes.width / sizes.height,
    0.1,
    1000
  );
  camera.position.z = 6;
  cameraGroup.add(camera);

  // 创建渲染器对象
  renderer = new THREE.WebGLRenderer();
  renderer.setSize(sizes.width, sizes.height); //设置three.js渲染区域的尺寸(像素px)
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  // renderer.setClearColor(new THREE.Color("#262837")); //设置渲染器的背景颜色
  webgl.value!.appendChild(renderer.domElement);

  const clock = new THREE.Clock(); //创建一个时钟对象，用于计算时间差
  let previousTime = 0;
  function render() {
    if (!camera || !renderer) return;

    const elapsedTime = clock.getElapsedTime(); //获取自创建时钟以来的时间
    const deltaTime = elapsedTime - previousTime;
    previousTime = elapsedTime;

    // Animate camera
    camera.position.y = (-scrollY / sizes.height) * objectsDistance;

    const parallaxX = -cursor.x;
    const parallaxY = cursor.y;
    // cameraGroup.position.x = parallaxX;
    // cameraGroup.position.y = parallaxY;
    // cameraGroup.position.x += (parallaxX - cameraGroup.position.x) * 0.02;
    // cameraGroup.position.y += (parallaxY - cameraGroup.position.y) * 0.02;
    const CAMERA_SPEED = 5; // 明确速度变量
    cameraGroup.position.x +=
      (parallaxX - cameraGroup.position.x) * CAMERA_SPEED * deltaTime;
    cameraGroup.position.y +=
      (parallaxY - cameraGroup.position.y) * CAMERA_SPEED * deltaTime;

    // Animate meshes
    meshArray.forEach((mesh) => {
      mesh.rotation.x += deltaTime * 0.1;
      mesh.rotation.y += deltaTime * 0.12;
    });

    renderer.render(scene, camera); //执行渲染操作
    requestAnimationFrame(render); //请求再次执行函数render
  }
  render();

  // 添加事件监听
  window.addEventListener("resize", handleResize);

  // 创建GUI===================
  gui = new GUI();

  // 添加按钮
  gui
    .addColor(parameters, "materialColor")
    .name("材质颜色")
    .onChange(() => {
      material.color.set(parameters.materialColor);
      particlesMaterial.color.set(parameters.materialColor);
    });

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

<style scoped>
.container {
  height: 100vh;
  overflow-y: scroll;
}

.webgl {
  width: 100vw;
  height: 100vh;
  background-color: rgb(38, 25, 65);
  top: 0;
  left: 0;
  position: fixed;
}

.section {
  display: flex;
  align-items: center;
  height: 100vh;
  position: relative;
  font-family: "Cabin", sans-serif;
  color: #ffeded;
  text-transform: uppercase;
  font-size: 7vmin;
  padding-left: 10%;
  padding-right: 10%;
  /* background-color: blue; */
}

section:nth-child(odd) {
  justify-content: flex-end;
}
</style>
