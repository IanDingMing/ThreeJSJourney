<script setup lang="ts">
import { ref, useTemplateRef, onMounted } from "vue";
import * as THREE from "three";
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

  const group = new THREE.Group(); //创建一个组对象
  group.position.set(0, 1, 0); //设置组对象在x、y、z轴上的位置
  group.scale.set(1, 1.5, 1); //设置组对象的缩放比例
  scene.add(group); //将组对象添加到场景中

  const cube1 = new THREE.Mesh(
    new THREE.BoxGeometry(1, 1, 1), //创建一个立方体几何体
    new THREE.MeshBasicMaterial({ color: 0xff0000 }) //创建一个红色材质
  );
  group.add(cube1); //将立方体添加到组对象中

  const cube2 = new THREE.Mesh(
    new THREE.BoxGeometry(1, 1, 1),
    new THREE.MeshBasicMaterial({ color: 0x00ff00 })
  );
  cube2.position.set(1.5, 0, 0); //设置立方体在x、y、z轴上的位置
  group.add(cube2); //将立方体添加到组对象中

  const cube3 = new THREE.Mesh(
    new THREE.BoxGeometry(1, 1, 1),
    new THREE.MeshBasicMaterial({ color: 0x0000ff })
  );
  cube3.position.set(-1.5, 0, 0); //设置立方体在x、y、z轴上的位置
  group.add(cube3); //将立方体添加到组对象中

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

  renderer.render(scene, camera); //执行渲染操作
});
</script>

<template>
  <!-- <h1>{{ msg }}</h1> -->
  <div ref="webgl"></div>
</template>

<style scoped></style>
