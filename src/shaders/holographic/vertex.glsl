uniform float uTime;

varying vec3 vPosition;
varying vec3 vNormal;

float random2D(vec2 value) {
    return fract(sin(dot(value.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void main() {
    // Position
    vec4 modelPosition = modelMatrix * vec4(position, 1.0);

    // Glitch
    float glitchTime = uTime - modelPosition.y;
    float glitchStrength = (sin(glitchTime) + sin(glitchTime * 3.45) + sin(glitchTime * 8.76)) / 3.0;
    glitchStrength = smoothstep(.3, 1.0, glitchStrength);
    glitchStrength *= .25;
    modelPosition.x += (random2D(modelPosition.xz + uTime) - .5) * glitchStrength;
    modelPosition.z += (random2D(modelPosition.zx + uTime) - .5) * glitchStrength;

    // Final position
    vec4 viewPosition = viewMatrix * modelPosition;
    vec4 projectedPosition = projectionMatrix * viewPosition;
    gl_Position = projectedPosition;

    // Model normal
    vec4 modelNormal = modelMatrix * vec4(normal, 0.0);

    // varyings
    vPosition = modelPosition.xyz;
    vNormal = modelNormal.xyz;
}