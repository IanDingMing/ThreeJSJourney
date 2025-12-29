## P51-P53 Creating a scene in Blender Blender场景烘焙与Three.js导入完整流程

### 核心概念：烘焙（Baking）

**基本原理**：将复杂的光线追踪计算结果预先“烘焙”到纹理贴图上，替代实时计算。

**为什么需要烘焙？**

- 光线追踪效果真实，但在WebGL中性能消耗过大
- 烘焙后只需加载纹理，大大降低运行时计算量
- 适合静态场景和静态光照

**缺点**：

- 所有效果必须在Blender中预先烘焙
- 需要加载所有纹理贴图
- 灯光效果是静态的，无法动态变化

------

### 完整工作流程

#### 第一阶段：Blender场景准备与优化

##### 1. 场景创建与模型优化

- 在Blender中创建完整场景
- 删除不可见面以优化模型：
  - 进入编辑模式（Tab）
  - 选择面模式
  - 选中多余的面（如石头贴近地面的底面、模型内部的面）
  - 按X键删除选中的面

##### 2. 检查面朝向（法线方向）

- 开启面朝向显示选项
- 检查是否有反面（通常显示为不同颜色）
- 修正错误朝向：
  - 选择需要修正的面
  - 使用“翻转法线”功能或“重新计算内部”

> 原笔记有示意图：面朝向.png，翻转法向.png

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-3/面朝向.png)

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-3/翻转法向.png)

##### 3. 统一物体缩放比例

- **重要原则**：缩放操作应在编辑模式下进行，而非物体模式
- **原因**：UV展开不考虑物体模式的缩放，直接拉伸会导致UV比例异常
- **解决方法**：
  1. 选择所有物体（A）
  2. Ctrl+A打开应用菜单
  3. 选择“缩放”，将所有物体的缩放值重置为1

------

#### 第二阶段：UV展开与整理

##### 1. 基础UV展开

1. 打开UV编辑器窗口
2. 选择物体，进入编辑模式（Tab）
3. 切换到面模式，全选所有面（A）
4. 按U键选择“展开”
5. 在UV编辑器中查看初步展开结果（通常不理想）

##### 2. 优化UV布局

1. 切换到线模式
2. 选择模型正面（面向摄像机）的边线
3. 按U键，选择“标记缝合边”
4. 再次全选所有面（A）
5. 按U键重新展开，获得更合理的UV布局

##### 3. UV分组管理

- 根据模型部件分组整理UV块
- 优势：便于后期单独调整或删除特定部件
- 确保各组UV块之间保持适当间距，避免烘焙时互相影响

> 原笔记有示意图：uv分组.png

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-3/uv分组.png)

##### 4. 调整UV比例

- 目标：使所有UV块的实际面积比例接近模型表面的真实比例
- 检查方法：使用UV面积检查工具
- 完成标志：UV编辑器中大部分区域颜色均匀，无明显拉伸

> 原笔记有示意图：uv拉伸面积.png，uv面积调整完成.png

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-3/uv拉伸面积.png)

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-3/uv面积调整完成.png)

------

#### 第三阶段：烘焙配置与执行

##### 1. 创建烘焙纹理

1. 点击“新建”按钮创建图像纹理
2. 配置关键参数：
   - **宽度/高度**：纹理分辨率（根据需求设置）
   - **颜色**：纹理基础颜色
   - **Alpha**：是否包含透明度通道
   - **生成类型**：纹理生成算法
   - **32位浮点格式**：保存更高精度的颜色信息（为HDR输出做准备）
   - **拼贴**：纹理是否可平铺

> 原笔记有示意图：烘焙初始.png

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-3/烘焙初始.png)

##### 2. 保存HDR版本

- HDR格式可保存完整的亮度范围信息
- 在图像编辑器中选择“另存为”，格式选择支持HDR的格式

> 原笔记有示意图：保存hdr烘焙.png，保存hdr烘焙1.png

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-3/保存hdr烘焙.png)

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-3/保存hdr烘焙1.png)

##### 3. 设置着色节点

1. 新建窗口，选择“着色编辑器”
2. 确保勾选“使用节点”
3. 添加“图像纹理”节点
4. 选择刚才创建的烘焙纹理

> 原笔记有示意图：着色编辑器.png，图像纹理.png，图像纹理1.png

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-3/着色编辑器.png)

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-3/图像纹理.png)

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-3/图像纹理1.png)

##### 4. 配置烘焙参数

1. 取消勾选“清空图像”（便于分步烘焙）
2. 调整渲染采样为128（平衡质量与速度）

> 原笔记有示意图：烘焙配置.png，提高烘焙速度.png

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-3/烘焙配置.png)![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-3/提高烘焙速度.png)

##### 5. 执行烘焙

- 执行烘焙后，如纹理未更新，可尝试重新保存以刷新
- 按N键可隐藏侧边栏简化界面
- 烘焙首次完成，如果uv排列的不好，会出现重叠，这时候需要调整，不让它们互相影响
- 可以移动模型uv，稍微偏移

> 原笔记有示意图：更新烘焙图.png，烘焙首次完成.png，烘焙调整.png

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-3/更新烘焙图.png)![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-3/烘焙首次完成.png)![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-3/烘焙调整.png)

------

#### 第四阶段：烘焙问题解决与优化

##### 1. 颜色校正问题

- **问题**：Blender默认颜色管理（标准/AgX）可能导致色差
- **解决**：切换到filmic颜色管理

> 原笔记有示意图：应用flimic.png

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-3/应用flimic.png)

##### 2. 降噪处理（如需要）

1. 打开“合成器”窗口
2. 添加图像输入节点，连接烘焙输出
3. 添加降噪节点（滤镜 → 降噪）
4. 将降噪节点连接在烘焙输出和合成器之间

> 原笔记有示意图：合成器窗口.png，合成器中输入图像.png，合成器中输入图像1.png，烘焙降噪.png，烘焙降噪1.png

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-3/合成器窗口.png)![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-3/合成器中输入图像.png)![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-3/合成器中输入图像1.png)![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-3/烘焙降噪.png)

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-3/烘焙降噪1.png)

##### 3. 预览与保存优化

1. 点击渲染层，按M键屏蔽/显示
2. 配置最终输出：
   - 调整分辨率，一般是1024*4
   - 设置输出路径
   - 保存最终烘焙图

> 原笔记有示意图：预览烘焙图.png，烘焙图最终保存配置.png，烘焙图最终保存.png

##### 4. 恢复合成器设置

- 取消烘焙屏蔽
- 将渲染层重新连接合成器
- 恢复输出配置

> 原笔记有示意图：合成器恢复.png，输出配置恢复.png

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-3/合成器恢复.png)![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-3/输出配置恢复.png)

------

#### 第五阶段：模型导出与Three.js导入

##### 1. 从Blender导出

1. 选择所有模型（排除摄像机和平面光）
2. 文件 → 导出 → glTF 2.0
3. 关键导出设置：
   - 不导出法线数据（烘焙纹理已包含）
   - 不导出材质
   - 启用压缩
   - 无动画时不勾选动画选项

> 原笔记有示意图：模型导出.png，模型导出1.png

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-3/模型导出.png)![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-3/模型导出1.png)

##### 2. Three.js基础设置

javascript

```
// 渲染器颜色空间设置
renderer.outputColorSpace = THREE.SRGBColorSpace;

// 纹理加载与配置
const bakedTexture = texturesLoader.load(`${import.meta.env.BASE_URL}models/portal/baked.jpg`);
bakedTexture.flipY = false;  // Blender与Three.js的Y轴方向不同
bakedTexture.colorSpace = THREE.SRGBColorSpace;

// 基础材质
const bakedMaterial = new THREE.MeshBasicMaterial({ map: bakedTexture });
```



##### 3. 模型加载与材质应用（初步版本）

javascript

```
gltfLoader.load('models/portal/portal.glb', (gltf) => {
  // 遍历所有子元素并应用烘焙材质
  gltf.scene.traverse((child) => {
    child.material = bakedMaterial;
  });
  scene.add(gltf.scene);
});
```



##### 4. 处理发光体问题

- **问题**：烘焙纹理不包含发光体信息
- **解决**：返回Blender为发光体单独命名，重新导出

javascript

```
// 发光体专用材质
const portalLightMaterial = new THREE.MeshBasicMaterial({ color: 0xffffff });
const poleLightMaterial = new THREE.MeshBasicMaterial({ color: 0xffcb90 });

gltfLoader.load('models/portal/portal.glb', (gltf) => {
  gltf.scene.traverse((child) => {
    child.material = bakedMaterial;
  });
  
  // 通过名称查找发光体
  const portalLightMesh = gltf.scene.children.find(child => child.name === "portalLight");
  const poleLightAMesh = gltf.scene.children.find(child => child.name === "poleLightA");
  const poleLightBMesh = gltf.scene.children.find(child => child.name === "poleLightB");
  
  // 应用发光体材质
  poleLightAMesh.material = poleLightMaterial;
  poleLightBMesh.material = poleLightMaterial;
  portalLightMesh.material = portalLightMaterial;
  
  scene.add(gltf.scene);
});
```



------

#### 第六阶段：性能优化

##### 1. 问题诊断

- 使用Spector.js分析发现：多个独立模型导致大量加载步骤
- **原因**：每个独立物体都会产生单独的draw call

##### 2. Blender中合并模型

1. 创建新分组（如“merged”）
2. 选择所有需要合并的模型（**特别注意：不要选择发光体**）
3. 复制模型（非关联复制）
4. 按M键，选择目标分组
5. 合并所有选中模型

> 原笔记有示意图：合并模型.png

![](/Users/macbook/projects/threeJs-learn/ThreeJS Journey/ThreeJSJourney/note/images-3/合并模型.png)

##### 3. 优化后的Three.js代码

javascript

```
gltfLoader.load('models/portal/portal.glb', (gltf) => {
  // 直接通过名称查找合并后的模型
  const bakedMesh = gltf.scene.children.find(child => child.name === "baked");
  const portalLightMesh = gltf.scene.children.find(child => child.name === "portalLight");
  const poleLightAMesh = gltf.scene.children.find(child => child.name === "poleLightA");
  const poleLightBMesh = gltf.scene.children.find(child => child.name === "poleLightB");
  
  // 分别应用材质
  bakedMesh.material = bakedMaterial;
  poleLightAMesh.material = poleLightMaterial;
  poleLightBMesh.material = poleLightMaterial;
  portalLightMesh.material = portalLightMaterial;
  
  scene.add(gltf.scene);
});
```







P54

















# 附录
