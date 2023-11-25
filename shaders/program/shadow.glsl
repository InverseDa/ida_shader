#include "/lib/common.glsl"

// =====================================================================================
// ============================== Fragment Shader ======================================
// =====================================================================================
#ifdef FRAGMENT_SHADER
    uniform sampler2D texture;
    
    varying vec4 texcoord;
    
    void main() {
        gl_FragData[0] = texture2D(texture, texcoord.st);
    }
#endif

// =====================================================================================
// ============================== Fragment Shader ======================================
// =====================================================================================
#ifdef VERTEX_SHADER
    varying vec4 texcoord;
    
    void main() {
        gl_Position = ftransform();
        float dist = length(gl_Position.xy);
        float distortFactor = (1.0 - SHADOW_MAP_BIAS ) + dist * SHADOW_MAP_BIAS ;
        gl_Position.xy /= distortFactor;
        texcoord = gl_MultiTexCoord0;
    }
#endif