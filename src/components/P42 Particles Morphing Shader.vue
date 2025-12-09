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
import particlesVertexShader from "@/shaders/particles/vertex.glsl";
import particlesFragmentShader from "@/shaders/particles/fragment.glsl";

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
let modelFlightHelmet: THREE.Group | null = null;

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

  // 模型mesh==========================
  /**
   * Particles
   */
  let particles = null;
  // 3. 加载 Draco 压缩模型（路径指向 glTF-Draco 格式文件）
  gltfLoader.load(
    `${import.meta.env.BASE_URL}models/models.glb`,
    (gltf) => {
      // scene.add(gltf.scene);

      particles = {};
      particles.index = 0;

      // Positions
      const positions = gltf.scene.children.map(
        (child) => child.geometry.attributes.position
      );

      particles.maxCount = 0;
      for (const position of positions) {
        particles.maxCount = Math.max(particles.maxCount, position.count);
      }

      particles.positions = [];
      for (const position of positions) {
        const originalArray = position.array;
        const newArray = new Float32Array(particles.maxCount * 3);

        for (let index = 0; index < particles.maxCount; index++) {
          const i3 = index * 3;
          if (i3 < originalArray.length) {
            newArray[i3 + 0] = originalArray[i3 + 0];
            newArray[i3 + 1] = originalArray[i3 + 1];
            newArray[i3 + 2] = originalArray[i3 + 2];
          } else {
            const randomIndex = Math.floor(position.count * Math.random()) * 3;
            newArray[i3 + 0] = originalArray[randomIndex + 0];
            newArray[i3 + 1] = originalArray[randomIndex + 1];
            newArray[i3 + 2] = originalArray[randomIndex + 2];
          }
        }
        particles.positions.push(new THREE.Float32BufferAttribute(newArray, 3));
      }

      // Geometry
      const sizesArray = new Float32Array(particles.maxCount);

      for (let index = 0; index < particles.maxCount; index++) {
        sizesArray[index] = Math.random();
      }

      particles.geometry = new THREE.BufferGeometry();
      particles.geometry.setAttribute(
        "position",
        particles.positions[particles.index]
      );
      particles.geometry.setAttribute(
        "aPositionTarget",
        particles.positions[3]
      );
      particles.geometry.setAttribute(
        "aSize",
        new THREE.BufferAttribute(sizesArray, 1)
      );

      // Material
      particles.colorA = "#ff7300";
      particles.colorB = "#0091ff";
      particles.material = new THREE.ShaderMaterial({
        vertexShader: particlesVertexShader,
        fragmentShader: particlesFragmentShader,
        uniforms: {
          uSize: new THREE.Uniform(0.4),
          uResolution: new THREE.Uniform(
            new THREE.Vector2(
              sizes.width * sizes.pixelRatio,
              sizes.height * sizes.pixelRatio
            )
          ),
          uProgress: new THREE.Uniform(0),
          uColorA: new THREE.Uniform(new THREE.Color(particles.colorA)),
          uColorB: new THREE.Uniform(new THREE.Color(particles.colorB)),
        },
        blending: THREE.AdditiveBlending,
        depthWrite: false,
        // transparent: true,
      });

      // Points
      particles.points = new THREE.Points(
        particles.geometry,
        particles.material
      );
      particles.points.frustumCulled = false;
      scene.add(particles.points);

      // Methods
      particles.morph = (index) => {
        // Update attributes
        particles.geometry.attributes.position =
          particles.positions[particles.index];
        particles.geometry.attributes.aPositionTarget =
          particles.positions[index];

        // Animate uProgress
        gsap.fromTo(
          particles.material.uniforms.uProgress,
          { value: 0 },
          { value: 1, duration: 3, ease: "linear" }
        );

        // Save index
        particles.index = index;
      };

      particles.morph0 = () => {
        particles.morph(0);
      };
      particles.morph1 = () => {
        particles.morph(1);
      };
      particles.morph2 = () => {
        particles.morph(2);
      };
      particles.morph3 = () => {
        particles.morph(3);
      };

      // Tweaks
      gui
        .addColor(particles, "colorA")
        .onChange(() =>
          particles.material.uniforms.uColorA.value.set(particles.colorA)
        );
      gui
        .addColor(particles, "colorB")
        .onChange(() =>
          particles.material.uniforms.uColorB.value.set(particles.colorB)
        );
      gui
        .add(particles.material.uniforms.uProgress, "value", 0, 1, 0.001)
        .name("uProgress")
        .listen();

      gui.add(particles, "morph0");
      gui.add(particles, "morph1");
      gui.add(particles, "morph2");
      gui.add(particles, "morph3");
    }
    // 进度/错误回调同上
  );

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
  camera.position.set(0, 0, 8 * 2);
  scene.add(camera);

  // Controls
  controls = new OrbitControls(camera, webgl.value);
  controls.enableDamping = true;

  // 创建渲染器对象
  const rendererParameters = { clearColor: "#160920" };
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(sizes.width, sizes.height); //设置three.js渲染区域的尺寸(像素px)
  renderer.setPixelRatio(sizes.pixelRatio);
  renderer.setClearColor(rendererParameters.clearColor); //设置渲染器的背景颜色
  gui.addColor(rendererParameters, "clearColor").onChange(() => {
    renderer.setClearColor(rendererParameters.clearColor);
  });

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
