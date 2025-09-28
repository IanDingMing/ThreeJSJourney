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
// 导入自定义的纹理工具函数
import { getTextureUrl } from "@/utils/texturesUtils";
// 导入RectAreaLightHelper
import { RectAreaLightHelper } from "three/addons/helpers/RectAreaLightHelper.js";
import * as CANNON from "cannon-es";

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
// const environmentMapTexture = cubeTextureLoader.load([
// getTextureUrl("environmentMaps/0/px.jpg"),
// getTextureUrl("environmentMaps/0/nx.jpg"),
// getTextureUrl("environmentMaps/0/py.jpg"),
// getTextureUrl("environmentMaps/0/ny.jpg"),
// getTextureUrl("environmentMaps/0/pz.jpg"),
// getTextureUrl("environmentMaps/0/nz.jpg"),
// ]);

/**
 * Model
 */
// 1. 初始化加载器
const gltfLoader = new GLTFLoader();

// 2. 定义模型路径（支持 gltf/glb 等格式）
const modelPath = `${import.meta.env.BASE_URL}models/Duck/glTF-Binary/Duck.glb`; // 文件路径：/public/models/Duck

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

const mouse = new THREE.Vector2();
let currentIntersect: THREE.Intersection<THREE.Object3D> | null = null;

const mouseMoveEvent = (e: MouseEvent) => {
  mouse.x = (e.clientX / sizes.width) * 2 - 1;
  mouse.y = -(e.clientY / sizes.height) * 2 + 1;
};

const mouseClickEvenet = (e: MouseEvent) => {
  if (currentIntersect) {
    switch (currentIntersect.object) {
      case meshArray[0]:
        console.log("1");
        break;
      case meshArray[1]:
        console.log("2");
        break;
      case meshArray[2]:
        console.log("3");
        break;
      default:
        break;
    }
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
   * Objects
   */
  const object1 = new THREE.Mesh(
    new THREE.SphereGeometry(0.5, 16, 16),
    new THREE.MeshBasicMaterial({ color: "#ff0000" })
  );
  object1.position.x = -2;

  const object2 = new THREE.Mesh(
    new THREE.SphereGeometry(0.5, 16, 16),
    new THREE.MeshBasicMaterial({ color: "#ff0000" })
  );

  const object3 = new THREE.Mesh(
    new THREE.SphereGeometry(0.5, 16, 16),
    new THREE.MeshBasicMaterial({ color: "#ff0000" })
  );
  object3.position.x = 2;

  meshArray.push(object1, object2, object3);
  scene.add(object1, object2, object3);

  //   /**
  //    * Raycaster
  //    */
  //   const raycaster = new THREE.Raycaster();
  //   const rayOrgin = new THREE.Vector3(-3, 0, 0);
  //   const rayDirection = new THREE.Vector3(10, 0, 0);
  //   rayDirection.normalize();

  //   raycaster.set(rayOrgin, rayDirection);

  //   const intersect = raycaster.intersectObject(object2);
  //   console.log(intersect);

  //   /**
  //    * distance: 2.5
  // face: {a: 136, b: 153, c: 154, normal: _Vector3, materialIndex: 0}
  // faceIndex: 241
  // object: Mesh {isObject3D: true, uuid: 'f60c88f6-3191-452f-9c9d-d5573fef94d8', name: '', type: 'Mesh', parent: Scene, …}
  // point: _Vector3 {x: -0.5, y: 0, z: 0}
  // uv: _Vector2 {x: -1.9038029661559934e-19, y: 0.49999999999999994}
  //    */
  //   const intersects = raycaster.intersectObjects([object1, object2, object3]);
  //   console.log(intersects);

  // 3. 执行加载
  let model: THREE.Group | null = null;
  gltfLoader.load(
    modelPath,
    // 加载成功回调
    (gltf) => {
      // 关键：添加整个模型场景（含完整层级，避免漏元素）
      gltf.scene.position.y = -1.2;
      model = gltf.scene;
      scene.add(gltf.scene);
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
  /**
   * Lights
   */
  const ambientLight = new THREE.AmbientLight(0xffffff, 0.3); //创建环境光对象
  scene.add(ambientLight); //将环境光添加到场景中

  // 从上方照射的白色平行光，强度为 0.5。
  const directionalLight = new THREE.DirectionalLight(0xffffff, 0.7); //创建平行光对象
  directionalLight.position.set(1, 2, 3); //设置平行光位置
  scene.add(directionalLight); //将平行光添加到场景中

  const axesHelper = new THREE.AxesHelper(); //创建一个坐标轴辅助对象
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
  camera.position.z = 3;
  scene.add(camera);

  // Controls
  controls = new OrbitControls(camera, webgl.value);
  controls.target.set(0, 0.75, 0);
  controls.enableDamping = true;

  // 创建渲染器对象
  renderer = new THREE.WebGLRenderer();
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.setSize(sizes.width, sizes.height); //设置three.js渲染区域的尺寸(像素px)
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  // renderer.setClearColor(new THREE.Color("#262837")); //设置渲染器的背景颜色
  webgl.value!.appendChild(renderer.domElement);

  const clock = new THREE.Clock(); //创建一个时钟对象，用于计算时间差
  function render() {
    if (!camera || !renderer || !controls) return;

    const deltaTime = clock.getDelta();
    const elapsedTime = clock.getElapsedTime(); //获取自创建时钟以来的时间

    // Animater objects
    object1.position.y = Math.sin(elapsedTime * 0.3) * 1.5;
    object2.position.y = Math.sin(elapsedTime * 0.8) * 1.5;
    object3.position.y = Math.sin(elapsedTime * 1.3) * 1.5;

    // // Cast a ray
    // const raycaster = new THREE.Raycaster();
    // const rayOrgin = new THREE.Vector3(-3, 0, 0);
    // const rayDirection = new THREE.Vector3(1, 0, 0);
    // rayDirection.normalize();
    // raycaster.set(rayOrgin, rayDirection);

    // const objectToTest = [object1, object2, object3];
    // const intersects = raycaster.intersectObjects(objectToTest);
    // console.log(intersects.length);

    // objectToTest.forEach((object) => {
    //   object.material.color.set("#ff0000");
    // });

    // intersects.forEach((intersect) => {
    //   intersect.object.material.color.set("#0000ff");
    // });

    // Cast a ray
    const raycaster = new THREE.Raycaster();
    raycaster.setFromCamera(mouse, camera);

    const objectToTest = [object1, object2, object3];
    const intersects = raycaster.intersectObjects(objectToTest);

    objectToTest.forEach((object) => {
      object.material.color.set("#ff0000");
    });

    if (intersects[0]?.object instanceof THREE.Mesh) {
      (intersects[0].object.material as THREE.MeshBasicMaterial).color.set(
        0x0000ff
      );
    }
    intersects.forEach((intersect: THREE.Intersection) => {
      // if (intersect.object instanceof THREE.Mesh) {
      //   (intersect.object.material as THREE.MeshBasicMaterial).color.set(
      //     0x0000ff
      //   );
      // }
    });

    if (intersects.length) {
      currentIntersect = intersects[0];
    } else {
      currentIntersect = null;
    }

    //测试鸭子模型
    if (model) {
      const modelIntersects = raycaster.intersectObject(model);
      if (modelIntersects.length) {
        model.scale.set(1.2, 1.2, 1.2);
      } else {
        model.scale.set(1, 1, 1);
      }
    }

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
  <div class="container" @mousemove="mouseMoveEvent" @click="mouseClickEvenet">
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
