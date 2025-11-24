import QtQuick 2.15
import QtGraphicalEffects 1.15

ShaderEffect {
    id: crtEffect
    anchors.fill: parent
    property variant source: bgImage
    property real time: 0.0
    property bool crtEffectEnabled: true

    // PROPIEDADES CONFIGURABLES
    property real zoomFactor: 1.08
    property real curvature: 0.3           // Curvatura de la pantalla (0.0 = plana, 0.3 = muy curva)
    property real scanlineThickness: 1600.0 // Frecuencia de scanlines (mayor = más delgadas)
    property real scanlineIntensity: 0.18   // Intensidad de scanlines
    property real brightness: 0.9          // Brillo general (0.5 = oscuro, 1.0 = normal)
    property real colorTemperature: 1.1     // Temperatura de color (0.8 = frío, 1.2 = cálido)
    property real vignetteStrength: 0.80    // Fuerza del efecto vignette
    property real flickerAmount: 0.08       // Cantidad de parpadeo

    visible: crtEffectEnabled

    NumberAnimation on time {
        loops: Animation.Infinite
        from: 0
        to: 100
        duration: 100000
    }

    fragmentShader: "
    uniform sampler2D source;
    uniform lowp float qt_Opacity;
    uniform lowp float time;
    uniform lowp float zoomFactor;
    uniform lowp float curvature;
    uniform lowp float scanlineThickness;
    uniform lowp float scanlineIntensity;
    uniform lowp float brightness;
    uniform lowp float colorTemperature;
    uniform lowp float vignetteStrength;
    uniform lowp float flickerAmount;
    varying highp vec2 qt_TexCoord0;

    void main() {
    // Aplicar zoom sutil
    vec2 uv = (qt_TexCoord0 - 0.5) / zoomFactor + 0.5;

    // Curvatura CRT - CONFIGURABLE
    vec2 centered = uv - 0.5;
    float dist = length(centered);

    // Aplicar curvatura usando propiedad configurable
    vec2 curvedUV = centered * (1.0 + curvature * dist * dist) + 0.5;

    // Usar coordenadas corregidas por curvatura para todo el efecto
    vec2 finalUV = curvedUV;

    // Bordes negros cuando la curvatura saca píxeles fuera de rango
    if (finalUV.x < 0.0 || finalUV.x > 1.0 || finalUV.y < 0.0 || finalUV.y > 1.0) {
        gl_FragColor = vec4(0.0, 0.0, 0.0, qt_Opacity);
        return;
}

vec4 color = texture2D(source, finalUV);

// SCANLINES LIMPIAS - SIN EFECTOS ADICIONALES
float scanlineEffect = sin(finalUV.y * scanlineThickness) * scanlineIntensity;

// MÁSCARA MEJORADA - tratamiento igual para superior e inferior
float topMask = smoothstep(0.0, 0.15, finalUV.y);    // Suavizar borde superior
float bottomMask = smoothstep(1.0, 0.85, finalUV.y); // Suavizar borde inferior
float verticalMask = topMask * bottomMask;

float sideMask = smoothstep(0.0, 0.1, finalUV.x) * smoothstep(1.0, 0.9, finalUV.x);

float finalMask = verticalMask * sideMask;

// Aplicar scanlines con máscara simétrica
color.rgb -= scanlineEffect * finalMask;

// EFECTO DE PERSPECTIVA CORREGIDO
float verticalPerspective = 1.0 - abs(finalUV.y - 0.5) * 0.25;
color.rgb *= verticalPerspective;

// BRILLO GENERAL CONFIGURABLE
color.rgb *= brightness;

// TEMPERATURA DE COLOR CONFIGURABLE
color.r *= (1.02 * colorTemperature);
color.g *= (0.995 / colorTemperature);
color.b *= (1.01 * (1.0 / colorTemperature));

// VIGNETTE CONFIGURABLE
float vignette = 1.0 - vignetteStrength * pow(dist, 2.2);
vignette = smoothstep(0.0, 1.0, vignette);
color.rgb *= vignette;

// BORDES OSCUROS MEJORADOS
float edgeFade = smoothstep(0.0, 0.08, finalUV.x) *
smoothstep(1.0, 0.92, finalUV.x) *
smoothstep(0.0, 0.08, finalUV.y) *
smoothstep(1.0, 0.92, finalUV.y);
color.rgb *= edgeFade;

// PARPADEO CONFIGURABLE (más sutil)
float flicker = 1.0 - flickerAmount + (flickerAmount * sin(time * 0.1));
color.rgb *= flicker;

// CONTRASTE UNIFORME
color.rgb = pow(color.rgb, vec3(1.03));

gl_FragColor = color * qt_Opacity;
}"
}
