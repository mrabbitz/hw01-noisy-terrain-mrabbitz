#version 300 es
precision highp float;

uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane

in vec3 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_Col;

in float fs_Sine;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.


float noise1D( vec2 p ) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) *
                 43758.5453);
}

float random1o2i( vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Quintic: t = t * t * t * (t * (t * 6 - 15) + 10), then LERP
float quinticEase(float t)
{
  return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float interpNoise2D(float x, float y) {
  float intX = floor(x);
  float fractX = fract(x);
  float intY = floor(y);
  float fractY = fract(y);

  float v1 = random1o2i(vec2(intX, intY));
  float v2 = random1o2i(vec2(intX + 1.0, intY));
  float v3 = random1o2i(vec2(intX, intY + 1.0));
  float v4 = random1o2i(vec2(intX + 1.0, intY + 1.0));

  // fractX = cosineEase(fractX);
  // fractY = cosineEase(fractY);

  // fractX = cubicEase(fractX);
  // fractY = cubicEase(fractY);

  fractX = quinticEase(fractX);
  fractY = quinticEase(fractY);

  float i1 = mix(v1, v2, fractX);
  float i2 = mix(v3, v4, fractX);

  return mix(i1, i2, fractY);
}

float fbm2D(float x, float y, float p, int o) {
  float total = 0.f;
  float persistence = p;
  int octaves = o;

  for (int i = 0; i < octaves; i++) {
    float freq = pow(2.f, float(i));
    float amp = pow(persistence, float(i));

    total += interpNoise2D(x * freq,
                           y * freq) * amp;
  }
  return total;
}

float interpNoise1D(float x) {
  int intX = int(floor(x));
  float fractX = fract(x);

  float v1 = noise1D(vec2(intX));
  float v2 = noise1D(vec2(intX + 1));
  return mix(v1, v2, fractX);
}


float fbm1D(float x) {
  float total = 0.f;
  float persistence = 0.5f;
  int octaves = 8;

  for (int i = 0; i < octaves; i++) {
    float freq = pow(2.f, float(i));
    float amp = pow(persistence, float(i));

    total += interpNoise1D(x * freq) * amp;
  }
  return total;
}

void main()
{
    float t = clamp(smoothstep(40.0, 50.0, length(fs_Pos)), 0.0, 1.0); // Distance fog
    out_Col = vec4(mix(vec3(0.5 * (fs_Sine + 1.0)), vec3(164.0 / 255.0, 233.0 / 255.0, 1.0), t), 1.0);


float newVar = random1o2i(vec2(fs_Sine, fs_Sine));

vec4 water = vec4(62.0/256.0, 96.0/256.0, 193.0/256.0, 1.0);
vec4 sand = vec4(238.0/256.0, 214.0/256.0, 175.0/256.0, 1.0);
vec4 grass = vec4(116.0/256.0, 169.0/256.0, 99.0/256.0, 1.0);
vec4 trees = vec4(62.0/256.0, 126.0/256.0, 98.0/256.0, 1.0);
vec4 mountainBase = vec4(165.0/256.0, 189.0/256.0, 126.0/256.0, 1.0);
vec4 mountainTop = vec4(191.0/256.0, 210.0/256.0, 175.0/256.0, 1.0);

vec4 smokey = vec4(85.0/256.0, 85.0/256.0, 85.0/256.0, 1.0);
vec4 gray = vec4(136.0/256.0, 136.0/256.0, 136.0/256.0, 1.0);
vec4 top = vec4(188.0/256.0, 188.0/256.0, 171.0/256.0, 1.0);
vec4 snow = vec4(242.0/256.0, 242.0/256.0, 242.0/256.0, 1.0);

newVar = clamp(fs_Sine, 0.f, 1.f) - fbm1D(fs_Sine);

// water
if (fs_Sine < 0.1)
{
    out_Col = water;
}
// sand
else if (fs_Sine < 0.14f)
{
    out_Col = sand;
}
else if (fs_Sine > 1.8)
{
    if (newVar < 0.1)
    {
        out_Col = smokey;
    }
    else if (newVar < 0.2)
    {
        out_Col = gray;
    }
    else if (newVar < 0.5)
    {
        out_Col = top;
    }
    else 
    {
        out_Col = snow;
    }
}
else if (fs_Sine > 0.9)
{
    if (newVar < 0.5)
    {
        out_Col = mountainBase;
    }
    else
    {
        out_Col = mountainTop;
    }
}
else if (fs_Sine > 0.4)
{
    if (newVar < 0.5)
    {
        out_Col = trees;
    }
    else
    {
        out_Col = mountainBase;
    }
}
else
{
    if (newVar < 0.5)
    {
        out_Col = grass;
    }
    else
    {
        out_Col = trees;
    }
}
    
}
