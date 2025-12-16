uniform float uTime;
uniform float uDeltaTime;
uniform sampler2D uBase;
uniform float uFlowFieldInfluence;
uniform float uFlowFieldStrength;
uniform float uFlowFieldFrequency;

#include ../includes/simplexNoise4d.glsl

void main() {
    float time = uTime * .2;
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec4 particle = texture(uParticles, uv);
    vec4 base = texture(uBase, uv);
    // particle.x += .01;

    // Dead
    if(particle.a >= 1.0) {
        // particle.a = .0;
        particle.a = mod(particle.a, 1.0);
        particle.xyz = base.xyz;
    }
    // Alive
    else {
        // Strength 
        float strength = simplexNoise4d(vec4(base.xyz * .2, time + 1.0));
        float influence = (uFlowFieldInfluence - .5) * (-2.0);
        strength = smoothstep(influence, 1.0, strength);

        // Flow field
        vec3 flowField = vec3(simplexNoise4d(vec4(particle.xyz * uFlowFieldFrequency + 1.0, uTime)), simplexNoise4d(vec4(particle.xyz * uFlowFieldFrequency + 2.0, uTime)), simplexNoise4d(vec4(particle.xyz * uFlowFieldFrequency + 3.0, uTime)));
        flowField = normalize(flowField);
        particle.xyz += flowField * uDeltaTime * strength * uFlowFieldStrength;

        // Decay
        particle.a += uDeltaTime * .3;
    }

    gl_FragColor = particle;
}