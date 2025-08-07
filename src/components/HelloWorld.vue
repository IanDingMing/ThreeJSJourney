<script setup lang="ts">
import { ref, useTemplateRef, onMounted, onUnmounted } from "vue";
import * as THREE from "three";
import gsap from "gsap";
// 导入OrbitControls
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
// 导入lil.gui
import { GUI } from "three/addons/libs/lil-gui.module.min.js";
import { color, log } from "three/tsl";

// 使用TextureLoader加载纹理
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
const cubeTextureLoader = new THREE.CubeTextureLoader(loadingManager);
// 加载纹理
const doorColorTextures = texturesLoader.load("/textures/door/color.jpg");
const doorAlphaTextures = texturesLoader.load("/textures/door/alpha.jpg");
const doorHeightTextures = texturesLoader.load("/textures/door/height.jpg");
const doorNormalTextures = texturesLoader.load("/textures/door/normal.jpg");
const doorAmbientOcclusionTextures = texturesLoader.load(
  "/textures/door/ambientOcclusion.jpg"
);
const doorMetalnessTextures = texturesLoader.load(
  "/textures/door/metalness.jpg"
);
const doorRoughnessTextures = texturesLoader.load(
  "/textures/door/roughness.jpg"
);
// 其他纹理加载
const matcapTextures = texturesLoader.load("/textures/matcaps/1.png");
const gradientTextures = texturesLoader.load("/textures/gradients/3.jpg");
gradientTextures.magFilter = THREE.NearestFilter; //设置纹理的缩放过滤器
gradientTextures.minFilter = THREE.NearestFilter; //设置纹理的缩放过滤器
gradientTextures.generateMipmaps = false; //设置纹理是否生成mipmap

// 环境贴图
const environmentMapTexture = cubeTextureLoader.load([
  "/textures/environmentMaps/0/px.jpg",
  "/textures/environmentMaps/0/nx.jpg",
  "/textures/environmentMaps/0/py.jpg",
  "/textures/environmentMaps/0/ny.jpg",
  "/textures/environmentMaps/0/pz.jpg",
  "/textures/environmentMaps/0/nz.jpg",
]);

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

  // 模型mesh==========================
  // material = new THREE.MeshBasicMaterial();
  // material.map = doorColorTextures;
  // // material.color = new THREE.Color(0xff0000);
  // // material.wireframe = true;
  // material.side = THREE.DoubleSide; //两面可见
  // material.transparent = true; //开启透明度
  // // material.opacity = 0.5; //设置透明度
  // material.alphaMap = doorAlphaTextures; //设置透明贴图,使用时必须开启透明度

  // material = new THREE.MeshNormalMaterial(); //法线网格材质
  // material.flatShading = true; //定义材质是否使用平面着色进行渲染。默认值为false。

  // material = new THREE.MeshMatcapMaterial(); //matcap网格材质，模拟光照材质，即不需要光照就有真实的材质效果
  // material.matcap = matcapTextures; //设置matcap贴图

  // material = new THREE.MeshDepthMaterial(); //深度网格材质，最直接的例子模拟雾气

  // material = new THREE.MeshLambertMaterial(); //朗伯网格材质，非金属材质，受光照影响

  // material = new THREE.MeshPhongMaterial(); //Phong网格材质，金属材质，受光照影响
  // material.shininess = 100; //设置材质的光泽度
  // material.specular = new THREE.Color(0xff0000); //设置材质的高光颜色

  // material = new THREE.MeshToonMaterial(); //标准网格材质，受光照影响
  // /**
  //  * 设置卡通着色的渐变贴图。使用此类纹理时，需要将Texture.minFilterTexture.minFilter
  //  * 和Texture.magFilterTexture.magFilter设置为THREE.NearestFilter。默认为空。
  //  */
  // material.gradientMap = gradientTextures;

  // material = new THREE.MeshStandardMaterial(); //标准网格材质，受光照影响
  // material.metalness = 0.5; //设置材质的金属度
  // material.roughness = 0.5; //设置材质的粗糙
  // material.map = doorColorTextures; //设置颜色贴图
  // material.aoMap = doorAmbientOcclusionTextures; //设置环境光遮蔽贴图
  // material.aoMapIntensity = 1; //设置环境光遮蔽贴图强度
  // material.displacementMap = doorHeightTextures; //设置位移贴图
  // material.displacementScale = 0.1; //设置位移贴图缩放
  // material.metalnessMap = doorMetalnessTextures; //设置金属贴图
  // material.roughnessMap = doorRoughnessTextures; //设置粗糙贴图
  // material.normalMap = doorNormalTextures; //设置法线贴图
  // material.normalScale.set(0.5, 0.5); //设置法线贴图缩放
  // material.transparent = true; //开启透明度
  // material.alphaMap = doorAlphaTextures; //设置透明贴图,使用时必须开启透明度

  material = new THREE.MeshStandardMaterial(); //标准网格材质，受光照影响
  material.metalness = 0.7; //设置材质的金属度
  material.roughness = 0.2; //设置材质的粗糙
  material.envMap = environmentMapTexture; //设置环境贴图

  const sphereGeometry = new THREE.SphereGeometry(0.5, 64, 64);
  const sphere = new THREE.Mesh(sphereGeometry, material);
  sphere.position.x = -1.5;
  meshArray.push(sphere);
  scene.add(sphere);

  const planeGeometry = new THREE.PlaneGeometry(1, 1, 100, 100);
  const plane = new THREE.Mesh(planeGeometry, material);
  plane.geometry.setAttribute(
    "uv2",
    new THREE.BufferAttribute(planeGeometry.attributes.uv.array, 2)
  ); //设置uv2属性，用于环境光遮蔽贴图
  meshArray.push(plane);
  scene.add(plane);

  const torusGeometry = new THREE.TorusGeometry(0.3, 0.2, 16, 100);
  const torus = new THREE.Mesh(torusGeometry, material);
  torus.position.x = 1.5;
  meshArray.push(torus);
  scene.add(torus);

  // 模型mesh==========================

  const axesHelper = new THREE.AxesHelper(); //创建一个坐标轴辅助对象
  scene.add(axesHelper); //将坐标轴辅助对象添加到网格模型中

  // 添加灯光
  const ambientLight = new THREE.AmbientLight(0xffffff, 0.5); //创建环境光对象
  scene.add(ambientLight); //将环境光添加到场景中
  const pointLight = new THREE.PointLight(0xffffff, 0.5); //创建点光源对象
  pointLight.position.set(2, 3, 4); //设置点光源位置
  scene.add(pointLight); //将点光源添加到场景中

  // 实例化一个透视投影相机对象
  camera = new THREE.PerspectiveCamera(75, sizes.width / sizes.height, 1, 1000);
  camera.position.set(2, 2, 2);
  camera.lookAt(new THREE.Vector3(0, 0, 0)); //设置相机方向(指向的场景对象)

  // 创建渲染器对象
  renderer = new THREE.WebGLRenderer();
  renderer.setSize(sizes.width, sizes.height); //设置three.js渲染区域的尺寸(像素px)
  webgl.value!.appendChild(renderer.domElement);

  controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true; // 添加惯性效果

  const clock = new THREE.Clock(); //创建一个时钟对象，用于计算时间差
  function render() {
    if (!camera || !renderer || !controls) return;

    const elapsedTime = clock.getElapsedTime(); //获取自创建时钟以来的时间差
    meshArray.forEach((mesh) => {
      // mesh.rotation.x = elapsedTime * 0.1; //设置网格模型的旋转角度
      // mesh.rotation.y = elapsedTime * 0.15; //设置网格模型的旋转角度
    });
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
  gui.add(eventObj, "useAlphaMap").name("alphaMap贴图");
  gui.add(eventObj, "flatShading").name("开启平面着色");
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
