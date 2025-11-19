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

/**
 * 模型加载
 */
// 1. 初始化加载器
const gltfLoader = new GLTFLoader();

// 2. 定义模型路径（支持 gltf/glb 等格式）
const modelPath = `${
  import.meta.env.BASE_URL
}models/LeePerrySmith/LeePerrySmith.glb`; // 文件路径：/public/models/Duck

/**
 * Textures加载
 */
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

// 加载环境贴图
const cubeTextureLoader = new THREE.CubeTextureLoader(loadingManager);
const environmentMap = cubeTextureLoader.load([
  getTextureUrl("environmentMaps/0/px.jpg"),
  getTextureUrl("environmentMaps/0/nx.jpg"),
  getTextureUrl("environmentMaps/0/py.jpg"),
  getTextureUrl("environmentMaps/0/ny.jpg"),
  getTextureUrl("environmentMaps/0/pz.jpg"),
  getTextureUrl("environmentMaps/0/nz.jpg"),
]);
environmentMap.encoding = THREE.sRGBEncoding;

// 加载模型纹理
const texturesLoader = new THREE.TextureLoader(loadingManager);
const mapTexture = texturesLoader.load(
  `${import.meta.env.BASE_URL}models/LeePerrySmith/color.jpg`
);
mapTexture.encoding = THREE.sRGBEncoding;
const normalTexture = texturesLoader.load(
  `${import.meta.env.BASE_URL}models/LeePerrySmith/normal.jpg`
);

/**
 * Update all materials
 */
const updateAllMaterials = (scene: THREE.Scene) => {
  scene.traverse((child) => {
    if (
      child instanceof THREE.Mesh &&
      child.material instanceof THREE.MeshStandardMaterial
    ) {
      child.material.envMapIntensity = 5;
      child.material.needsUpdate = true;
      child.castShadow = true;
      child.receiveShadow = true;
    }
  });
};
onMounted(() => {
  // console.log(webgl, webgl.value?.clientHeight, webgl.value?.clientWidth);
  sizes.width = webgl.value!.clientWidth;
  sizes.height = webgl.value!.clientHeight;

  // 创建3D场景对象Scene
  const scene = new THREE.Scene();
  // scene.background = new THREE.Color("#262837"); //设置场景背景颜色
  scene.background = environmentMap;
  scene.environment = environmentMap;

  // 模型mesh======================
  // Material
  const material = new THREE.MeshStandardMaterial({
    map: mapTexture,
    normalMap: normalTexture,
  });

  // 3. 执行加载
  gltfLoader.load(
    modelPath,
    // 加载成功回调
    (gltf) => {
      // Model
      const mesh = gltf.scene.children[0];
      mesh.rotation.y = Math.PI * 0.5;
      mesh.material = material;
      scene.add(mesh);

      // Update materials
      updateAllMaterials(scene);
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
  // 模型mesh==========================

  const axesHelper = new THREE.AxesHelper(); //创建一个坐标轴辅助对象
  scene.add(axesHelper); //将坐标轴辅助对象添加到网格模型中

  /**
   * Lights
   */
  const directionalLight = new THREE.DirectionalLight("#ffffff", 3);
  directionalLight.castShadow = true;
  directionalLight.shadow.mapSize.set(1024, 1024);
  directionalLight.shadow.camera.far = 15;
  directionalLight.shadow.normalBias = 0.05;
  directionalLight.position.set(0.25, 2, -2.25);
  scene.add(directionalLight);

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
  camera.position.set(4, 1, -4);
  scene.add(camera);

  // Controls
  controls = new OrbitControls(camera, webgl.value);
  controls.enableDamping = true;

  // 创建渲染器对象
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(sizes.width, sizes.height); //设置three.js渲染区域的尺寸(像素px)
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  // renderer.setClearColor(new THREE.Color("#262837")); //设置渲染器的背景颜色

  webgl.value!.appendChild(renderer.domElement);

  const clock = new THREE.Clock(); //创建一个时钟对象，用于计算时间差
  function render() {
    if (!camera || !renderer || !controls) return;

    const deltaTime = clock.getDelta();
    const elapsedTime = clock.elapsedTime; //获取自创建时钟以来的时间

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
