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
  const clock = new THREE.Clock();
  const rotationSpeed = Math.PI / 180 / 100; //旋转速度,每帧旋转0.01度
  function render() {
    const spt = clock.getDelta() * 1000; //毫秒
    console.log("两帧渲染时间间隔(毫秒)", spt);
    console.log("帧率FPS", 1000 / spt);
    renderer.render(scene, camera); //执行渲染操作
    /**
     * 为什么需要它？
     * 直接使用固定值（如0.01弧度）旋转会导致：
     * 高刷新率屏幕（120Hz）旋转更快
     * 低刷新率屏幕（30Hz）旋转更慢
     * 这样无论帧率高低，物体每秒旋转角度保持一致。
     */
    // 帧率无关的旋转（推荐写法）
    mesh.rotateY(rotationSpeed * spt);
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
