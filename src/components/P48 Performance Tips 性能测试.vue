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
import terrainVertexShader from "@/shaders/terrain/vertex.glsl";
import terrainFragmentShader from "@/shaders/terrain/fragment.glsl";
import gpgpuParticlesShader from "@/shaders/gpgpu/particles.glsl";
import displacementMapPath from "@/assets/textures/displacementMap.png";

/**
 * Stats
 */
const stats = new Stats();
stats.showPanel(0);
document.body.appendChild(stats.dom);

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
const displacementTexture = texturesLoader.load(displacementMapPath);

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

  // 创建渲染器对象
  const rendererParameters = { clearColor: "#29191f" };
  renderer = new THREE.WebGLRenderer({
    powerPreference: "high-performance", // 电源模式
    antialias: true,
  });
  renderer.setSize(sizes.width, sizes.height); //设置three.js渲染区域的尺寸(像素px)
  renderer.setPixelRatio(sizes.pixelRatio);
  renderer.setClearColor(rendererParameters.clearColor); //设置渲染器的背景颜色
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;

  webgl.value!.appendChild(renderer.domElement);

  // 模型mesh==========================
  /**
   * Test meshes
   */
  const cube = new THREE.Mesh(
    new THREE.BoxGeometry(2, 2, 2),
    new THREE.MeshStandardMaterial()
  );
  cube.castShadow = true;
  cube.receiveShadow = true;
  cube.position.set(-5, 0, 0);
  // scene.add(cube);

  const torusKnot = new THREE.Mesh(
    new THREE.TorusKnotGeometry(1, 0.4, 128, 32),
    new THREE.MeshStandardMaterial()
  );
  torusKnot.castShadow = true;
  torusKnot.receiveShadow = true;
  // scene.add(torusKnot);

  const sphere = new THREE.Mesh(
    new THREE.SphereGeometry(1, 32, 32),
    new THREE.MeshStandardMaterial()
  );
  sphere.position.set(5, 0, 0);
  sphere.castShadow = true;
  sphere.receiveShadow = true;
  // scene.add(sphere);

  const floor = new THREE.Mesh(
    new THREE.PlaneGeometry(10, 10),
    new THREE.MeshStandardMaterial()
  );
  floor.position.set(0, -2, 0);
  floor.rotation.x = -Math.PI * 0.5;
  floor.castShadow = true;
  floor.receiveShadow = true;
  // scene.add(floor);

  /**
   * Lights
   */
  const directionalLight = new THREE.DirectionalLight("#ffffff", 3);
  directionalLight.castShadow = true;
  directionalLight.shadow.mapSize.set(1024, 1024);
  directionalLight.shadow.camera.far = 15;
  directionalLight.shadow.normalBias = 0.05;
  directionalLight.position.set(0.25, 3, 2.25);
  // scene.add(directionalLight);
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
  camera.position.set(2, 2, 6);
  scene.add(camera);

  // Controls
  controls = new OrbitControls(camera, webgl.value);
  controls.enableDamping = true;

  const clock = new THREE.Clock(); //创建一个时钟对象，用于计算时间差
  function render() {
    stats.begin();
    if (!camera || !renderer || !controls) return;

    const deltaTime = clock.getDelta();
    const elapsedTime = clock.elapsedTime; //获取自创建时钟以来的时间

    // Update test mesh
    torusKnot.rotation.y = elapsedTime * 0.1;

    // Animate meshes
    meshArray.forEach((mesh) => {});

    // Update controls
    controls.update();

    renderer.render(scene, camera); //执行渲染操作
    requestAnimationFrame(render); //请求再次执行函数render
    stats.end();
  }
  render();

  /**
   * Tips
   */

  // // Tip 4
  // console.log(renderer.info)

  // // Tip 6
  // scene.remove(cube)
  // cube.geometry.dispose()
  // cube.material.dispose()

  // // Tip 10
  // directionalLight.shadow.camera.top = 3
  // directionalLight.shadow.camera.right = 6
  // directionalLight.shadow.camera.left = - 6
  // directionalLight.shadow.camera.bottom = - 3
  // directionalLight.shadow.camera.far = 10
  // directionalLight.shadow.mapSize.set(1024, 1024)

  // const cameraHelper = new THREE.CameraHelper(directionalLight.shadow.camera)
  // scene.add(cameraHelper)

  // // Tip 11
  // cube.castShadow = true
  // cube.receiveShadow = false

  // torusKnot.castShadow = true
  // torusKnot.receiveShadow = false

  // sphere.castShadow = true
  // sphere.receiveShadow = false

  // floor.castShadow = false
  // floor.receiveShadow = true

  // // Tip 12
  // renderer.shadowMap.autoUpdate = false
  // renderer.shadowMap.needsUpdate = true

  // // Tip 18
  // const geometry = new THREE.BoxGeometry(0.5, 0.5, 0.5)
  // const material = new THREE.MeshNormalMaterial()

  // for(let i = 0; i < 50; i++)
  // {
  //     const mesh = new THREE.Mesh(geometry, material)
  //     mesh.position.x = (Math.random() - 0.5) * 10
  //     mesh.position.y = (Math.random() - 0.5) * 10
  //     mesh.position.z = (Math.random() - 0.5) * 10
  //     mesh.rotation.x = (Math.random() - 0.5) * Math.PI * 2
  //     mesh.rotation.y = (Math.random() - 0.5) * Math.PI * 2

  //     scene.add(mesh)
  // }

  // // Tip 19
  // const geometries = []

  // for(let i = 0; i < 50; i++)
  // {
  //     const geometry = new THREE.BoxGeometry(0.5, 0.5, 0.5)

  //     geometry.rotateX((Math.random() - 0.5) * Math.PI * 2)
  //     geometry.rotateY((Math.random() - 0.5) * Math.PI * 2)

  //     geometry.translate(
  //         (Math.random() - 0.5) * 10,
  //         (Math.random() - 0.5) * 10,
  //         (Math.random() - 0.5) * 10
  //     )

  //     geometries.push(geometry)
  // }

  // const mergedGeometry = BufferGeometryUtils.mergeBufferGeometries(geometries)
  // const material = new THREE.MeshNormalMaterial()
  // const mesh = new THREE.Mesh(mergedGeometry, material)
  // scene.add(mesh)

  // // Tip 22
  // const geometry = new THREE.BoxGeometry(0.5, 0.5, 0.5)
  // const material = new THREE.MeshNormalMaterial()

  // const mesh = new THREE.InstancedMesh(geometry, material, 50)
  // mesh.instanceMatrix.setUsage(THREE.DynamicDrawUsage)
  // scene.add(mesh)

  // for(let i = 0; i < 50; i++)
  // {
  //     const position = new THREE.Vector3(
  //         (Math.random() - 0.5) * 10,
  //         (Math.random() - 0.5) * 10,
  //         (Math.random() - 0.5) * 10
  //     )

  //     const quaternion = new THREE.Quaternion()
  //     quaternion.setFromEuler(new THREE.Euler(
  //         (Math.random() - 0.5) * Math.PI * 2,
  //         (Math.random() - 0.5) * Math.PI * 2,
  //         0
  //     ))

  //     const matrix = new THREE.Matrix4()
  //     matrix.makeRotationFromQuaternion(quaternion)
  //     matrix.setPosition(position)
  //     mesh.setMatrixAt(i, matrix)
  // }

  // // Tip 29
  // renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))

  // // Tip 31, 32, 34 and 35
  // const shaderGeometry = new THREE.PlaneGeometry(10, 10, 256, 256)

  // const shaderMaterial = new THREE.ShaderMaterial({
  //     uniforms:
  //     {
  //         uDisplacementTexture: { value: displacementTexture },
  //         uDisplacementStrength: { value: 1.5 }
  //     },
  //     vertexShader: `
  //         uniform sampler2D uDisplacementTexture;
  //         uniform float uDisplacementStrength;

  //         varying vec2 vUv;

  //         void main()
  //         {
  //             vec4 modelPosition = modelMatrix * vec4(position, 1.0);

  //             float elevation = texture2D(uDisplacementTexture, uv).r;
  //             if(elevation < 0.5)
  //             {
  //                 elevation = 0.5;
  //             }

  //             modelPosition.y += elevation * uDisplacementStrength;

  //             gl_Position = projectionMatrix * viewMatrix * modelPosition;

  //             vUv = uv;
  //         }
  //     `,
  //     fragmentShader: `
  //         uniform sampler2D uDisplacementTexture;

  //         varying vec2 vUv;

  //         void main()
  //         {
  //             float elevation = texture2D(uDisplacementTexture, vUv).r;
  //             if(elevation < 0.25)
  //             {
  //                 elevation = 0.25;
  //             }

  //             vec3 depthColor = vec3(1.0, 0.1, 0.1);
  //             vec3 surfaceColor = vec3(0.1, 0.0, 0.5);
  //             vec3 finalColor = vec3(0.0);
  //             finalColor.r += depthColor.r + (surfaceColor.r - depthColor.r) * elevation;
  //             finalColor.g += depthColor.g + (surfaceColor.g - depthColor.g) * elevation;
  //             finalColor.b += depthColor.b + (surfaceColor.b - depthColor.b) * elevation;

  //             gl_FragColor = vec4(finalColor, 1.0);
  //         }
  //     `
  // })

  // const shaderMesh = new THREE.Mesh(shaderGeometry, shaderMaterial)
  // shaderMesh.rotation.x = - Math.PI * 0.5
  // scene.add(shaderMesh)

  // Tip 31, 32, 34 and 35 new
  const shaderGeometry = new THREE.PlaneGeometry(10, 10, 256, 256);

  const shaderMaterial = new THREE.ShaderMaterial({
    precision: "lowp",
    uniforms: {
      uDisplacementTexture: { value: displacementTexture },
    },
    defines: {
      DISPLACMENT_STRENGH: 1.5,
    },
    vertexShader: `
        uniform sampler2D uDisplacementTexture;

        varying vec3 vColor;

        void main()
        {
            // Position
            vec4 modelPosition = modelMatrix * vec4(position, 1.0);
            float elevation = texture2D(uDisplacementTexture, uv).r;
            modelPosition.y += max(elevation, 0.5) * DISPLACMENT_STRENGH;
            gl_Position = projectionMatrix * viewMatrix * modelPosition;

            // Color
            float colorElevation = max(elevation, 0.25);
            vec3 color = mix(vec3(1.0, 0.1, 0.1), vec3(0.1, 0.0, 0.5), colorElevation);

            // Varying
            vColor = color;
        }
    `,
    fragmentShader: `
        varying vec3 vColor;

        void main()
        {
            gl_FragColor = vec4(vColor, 1.0);
        }
    `,
  });

  const shaderMesh = new THREE.Mesh(shaderGeometry, shaderMaterial);
  shaderMesh.rotation.x = -Math.PI * 0.5;
  scene.add(shaderMesh);

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
