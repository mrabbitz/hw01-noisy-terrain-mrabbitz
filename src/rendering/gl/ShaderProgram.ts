import {vec2, vec4, mat4} from 'gl-matrix';
import Drawable from './Drawable';
import {gl} from '../../globals';

var activeProgram: WebGLProgram = null;

export class Shader {
  shader: WebGLShader;

  constructor(type: number, source: string) {
    this.shader = gl.createShader(type);
    gl.shaderSource(this.shader, source);
    gl.compileShader(this.shader);

    if (!gl.getShaderParameter(this.shader, gl.COMPILE_STATUS)) {
      throw gl.getShaderInfoLog(this.shader);
    }
  }
};

class ShaderProgram {
  prog: WebGLProgram;

  attrPos: number;
  attrNor: number;
  attrCol: number;

  unifModel: WebGLUniformLocation;
  unifModelInvTr: WebGLUniformLocation;
  unifViewProj: WebGLUniformLocation;
  unifColor: WebGLUniformLocation;
  unifPlanePos: WebGLUniformLocation;

  unifTime: WebGLUniformLocation;

  unifDistortion: WebGLUniformLocation;

  unifFractalIncrement: WebGLUniformLocation;
  unifLucinarity: WebGLUniformLocation;
  unifOctaves: WebGLUniformLocation;
  unifElevationExponent: WebGLUniformLocation;

  constructor(shaders: Array<Shader>) {
    this.prog = gl.createProgram();

    for (let shader of shaders) {
      gl.attachShader(this.prog, shader.shader);
    }
    gl.linkProgram(this.prog);
    if (!gl.getProgramParameter(this.prog, gl.LINK_STATUS)) {
      throw gl.getProgramInfoLog(this.prog);
    }

    this.attrPos = gl.getAttribLocation(this.prog, "vs_Pos");
    this.attrNor = gl.getAttribLocation(this.prog, "vs_Nor");
    this.attrCol = gl.getAttribLocation(this.prog, "vs_Col");
    this.unifModel      = gl.getUniformLocation(this.prog, "u_Model");
    this.unifModelInvTr = gl.getUniformLocation(this.prog, "u_ModelInvTr");
    this.unifViewProj   = gl.getUniformLocation(this.prog, "u_ViewProj");
    this.unifPlanePos   = gl.getUniformLocation(this.prog, "u_PlanePos");
  
    this.unifTime = gl.getUniformLocation(this.prog, "u_Time");
    this.unifDistortion = gl.getUniformLocation(this.prog, "u_Distortion");
    this.unifFractalIncrement = gl.getUniformLocation(this.prog, "u_FractalIncrement");
    this.unifLucinarity = gl.getUniformLocation(this.prog, "u_Lucinarity");
    this.unifOctaves = gl.getUniformLocation(this.prog, "u_Octaves");
    this.unifElevationExponent = gl.getUniformLocation(this.prog, "u_ElevationExponent");
  }

  use() {
    if (activeProgram !== this.prog) {
      gl.useProgram(this.prog);
      activeProgram = this.prog;
    }
  }

setElevationExponent(exponent: number)
  {
      this.use();
  
      if(this.unifElevationExponent !== -1)
      {
          gl.uniform1f(this.unifElevationExponent, exponent);
      }
  }
setOctaves(octaves: number)
{
    this.use();

    if(this.unifOctaves !== -1)
    {
        gl.uniform1f(this.unifOctaves, octaves);
    }
}
setLucinarity(lucinarity: number)
{
    this.use();

    if(this.unifLucinarity !== -1)
    {
        gl.uniform1f(this.unifLucinarity, lucinarity);
    }
}
setFractalIncrement(increment: number)
{
    this.use();

    if(this.unifFractalIncrement !== -1)
    {
        gl.uniform1f(this.unifFractalIncrement, increment);
    }
}

setDistortion(distortion: number)
{
    this.use();

    if(this.unifDistortion !== -1)
    {
        gl.uniform1f(this.unifDistortion, distortion);
    }
}

setTime(time: number)
{
    this.use();

    if(this.unifTime !== -1)
    {
        gl.uniform1f(this.unifTime, time);
    }
}

  setModelMatrix(model: mat4) {
    this.use();
    if (this.unifModel !== -1) {
      gl.uniformMatrix4fv(this.unifModel, false, model);
    }

    if (this.unifModelInvTr !== -1) {
      let modelinvtr: mat4 = mat4.create();
      mat4.transpose(modelinvtr, model);
      mat4.invert(modelinvtr, modelinvtr);
      gl.uniformMatrix4fv(this.unifModelInvTr, false, modelinvtr);
    }
  }

  setViewProjMatrix(vp: mat4) {
    this.use();
    if (this.unifViewProj !== -1) {
      gl.uniformMatrix4fv(this.unifViewProj, false, vp);
    }
  }

  setPlanePos(pos: vec2) {
    this.use();
    if (this.unifPlanePos !== -1) {
      gl.uniform2fv(this.unifPlanePos, pos);
    }
  }

  draw(d: Drawable) {
    this.use();

    if (this.attrPos != -1 && d.bindPos()) {
      gl.enableVertexAttribArray(this.attrPos);
      gl.vertexAttribPointer(this.attrPos, 4, gl.FLOAT, false, 0, 0);
    }

    if (this.attrNor != -1 && d.bindNor()) {
      gl.enableVertexAttribArray(this.attrNor);
      gl.vertexAttribPointer(this.attrNor, 4, gl.FLOAT, false, 0, 0);
    }

    d.bindIdx();
    gl.drawElements(d.drawMode(), d.elemCount(), gl.UNSIGNED_INT, 0);

    if (this.attrPos != -1) gl.disableVertexAttribArray(this.attrPos);
    if (this.attrNor != -1) gl.disableVertexAttribArray(this.attrNor);
  }
};

export default ShaderProgram;
