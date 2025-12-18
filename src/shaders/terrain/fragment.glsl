uniform vec3 uColorWaterDeep;
uniform vec3 uColorWaterSurface;
uniform vec3 uColorSand;
uniform vec3 uColorGrass;
uniform vec3 uColorSnow;
uniform vec3 uColorRock;

varying vec3 vPosition;
varying float vUpDot;

#include ../includes/simplexNoise2d.glsl

void main() {
    // csm_FragColor = vec4(1.0,.0,.0,1.0);

    // Color
    vec3 color = vec3(1.0);

    // Water
    float surfaceWaterMix = smoothstep(-1.0, -.1, vPosition.y);
    color = mix(uColorWaterDeep, uColorWaterSurface, surfaceWaterMix);

    // Sand
    float sandMix = step(-.1, vPosition.y);
    color = mix(color, uColorSand, sandMix);

    // Grass
    float grassMix = step(-.06, vPosition.y);
    color = mix(color, uColorGrass, grassMix);

    // Rock
    float rockMix = vUpDot;
    rockMix = 1.0 - step(.8, rockMix);
    rockMix *= grassMix;
    color = mix(color, uColorRock, rockMix);

    // Snow
    float snowThreshold = .45;
    snowThreshold += simplexNoise2d(vPosition.xz * 15.0) * .1;
    float snowMix = step(snowThreshold, vPosition.y);
    color = mix(color, uColorSnow, snowMix);

    // Final color
    csm_DiffuseColor = vec4(color, 1.0);
    // csm_FragColor = vec4(vec3(vUpDot),1.0);
}