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
let material: THREE.Material | null = null;

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
   * Particles
   */
  // Grometry
  const particlesGeometry = new THREE.BufferGeometry();
  const count = 500;

  const position = new Float32Array(count * 3);
  const color = new Float32Array(count * 3);
  for (let index = 0; index < count; index++) {
    const i3 = index * 3;
    position[i3 + 0] = (Math.random() - 0.5) * 10;
    position[i3 + 1] = (Math.random() - 0.5) * 10;
    position[i3 + 2] = (Math.random() - 0.5) * 10;

    color[i3 + 0] = Math.random();
    color[i3 + 1] = Math.random();
    color[i3 + 2] = Math.random();
  }

  particlesGeometry.setAttribute(
    "position",
    new THREE.BufferAttribute(position, 3)
  );

  particlesGeometry.setAttribute("color", new THREE.BufferAttribute(color, 3));

  // Material
  const particlesMaterial = new THREE.PointsMaterial();
  particlesMaterial.size = 0.5;
  particlesMaterial.sizeAttenuation = true;
  // particlesMaterial.color = new THREE.Color("#ff0000");
  // particlesMaterial.map = particleTexture;
  particlesMaterial.transparent = true;
  particlesMaterial.alphaMap = particleTexture;
  // particlesMaterial.alphaTest = 0.001;
  // particlesMaterial.depthTest = false;
  particlesMaterial.depthWrite = false;
  particlesMaterial.blending = THREE.AdditiveBlending;
  particlesMaterial.vertexColors = true;

  // Points
  const particles = new THREE.Points(particlesGeometry, particlesMaterial);
  scene.add(particles);

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
    // particles.rotation.y = elapsedTime * 0.2;
    for (let index = 0; index < count; index++) {
      const i3 = index * 3;

      const x = particlesGeometry.attributes.position.array[i3];
      particlesGeometry.attributes.position.array[i3 + 1] = Math.sin(
        elapsedTime + x
      );
    }
    particlesGeometry.attributes.position.needsUpdate = true;

    controls.update();

    renderer.render(scene, camera); //执行渲染操作
    requestAnimationFrame(render); //请求再次执行函数render
  }
  render();

  // 添加事件监听
  window.addEventListener("resize", handleResize);

  const eventObj = {
    useAlphaMap: function () {
      if (!material) return;
      if (material.alphaMap) {
        material.alphaMap = null;
        console.log("移除alphaMap贴图");
      } else {
        material.alphaMap = doorAlphaTextures;
        console.log("添加alphaMap贴图");
      }
      material.needsUpdate = true; //更新材质
    },
    flatShading: function () {
      if (!material) return;
      if ((material as THREE.MeshPhongMaterial).flatShading) {
        (material as THREE.MeshPhongMaterial).flatShading = false;
        console.log("取消平面着色");
      } else {
        (material as THREE.MeshPhongMaterial).flatShading = true;
        console.log("开启平面着色");
      }
      material.needsUpdate = true; //更新材质
    },
  };

  // 创建GUI===================
  gui = new GUI();
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
  meshArray.forEach((mesh) => {
    mesh.geometry?.dispose();
    mesh.material?.dispose();
  });
  meshArray.length = 0; // 再清空数组
  material?.dispose();
  material = null;
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
