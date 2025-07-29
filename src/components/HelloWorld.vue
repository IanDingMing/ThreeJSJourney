<script setup lang="ts">
import { ref, useTemplateRef, onMounted } from "vue";
import * as THREE from "three";
import gsap from "gsap";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";

defineProps<{ msg: string }>();
const sizes = {
  width: 800,
  height: 600,
};
const webgl = useTemplateRef("webgl");
onMounted(() => {
  // console.log(webgl, webgl.value?.clientHeight, webgl.value?.clientWidth);
  sizes.width = webgl.value!.clientWidth;
  sizes.height = webgl.value!.clientHeight;

  function handleResize() {
    if (!webgl.value) return; // 防止 webgl.value 为 null 时报错
    sizes.width = webgl.value.clientWidth;
    sizes.height = webgl.value.clientHeight;
    camera.aspect = sizes.width / sizes.height;
    camera.updateProjectionMatrix();
    renderer.setSize(sizes.width, sizes.height);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  }
  function handleDoubleClick() {
    const fullscreenElement =
      document.fullscreenElement ||
      (document as any).webkitFullscreenElement ||
      (document as any).mozFullScreenElement;
    // 如果当前不是全屏状态，则请求全屏，否则退出全屏
    if (!fullscreenElement) {
      webgl.value!.requestFullscreen();
    } else {
      document.exitFullscreen();
    }
  }
  // 监听浏览器窗口大小变化事件
  window.addEventListener("resize", handleResize);
  //监听双击事件全屏
  window.addEventListener("dblclick", handleDoubleClick);

  // 创建3D场景对象Scene
  const scene = new THREE.Scene();

  const mesh = new THREE.Mesh(
    new THREE.BoxGeometry(1, 1, 1), //创建一个立方体几何体
    new THREE.MeshBasicMaterial({ color: 0xff0000 }) //创建一个红色材质
  );
  scene.add(mesh); //将立方体添加到组对象中

  const axesHelper = new THREE.AxesHelper(); //创建一个坐标轴辅助对象
  scene.add(axesHelper); //将坐标轴辅助对象添加到网格模型中

  // 实例化一个透视投影相机对象
  const camera = new THREE.PerspectiveCamera(
    75,
    sizes.width / sizes.height,
    1,
    1000
  );
  camera.position.set(2, 2, 2);
  camera.lookAt(mesh.position); //设置相机观察的目标点

  // 创建渲染器对象
  const renderer = new THREE.WebGLRenderer();
  renderer.setSize(sizes.width, sizes.height); //设置three.js渲染区域的尺寸(像素px)
  webgl.value!.appendChild(renderer.domElement);

  const controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true; // 添加惯性效果

  const clock = new THREE.Clock(); //创建一个时钟对象，用于计算时间差
  function render() {
    const elapsedTime = clock.getElapsedTime(); //获取自创建时钟以来的时间差
    // mesh.rotation.y = elapsedTime; //让立方体绕y轴旋转

    controls.update();

    renderer.render(scene, camera); //执行渲染操作
    requestAnimationFrame(render); //请求再次执行函数render
  }
  render();
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
  background-color: #f00; /* 设置背景颜色为黑色 */
}
</style>
