<script setup lang="ts">
import { ref, useTemplateRef, onMounted } from "vue";
import * as THREE from "three";
import gsap from "gsap";

defineProps<{ msg: string }>();
const sizes = {
  width: 800,
  height: 600,
};
const webgl = useTemplateRef("webgl");
onMounted(() => {
  // console.log(webgl);
  // 用 style 设置 div 的宽高
  webgl.value!.style.width = sizes.width + "px";
  webgl.value!.style.height = sizes.height + "px";

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
  const camera = new THREE.PerspectiveCamera(75, sizes.width / sizes.height);

  //相机在Three.js三维坐标系中的位置
  // 根据需要设置相机位置具体值
  camera.position.set(0, 0, 3);
  // camera.lookAt(0, 0, 0); // 让相机向下看向原点

  // 创建渲染器对象
  const renderer = new THREE.WebGLRenderer();
  renderer.setSize(sizes.width, sizes.height); //设置three.js渲染区域的尺寸(像素px)
  webgl.value!.appendChild(renderer.domElement);

  // requestAnimationFrame实现周期性循环执行
  gsap.to(mesh.position, {
    x: 2,
    duration: 1,
    delay: 1,
    ease: "none",
  });
  gsap.to(mesh.position, {
    x: 0,
    duration: 1,
    delay: 2,
    ease: "none",
  });
  function render() {
    renderer.render(scene, camera); //执行渲染操作
    requestAnimationFrame(render); //请求再次执行函数render
  }
  render();
});
</script>

<template>
  <!-- <h1>{{ msg }}</h1> -->
  <div ref="webgl"></div>
</template>

<style scoped></style>
