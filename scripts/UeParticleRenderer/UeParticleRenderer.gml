global.UE_PARTICLE_VERSION = "1.2.1";
global.UE_PARTICLE_RENDER_FORMAT = undefined;

/**
 * @description State-of-the-art GPU Particle Renderer. 
 * Orchestrates shaders, uniforms, and procedural textures.
 */
function UeParticleRenderer(_shaders = {}) constructor {
  gml_pragma("forceinline");

  // ===== Vertex Format (52 bytes) =====
  if (global.UE_PARTICLE_RENDER_FORMAT == undefined) {
    vertex_format_begin();
    vertex_format_add_position_3d();                                      // in_Position (SpawnPos)
    vertex_format_add_colour();                                           // in_Colour (Start)
    vertex_format_add_custom(vertex_type_float2, vertex_usage_texcoord);   // in_TextureCoord (CornerXY)
    vertex_format_add_custom(vertex_type_float4, vertex_usage_texcoord);   // in_TextureCoord1 (VelXYZ + SpawnTime)
    vertex_format_add_custom(vertex_type_float3, vertex_usage_texcoord);   // in_TextureCoord2 (MaxLife, sStart, rStart)
    global.UE_PARTICLE_RENDER_FORMAT = vertex_format_end();
  }
  self.format = global.UE_PARTICLE_RENDER_FORMAT;

  self.shader = _shaders[$ "main"] ?? sh_ue_particle;
  self.uRight = shader_get_uniform(self.shader, "u_ueCameraRight");
  self.uUp = shader_get_uniform(self.shader, "u_ueCameraUp");
  self.uUVRegion = shader_get_uniform(self.shader, "u_ueUVRegion");
  self.uTime = shader_get_uniform(self.shader, "u_ueTime");
  
  self.uGrav   = shader_get_uniform(self.shader, "u_ueGravity");
  self.uSizeE  = shader_get_uniform(self.shader, "u_ueSizeEnd");
  
  self.uColM   = shader_get_uniform(self.shader, "u_ueColorMid");
  self.uColE   = shader_get_uniform(self.shader, "u_ueColorEnd");
  self.uColT   = shader_get_uniform(self.shader, "u_ueColorTimes"); // x: midTime, y: glow
  
  self.uRotSpd = shader_get_uniform(self.shader, "u_ueRotSpeed");
  self.uDrag   = shader_get_uniform(self.shader, "u_ueDrag");
  self.uAnim   = shader_get_uniform(self.shader, "u_ueAnimData"); // x: framesX, y: framesY, z: animSpeed
  
  self.uDepthTex = shader_get_sampler_index(self.shader, "u_ueDepthTex");
  self.uDepthParams = shader_get_uniform(self.shader, "u_ueDepthParams");

  self.uShadowTex = shader_get_sampler_index(self.shader, "u_ueShadowTex");
  self.uShadowMatrix = shader_get_uniform(self.shader, "u_ueShadowMatrix");
  self.uShadowParams = shader_get_uniform(self.shader, "u_ueShadowParams");

  // ===== Procedural Shape Generator =====
  self.shapes = {};
  
  /**
   * @description Internal helper to create textured procedural shapes.
   * @param {string} _name Identifier for the shape.
   * @param {function} _drawFunc Function that draws the shape on a surface.
   * @returns {struct} Struct containing texture and UV data.
   * @private
   */
  static __createShape = function (_name, _drawFunc) {
    var _res = 64;
    var _surf = surface_create(_res, _res);
    if (!surface_exists(_surf)) return undefined;
    surface_set_target(_surf);
    draw_clear_alpha(c_black, 0); _drawFunc(_res);
    surface_reset_target();
    var _spr = sprite_create_from_surface(_surf, 0, 0, _res, _res, false, false, _res/2, _res/2);
    surface_free(_surf);
    var _tex = sprite_get_texture(_spr, 0), _uvs = texture_get_uvs(_tex);
    self.shapes[$ _name] = { sprite: _spr, texture: _tex, uvs: [_uvs[0], _uvs[1], _uvs[2]-_uvs[0], _uvs[3]-_uvs[1]] };
    return self.shapes[$ _name];
  };

  // Build standard shape library
  self.__createShape("point", function(r) { draw_circle(r/2, r/2, r/2-2, false); });
  self.__createShape("sphere", function(r) {
    gpu_set_blendmode(bm_add);
    for(var i=0; i<r/2; i++) { draw_set_alpha((1-i/(r/2))*0.5); draw_circle(r/2, r/2, i, false); }
    gpu_set_blendmode(bm_normal); draw_set_alpha(1.0);
  });
  self.__createShape("smoke", function(r) {
      draw_set_alpha(0.3);
      var m = r/2;
      for(var i=0; i<8; i++) {
          var ang = i * 45;
          var dist = random_range(2, r/4);
          draw_circle(m + lengthdir_x(dist, ang), m + lengthdir_y(dist, ang), random_range(r/4, r/2.5), false);
      }
      draw_set_alpha(1);
  });
  self.__createShape("flare", function(r) {
      var m = r/2; draw_set_alpha(0.5);
      for(var i=0; i<r/2; i++) { draw_line_width(m-i, m, m+i, m, 2); draw_line_width(m, m-i, m, m+i, 2); }
      draw_set_alpha(1); draw_circle(m, m, r/6, false);
  });
  self.__createShape("square", function(r) { draw_rectangle(4, 4, r-5, r-5, false); });
  self.__createShape("box", function(r) { draw_rectangle(4, 4, r-5, r-5, true); });
  self.__createShape("disk", function(r) { draw_circle(r/2, r/2, r/2-2, false); });
  self.__createShape("ring", function(r) {
      draw_set_circle_precision(32);
      draw_circle(r/2, r/2, r/2-2, true);
      draw_circle(r/2, r/2, r/2-3, true); 
  });

  self.fallbackTexture = self.shapes.sphere.texture;

  /**
   * @description Low-level submission of a vertex buffer to the GPU.
   * Handles uniform updates and shader state.
   * @param {UeParticleEmitter} emitter The emitter whose buffer will be submitted.
   * @param {resource.camera} camera Reference camera for billboarding.
   * @param {struct} type The particle type containing visual data (texture, uvs).
   * @param {texture} depthTex Optional depth texture for soft particles.
   * @param {array} depthParams [near, far, softness, enabled]
   * @param {texture} shadowTex Optional shadow map texture.
   * @param {array} shadowMatrix 4x4 matrix for shadow projection.
   * @param {array} shadowParams [strength, bias, resolution, enabled]
   */
  static submit = function(emitter, camera, type, depthTex = undefined, depthParams = undefined, shadowTex = undefined, shadowMatrix = undefined, shadowParams = undefined) {
      gml_pragma("forceinline");
      shader_set(self.shader);
      var vm = camera_get_view_mat(camera);
      shader_set_uniform_f(self.uTime, current_time / 1000.0);
      shader_set_uniform_f_array(self.uUVRegion, type.uvs);
      shader_set_uniform_f(self.uRight, vm[0], vm[4], vm[8]);
      shader_set_uniform_f(self.uUp, vm[1], vm[5], vm[9]);
      
      shader_set_uniform_f(self.uGrav, type.gravX, type.gravY, type.zGravAmount);
      shader_set_uniform_f(self.uSizeE, type.sizeMin + type.sizeIncr * type.lifeMax);
      
      shader_set_uniform_f(self.uColM, type.colorMid[0], type.colorMid[1], type.colorMid[2]);
      shader_set_uniform_f(self.uColE, type.colorEnd[0], type.colorEnd[1], type.colorEnd[2], type.alphaEnd);
      shader_set_uniform_f(self.uColT, type.colorMidTime, type.glow);
      
      shader_set_uniform_f(self.uRotSpd, type.rotIncr);
      shader_set_uniform_f(self.uDrag, type.drag);
      shader_set_uniform_f(self.uAnim, type.animFramesX, type.animFramesY, type.animSpeed);

      if (depthTex != undefined && depthParams != undefined) {
          texture_set_stage(self.uDepthTex, depthTex);
          shader_set_uniform_f(self.uDepthParams, depthParams[0], depthParams[1], depthParams[2], 1.0);
      } else {
          shader_set_uniform_f(self.uDepthParams, 0, 0, 0, 0);
      }

      if (shadowTex != undefined && shadowMatrix != undefined && shadowParams != undefined) {
          texture_set_stage(self.uShadowTex, shadowTex);
          shader_set_uniform_matrix_array(self.uShadowMatrix, shadowMatrix);
          shader_set_uniform_f(self.uShadowParams, shadowParams[0], shadowParams[1], shadowParams[2], 1.0);
      } else {
          static identity = matrix_build_identity();
          shader_set_uniform_matrix_array(self.uShadowMatrix, identity);
          shader_set_uniform_f(self.uShadowParams, 0, 0, 0, 0);
      }

      gpu_set_zwriteenable(false);
      vertex_submit(emitter.vbuffer, pr_trianglelist, type.texture);
      gpu_set_zwriteenable(true);
      shader_reset();
  }
}

global.UE_PARTICLE_RENDERER = new UeParticleRenderer();
