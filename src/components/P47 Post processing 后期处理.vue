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
import pxEnvironmentMapsPath from "@/assets/textures/environmentMaps/0/px.jpg";
import nxEnvironmentMapsPath from "@/assets/textures/environmentMaps/0/nx.jpg";
import pyEnvironmentMapsPath from "@/assets/textures/environmentMaps/0/py.jpg";
import nyEnvironmentMapsPath from "@/assets/textures/environmentMaps/0/ny.jpg";
import pzEnvironmentMapsPath from "@/assets/textures/environmentMaps/0/pz.jpg";
import nzEnvironmentMapsPath from "@/assets/textures/environmentMaps/0/nz.jpg";
import interfaceNormalMapPath from "@/assets/textures/interfaceNormalMap.png";

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
let effectComposer: EffectComposer | null = null;
let controls: OrbitControls | null = null;
const gui: GUI = new GUI();
const meshArray: THREE.Mesh[] = [];
const global = { envMapIntensity: 2.5 };
let model: THREE.Group | null = null;

// 2. 声明事件处理函数
const handleResize = () => {
  if (!webgl.value || !camera || !renderer || !effectComposer) return;

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

  // Update renderer composer
  effectComposer.setSize(sizes.width, sizes.height);
  effectComposer.setPixelRatio(sizes.pixelRatio);

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
// 加载立方体贴图
const cubeTextureLoader = new THREE.CubeTextureLoader(loadingManager);
const environmentMap = cubeTextureLoader.load([
  pxEnvironmentMapsPath,
  nxEnvironmentMapsPath,
  pyEnvironmentMapsPath,
  nyEnvironmentMapsPath,
  pzEnvironmentMapsPath,
  nzEnvironmentMapsPath,
]);

// 1. 初始化加载器
const gltfLoader = new GLTFLoader();

// 2. 定义模型路径（支持 gltf/glb 等格式）
const modelPath = `${
  import.meta.env.BASE_URL
}models/DamagedHelmet/glTF/DamagedHelmet.gltf`; // 文件路径：/public/models/Duck

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
  // console.log(webgl, webgl.value?.clientHeight, webgl.value?.clientWidth);
  sizes.width = webgl.value!.clientWidth;
  sizes.height = webgl.value!.clientHeight;

  // 创建3D场景对象Scene
  const scene = new THREE.Scene();
  // scene.background = new THREE.Color("#262837"); //设置场景背景颜色
  // 设置为场景背景
  scene.background = environmentMap;
  scene.environment = environmentMap;

  // 创建渲染器对象
  const rendererParameters = { clearColor: "#29191f" };
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(sizes.width, sizes.height); //设置three.js渲染区域的尺寸(像素px)
  renderer.setPixelRatio(sizes.pixelRatio);
  renderer.setClearColor(rendererParameters.clearColor); //设置渲染器的背景颜色
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  // renderer.outputEncoding = THREE.sRGBEncoding;
  renderer.toneMapping = THREE.ReinhardToneMapping;
  renderer.toneMappingExposure = 1.5;

  webgl.value!.appendChild(renderer.domElement);

  // 模型mesh==========================
  // 3. 执行加载
  gltfLoader.load(
    modelPath,
    // 加载成功回调
    (gltf) => {
      gltf.scene.scale.set(2, 2, 2);
      gltf.scene.rotation.y = Math.PI * 0.5;
      scene.add(gltf.scene);

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

  /**
   * Lights
   */
  const directionalLight = new THREE.DirectionalLight("#ffffff", 3);
  directionalLight.castShadow = true;
  directionalLight.shadow.mapSize.set(1024, 1024);
  directionalLight.shadow.camera.far = 15;
  directionalLight.shadow.normalBias = 0.05;
  directionalLight.position.set(0.25, 3, -2.25);
  scene.add(directionalLight);
  // 模型mesh==========================

  const axesHelper = new THREE.AxesHelper(5); //创建一个坐标轴辅助对象
  scene.add(axesHelper); //将坐标轴辅助对象添加到网格模型中

  /**
   * Camera
   */
  // Base camera
  camera = new THREE.PerspectiveCamera(
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

  /**
   * Post processing
   */
  // Render target
  const renderTarget = new THREE.WebGLRenderTarget(800, 600, {
    samples: renderer.getPixelRatio() === 1 ? 2 : 0,
  });
  effectComposer = new EffectComposer(renderer, renderTarget);
  effectComposer.setSize(sizes.width, sizes.height); //设置three.js渲染区域的尺寸(像素px)
  effectComposer.setPixelRatio(sizes.pixelRatio);

  const renderPass = new RenderPass(scene, camera);
  effectComposer.addPass(renderPass);

  // 报纸特效
  const dotScreenPass = new DotScreenPass();
  dotScreenPass.enabled = false;
  effectComposer.addPass(dotScreenPass);

  // 电脑入侵特效
  const glitchPass = new GlitchPass();
  glitchPass.goWild = false;
  glitchPass.enabled = false;
  effectComposer.addPass(glitchPass);

  // 炫光特效
  const rgbShiftPass = new ShaderPass(RGBShiftShader);
  rgbShiftPass.enabled = false;
  effectComposer.addPass(rgbShiftPass);

  // 天堂光
  // strength 光强
  // radius 光范围
  // threshold 最小值
  const unrealBloomPass = new UnrealBloomPass();
  unrealBloomPass.strength = 0.3;
  unrealBloomPass.radius = 1;
  unrealBloomPass.threshold = 0.6;
  effectComposer.addPass(unrealBloomPass);
  gui.add(unrealBloomPass, "enabled");
  gui.add(unrealBloomPass, "strength", 0, 2, 0.001);
  gui.add(unrealBloomPass, "radius", 0, 2, 0.001);
  gui.add(unrealBloomPass, "threshold", 0, 1, 0.001);

  // Tint pass 色调
  const TintShader = {
    uniforms: {
      tDiffuse: { value: null },
      uTint: { value: null },
    },
    vertexShader: `
      varying vec2 vUv;

      void main(){
        gl_Position = projectionMatrix *modelViewMatrix * vec4 (position,1);

        vUv = uv;
      }
    `,
    fragmentShader: `
      uniform sampler2D tDiffuse;
      uniform vec3 uTint;

      varying vec2 vUv;

      void main(){
        vec4 color = texture2D(tDiffuse, vUv);
        color.rgb += uTint;
        // color.b += .1;
        gl_FragColor = color;
      }
    `,
  };
  const tintPass = new ShaderPass(TintShader);
  tintPass.material.uniforms.uTint.value = new THREE.Vector3();
  effectComposer.addPass(tintPass);
  gui
    .add(tintPass.material.uniforms.uTint.value, "x", -1, 1, 0.001)
    .name("red");
  gui
    .add(tintPass.material.uniforms.uTint.value, "y", -1, 1, 0.001)
    .name("green");
  gui
    .add(tintPass.material.uniforms.uTint.value, "z", -1, 1, 0.001)
    .name("blue");

  // Displacement pass 自定义后期处理
  const DisplacementShader = {
    uniforms: {
      tDiffuse: { value: null },
      uTime: { value: null },
      uNormalMap: { value: null },
    },
    vertexShader: `
      varying vec2 vUv;

      void main(){
        gl_Position = projectionMatrix *modelViewMatrix * vec4 (position,1);

        vUv = uv;
      }
    `,
    fragmentShader: `
      uniform sampler2D tDiffuse;
      uniform float uTime;
      uniform sampler2D uNormalMap;

      varying vec2 vUv;

      void main(){
        // vec2 newUv = vUv;
        // newUv.y += .5;

        // vec2 newUv = vec2(
        //   vUv.x,
        //   vUv.y + sin(vUv.x * 10.0 + uTime) * .1
        // );

        vec3 normalColor = texture2D(uNormalMap, vUv).xyz * 2.0 - 1.0;
        vec2 newUv = vUv + normalColor.xy * .1;

        vec4 color = texture2D(tDiffuse, newUv);

        vec3 lightDirection = normalize(vec3(-1.0,1.0,.0));
        float lightness = clamp(dot(normalColor, lightDirection), .0, 1.0);
        color.rgb += lightness * 2.0;

        gl_FragColor = color;
      }
    `,
  };
  const displacementPass = new ShaderPass(DisplacementShader);
  displacementPass.material.uniforms.uTime.value = 0;
  displacementPass.material.uniforms.uNormalMap.value = texturesLoader.load(
    interfaceNormalMapPath
  );
  effectComposer.addPass(displacementPass);

  // SMAA pass
  if (renderer.getPixelRatio() === 1 && !renderer.capabilities.isWebGL2) {
    const smaaPass = new SMAAPass();
    effectComposer.addPass(smaaPass);
    console.log("Using SMAA");
  }

  // Gamma Correction pass  伽马校正，没有这个画面会暗
  const gammaCorrectionPass = new ShaderPass(GammaCorrectionShader);
  effectComposer.addPass(gammaCorrectionPass);

  const clock = new THREE.Clock(); //创建一个时钟对象，用于计算时间差
  function render() {
    if (!camera || !renderer || !controls) return;

    const deltaTime = clock.getDelta();
    const elapsedTime = clock.elapsedTime; //获取自创建时钟以来的时间

    // Update passes
    displacementPass.material.uniforms.uTime.value = elapsedTime;

    // Animate meshes
    meshArray.forEach((mesh) => {});

    // Update controls
    controls.update();

    // renderer.render(scene, camera); //执行渲染操作
    effectComposer.render();
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
