uniform float uSize;
uniform vec2 uResolution;
uniform float uProgress;

attribute float aSize;
attribute float aTimeMultiplier;

/**
 * remap 重映射 示例1：将 [0,1] 映射到 [0,100]
 * @param value 重映射的值
 * @param originMin 原始最小值
 * @param originMax 原始最大值
 * @param destinationMin 终点最小值
 * @param destinationMax 终点最大值
 */
float remap(float value, float originMin, float originMax, float destinationMin, float destinationMax) {
    return destinationMin + (value - originMin) * (destinationMax - destinationMin) / (originMax - originMin);
}

void main() {
    float progress = uProgress * aTimeMultiplier;
    vec3 newPosition = position;

    // Exploding
    float explodingProgress = remap(progress, .0, .1, .0, 1.0);
    explodingProgress = clamp(explodingProgress, .0, 1.0);//解决超出界面问题
    explodingProgress = 1.0 - pow(1.0 - explodingProgress, 3.0);// 优化动画，动画末尾缓动效果
    newPosition *= explodingProgress;

    // Falling
    float fallingProgress = remap(progress, .1, 1.0, .0, 1.0);
    fallingProgress = clamp(fallingProgress, .0, 1.0);//解决超出界面问题
    fallingProgress = 1.0 - pow(1.0 - fallingProgress, 3.0);// 优化动画，动画末尾缓动效果
    newPosition.y -= fallingProgress * .2;

    // Scalling
    float sizeOpeningProgress = remap(progress, .0, .125, .0, 1.0);
    float sizeClosingProgress = remap(progress, .125, 1.0, 1.0, .0);
    float sizeProgress = min(sizeOpeningProgress, sizeClosingProgress);
    sizeProgress = clamp(sizeProgress, .0, 1.0);

    // Twinkling
    float twinklingProgress = remap(progress, .2, .8, .0, 1.0);
    twinklingProgress = clamp(twinklingProgress, .0, 1.0);
    float sizeTwinkling = sin(progress * 30.0) * .5 + .5;
    sizeTwinkling = 1.0 - sizeTwinkling * twinklingProgress;

    // Final position
    vec4 modelPosition = modelMatrix * vec4(newPosition, 1.0);
    vec4 viewPosition = viewMatrix * modelPosition;
    gl_Position = projectionMatrix * viewPosition;

    // Final size
    gl_PointSize = uSize * uResolution.y * aSize * sizeProgress * sizeTwinkling;// 因为窗口缩放和视口的高有关，所以这里是y
    gl_PointSize *= 1.0 / -viewPosition.z;//粒子大小随摄像机的距离增大而变小

    if(gl_PointSize < 1.0)
        gl_Position = vec4(9999.9);

}