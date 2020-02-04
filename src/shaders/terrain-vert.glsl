#version 300 es


uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;
uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane
uniform float u_Time;

uniform float u_Distortion;
uniform float u_FractalIncrement;
uniform float u_Lucinarity;
uniform float u_Octaves;
uniform float u_ElevationExponent;


in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;

out vec3 fs_Pos;
out vec4 fs_Nor;
out vec4 fs_Col;

out float fs_Sine;

float random1( vec2 p , vec2 seed) {
  return fract(sin(dot(p + seed, vec2(127.1, 311.7)))
                       * 43758.5453);
}

float random1( vec3 p , vec3 seed) {
  return fract(sin(dot(p + seed, vec3(987.654, 123.456, 531.975)))
                   * 85734.3545);
}

vec2 random2( vec2 p , vec2 seed) {
  return fract(sin(vec2(dot(p + seed, vec2(311.7, 127.1)),
                        dot(p + seed, vec2(269.5, 183.3))))
                        * 85734.3545);
}

vec2 random2(vec2 p)
{
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)),
                          dot(p, vec2(269.5, 183.3))))
                          * 43758.5453);
}

float random1o2i( vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec3 random3o3i(vec3 p) {
  return fract(sin(vec3(dot(p, vec3(127.1, 311.7, 191.999)),
                        dot(p, vec3(269.5, 183.3, 765.54)),
                        dot(p, vec3(420.69, 631.2, 109.21))))
                        * 43758.5453);
}

float noise1D(int x) {
    x = (x << 13) ^ x;
    return (1.0 - float(x * (x * x * 15731 + 789221)
            + 1376312589))
            / 10737741824.0;
}

float noise1D( vec2 p ) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) *
                 43758.5453);
}

// Linear: (1 - t) * a + t * b
// Mix function
// Cosine: t = cos((1 - t) * 3.14159 * 0.5), then LERP
float cosineEase(float t)
{
  return cos((1.0 - t) * 3.14159 * 0.5);
}
// Cubic: t = t * t * (3 - 2 * t), then LERP
float cubicEase(float t)
{
  return t * t * (3.0 - 2.0 * t);
}
// Quintic: t = t * t * t * (t * (t * 6 - 15) + 10), then LERP
float quinticEase(float t)
{
  return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}


float interpNoise1D(float x) {
  int intX = int(floor(x));
  float fractX = fract(x);

  float v1 = noise1D(vec2(intX));
  float v2 = noise1D(vec2(intX + 1));
  return mix(v1, v2, fractX);
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

float WorleyNoise(vec2 uv, float factor) {
    uv *= factor;
    vec2 uvInt = floor(uv);
    vec2 uvFract = fract(uv);
    float minDist = 1.0;
    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 point = random2(uvInt + neighbor);
            vec2 diff = neighbor + point - uvFract;
            float dist = length(diff);
            minDist = min(minDist, dist);
        }
    }
    return minDist;
}

float surflet(vec2 p, vec2 gridPoint) {
    // Compute the distance between p and the grid point along each axis, and warp it with a
    // quintic function so we can smooth our cells
    vec2 t2 = abs(p - gridPoint);
    vec2 t = vec2(1.f) - 6.f * pow(t2, vec2(5.f)) - 15.f * pow(t2, vec2(4.f)) + 10.f * pow(t2, vec2(3.f));
    // Get the random vector for the grid point (assume we wrote a function random2)
    vec2 gradient = random2(gridPoint);
    // Get the vector from the grid point to P
    vec2 diff = p - gridPoint;
    // Get the value of our height field by dotting grid->P with our gradient
    float height = dot(diff, gradient);
    // Scale our height field (i.e. reduce it) by our polynomial falloff function
    return height * t.x * t.y;
}


float perlinNoise(vec2 uv) {
	float surfletSum = 0.f;
	// Iterate over the four integer corners surrounding uv
	for(int dx = 0; dx <= 1; ++dx) {
		for(int dy = 0; dy <= 1; ++dy) {
			surfletSum += surflet(uv, floor(uv) + vec2(dx, dy));
		}
	}
	return surfletSum;
}

/*
* Procedural fBm evaluated at "point"; returns value stored in "value".
*
* Parameters:
* "H" is the fractal increment
* "lacunarity" is the gap between successive frequencies
* "octaves" is the number of frequencies in the fBm
* "Basis()" is usually Perlin noise
*/
float musgraveFBM(vec2 point, float H, float lacunarity, float octaves)
{
  int octavesInt = int(floor(octaves));
  float octavesFract = fract(octaves);

    float value, frequency, remainder;
    int i;
    bool first = true;
    float exponent_array[100];
    /* precompute and store spectral weights */
    if (first) {
      frequency = 1.0;
      for (i = 0; i < 100; i++) {
        /* compute weight for each frequency */
        exponent_array[i] = pow(frequency, -H);
        frequency *= lacunarity;
      }
      first = false;
    }

    value = 0.0;

    /* inner loop of spectral construction */
    for (i = 0; i < octavesInt; i++) {
      value += interpNoise2D(point.x, point.y) * exponent_array[i];
      point.x *= lacunarity;
      point.y *= lacunarity;
      //point.z *= lacunarity;
    } /* for */
    remainder = octavesFract;
    if (remainder > 0.0) {/* add in "octaves" remainder */
    /* "i" and spatial freq. are preset in loop above */
      value += remainder * interpNoise2D(point.x, point.y) * exponent_array[i];
    }
    return value;
} /* fBm() */

/* Hybrid additive/multiplicative multifractal terrain model.
*
* Some good parameter values to start with:
* H: 0.25
* offset: 0.7
*/
float HybridMultifractal(vec2 point, float H, float lacunarity, float octaves, float offset )
{
  float worleyOffset = 0.1;

  int octavesInt = int(floor(octaves));
  float octavesFract = fract(octaves);

float frequency, result, signal, weight, remainder;
int i;
bool first = true;
float exponent_array[100];
    /* precompute and store spectral weights */
    if (first) {
      frequency = 1.0;
      for (i = 0; i < 100; i++) {
        /* compute weight for each frequency */
        exponent_array[i] = pow(frequency, -H);
        frequency *= lacunarity;
      }
      first = false;
    }
/* get first octave of function */

result = (WorleyNoise(point, worleyOffset) + offset) * exponent_array[0];
weight = result;
/* increase frequency */
point.x *= lacunarity;
point.y *= lacunarity;
//point.z *= lacunarity;
/* spectral construction inner loop, where the fractal is built */
for (i=1; i<octavesInt; i++) {
/* prevent divergence */
if ( weight > 1.0 )
{
  weight = 1.0;
}
/* get next higher frequency */
signal = (WorleyNoise(point, worleyOffset) + offset ) * exponent_array[i];
/* add it in, weighted by previous freq's local value */
result += weight * signal;
/* update the (monotonically decreasing) weighting value */
/* (this is why H must specify a high fractal dimension) */
weight *= signal;
/* increase frequency */
point.x *= lacunarity;
point.y *= lacunarity;
//point.z *= lacunarity;
} /* for */
/* take care of remainder in “octaves” */
remainder = octavesFract;
if ( remainder > 0.0)
/* “i” and spatial freq. are preset in loop above */
result += remainder * WorleyNoise(point, worleyOffset) * exponent_array[i];
return result;
} /* HybridMultifractal() */


void main()
{
  fs_Pos = vs_Pos.xyz;
  //fs_Sine = (sin((vs_Pos.x + u_PlanePos.x) * 3.14159 * 0.1) + cos((vs_Pos.z + u_PlanePos.y) * 3.14159 * 0.1));

  // float freq1 = 1.0f;
  // float freq2 = 2.0f;
  // float freq3 = 4.0f;
  // float freq1Div = 1.0 / freq1;
  // float freq2Div = 1.0 / freq2;
  // float freq3Div = 1.0 / freq3;

  // float persistenceFactor = 0.5;
  // int octaves = 8;
  // float fbm = freq1Div * fbm2D((vs_Pos.x + u_PlanePos.x) * freq1, (vs_Pos.z + u_PlanePos.y) * freq1, persistenceFactor, octaves)
  //         + freq2Div * fbm2D((vs_Pos.x + u_PlanePos.x) * freq2, (vs_Pos.z + u_PlanePos.y) * freq2, persistenceFactor, octaves)
  //         + freq3Div * fbm2D((vs_Pos.x + u_PlanePos.x) * freq3, (vs_Pos.z + u_PlanePos.y) * freq3, persistenceFactor, octaves);
  // fbm = fbm2D(vs_Pos.x + u_PlanePos.x, vs_Pos.z + u_PlanePos.y, persistenceFactor, octaves);
  
  // float factor = 0.1;
  // float worley = freq1Div * WorleyNoise(vec2((vs_Pos.x + u_PlanePos.x) * freq1, (vs_Pos.z + u_PlanePos.y) * freq1), factor)
  //              + freq2Div * WorleyNoise(vec2((vs_Pos.x + u_PlanePos.x) * freq2, (vs_Pos.z + u_PlanePos.y) * freq2), factor)
  //              + freq3Div * WorleyNoise(vec2((vs_Pos.x + u_PlanePos.x) * freq3, (vs_Pos.z + u_PlanePos.y) * freq3), factor);
  // //worley = WorleyNoise(vec2(vs_Pos.x + u_PlanePos.x, vs_Pos.z + u_PlanePos.y), factor);

  // float perlinFactor = 0.5;

  // float perlin = freq1Div * perlinNoise(vec2((vs_Pos.x + u_PlanePos.x) * freq1, (vs_Pos.z + u_PlanePos.y) * freq1))
  //              + freq2Div * perlinNoise(vec2((vs_Pos.x + u_PlanePos.x) * freq2, (vs_Pos.z + u_PlanePos.y) * freq2))
  //              + freq3Div * perlinNoise(vec2((vs_Pos.x + u_PlanePos.x) * freq3, (vs_Pos.z + u_PlanePos.y) * freq3));
  // perlin = perlinNoise(vec2((vs_Pos.x + u_PlanePos.x) * perlinFactor, (vs_Pos.z + u_PlanePos.y) * perlinFactor));

  // perlin = abs(perlin);

  // perlin = clamp(perlin, 0.0, 10.0) / 10.0;
  // perlin = clamp(perlin, 0.0, 1.0);

  //fs_Sine *= fbm;

  // fs_Sine = 1.0 + (worley * -1.0);


  //worley -= random1o2i(vec2(worley, worley));
  //worley = clamp(worley, 0.5, 1.0);


  // fbm = pow(fbm, 2.0);
  // fbm /= float(octaves);

  // fs_Sine = fbm;

  // fs_Sine = musgraveFBM(vec2((vs_Pos.x + u_PlanePos.x), (vs_Pos.z + u_PlanePos.y)), 1.0, 2.0, float(octaves));

  vec2 pointTest = vec2((vs_Pos.x + u_PlanePos.x), (vs_Pos.z + u_PlanePos.y));
  vec2 tmp = pointTest;
  vec2 distort;
  distort.x = HybridMultifractal(tmp, u_FractalIncrement, u_Lucinarity, u_Octaves, 0.6);
  tmp.x += 10.5;
  distort.y = HybridMultifractal(tmp, u_FractalIncrement, u_Lucinarity, u_Octaves, 0.6);

  pointTest.x += u_Distortion * distort.x;
  pointTest.y += u_Distortion * distort.y;

  fs_Sine = HybridMultifractal(pointTest, u_FractalIncrement, u_Lucinarity, u_Octaves, 0.6);

  fs_Sine -= 3.1;

  // fs_Sine = clamp(fs_Sine, 0.0, 10.0);

  // if (fs_Sine > 0.5)
  // {
  //   fs_Sine *= fbm;
  // }

  // if (fs_Sine > 0.6f)
  // {
  //   fs_Sine += fbm;
  //   fs_Sine = pow(fs_Sine, 5.0);
  //   fs_Sine /= float(octaves);
  // }

// if (fs_Sine > 0.0)
// {
//   if (fs_Sine >= 1.0)
//   {
//     fs_Sine = pow(fs_Sine, 2.0);
//   }
//   else
//   {
//     fs_Sine = pow(fs_Sine, .5);
//   }
// }

  fs_Sine = clamp(fs_Sine, 0.f, 10.f);
  fs_Sine = pow(fs_Sine, u_ElevationExponent);
  //fs_Sine /= float(octaves);


  //fs_Sine = clamp(fs_Sine - random1o2i(vec2(fs_Sine, fs_Sine)), 0.f, 1.f);

  vec4 modelposition = vec4(vs_Pos.x, fs_Sine, vs_Pos.z, 1.0);
  modelposition = u_Model * modelposition;
  gl_Position = u_ViewProj * modelposition;
}
