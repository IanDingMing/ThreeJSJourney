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

const bricksColorTextures = texturesLoader.load(
  getTextureUrl("bricks/color.jpg")
);
const bricksAmbientOcclusionTextures = texturesLoader.load(
  getTextureUrl("bricks/ambientOcclusion.jpg")
);
const bricksNormalTextures = texturesLoader.load(
  getTextureUrl("bricks/normal.jpg")
);
const bricksRoughnessTextures = texturesLoader.load(
  getTextureUrl("bricks/roughness.jpg")
);

const grassColorTextures = texturesLoader.load(
  getTextureUrl("grass/color.jpg")
);
const grassAmbientOcclusionTextures = texturesLoader.load(
  getTextureUrl("grass/ambientOcclusion.jpg")
);
const grassNormalTextures = texturesLoader.load(
  getTextureUrl("grass/normal.jpg")
);
const grassRoughnessTextures = texturesLoader.load(
  getTextureUrl("grass/roughness.jpg")
);

grassColorTextures.wrapS = THREE.RepeatWrapping; //设置纹理的水平重复方式
grassColorTextures.wrapT = THREE.RepeatWrapping; //设置纹理的垂直重复方式
grassColorTextures.repeat.set(8, 8); //设置纹理的重复
grassAmbientOcclusionTextures.wrapS = THREE.RepeatWrapping; //设置纹理的水平重复方式
grassAmbientOcclusionTextures.wrapT = THREE.RepeatWrapping; //设置纹理的垂直重复方式
grassAmbientOcclusionTextures.repeat.set(8, 8); //设置纹理的重复
grassNormalTextures.wrapS = THREE.RepeatWrapping; //设置纹理的水平重复方式
grassNormalTextures.wrapT = THREE.RepeatWrapping; //设置 纹理的垂直重复方式
grassNormalTextures.repeat.set(8, 8); //设置纹理的重复
grassRoughnessTextures.wrapS = THREE.RepeatWrapping; //设置纹理的水平重复方式
grassRoughnessTextures.wrapT = THREE.RepeatWrapping; //设置纹理的垂直重复方式
grassRoughnessTextures.repeat.set(8, 8); //设置纹理的重复

// 其他纹理加载
const matcapTextures = texturesLoader.load(getTextureUrl("matcaps/1.png"));
const gradientTextures = texturesLoader.load(getTextureUrl("gradients/3.jpg"));
gradientTextures.magFilter = THREE.NearestFilter; //设置纹理的缩放过滤器
gradientTextures.minFilter = THREE.NearestFilter; //设置纹理的缩放过滤器
gradientTextures.generateMipmaps = false; //设置纹理是否生成mipmap
const bakedShadowsTextures = texturesLoader.load(
  getTextureUrl("bakedShadow.jpg")
);
const simpleShadowTextures = texturesLoader.load(
  getTextureUrl("simpleShadow.jpg")
);

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
  // scene.background = new THREE.Color("#262837"); //设置场景背景颜色

  // Fog
  const fog = new THREE.Fog("#262837", 1, 15); //雾化效果
  scene.fog = fog; //将雾化效果添加到场景中

  // 模型mesh==========================
  material = new THREE.MeshStandardMaterial(); //标准网格材质，受光照影响
  material.roughness = 0.2; //设置材质的粗糙

  /**
   * House
   */
  // Group
  const house = new THREE.Group();
  scene.add(house); //将组添加到场景中
  // Wall
  const wall = new THREE.Mesh(
    new THREE.BoxGeometry(4, 2.5, 4), //立方体几何体
    new THREE.MeshStandardMaterial({
      // color: "#ac8e82", //设置立方体颜色
      map: bricksColorTextures, //设置立方体贴图
      aoMap: bricksAmbientOcclusionTextures, //设置立方体环境光遮蔽贴图
      normalMap: bricksNormalTextures, //设置立方体法线贴图
      roughnessMap: bricksRoughnessTextures, //设置立方体粗糙度贴图
    })
  );
  wall.geometry.setAttribute(
    "uv2",
    new THREE.Float32BufferAttribute(wall.geometry.attributes.uv.array, 2)
  ); //设置立方体UV坐标
  wall.position.y = 1.25; //设置立方体位置
  house.add(wall); //将立方体添加到组中
  // Roof
  const roof = new THREE.Mesh(
    new THREE.ConeGeometry(3.5, 1, 4), //圆锥几何体
    new THREE.MeshStandardMaterial({
      color: "#b35f45", //设置圆锥颜色
    })
  );
  roof.position.y = 2.5 + 0.5; //设置圆锥位置
  roof.rotation.y = Math.PI / 4; //将圆锥绕Y轴旋转45度
  house.add(roof); //将圆锥添加到组中
  // Door
  const door = new THREE.Mesh(
    new THREE.PlaneGeometry(2, 2, 100, 100), //平面几何体
    new THREE.MeshStandardMaterial({
      map: doorColorTextures, //设置平面贴图
      alphaMap: doorAlphaTextures, //设置平面透明贴图
      transparent: true, //开启透明度
      aoMap: doorAmbientOcclusionTextures, //设置平面环境光遮蔽贴图
      displacementMap: doorHeightTextures, //设置平面位移贴图
      displacementScale: 0.1, //设置平面位移缩放
      metalnessMap: doorMetalnessTextures, //设置平面金属度贴图
      roughnessMap: doorRoughnessTextures, //设置平面粗糙度贴图
      normalMap: doorNormalTextures, //设置平面法线贴图
      side: THREE.DoubleSide, //双面渲染
    })
  );
  door.geometry.setAttribute(
    "uv2",
    new THREE.Float32BufferAttribute(door.geometry.attributes.uv.array, 2)
  ); //设置平面UV坐标
  door.position.set(0, 1, 2 + 0.01); //设置平面位置
  house.add(door); //将平面添加到组中
  // Bushes
  const bushGeometry = new THREE.SphereGeometry(1, 16, 16);
  const bushMaterial = new THREE.MeshStandardMaterial({
    color: "#89c854", //设置球体颜色
  });
  const bush1 = new THREE.Mesh(bushGeometry, bushMaterial);
  bush1.scale.set(0.5, 0.5, 0.5); //缩放球体
  bush1.position.set(0.8, 0.2, 2.2); //设置球体位置
  const bush2 = new THREE.Mesh(bushGeometry, bushMaterial);
  bush2.scale.set(0.25, 0.25, 0.25); //缩放球体
  bush2.position.set(1.4, 0.1, 2.1); //设置球体位置
  const bush3 = new THREE.Mesh(bushGeometry, bushMaterial);
  bush3.scale.set(0.4, 0.4, 0.4); //缩放球体
  bush3.position.set(-0.8, 0.1, 2.2); //设置球体位置
  const bush4 = new THREE.Mesh(bushGeometry, bushMaterial);
  bush4.scale.set(0.15, 0.15, 0.15); //缩放球体
  bush4.position.set(-1, 0.05, 2.6); //设置球体位置
  house.add(bush1, bush2, bush3, bush4); //将球体添加到组中

  // Graves
  const graves = new THREE.Group(); //创建一个组用于存放墓碑
  scene.add(graves); //将组添加到场景中
  const graveGeometry = new THREE.BoxGeometry(0.6, 0.8, 0.2); //立方体几何体
  const graveMaterial = new THREE.MeshStandardMaterial({
    color: "#b2b6b1", //设置立方体颜色
  });
  for (let index = 0; index < 50; index++) {
    const angle = Math.random() * Math.PI * 2; //生成随机角度
    const radius = 3 + Math.random() * 6; //生成随机半径
    const x = Math.cos(angle) * radius; //计算X坐标
    const z = Math.sin(angle) * radius; //计算Z坐标

    const grave = new THREE.Mesh(graveGeometry, graveMaterial); //创建一个立方体网格模型
    grave.position.set(x, 0.3, z); //设置立方体位置
    grave.rotation.set(
      0,
      (Math.random() - 0.5) * 0.4,
      (Math.random() - 0.5) * 0.4
    ); //设置立方体旋转
    grave.castShadow = true; //设置立方体投射阴影
    graves.add(grave); //将立方体添加到组中
  }

  const floor = new THREE.Mesh(
    new THREE.PlaneGeometry(20, 20), //平面几何体
    new THREE.MeshStandardMaterial({
      // color: "#a9c388", //设置平面颜色
      map: grassColorTextures, //设置平面贴图
      aoMap: grassAmbientOcclusionTextures, //设置平面环境光遮蔽贴图
      normalMap: grassNormalTextures, //设置平面法线贴图
      roughnessMap: grassRoughnessTextures, //设置平面粗糙度贴图
    })
  );
  floor.geometry.setAttribute(
    "uv2",
    new THREE.Float32BufferAttribute(floor.geometry.attributes.uv.array, 2)
  ); //设置平面UV坐标
  floor.rotation.x = -Math.PI / 2; //将平面绕X轴旋转90度
  floor.position.y = 0; //设置平面位置
  scene.add(floor); //将平面添加到场景中

  // 模型mesh==========================

  const axesHelper = new THREE.AxesHelper(); //创建一个坐标轴辅助对象
  scene.add(axesHelper); //将坐标轴辅助对象添加到网格模型中

  // 添加灯光
  const ambientLight = new THREE.AmbientLight("#b9d5ff", 0.3); //创建环境光对象
  scene.add(ambientLight); //将环境光添加到场景中

  // Directional light
  const moonLight = new THREE.DirectionalLight("#b9d5ff", 0.12);
  moonLight.position.set(4, 5, -2);
  scene.add(moonLight);

  // Door light
  const doorLight = new THREE.PointLight("#ff7d46", 1, 7);

  doorLight.position.set(0, 2.2, 2.7);
  house.add(doorLight);

  // Ghosts
  const ghost1 = new THREE.PointLight("#ff00ff", 2, 3);
  const ghost2 = new THREE.PointLight("#00ffff", 2, 3);
  const ghost3 = new THREE.PointLight("#ffff00", 2, 3);
  scene.add(ghost1, ghost2, ghost3);

  // 实例化一个透视投影相机对象
  camera = new THREE.PerspectiveCamera(75, sizes.width / sizes.height, 1, 1000);
  camera.position.set(5, 5, 5);
  camera.lookAt(new THREE.Vector3(0, 0, 0)); //设置相机方向(指向的场景对象)

  // 创建渲染器对象
  renderer = new THREE.WebGLRenderer();
  renderer.setSize(sizes.width, sizes.height); //设置three.js渲染区域的尺寸(像素px)
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  renderer.setClearColor(new THREE.Color("#262837")); //设置渲染器的背景颜色
  webgl.value!.appendChild(renderer.domElement);

  // Shadow
  renderer.shadowMap.enabled = true; //开启渲染器的阴影贴图
  renderer.shadowMap.type = THREE.PCFSoftShadowMap; //设置阴影贴图类型

  wall.castShadow = true; //设置立方体投射阴影
  bush1.castShadow = true; //设置球体投射阴影
  bush2.castShadow = true; //设置球体投射阴影
  bush3.castShadow = true; //设置球体投射阴影
  bush4.castShadow = true; //设置球体投射阴影
  ghost1.castShadow = true;
  ghost2.castShadow = true;
  ghost3.castShadow = true;
  moonLight.castShadow = true;
  doorLight.castShadow = true;

  wall.receiveShadow = true; //设置立方体接收阴影
  floor.receiveShadow = true; //设置平面接收阴影

  moonLight.shadow.mapSize.width = 256;
  moonLight.shadow.mapSize.height = 256;
  moonLight.shadow.camera.far = 15;
  doorLight.shadow.mapSize.width = 256;
  doorLight.shadow.mapSize.height = 256;
  doorLight.shadow.camera.far = 7;

  controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true; // 添加惯性效果

  const clock = new THREE.Clock(); //创建一个时钟对象，用于计算时间差
  function render() {
    if (!camera || !renderer || !controls) return;

    const elapsedTime = clock.getElapsedTime(); //获取自创建时钟以来的时间差

    // Update ghost
    ghost1.position.set(
      Math.sin(elapsedTime * 0.5) * 4,
      Math.sin(elapsedTime * 3),
      Math.cos(elapsedTime * 0.5) * 4
    );
    ghost2.position.set(
      Math.sin(elapsedTime * 0.32) * 5,
      Math.sin(elapsedTime * 2.5) + Math.sin(elapsedTime * 4),
      Math.cos(elapsedTime * 0.32) * 5
    );
    ghost3.position.set(
      Math.sin(elapsedTime * 0.18) * (6 + Math.sin(elapsedTime * 0.32)),
      Math.sin(elapsedTime * 5) + Math.sin(elapsedTime * 2),
      Math.cos(elapsedTime * 0.18) * (6 + Math.sin(elapsedTime * 0.5))
    );

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
