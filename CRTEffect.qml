// Run&Game Theme
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/
import QtQuick 2.15
import QtGraphicalEffects 1.15

ShaderEffect {
    id: crtEffect
    property variant source
    property real time: 0.0
    property bool crtEffectEnabled: true
    property real zoomFactor: 1.0
    property real curvature: 0.3
    property real mediaCurvature: 0.0
    property real scanlineThickness: 1600.0
    property real scanlineIntensity: 0.18
    property real brightness: 0.9
    property real colorTemperature: 1.1
    property real flickerAmount: 0.0
    property real contrast: 1.0
    property real gamma: 1.0
    property real saturation: 1.0
    property real noiseAmount: 0.0
    property real shadowMaskStrength: 0.0
    property real rgbShiftAmount: 0.0
    property real chromaticAberration: 0.0
    property real blurAmount: 0.0
    property real targetAspect: 4.0/3.0
    property real sourceAspect: width / height
    property real barsExtra: 1.0

    NumberAnimation on time {
        loops: Animation.Infinite
        from: 0
        to: 100
        duration: 100000
    }

    fragmentShader: "
    #ifdef GL_ES
    precision mediump float;
    #endif

    uniform sampler2D source;
    uniform lowp float qt_Opacity;
    uniform mediump float time;
    uniform mediump float zoomFactor;
    uniform mediump float curvature;
    uniform mediump float mediaCurvature;
    uniform mediump float scanlineThickness;
    uniform mediump float scanlineIntensity;
    uniform mediump float brightness;
    uniform mediump float colorTemperature;
    uniform mediump float flickerAmount;
    uniform mediump float contrast;
    uniform mediump float gamma;
    uniform mediump float saturation;
    uniform mediump float noiseAmount;
    uniform mediump float shadowMaskStrength;
    uniform mediump float rgbShiftAmount;
    uniform mediump float chromaticAberration;
    uniform mediump float blurAmount;
    uniform bool crtEffectEnabled;
    uniform mediump float targetAspect;
    uniform mediump float sourceAspect;
    uniform mediump float barsExtra;

    varying mediump vec2 qt_TexCoord0;

    float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
if (!crtEffectEnabled) {
    gl_FragColor = texture2D(source, qt_TexCoord0);
    return;
}

// 1. Ajuste por relación de aspecto
float srcAR = sourceAspect;
float tgtAR = targetAspect;

float scaleX, scaleY;
if (srcAR / tgtAR > 1.0) {
    // El viewport es más ancho que el target → pillarbox (barras a los costados)
    scaleX = (tgtAR / srcAR) * barsExtra;
    scaleY = 1.0 * barsExtra;
} else {
    // El viewport es más alto que el target → letterbox (barras arriba/abajo)
    scaleX = 1.0 * barsExtra;
    scaleY = (srcAR / tgtAR) * barsExtra;
}

// Se divide (no se multiplica) para que el contenido quede centrado
// dentro de un recuadro más chico y el resto se pinte negro,
// en vez de recortar/zoomear la textura.
vec2 adjustedUV;
adjustedUV.x = (qt_TexCoord0.x - 0.5) / scaleX + 0.5;
adjustedUV.y = (qt_TexCoord0.y - 0.5) / scaleY + 0.5;

// Si está fuera del rango, pintar negro (barras)
if (adjustedUV.x < 0.0 || adjustedUV.x > 1.0 || adjustedUV.y < 0.0 || adjustedUV.y > 1.0) {
    gl_FragColor = vec4(0.0, 0.0, 0.0, qt_Opacity);
    return;
}

// 2. Aplicar zoom (overscan) después del ajuste de aspect ratio
vec2 zoomedUV = (adjustedUV - 0.5) / max(zoomFactor, 0.1) + 0.5;

// Si el zoom saca la imagen fuera, pintar negro (opcional)
if (zoomedUV.x < 0.0 || zoomedUV.x > 1.0 || zoomedUV.y < 0.0 || zoomedUV.y > 1.0) {
    gl_FragColor = vec4(0.0, 0.0, 0.0, qt_Opacity);
    return;
}

// 3. Aplicar curvatura con zona de media protegida
// La zona central de la pantalla (donde viven las imágenes/video)
// usa mediaCurvature en vez de curvature para evitar el estiramiento.
// La zona de borde/UI sigue usando curvature completa.
vec2 centered = zoomedUV - 0.5;
float dist = length(centered);

// Máscara suave: 0.0 en el centro, 1.0 en los bordes.
// edgeZone controla qué tan amplia es la zona protegida (0.3 = 30% central = sin curvar).
float edgeZone = smoothstep(0.0, 0.55, dist * 2.0);
float effectiveCurvature = mix(mediaCurvature, curvature, edgeZone);

vec2 curvedUV = centered * (1.0 + effectiveCurvature * dist * dist) + 0.5;

if (curvedUV.x < 0.0 || curvedUV.x > 1.0 || curvedUV.y < 0.0 || curvedUV.y > 1.0) {
    gl_FragColor = vec4(0.0, 0.0, 0.0, qt_Opacity);
    return;
}

// --- El resto del shader (desenfoque, aberración, scanlines, etc.) se aplica sobre curvedUV ---
vec4 color = texture2D(source, curvedUV);
if (blurAmount > 0.01) {
    float blur = clamp(blurAmount, 0.0, 2.0) * 0.003;
    vec2 offset = vec2(blur, 0.0);
    vec4 sum = color;
    sum += texture2D(source, curvedUV - offset);
    sum += texture2D(source, curvedUV + offset);
    sum += texture2D(source, curvedUV - offset.yx);
    sum += texture2D(source, curvedUV + offset.yx);
    sum += texture2D(source, curvedUV - vec2(0.0, blur));
    sum += texture2D(source, curvedUV + vec2(0.0, blur));
    sum += texture2D(source, curvedUV - vec2(blur, blur));
    sum += texture2D(source, curvedUV + vec2(blur, blur));
    color = sum / 9.0;
}

if (chromaticAberration > 0.001) {
    float amount = chromaticAberration * 0.02;
    vec2 offset = (curvedUV - 0.5) * amount;
    float r = texture2D(source, curvedUV - offset).r;
    float g = texture2D(source, curvedUV).g;
    float b = texture2D(source, curvedUV + offset).b;
    color = vec4(r, g, b, color.a);
}

if (rgbShiftAmount > 0.001) {
    float shift = rgbShiftAmount * 0.02;
    vec2 shiftVec = vec2(shift, 0.0);
    float r = texture2D(source, curvedUV - shiftVec).r;
    float g = texture2D(source, curvedUV).g;
    float b = texture2D(source, curvedUV + shiftVec).b;
    color = vec4(r, g, b, color.a);
}

if (saturation != 1.0) {
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    color.rgb = mix(vec3(gray), color.rgb, saturation);
}

color.rgb = (color.rgb - 0.5) * contrast + 0.5;
color.rgb = pow(color.rgb, vec3(1.0 / gamma));

// Scanlines (usando curvedUV.y)
float scanlineEffect = sin(curvedUV.y * scanlineThickness) * scanlineIntensity;
float topMask = smoothstep(0.0, 0.15, curvedUV.y);
float bottomMask = smoothstep(1.0, 0.85, curvedUV.y);
float verticalMask = topMask * bottomMask;
float sideMask = smoothstep(0.0, 0.1, curvedUV.x) * smoothstep(1.0, 0.9, curvedUV.x);
float finalMask = verticalMask * sideMask;
color.rgb -= scanlineEffect * finalMask;

if (shadowMaskStrength > 0.01) {
    vec2 maskUV = curvedUV * vec2(300.0, 200.0);
    float mask = sin(maskUV.x * 3.14159) * sin(maskUV.y * 3.14159);
    mask = abs(mask) * 2.0 - 1.0;
    mask = clamp(mask * shadowMaskStrength, 0.0, 1.0);
    color.rgb *= (0.8 + 0.2 * mask);
}

if (noiseAmount > 0.001) {
    float noise = hash(curvedUV * 100.0 + time * 0.5) * 2.0 - 1.0;
    color.rgb += noise * noiseAmount;
}

color.rgb *= brightness;
color.r *= (1.02 * colorTemperature);
color.g *= (0.995 / colorTemperature);
color.b *= (1.01 * (1.0 / colorTemperature));

float edgeFade = smoothstep(0.0, 0.08, curvedUV.x) *
smoothstep(1.0, 0.92, curvedUV.x) *
smoothstep(0.0, 0.08, curvedUV.y) *
smoothstep(1.0, 0.92, curvedUV.y);
color.rgb *= edgeFade;

// Flicker
float flickerFreq1 = 314.16;
float flickerFreq2 = 287.0;
float flickerPhase = 1.2;
float flickerOsc = 0.5 * sin(time * flickerFreq1) + 0.5 * sin(time * flickerFreq2 + flickerPhase);
float noiseFlicker = (hash(vec2(time * 0.1, 0.5)) - 0.5) * 0.01;
float flicker = 1.0 + flickerAmount * (flickerOsc + noiseFlicker);
color.rgb *= flicker;

color.rgb = pow(color.rgb, vec3(1.03));
gl_FragColor = color * qt_Opacity;
}
"
}
