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
const doorColorTextures = texturesLoader.load(getTextureUrl("door/color.jpg"));
const doorAlphaTextures = texturesLoader.load(getTextureUrl("door/alpha.jpg"));
const doorHeightTextures = texturesLoader.load(
  getTextureUrl("door/height.jpg")
);
const doorNormalTextures = texturesLoader.load(
  getTextureUrl("door/normal.jpg")
);
const doorAmbientOcclusionTextures = texturesLoader.load(
  getTextureUrl("door/ambientOcclusion.jpg")
);
const doorMetalnessTextures = texturesLoader.load(
  getTextureUrl("door/metalness.jpg")
);
const doorRoughnessTextures = texturesLoader.load(
  getTextureUrl("door/roughness.jpg")
);
// 其他纹理加载
const matcapTextures = texturesLoader.load(getTextureUrl("matcaps/1.png"));
const gradientTextures = texturesLoader.load(getTextureUrl("gradients/3.jpg"));
gradientTextures.magFilter = THREE.NearestFilter; //设置纹理的缩放过滤器
gradientTextures.minFilter = THREE.NearestFilter; //设置纹理的缩放过滤器
gradientTextures.generateMipmaps = false; //设置纹理是否生成mipmap

// 环境贴图
const environmentMapTexture = cubeTextureLoader.load([
  getTextureUrl("environmentMaps/0/px.jpg"),
  getTextureUrl("environmentMaps/0/nx.jpg"),
  getTextureUrl("environmentMaps/0/py.jpg"),
  getTextureUrl("environmentMaps/0/ny.jpg"),
  getTextureUrl("environmentMaps/0/pz.jpg"),
  getTextureUrl("environmentMaps/0/nz.jpg"),
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
  material = new THREE.MeshStandardMaterial(); //标准网格材质，受光照影响
  material.roughness = 0.2; //设置材质的粗糙

  const sphereGeometry = new THREE.SphereGeometry(0.5, 32, 32);
  const sphere = new THREE.Mesh(sphereGeometry, material);
  sphere.castShadow = true; //设置网格模型是否投射阴影
  meshArray.push(sphere);
  scene.add(sphere);

  const planeGeometry = new THREE.PlaneGeometry(5, 5);
  const plane = new THREE.Mesh(planeGeometry, material);
  plane.rotation.x = -Math.PI * 0.5; //将平面旋转90度
  plane.position.y = -0.5;
  plane.receiveShadow = true; //设置网格模型是否接收阴影
  scene.add(plane);
  // 模型mesh==========================

  const axesHelper = new THREE.AxesHelper(); //创建一个坐标轴辅助对象
  scene.add(axesHelper); //将坐标轴辅助对象添加到网格模型中

  // 添加灯光
  const ambientLight = new THREE.AmbientLight(0xffffff, 0.3); //创建环境光对象
  scene.add(ambientLight); //将环境光添加到场景中
  // 从上方照射的白色平行光，强度为 0.5。
  const directionalLight = new THREE.DirectionalLight(0xffffff, 0.3); //创建平行光对象

  directionalLight.castShadow = true; //设置平行光是否投射阴影
  directionalLight.shadow.mapSize.width = 1024; //设置阴影贴图的宽度，默认是512，影响阴影的清晰度
  directionalLight.shadow.mapSize.height = 1024; //设置阴影贴图的高度，默认是512，影响阴影的清晰度
  directionalLight.shadow.camera.near = 1; //设置阴影相机的近裁剪面
  directionalLight.shadow.camera.far = 6; //设置阴影相机的远裁剪面
  directionalLight.shadow.camera.left = -2; //设置阴影相机的左侧边界
  directionalLight.shadow.camera.right = 2; //设置阴影相机的右侧边界
  directionalLight.shadow.camera.top = 2; //设置阴影相机的上侧边界
  directionalLight.shadow.camera.bottom = -2; //设置阴影相机的下侧边界
  directionalLight.shadow.radius = 10; //设置阴影模糊半径

  directionalLight.position.set(2, 2, -1); //设置平行光位置
  scene.add(directionalLight); //将平行光添加到场景中
  // 半球光，参数1：天空颜色 参数2：地面颜色 参数3：光照强度
  const hemisphereLight = new THREE.HemisphereLight(0xff0000, 0x0000ff, 0);
  scene.add(hemisphereLight); //添加半球光
  // 点光源，参数1：光的颜色 参数2：光照强度 参数3：光照距离(范围) 参数4：衰减程度
  const pointLight = new THREE.PointLight(0xffffff, 0.3);
  pointLight.castShadow = true; //设置点光源是否投射阴影
  pointLight.shadow.mapSize.width = 1024; //设置阴影贴图的宽度，默认是512，影响阴影的清晰度
  pointLight.shadow.mapSize.height = 1024; //设置阴影贴图的高度，默认是512，影响阴影的清晰度
  pointLight.shadow.camera.near = 0.1; //设置阴影相机的近裁剪面
  pointLight.shadow.camera.far = 5; //设置阴影相机的远
  pointLight.position.set(-1, 1, 0);
  scene.add(pointLight);

  // 矩形区域光，参数1：光的颜色 参数2：光照强度 参数3：光照宽度 参数4：光照高度
  const rectLight = new THREE.RectAreaLight(0x4e00ff, 0, 1, 1);
  rectLight.position.set(-1.5, 0, 1.5);
  rectLight.lookAt(0, 0, 0);
  scene.add(rectLight);
  // 聚光灯，参数1：光的颜色 参数2：光照强度 参数3：光照距离(范围) 参数4：光照角度(弧度) 参数5：边缘衰减程度 参数6：光照衰减程度
  const spotLight = new THREE.SpotLight(0xffffff, 0.3, 10, Math.PI * 0.3);

  spotLight.castShadow = true; //设置聚光灯是否投射阴影
  spotLight.shadow.mapSize.width = 1024; //设置阴影贴图的宽度，默认是512，影响阴影的清晰度
  spotLight.shadow.mapSize.height = 1024; //设置阴影贴图的高度，默认是512，影响阴影的清晰度
  spotLight.shadow.camera.near = 1; //设置阴影相机的近裁剪面
  spotLight.shadow.camera.far = 6; //设置阴影相机的远裁剪面
  spotLight.shadow.camera.fov = 30; //设置阴影相机的视野角度

  spotLight.position.set(0, 2, 2);
  scene.add(spotLight);

  // 灯光非常消耗性能，所以在项目中尽量少用灯光，使用烘焙就是一个很好的解决办法，把光的信息事先烘焙到纹理中。
  // Helper
  let hideHelpers = false; // 是否隐藏灯光辅助对象
  const directionalLightHelper = new THREE.DirectionalLightHelper(
    directionalLight,
    0.2
  );
  directionalLightHelper.visible = hideHelpers; // 设置是否显示平行光辅助对象
  scene.add(directionalLightHelper);
  const hemisphereLightHelper = new THREE.HemisphereLightHelper(
    hemisphereLight,
    0.1
  );
  hemisphereLightHelper.visible = hideHelpers; // 设置是否显示半球光辅助对象
  scene.add(hemisphereLightHelper);
  const pointLightHelper = new THREE.PointLightHelper(pointLight, 0.2);
  pointLightHelper.visible = hideHelpers; // 设置是否显示点光源辅助对象
  scene.add(pointLightHelper);
  const rectLightHelper = new RectAreaLightHelper(rectLight);
  rectLightHelper.visible = hideHelpers; // 设置是否显示矩形区域光辅助对象
  scene.add(rectLightHelper);
  const spotLightHelper = new THREE.SpotLightHelper(spotLight);
  spotLightHelper.visible = hideHelpers;
  scene.add(spotLightHelper);

  const directionalLightShadowCameraHelper = new THREE.CameraHelper(
    directionalLight.shadow.camera
  );
  directionalLightShadowCameraHelper.visible = true; // 设置是否显示平行光阴影相机辅助对象
  scene.add(directionalLightShadowCameraHelper);
  const spotLightShadowCameraHelper = new THREE.CameraHelper(
    spotLight.shadow.camera
  );
  spotLightShadowCameraHelper.visible = false; // 设置是否显示聚光灯阴影相机辅助对象
  scene.add(spotLightShadowCameraHelper);
  const pointLightShadowCameraHelper = new THREE.CameraHelper(
    pointLight.shadow.camera
  );
  pointLightShadowCameraHelper.visible = false; // 设置是否显示点光源阴影相机辅助对象
  scene.add(pointLightShadowCameraHelper);

  // 实例化一个透视投影相机对象
  camera = new THREE.PerspectiveCamera(75, sizes.width / sizes.height, 1, 1000);
  camera.position.set(2, 2, 2);
  camera.lookAt(new THREE.Vector3(0, 0, 0)); //设置相机方向(指向的场景对象)

  // 创建渲染器对象
  renderer = new THREE.WebGLRenderer();
  renderer.setSize(sizes.width, sizes.height); //设置three.js渲染区域的尺寸(像素px)
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  renderer.shadowMap.enabled = true; //开启阴影
  // renderer.shadowMap.type = THREE.PCFSoftShadowMap; //设置阴影类型
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
    hideHelpers: function () {
      hideHelpers = !hideHelpers;
      directionalLightHelper.visible = hideHelpers;
      hemisphereLightHelper.visible = hideHelpers;
      pointLightHelper.visible = hideHelpers;
      rectLightHelper.visible = hideHelpers;
      spotLightHelper.visible = hideHelpers;
    },
  };

  // 创建GUI===================
  gui = new GUI();
  // 添加按钮
  // gui.add(eventObj, "hideHelpers").name("隐藏灯光辅助对象");
  // gui?.add(pointLight, "intensity", 0, 2, 0.01).name("点光源强度");
  // gui?.add(pointLight, "distance", 0, 20, 0.1).name("点光源距离");
  // gui?.add(pointLight, "decay", 0, 5, 0.01).name("点光源衰减");
  // gui.add(ambientLight, "intensity", 0, 2, 0.001).name("环境光强度");
  gui.add(directionalLight, "intensity", 0, 2, 0.01).name("平行光强度");
  gui.add(directionalLight.position, "x", -5, 5, 0.01).name("平行光X位置");
  gui.add(directionalLight.position, "y", -5, 5, 0.01).name("平行光Y位置");
  gui.add(directionalLight.position, "z", -5, 5, 0.01).name("平行光Z位置");
  gui.add(directionalLight, "castShadow").name("平行光投射阴影");
  gui
    .add(directionalLight.shadow.mapSize, "width", 0, 1024 * 3, 512)
    .name("平行光阴影贴图宽度");
  gui
    .add(directionalLight.shadow.mapSize, "height", 0, 1024 * 3, 512)
    .name("平行光阴影贴图高度");
  // 由于阴影偏移量比较小，所以步长设置为0.0001
  gui
    .add(directionalLight.shadow, "bias", -0.01, 0.01, 0.0001)
    .name("平行光阴影偏移");
  gui
    .add(directionalLight.shadow, "radius", 0, 10, 0.1)
    .name("平行光阴影模糊半径");
  gui
    .add(directionalLight.shadow, "normalBias", 0, 1, 0.001)
    .name("平行光阴影法线偏移");
  // gui.add(hemisphereLight, "intensity", 0, 2, 0.01).name("半球光强度");
  // gui.add(rectLight, "intensity", 0, 5, 0.01).name("矩形区域光强度");
  // gui.add(spotLight, "intensity", 0, 2, 0.01).name("聚光灯强度");
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
