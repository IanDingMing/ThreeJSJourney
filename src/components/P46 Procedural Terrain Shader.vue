<script setup lang="ts">
import { ref, useTemplateRef, onMounted, onUnmounted } from "vue";
import * as THREE from "three";
import gsap from "gsap";
import CustomShaderMaterial from "three-custom-shader-material/vanilla";
import { SUBTRACTION, Brush, Evaluator } from "three-bvh-csg";
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
import { GPUComputationRenderer } from "three/addons/misc/GPUComputationRenderer.js";
import { mergeVertices } from "three/addons/utils/BufferGeometryUtils.js";
import * as CANNON from "cannon-es";
import terrainVertexShader from "@/shaders/terrain/vertex.glsl";
import terrainFragmentShader from "@/shaders/terrain/fragment.glsl";
import gpgpuParticlesShader from "@/shaders/gpgpu/particles.glsl";
import environmentMapsPath from "@/assets/textures/environmentMaps/spruit_sunrise.hdr";

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
const gui: GUI = new GUI();
const meshArray: THREE.Mesh[] = [];
const global = { envMapIntensity: 1 };
let model: THREE.Group | null = null;

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

// 加载纹理
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
const rgbeLoader = new RGBELoader();

// 1. 初始化 Draco 解码器
const dracoLoader = new DRACOLoader();
// 设置解码器路径（对应 public 下的资源）
dracoLoader.setDecoderPath(`${import.meta.env.BASE_URL}draco/`); // 文件路径：/public/models/draco

// 2. 关联到 GLTFLoader
const gltfLoader = new GLTFLoader();
gltfLoader.setDRACOLoader(dracoLoader);

onMounted(() => {
  // console.log(webgl, webgl.value?.clientHeight, webgl.value?.clientWidth);
  sizes.width = webgl.value!.clientWidth;
  sizes.height = webgl.value!.clientHeight;

  // 创建3D场景对象Scene
  const scene = new THREE.Scene();
  // scene.background = new THREE.Color("#262837"); //设置场景背景颜色
  // HDR (RGBE) equirectangular
  rgbeLoader.load(environmentMapsPath, (environmentMap) => {
    environmentMap.mapping = THREE.EquirectangularReflectionMapping;

    scene.background = environmentMap;
    scene.backgroundBlurriness = 0.5;
    scene.environment = environmentMap;
  });

  // 创建渲染器对象
  const rendererParameters = { clearColor: "#29191f" };
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(sizes.width, sizes.height); //设置three.js渲染区域的尺寸(像素px)
  renderer.setPixelRatio(sizes.pixelRatio);
  renderer.setClearColor(rendererParameters.clearColor); //设置渲染器的背景颜色
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1;

  webgl.value!.appendChild(renderer.domElement);

  // 模型mesh==========================
  /**
   * Placeholder
   */
  const placeholder = new THREE.Mesh(
    new THREE.IcosahedronGeometry(2, 5),
    new THREE.MeshPhysicalMaterial()
  );
  // scene.add(placeholder);

  /**
   * Terrain
   */
  // Geometry
  const geometry = new THREE.PlaneGeometry(10, 10, 500, 500);
  geometry.deleteAttribute("uv");
  geometry.deleteAttribute("noraml");
  geometry.rotateX(-Math.PI * 0.5);

  // Material
  const debugObject = {
    colorWaterDeep: "#002b3d",
    colorWaterSurface: "#66a8ff",
    colorSand: "#ffe894",
    colorGrass: "#85d534",
    colorSnow: "#ffffff",
    colorRock: "#bfbd8d",
  };
  const uniforms = {
    uTime: new THREE.Uniform(0),

    uPositionFrequency: new THREE.Uniform(0.2),
    uStrength: new THREE.Uniform(2.0),
    uWarpFrequency: new THREE.Uniform(5.0),
    uWarpStrength: new THREE.Uniform(0.5),

    uColorWaterDeep: new THREE.Uniform(
      new THREE.Color(debugObject.colorWaterDeep)
    ),
    uColorWaterSurface: new THREE.Uniform(
      new THREE.Color(debugObject.colorWaterSurface)
    ),
    uColorSand: new THREE.Uniform(new THREE.Color(debugObject.colorSand)),
    uColorGrass: new THREE.Uniform(new THREE.Color(debugObject.colorGrass)),
    uColorSnow: new THREE.Uniform(new THREE.Color(debugObject.colorSnow)),
    uColorRock: new THREE.Uniform(new THREE.Color(debugObject.colorRock)),
  };
  gui
    .add(uniforms.uPositionFrequency, "value", 0, 1, 0.001)
    .name("uPositionFrequency");
  gui.add(uniforms.uStrength, "value", 0, 10, 0.001).name("uStrength");
  gui
    .add(uniforms.uWarpFrequency, "value", 0, 10, 0.001)
    .name("uWarpFrequency");
  gui.add(uniforms.uWarpStrength, "value", 0, 1, 0.001).name("uWarpStrength");

  gui
    .addColor(debugObject, "colorWaterDeep")
    .onChange(() =>
      uniforms.uColorWaterDeep.value.set(debugObject.colorWaterDeep)
    );
  gui
    .addColor(debugObject, "colorWaterSurface")
    .onChange(() =>
      uniforms.uColorWaterSurface.value.set(debugObject.colorWaterSurface)
    );
  gui
    .addColor(debugObject, "colorSand")
    .onChange(() => uniforms.uColorSand.value.set(debugObject.colorSand));
  gui
    .addColor(debugObject, "colorGrass")
    .onChange(() => uniforms.uColorGrass.value.set(debugObject.colorGrass));
  gui
    .addColor(debugObject, "colorSnow")
    .onChange(() => uniforms.uColorSnow.value.set(debugObject.colorSnow));
  gui
    .addColor(debugObject, "colorRock")
    .onChange(() => uniforms.uColorRock.value.set(debugObject.colorRock));

  const material = new CustomShaderMaterial({
    //CSM
    baseMaterial: THREE.MeshStandardMaterial,
    vertexShader: terrainVertexShader,
    fragmentShader: terrainFragmentShader,
    uniforms,
    silent: true,

    // MeshStandarMaterial
    metalness: 0,
    roughness: 0.5,
    color: "#85d534",
  });
  const depthMaterial = new CustomShaderMaterial({
    //CSM
    baseMaterial: THREE.MeshDepthMaterial,
    vertexShader: terrainVertexShader,
    uniforms,
    silent: true,

    // MeshDepthMaterial
    depthPacking: THREE.RGBADepthPacking,
  });

  // Mesh
  const terrain = new THREE.Mesh(geometry, material);
  terrain.customDepthMaterial = depthMaterial;
  terrain.castShadow = true;
  terrain.receiveShadow = true;
  scene.add(terrain);

  /**
   * Water
   */
  const water = new THREE.Mesh(
    new THREE.PlaneGeometry(10, 10, 1, 1),
    new THREE.MeshPhysicalMaterial({
      transmission: 1,
      roughness: 0.3,
    })
  );
  water.rotation.x = -Math.PI * 0.5;
  water.position.y = -0.1;
  scene.add(water);

  /**
   * Board
   */
  // Brushes
  const boardFill = new Brush(new THREE.BoxGeometry(11, 2, 11));
  const boardHole = new Brush(new THREE.BoxGeometry(10, 2.1, 10));
  // boardHole.position.y = .2
  // boardHole.updateMatrixWorld()

  // Evaluate
  const evaluator = new Evaluator();
  const board = evaluator.evaluate(boardFill, boardHole, SUBTRACTION);
  board.geometry.clearGroups();
  board.material = new THREE.MeshStandardMaterial({
    color: "#ffffff",
    metalness: 0,
    roughness: 0.3,
  });
  board.castShadow = true;
  board.receiveShadow = true;
  scene.add(board);

  /**
   * Lights
   */
  const directionalLight = new THREE.DirectionalLight("#ffffff", 2);
  directionalLight.position.set(6.25, 3, 4);
  directionalLight.castShadow = true;
  directionalLight.shadow.mapSize.set(1024, 1024);
  directionalLight.shadow.camera.near = 0.1;
  directionalLight.shadow.camera.far = 30;
  directionalLight.shadow.camera.top = 8;
  directionalLight.shadow.camera.right = 8;
  directionalLight.shadow.camera.bottom = -8;
  directionalLight.shadow.camera.left = -8;
  scene.add(directionalLight);

  // 模型mesh==========================

  const axesHelper = new THREE.AxesHelper(5); //创建一个坐标轴辅助对象
  scene.add(axesHelper); //将坐标轴辅助对象添加到网格模型中

  /**
   * Camera
   */
  // Base camera
  camera = new THREE.PerspectiveCamera(
    35,
    sizes.width / sizes.height,
    0.1,
    100
  );
  camera.position.set(-10, 6, -2);
  scene.add(camera);

  // Controls
  controls = new OrbitControls(camera, webgl.value);
  controls.enableDamping = true;

  const clock = new THREE.Clock(); //创建一个时钟对象，用于计算时间差
  function render() {
    if (!camera || !renderer || !controls) return;

    const deltaTime = clock.getDelta();
    const elapsedTime = clock.elapsedTime; //获取自创建时钟以来的时间

    // Uniforms
    uniforms.uTime.value = elapsedTime;

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
