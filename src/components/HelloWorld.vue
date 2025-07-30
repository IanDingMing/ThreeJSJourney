<script setup lang="ts">
import { ref, useTemplateRef, onMounted, onUnmounted } from "vue";
import * as THREE from "three";
import gsap from "gsap";
// 导入OrbitControls
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
// 导入lil.gui
import { GUI } from "three/addons/libs/lil-gui.module.min.js";

defineProps<{ msg: string }>();
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

  const parentMaterial = new THREE.MeshBasicMaterial({
    color: 0x00ff00,
    wireframe: false, // 设置父元素的线框模式
  });
  const mesh = new THREE.Mesh(
    new THREE.BoxGeometry(1, 1, 1, 4, 4, 4), //创建一个立方体几何体，长宽高的可分段数都为4
    parentMaterial //使用父元素的材质);
  );
  scene.add(mesh); //将立方体添加到组对象中

  const axesHelper = new THREE.AxesHelper(); //创建一个坐标轴辅助对象
  scene.add(axesHelper); //将坐标轴辅助对象添加到网格模型中

  // 实例化一个透视投影相机对象
  camera = new THREE.PerspectiveCamera(75, sizes.width / sizes.height, 1, 1000);
  camera.position.set(2, 2, 2);
  camera.lookAt(mesh.position); //设置相机观察的目标点

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
    // mesh.rotation.y = elapsedTime; //让立方体绕y轴旋转

    controls.update();

    renderer.render(scene, camera); //执行渲染操作
    requestAnimationFrame(render); //请求再次执行函数render
  }
  render();

  // 添加事件监听
  window.addEventListener("resize", handleResize);
  window.addEventListener("dblclick", handleDoubleClick);

  const eventObj = {
    Fullscreen: function () {
      document.body.requestFullscreen();
    },
    ExitFullscreen: function () {
      document.exitFullscreen();
    },
    Spin: function () {
      gsap.to(mesh.rotation, {
        duration: 1,
        y: mesh.rotation.y + Math.PI * 2,
        ease: "power1.inOut",
      });
    },
  };

  // 创建GUI===================
  gui = new GUI();
  // 添加按钮
  gui.add(eventObj, "Fullscreen").name("全屏");
  gui.add(eventObj, "ExitFullscreen").name("退出全屏");
  gui.add(eventObj, "Spin").name("旋转一周");
  // 控制立方体的位置
  const folder = gui.addFolder("立方体位置");
  // gui.add(mesh.position, 'x', -5, 5).step(1).name('x轴位置')
  folder
    .add(mesh.position, "x")
    .min(-10)
    .max(10)
    .step(1)
    .name("x轴位置")
    .onChange(function (value) {
      console.log("位置", value);
    });
  folder
    .add(mesh.position, "y")
    .min(-10)
    .max(10)
    .step(1)
    .name("y轴位置")
    .onFinishChange(function (value) {
      console.log("结束", value);
    });
  folder.add(mesh.position, "z").min(-10).max(10).step(1).name("z轴位置");
  1;
  gui.add(parentMaterial, "wireframe").name("父元素线框模式");

  const colorParams = {
    meshColor: "#00ff00",
  };
  gui
    .addColor(colorParams, "meshColor")
    .name("立方体颜色")
    .onChange(function (value) {
      mesh.material.color.set(value);
    });
  // 创建GUI===================
});
// 组件卸载时移除事件监听
onUnmounted(() => {
  // 移除事件监听
  window.removeEventListener("resize", handleResize);
  window.removeEventListener("dblclick", handleDoubleClick);
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
});
</script>

<template>
  <!-- <h1>{{ msg }}</h1> -->
  <div ref="webgl" class="webgl"></div>
</template>

<style scoped>
.webgl {
  width: 100vw;
  height: 100vh;
  background-color: #f00;
}
</style>
