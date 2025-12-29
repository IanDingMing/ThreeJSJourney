<script setup lang="ts">
import { ref, useTemplateRef, onMounted, onUnmounted } from "vue";
import * as THREE from "three";
import gsap from "gsap";
import Stats from "stats.js";
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
// 后期处理
import { EffectComposer } from "three/examples/jsm/postprocessing/EffectComposer.js";
import { RenderPass } from "three/examples/jsm/postprocessing/RenderPass.js";
import { DotScreenPass } from "three/examples/jsm/postprocessing/DotScreenPass.js";
import { GlitchPass } from "three/examples/jsm/postprocessing/GlitchPass.js";
import { ShaderPass } from "three/examples/jsm/postprocessing/ShaderPass.js";
import { RGBShiftShader } from "three/examples/jsm/shaders/RGBShiftShader.js";
import { GammaCorrectionShader } from "three/examples/jsm/shaders/GammaCorrectionShader.js";
import { UnrealBloomPass } from "three/examples/jsm/postprocessing/UnrealBloomPass";
import { SMAAPass } from "three/examples/jsm/postprocessing/SMAAPass.js";
import * as BufferGeometryUtils from "three/examples/jsm/utils/BufferGeometryUtils.js";
// 导入自定义的纹理工具函数
import { getTextureUrl } from "@/utils/texturesUtils";
// 导入RectAreaLightHelper
import { RectAreaLightHelper } from "three/addons/helpers/RectAreaLightHelper.js";
import { GPUComputationRenderer } from "three/addons/misc/GPUComputationRenderer.js";
import { mergeVertices } from "three/addons/utils/BufferGeometryUtils.js";
import * as CANNON from "cannon-es";
import firefliesVertexShader from "@/shaders/fireflies/vertex.glsl";
import firefliesFragmentShader from "@/shaders/fireflies/fragment.glsl";
import portalVertexShader from "@/shaders/portal/vertex.glsl";
import portalFragmentShader from "@/shaders/portal/fragment.glsl";
import gpgpuParticlesShader from "@/shaders/gpgpu/particles.glsl";
import pxEnvironmentMapsPath from "@/assets/textures/environmentMaps/0/px.jpg";
import nxEnvironmentMapsPath from "@/assets/textures/environmentMaps/0/nx.jpg";
import pyEnvironmentMapsPath from "@/assets/textures/environmentMaps/0/py.jpg";
import nyEnvironmentMapsPath from "@/assets/textures/environmentMaps/0/ny.jpg";
import pzEnvironmentMapsPath from "@/assets/textures/environmentMaps/0/pz.jpg";
import nzEnvironmentMapsPath from "@/assets/textures/environmentMaps/0/nz.jpg";

/**
 * 性能监控
 */
const stats = new Stats();
stats.showPanel(0);
document.body.appendChild(stats.dom);

/**
 * 尺寸配置
 */
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

/**
 * DOM引用
 */
const webgl = useTemplateRef("webgl");
const loadingBar = useTemplateRef("loadingBar");
const htmlOverlay = useTemplateRef("htmlOverlay");

/**
 * 全局变量声明
 */
let camera: THREE.PerspectiveCamera | null = null;
let renderer: THREE.WebGLRenderer | null = null;
let effectComposer: EffectComposer | null = null;
let controls: OrbitControls | null = null;
const gui: GUI = new GUI();
const meshArray: THREE.Mesh[] = [];
const global = { envMapIntensity: 2.5 };
let model: THREE.Group | null = null;

/**
 * 事件处理函数
 */
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
 * Update all materials
 */
const updateAllMaterials = (scene: THREE.Scene) => {
  scene.traverse((child) => {
    if (
      child instanceof THREE.Mesh &&
      child.material instanceof THREE.MeshStandardMaterial
    ) {
      child.material.envMapIntensity = global.envMapIntensity;
      child.material.needsUpdate = true;
      child.castShadow = true;
      child.receiveShadow = true;
    }
  });
};

onMounted(() => {
  // 1. 获取容器尺寸
  // console.log(webgl, webgl.value?.clientHeight, webgl.value?.clientWidth);
  sizes.width = webgl.value!.clientWidth;
  sizes.height = webgl.value!.clientHeight;

  // 2. 创建场景
  const scene = new THREE.Scene();
  // scene.background = new THREE.Color("#262837"); //设置场景背景颜色

  // 3. 创建渲染器
  const rendererParameters = { clearColor: "#201919" };
  renderer = new THREE.WebGLRenderer({
    powerPreference: "high-performance", // 电源模式
    antialias: true,
  });
  renderer.setSize(sizes.width, sizes.height); //设置three.js渲染区域的尺寸(像素px)
  renderer.setPixelRatio(sizes.pixelRatio);
  renderer.setClearColor(rendererParameters.clearColor); //设置渲染器的背景颜色
  // renderer.shadowMap.enabled = true;
  // renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  // renderer.toneMapping = THREE.ReinhardToneMapping;
  // renderer.toneMappingExposure = 3;
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  webgl.value!.appendChild(renderer.domElement);
  gui.addColor(rendererParameters, "clearColor").onChange(() => {
    renderer.setClearColor(rendererParameters.clearColor);
  });

  // 4. 创建加载管理器
  let sceneReady = false;
  const loadingManager = new THREE.LoadingManager();
  loadingManager.onStart = () => {
    console.log("Loading started");
  };
  loadingManager.onLoad = () => {
    console.log("Loading complete");
    // Wait a little
    setTimeout(() => {
      // 使用 gsap 淡出 HTML 幕布
      if (htmlOverlay.value) {
        gsap.to(htmlOverlay.value, {
          duration: 3,
          opacity: 0,
          delay: 1,
          onComplete: () => {
            // 淡出完成后可以移除元素或保持隐藏
            htmlOverlay.value.style.display = "none";
          },
        });
      }

      // 更新 loadingBarElement
      loadingBar.value.classList.add("ended");
      loadingBar.value.style.transform = "";
    }, 500);

    setTimeout(() => {
      sceneReady = true;
    }, 2000);
  };
  loadingManager.onProgress = (url, itemsLoaded, itemsTotal) => {
    console.log(
      `Loading file: ${url}. Loaded ${itemsLoaded} of ${itemsTotal} files.`
    );
    // 计算进度并更新
    const progressRatio = itemsLoaded / itemsTotal;
    loadingBar.value.style.transform = `scaleX(${progressRatio})`;
  };
  loadingManager.onError = (url) => {
    console.log(`There was an error loading ${url}`);
  };

  // 5. 创建加载器（使用同一个loadingManager）
  const texturesLoader = new THREE.TextureLoader(loadingManager);
  const rgbeLoader = new RGBELoader(loadingManager);
  const cubeTextureLoader = new THREE.CubeTextureLoader(loadingManager);
  const gltfLoader = new GLTFLoader(loadingManager);

  // 6. 加载环境贴图
  // const environmentMap = cubeTextureLoader.load([
  //   pxEnvironmentMapsPath,
  //   nxEnvironmentMapsPath,
  //   pyEnvironmentMapsPath,
  //   nyEnvironmentMapsPath,
  //   pzEnvironmentMapsPath,
  //   nzEnvironmentMapsPath,
  // ]);
  // environmentMap.colorSpace = THREE.SRGBColorSpace;
  // scene.background = environmentMap;
  // scene.environment = environmentMap;

  // 模型mesh==========================
  /**
   * Textures
   */
  const bakedTexture = texturesLoader.load(
    `${import.meta.env.BASE_URL}models/portal/baked.jpg`
  );
  bakedTexture.flipY = false;
  bakedTexture.colorSpace = THREE.SRGBColorSpace;

  /**
   * Materials
   */
  const bakedMaterial = new THREE.MeshBasicMaterial({ map: bakedTexture });

  // Portal light material
  const debugObject = {
    portalColorStart: "#000000",
    portalColorEnd: "#ffffff",
  };
  const portalLightMaterial = new THREE.ShaderMaterial({
    uniforms: {
      uTime: { value: 0 },
      uColorStart: { value: new THREE.Color(debugObject.portalColorStart) },
      uColorEnd: { value: new THREE.Color(debugObject.portalColorEnd) },
    },
    vertexShader: portalVertexShader,
    fragmentShader: portalFragmentShader,
  });
  gui.addColor(debugObject, "portalColorStart").onChange(() => {
    portalLightMaterial.uniforms.uColorStart.value.set(
      debugObject.portalColorStart
    );
  });
  gui.addColor(debugObject, "portalColorEnd").onChange(() => {
    portalLightMaterial.uniforms.uColorEnd.value.set(
      debugObject.portalColorEnd
    );
  });

  // Pole light material
  const poleLightMaterial = new THREE.MeshBasicMaterial({ color: 0xffcb90 });

  // 7. 加载3D模型
  const modelPath = `${import.meta.env.BASE_URL}models/portal/portal.glb`; // 文件路径：/public/models/Duck
  gltfLoader.load(
    modelPath,
    // 加载成功回调
    (gltf) => {
      const bakedMesh = gltf.scene.children.find(
        (child) => child.name === "baked"
      );
      const portalLightMesh = gltf.scene.children.find(
        (child) => child.name === "portalLight"
      );
      const poleLightAMesh = gltf.scene.children.find(
        (child) => child.name === "poleLightA"
      );
      const poleLightBMesh = gltf.scene.children.find(
        (child) => child.name === "poleLightB"
      );

      bakedMesh.material = bakedMaterial;
      poleLightAMesh.material = poleLightMaterial;
      poleLightBMesh.material = poleLightMaterial;
      portalLightMesh.material = portalLightMaterial;

      console.log(gltf.scene);
      scene.add(gltf.scene);

      // updateAllMaterials(gltf.scene);
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

  /**
   * FireFlies
   */
  // Geometry
  const firefliesGometry = new THREE.BufferGeometry();
  const firefilesCount = 30;
  const positionArray = new Float32Array(firefilesCount * 3);
  const scaleArray = new Float32Array(firefilesCount * 1);

  for (let i = 0; i < firefilesCount; i++) {
    positionArray[i * 3 + 0] = (Math.random() - 0.5) * 4;
    positionArray[i * 3 + 1] = Math.random() * 1.5;
    positionArray[i * 3 + 2] = (Math.random() - 0.5) * 4;

    scaleArray[i] = Math.random();
  }

  firefliesGometry.setAttribute(
    "position",
    new THREE.BufferAttribute(positionArray, 3)
  );
  firefliesGometry.setAttribute(
    "aScale",
    new THREE.BufferAttribute(scaleArray, 1)
  );

  // Material
  const firefliesMaterial = new THREE.ShaderMaterial({
    uniforms: {
      uTime: { value: 0 },
      uPixelRatio: { value: sizes.pixelRatio },
      uSize: { value: 100 },
    },
    vertexShader: firefliesVertexShader,
    fragmentShader: firefliesFragmentShader,
    transparent: true,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
  });
  gui
    .add(firefliesMaterial.uniforms.uSize, "value", 0, 500, 1)
    .name("firefliesSize");

  // Points
  const fireflies = new THREE.Points(firefliesGometry, firefliesMaterial);
  scene.add(fireflies);

  // 模型mesh==========================
  // 8. 创建相机
  camera = new THREE.PerspectiveCamera(
    45,
    sizes.width / sizes.height,
    0.1,
    100
  );
  camera.position.x = 4;
  camera.position.y = 2;
  camera.position.z = 4;
  scene.add(camera);

  // 9. 创建控制器
  controls = new OrbitControls(camera, webgl.value);
  controls.enableDamping = true;

  // 10. 添加灯光
  // const directionalLight = new THREE.DirectionalLight("#ffffff", 3);
  // directionalLight.castShadow = true;
  // directionalLight.shadow.camera.far = 15;
  // directionalLight.shadow.mapSize.set(1024, 1024);
  // directionalLight.shadow.normalBias = 0.05;
  // directionalLight.position.set(0.25, 3, -2.25);
  // scene.add(directionalLight);

  // 11. 添加辅助工具
  const axesHelper = new THREE.AxesHelper(5); //创建一个坐标轴辅助对象
  scene.add(axesHelper); //将坐标轴辅助对象添加到网格模型中

  // 12. 动画循环
  const clock = new THREE.Clock(); //创建一个时钟对象，用于计算时间差
  function render() {
    stats.begin();
    if (!camera || !renderer || !controls) return;

    const deltaTime = clock.getDelta();
    const elapsedTime = clock.elapsedTime; //获取自创建时钟以来的时间

    // Update material
    firefliesMaterial.uniforms.uTime.value = elapsedTime;
    portalLightMaterial.uniforms.uTime.value = elapsedTime;

    // Animate meshes
    meshArray.forEach((mesh) => {});

    // Update controls
    controls.update();

    renderer.render(scene, camera); //执行渲染操作
    requestAnimationFrame(render); //请求再次执行函数render
    stats.end();
  }
  render();

  // 13. 添加事件监听
  window.addEventListener("resize", handleResize);
});

/**
 * 组件卸载
 */
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
    <div ref="loadingBar" class="loading-bar"></div>
    <div ref="htmlOverlay" class="html-overlay"></div>
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

.loading-bar {
  position: absolute;
  top: 50%;
  width: 100%;
  height: 2px;
  background: #ffffff;
  transform: scaleX(0.3);
  transform-origin: top left;
  transition: transform 0.5s;
  z-index: 1003; /* 在幕布之上 */
}

.loading-bar.ended {
  transform: scaleX(0);
  transform-origin: 100% 0;
  transition: transform 1.5s ease-in-out;
}

/* HTML 幕布样式 */
.html-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background-color: #000000;
  opacity: 1; /* 初始完全显示 */
  z-index: 1002; /* 在 Three.js 画布之上 li.gui是z-index:1001*/
  pointer-events: none; /* 允许点击穿透到 Three.js 画布 */
}

.point {
  position: absolute;
  top: 50%;
  left: 50%;
  /* pointer-events: none; */
}

.point .label {
  position: absolute;
  top: -20px;
  left: -20px;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: #00000077;
  border: 1px solid #ffffff77;
  color: #ffffff;
  font-family: Helvetica, Arial, sans-serif;
  text-align: center;
  line-height: 40px;
  font-weight: 100;
  font-size: 14px;
  cursor: help;
  transform: scale(0, 0);
  transition: transform 0.3s;
}

.point .text {
  position: absolute;
  top: 30px;
  left: -120px;
  width: 200px;
  padding: 20px;
  border-radius: 4px;
  background: #00000077;
  border: 1px solid #ffffff77;
  color: #ffffff;
  line-height: 1.3em;
  font-family: Helvetica, Arial, sans-serif;
  font-weight: 100;
  font-size: 14px;
  opacity: 0;
  transition: opacity 0.3s;
  pointer-events: none;
}

.point:hover .text {
  opacity: 1;
}

.point.visible .label {
  transform: scale(1, 1);
}
</style>
