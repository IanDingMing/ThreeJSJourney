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
// glTF加载器
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";
// DRACOLoader
import { DRACOLoader } from "three/addons/loaders/DRACOLoader.js";
// RGBELoader
import { RGBELoader } from "three/addons/loaders/RGBELoader.js";
// 导入自定义的纹理工具函数
import { getTextureUrl } from "@/utils/texturesUtils";
// 导入RectAreaLightHelper
import { RectAreaLightHelper } from "three/addons/helpers/RectAreaLightHelper.js";
import * as CANNON from "cannon-es";
import waterVertexShader from "@/shaders/water2/vertex.glsl?raw";
import waterFragmentShader from "@/shaders/water2/fragment.glsl?raw";

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
const global = { envMapIntensity: 1 };
let modelFlightHelmet: THREE.Group | null = null;

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

  /**
   * Water
   */
  // Geometry
  const waterGeometry = new THREE.PlaneGeometry(2, 2, 512, 512);
  waterGeometry.deleteAttribute("normal");
  waterGeometry.deleteAttribute("uv");

  // Color
  const debugObject = {
    depthColor: "#ff4000",
    sufaceColor: "#151c37",
  };

  // Material
  const waterMaterial = new THREE.ShaderMaterial({
    vertexShader: waterVertexShader,
    fragmentShader: waterFragmentShader,
    uniforms: {
      uTime: { value: 0 },
      uBigWavesElevation: { value: 0.2 },
      uBigWavesFrenquency: { value: new THREE.Vector2(4, 1.5) },
      uBigWavesSpeed: { value: 0.75 },

      uSmallWavesElevation: { value: 0.15 },
      uSmallWavesFrequency: { value: 3 },
      uSmallWavesSpeed: { value: 0.2 },
      uSmallIterations: { value: 4 },

      uDepthColor: { value: new THREE.Color(debugObject.depthColor) },
      uSufaceColor: { value: new THREE.Color(debugObject.sufaceColor) },
      uColorOffset: { value: 0.925 },
      uColorMultiplier: { value: 1 },
    },
  });

  // Mesh
  const water = new THREE.Mesh(waterGeometry, waterMaterial);
  water.rotation.x = -Math.PI * 0.5;
  scene.add(water);
  // 模型mesh==========================

  const axesHelper = new THREE.AxesHelper(); //创建一个坐标轴辅助对象
  axesHelper.position.y = 0.25;
  scene.add(axesHelper); //将坐标轴辅助对象添加到网格模型中

  /**
   * Camera
   */
  // Base camera
  const camera = new THREE.PerspectiveCamera(
    75,
    sizes.width / sizes.height,
    0.1,
    100
  );
  camera.position.set(1, 1, 1);
  scene.add(camera);

  // Controls
  controls = new OrbitControls(camera, webgl.value);
  controls.enableDamping = true;

  // 创建渲染器对象
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.setSize(sizes.width, sizes.height); //设置three.js渲染区域的尺寸(像素px)
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  // renderer.setClearColor(new THREE.Color("#262837")); //设置渲染器的背景颜色

  webgl.value!.appendChild(renderer.domElement);

  const clock = new THREE.Clock(); //创建一个时钟对象，用于计算时间差
  function render() {
    if (!camera || !renderer || !controls) return;

    const deltaTime = clock.getDelta();
    const elapsedTime = clock.elapsedTime; //获取自创建时钟以来的时间

    // Update water
    waterMaterial.uniforms.uTime.value = elapsedTime;

    // Animate meshes
    meshArray.forEach((mesh) => {});

    // Update controls
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
    .add(waterMaterial.uniforms.uBigWavesElevation, "value", 0, 1, 0.001)
    .name("uBigWavesElevation");
  gui
    .add(waterMaterial.uniforms.uBigWavesFrenquency.value, "x", 0, 10, 0.001)
    .name("uBigWavesFrenquencyX");
  gui
    .add(waterMaterial.uniforms.uBigWavesFrenquency.value, "y", 0, 10, 0.001)
    .name("uBigWavesFrenquencyY");
  gui
    .add(waterMaterial.uniforms.uBigWavesSpeed, "value", 0, 4, 0.001)
    .name("uBigWavesSpeed");

  gui
    .add(waterMaterial.uniforms.uSmallWavesElevation, "value", 0, 1, 0.001)
    .name("uSmallWavesElevation");
  gui
    .add(waterMaterial.uniforms.uSmallWavesFrequency, "value", 0, 30, 0.001)
    .name("uSmallWavesFrequency");
  gui
    .add(waterMaterial.uniforms.uSmallWavesSpeed, "value", 0, 4, 0.001)
    .name("uSmallWavesSpeed");
  gui
    .add(waterMaterial.uniforms.uSmallIterations, "value", 0, 5, 1)
    .name("uSmallIterations");

  gui
    .addColor(debugObject, "depthColor")
    .name("depthColor")
    .onChange(() => {
      waterMaterial.uniforms.uDepthColor.value.set(debugObject.depthColor);
    });
  gui
    .addColor(debugObject, "sufaceColor")
    .name("sufaceColor")
    .onChange(() => {
      waterMaterial.uniforms.uSufaceColor.value.set(debugObject.sufaceColor);
    });
  gui
    .add(waterMaterial.uniforms.uColorOffset, "value", 0, 1, 0.001)
    .name("uColorOffset");
  gui
    .add(waterMaterial.uniforms.uColorMultiplier, "value", 0, 10, 0.001)
    .name("uColorMultiplier");
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
  <div class="container">
    <div ref="webgl" class="webgl"></div>
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
