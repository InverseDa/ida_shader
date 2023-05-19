#version 130
#define SHADOW_MAP_BIAS 0.85

const int RG16 = 0;
const int gnormalFormat = RG16;
const bool shadowHardwareFiltering = true;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform sampler2D shadow;
uniform sampler2D depthtex0;
uniform sampler2D gcolor;
uniform sampler2D gnormal;
uniform float far;
uniform vec3 sunPosition;

varying vec4 texcoord;


vec3 normalDecode(vec2 enc) {
    vec4 nn = vec4(2.0 * enc - 1.0, 1.0, -1.0);
    float l = dot(nn.xyz,-nn.xyw);
    nn.z = l;
    nn.xy *= sqrt(l);
    return nn.xyz * 2.0 + vec3(0.0, 0.0, -1.0);
}

vec4 getWorldPosition() {
    float depth = texture2D(depthtex0, texcoord.st).x;
    vec4 positionInView = gbufferProjectionInverse * vec4(texcoord.x * 2.0 - 1.0, texcoord.y * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    positionInView /= positionInView.w;
    vec4 positionInWorld = gbufferModelViewInverse * positionInView;
    return positionInWorld;
}

float shadowMapping(vec4 positionInWorld, float dist, vec3 normal) {
    // dist > 0.9, dont render sky's shadow
    if(dist > 0.9) return 0.0;

    float shade = 0.0;
    // the angle bettween normal and light
    float cosine = dot(normalize(sunPosition), normal);

    if(cosine <= 0.1) shade = 1.0;
    else {
        vec4 positionInSunNDC = shadowProjection * shadowModelView * positionInWorld;
        float distb = sqrt(positionInSunNDC.x * positionInSunNDC.x + positionInSunNDC.y * positionInSunNDC.y);
        float distortFactor = (1.0 - SHADOW_MAP_BIAS) + distb * SHADOW_MAP_BIAS;
        positionInSunNDC.xy /= distortFactor;
        positionInSunNDC /= positionInSunNDC.w;
        positionInSunNDC = positionInSunNDC * 0.5 + 0.5;
        float depthInSunView = texture2D(shadow, positionInSunNDC.st).z;
        if(depthInSunView + 0.0001 < positionInSunNDC.z) shade = 1.0;
        if(cosine < 0.2) shade = max(shade, 1.0 - (cosine - 0.1) * 10.0);
    }
    return shade;
}

void main() {
    vec3 normal = normalDecode(texture2D(gnormal, texcoord.st).rg);
    vec4 positionInWorld = getWorldPosition();
    // near <= positionInWorld.z
    float dist = length(positionInWorld.xyz / far);
    float shadow = shadowMapping(positionInWorld, dist, normal);

/* DRAWBUFFERS:0 */
    gl_FragData[0] = texture2D(gcolor, texcoord.st);
    gl_FragData[0].rgb *= (1.0 - shadow * 0.5);
}