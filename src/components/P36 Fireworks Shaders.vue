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
import { Sky } from "three/addons/objects/Sky.js";
import fireworkVertexShader from "@/shaders/firework/vertex.glsl?raw";
import fireworkfragmentShader from "@/shaders/firework/fragment.glsl?raw";

const sizes = {
  width: 800,
  height: 600,
  resolution: new THREE.Vector2(800, 600),
  pixelRatio: Math.min(window.devicePixelRatio, 2),
};
sizes.resolution.set(
  sizes.width * sizes.pixelRatio,
  sizes.height * sizes.pixelRatio
);
const webgl = useTemplateRef("webgl");

// 1. 声明需要复用的变量
let camera: THREE.PerspectiveCamera | null = null;
let renderer: THREE.WebGLRenderer | null = null;
let controls: OrbitControls | null = null;
let gui: GUI | null = null;
const meshArray: THREE.Mesh[] = [];
const global = { envMapIntensity: 1 };
let modelFlightHelmet: THREE.Group | null = null;
let scene: THREE.Scene | null = null;

// 2. 声明事件处理函数
const handleResize = () => {
  if (!webgl.value || !camera || !renderer) return;

  // 更新容器尺寸
  const container = webgl.value;
  sizes.width = container.clientWidth;
  sizes.height = container.clientHeight;
  sizes.pixelRatio = Math.min(window.devicePixelRatio, 2);
  sizes.resolution.set(
    sizes.width * sizes.pixelRatio,
    sizes.height * sizes.pixelRatio
  );

  // 更新相机和渲染器
  camera.aspect = sizes.width / sizes.height;
  camera.updateProjectionMatrix();
  renderer.setSize(sizes.width, sizes.height);
  renderer.setPixelRatio(sizes.pixelRatio);

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
const modelPath = `${import.meta.env.BASE_URL}models/suzanne.glb`; // 文件路径：/public/models/Duck

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
const texturesLoader = new THREE.TextureLoader(loadingManager);
const textures = [
  texturesLoader.load(getTextureUrl("particles/1.png")),
  texturesLoader.load(getTextureUrl("particles/2.png")),
  texturesLoader.load(getTextureUrl("particles/3.png")),
  texturesLoader.load(getTextureUrl("particles/4.png")),
  texturesLoader.load(getTextureUrl("particles/5.png")),
  texturesLoader.load(getTextureUrl("particles/6.png")),
  texturesLoader.load(getTextureUrl("particles/7.png")),
  texturesLoader.load(getTextureUrl("particles/11.png")),
];

/**
 * Fireworks
 * @param count 粒子数量
 * @param position 烟花位置
 * @param size 烟花粒子大小
 * @param texture 烟花粒子纹理
 * @param radius 烟花半径
 * @param color 烟花颜色
 */
const createFirework = (
  count: number,
  position: THREE.Vector3,
  size: number,
  texture: THREE.Texture,
  radius: number,
  color: THREE.Color
) => {
  if (!scene) {
    console.warn("Scene not initialized");
    return;
  }

  // Geometry
  const positionArray = new Float32Array(count * 3);
  const sizesArray = new Float32Array(count);
  const timeMultipliersArray = new Float32Array(count);
  for (let index = 0; index < count; index++) {
    const i3 = index * 3;

    const spherical = new THREE.Spherical(
      radius * (0.75 + 0.25 * Math.random()),
      Math.random() * Math.PI,
      Math.random() * Math.PI * 2
    );
    const position = new THREE.Vector3();
    position.setFromSpherical(spherical);

    positionArray[i3 + 0] = position.x;
    positionArray[i3 + 1] = position.y;
    positionArray[i3 + 2] = position.z;

    sizesArray[index] = Math.random();

    timeMultipliersArray[index] = 1 + Math.random();
  }

  const geometry = new THREE.BufferGeometry();
  geometry.setAttribute(
    "position",
    new THREE.Float32BufferAttribute(positionArray, 3)
  );
  geometry.setAttribute(
    "aSize",
    new THREE.Float32BufferAttribute(sizesArray, 1)
  );
  geometry.setAttribute(
    "aTimeMultiplier",
    new THREE.Float32BufferAttribute(timeMultipliersArray, 1)
  );

  // Material
  texture.flipY = false;
  const material = new THREE.ShaderMaterial({
    vertexShader: fireworkVertexShader,
    fragmentShader: fireworkfragmentShader,
    uniforms: {
      uSize: new THREE.Uniform(size),
      uResolution: new THREE.Uniform(sizes.resolution),
      uTexture: new THREE.Uniform(texture),
      uColor: new THREE.Uniform(color),
      uProgress: new THREE.Uniform(0),
    },
    transparent: true,
    depthWrite: false,
    blending: THREE.AdditiveBlending,
  });

  // Points
  const firework = new THREE.Points(geometry, material);
  firework.position.copy(position);
  scene.add(firework);

  // Destroy
  const destroy = () => {
    scene!.remove(firework);
    geometry.dispose();
    material.dispose();
  };

  // Animate
  gsap.to(material.uniforms.uProgress, {
    value: 1,
    duration: 3,
    ease: "linear",
    onComplete: destroy,
  });
};
const createRandomFirework = () => {
  const count = Math.round(400 + Math.random() * 1000);
  const position = new THREE.Vector3(
    (Math.random() - 0.5) * 2,
    Math.random(),
    (Math.random() - 0.5) * 2
  );
  const size = 0.1 + Math.random() * 0.1;
  const texture = textures[Math.floor(Math.random() * textures.length)];
  const radius = 0.5 + Math.random();
  const color = new THREE.Color();
  color.setHSL(Math.random(), 1, 0.7);

  createFirework(count, position, size, texture, radius, color);
};

const handleClick = () => {
  // createFirework(
  //   1000,
  //   new THREE.Vector3(),
  //   0.5,
  //   textures[7],
  //   1,
  //   new THREE.Color("#8affff")
  // );
  createRandomFirework();
};

onMounted(() => {
  // console.log(webgl, webgl.value?.clientHeight, webgl.value?.clientWidth);
  sizes.width = webgl.value!.clientWidth;
  sizes.height = webgl.value!.clientHeight;

  // 创建3D场景对象Scene
  scene = new THREE.Scene();
  // scene.background = new THREE.Color("#262837"); //设置场景背景颜色

  // 模型mesh======================
  // 模型mesh==========================

  const axesHelper = new THREE.AxesHelper(); //创建一个坐标轴辅助对象
  scene.add(axesHelper); //将坐标轴辅助对象添加到网格模型中

  /**
   * Camera
   */
  // Base camera
  camera = new THREE.PerspectiveCamera(
    25,
    sizes.width / sizes.height,
    0.1,
    100
  );
  camera.position.set(1.5, 0, 6);
  scene.add(camera);

  // Controls
  controls = new OrbitControls(camera, webgl.value);
  controls.enableDamping = true;

  // 创建渲染器对象
  const rendererParameters = { clearColor: "#1d1f2a" };
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(sizes.width, sizes.height); //设置three.js渲染区域的尺寸(像素px)
  renderer.setPixelRatio(sizes.pixelRatio);

  webgl.value!.appendChild(renderer.domElement);

  /**
   * Sky
   */
  const sky = new Sky();
  sky.scale.setScalar(450000);
  scene.add(sky);

  const sun = new THREE.Vector3();

  const skyParameters = {
    turbidity: 10,
    rayleigh: 3,
    mieCoefficient: 0.005,
    mieDirectionalG: 0.95,
    elevation: -2.2,
    azimuth: 180,
    exposure: renderer.toneMappingExposure,
  };

  const updateSky = () => {
    const uniforms = sky.material.uniforms;
    uniforms["turbidity"].value = skyParameters.turbidity;
    uniforms["rayleigh"].value = skyParameters.rayleigh;
    uniforms["mieCoefficient"].value = skyParameters.mieCoefficient;
    uniforms["mieDirectionalG"].value = skyParameters.mieDirectionalG;

    const phi = THREE.MathUtils.degToRad(90 - skyParameters.elevation);
    const theta = THREE.MathUtils.degToRad(skyParameters.azimuth);

    sun.setFromSphericalCoords(1, phi, theta);

    uniforms["sunPosition"].value.copy(sun);

    renderer!.toneMappingExposure = skyParameters.exposure;
    renderer!.render(scene!, camera!);
  };

  updateSky();

  const clock = new THREE.Clock(); //创建一个时钟对象，用于计算时间差
  function render() {
    if (!camera || !renderer || !controls) return;

    const deltaTime = clock.getDelta();
    const elapsedTime = clock.elapsedTime; //获取自创建时钟以来的时间

    // Animate meshes
    meshArray.forEach((mesh) => {});

    // Update controls
    controls.update();

    renderer.render(scene!, camera); //执行渲染操作
    requestAnimationFrame(render); //请求再次执行函数render
  }
  render();

  // 添加事件监听
  window.addEventListener("resize", handleResize);

  // 创建GUI===================
  gui = new GUI();

  gui.add(skyParameters, "turbidity", 0.0, 20.0, 0.1).onChange(updateSky);
  gui.add(skyParameters, "rayleigh", 0.0, 4, 0.001).onChange(updateSky);
  gui.add(skyParameters, "mieCoefficient", 0.0, 0.1, 0.001).onChange(updateSky);
  gui.add(skyParameters, "mieDirectionalG", 0.0, 1, 0.001).onChange(updateSky);
  gui.add(skyParameters, "elevation", -3, 10, 0.01).onChange(updateSky);
  gui.add(skyParameters, "azimuth", -180, 180, 0.1).onChange(updateSky);
  gui.add(skyParameters, "exposure", 0, 1, 0.0001).onChange(updateSky);
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
  scene = null; // 清理 scene
  // 清空前释放材质/几何体
  meshArray.forEach((mesh) => {});
  meshArray.length = 0; // 再清空数组
});
</script>

<template>
  <div class="container" @click="handleClick">
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
