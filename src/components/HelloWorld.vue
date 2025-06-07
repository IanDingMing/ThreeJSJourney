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
  console.log(webgl);
  webgl.value!.width = sizes.width;
  webgl.value!.height = sizes.height;

  // 创建3D场景对象Scene
  const scene = new THREE.Scene();

  //创建一个长方体几何对象Geometry
  const geometry = new THREE.BoxGeometry(1, 1, 1);

  //创建一个材质对象Material
  const material = new THREE.MeshBasicMaterial({
    color: 0xff0000, //0xff0000设置材质颜色为红色
  });

  // 两个参数分别为几何体geometry、材质material
  const mesh = new THREE.Mesh(geometry, material); //网格模型对象Mesh
  scene.add(mesh);

  // 实例化一个透视投影相机对象
  const camera = new THREE.PerspectiveCamera(75, sizes.width / sizes.height);

  //相机在Three.js三维坐标系中的位置
  // 根据需要设置相机位置具体值
  camera.position.set(0, 0, 3);
  // camera.lookAt(0, 0, 0); // 让相机向下看向原点

  // 创建渲染器对象
  const renderer = new THREE.WebGLRenderer();
  renderer.setSize(sizes.width, sizes.height); //设置three.js渲染区域的尺寸(像素px)
  webgl.value.appendChild(renderer.domElement);

  renderer.render(scene, camera); //执行渲染操作
});
</script>

<template>
  <!-- <h1>{{ msg }}</h1> -->
  <div ref="webgl"></div>
</template>

<style scoped></style>
