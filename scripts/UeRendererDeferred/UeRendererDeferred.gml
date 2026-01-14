/**
 * @note Experimental and the Lightning pass needs to be reworked on in order to use light volumes.
 */
function UeRendererDeferred(data = {}): UeRenderer(data) constructor {
  self.type = "RendererDeferred";
  self.renderPath = UE_RENDER_PATH.DEFERRED;

  // G-Buffer (for Deferred Rendering)
  self.__gbuffer = undefined;
  self.__gbufferMaterial = new UeMaterial({ shader: sh_ue_gbuffer });
  self.__deferredLightingMaterial = new UeMaterial({
    shader: sh_ue_deferred_lighting,
    uniforms: {
      ueInvViewProj: { type: UE_UNIFORM_TYPE.MAT4 }
    }
  });

  function __initGBuffer() {
    gml_pragma("forceinline");
    if (self.__gbuffer != undefined) return;

    self.__gbuffer = {
      albedoAlpha: new UeRenderTarget(self.width, self.height),
      normalMetal: new UeRenderTarget(self.width, self.height, { internalFormat: surface_rgba16float }),
      roughnessAO: new UeRenderTarget(self.width, self.height, { internalFormat: surface_rgba16float }),
      emissive: new UeRenderTarget(self.width, self.height, { internalFormat: surface_rgba16float })
    };
  }

  function setSize(width, height) {
    gml_pragma("forceinline");
    self.width = width;
    self.height = height;

    if (self.__gbuffer != undefined) {
      self.__gbuffer.albedoAlpha.setSize(width, height);
      self.__gbuffer.normalMetal.setSize(width, height);
      self.__gbuffer.roughnessAO.setSize(width, height);
      self.__gbuffer.emissive.setSize(width, height);
    }
  }

  /**
   * Render a specific queue of objects
   */
  function __renderQueue(queue, scene, isTransparentPass = false) {
    gml_pragma("forceinline");
    var overrideMaterial = scene[$ "overrideMaterial"];

    for (var i = 0, len = array_length(queue); i < len; i++) {
      var _object = queue[i];
      var _onBeforeRender = _object[$ "onBeforeRender"];
      var _onAfterRender = _object[$ "onAfterRender"];
      var _material = _object[$ "material"] ?? global.UE_FALLBACK_MATERIAL;

      // Override material
      if (overrideMaterial != undefined && _material[$ "allowOverride"]) {
        _material = overrideMaterial;
      }

      // Wireframes material applies the default material
      var _wireframe = _material.wireframe;
      if (_wireframe) {
        _material = global.UE_DEFAULT_MATERIAL_WIREFRAME;
      }

      // Use the material
      if (_material.visible) {
        if (!isTransparentPass) {
          // Use G-Buffer shader but keep material settings
          _material.use(self, sh_ue_gbuffer);
          _material.useByMesh(_object);
          __boundMaterial = undefined; // Force re-bind for other passes
        } else {
          if (_material != __boundMaterial) {
            __boundMaterial = _material;
            _material.use(self);
          }
          _material.useByMesh(_object);
        }
      }

      if (_onBeforeRender != undefined) _onBeforeRender();
      _object.render(_wireframe);
      if (_onAfterRender != undefined) _onAfterRender();
    }
  }

  /// Render the scene
  function render(scene, camera) {
    gml_pragma("forceinline");

    if (!self.__prepareFrame(scene, camera)) return self;

    var _gpuState = gpu_get_state();

    // **PASS 2: Main camera pass**
    // --- DEFERRED PATH ---
    self.__initGBuffer();
    var _oldRT = self.getRenderTarget();

    // Ensure all G-buffer surfaces exist (they can be freed by GameMaker at any time)
    if (!surface_exists(self.__gbuffer.albedoAlpha.surface)) self.__gbuffer.albedoAlpha.create();
    if (!surface_exists(self.__gbuffer.normalMetal.surface)) self.__gbuffer.normalMetal.create();
    if (!surface_exists(self.__gbuffer.roughnessAO.surface)) self.__gbuffer.roughnessAO.create();
    if (!surface_exists(self.__gbuffer.emissive.surface)) self.__gbuffer.emissive.create();

    // 1. G-Buffer Pass (Opaque objects)
    surface_set_target_ext(0, self.__gbuffer.albedoAlpha.surface);
    surface_set_target_ext(1, self.__gbuffer.normalMetal.surface);
    surface_set_target_ext(2, self.__gbuffer.roughnessAO.surface);
    surface_set_target_ext(3, self.__gbuffer.emissive.surface);

    self.clear(true, true, true);
    camera_apply(camera.camera);

    self.__renderQueue(__queueOpaque, scene, false);

    surface_reset_target();

    // 2. Lighting Pass
    self.setRenderTarget(_oldRT);

    if (self.autoClear) self.clear(self.autoClearColor, self.autoClearDepth, self.autoClearStencil);

    var _lm = self.__deferredLightingMaterial;
    _lm.textures[$ "gbufferAlbedo"] = self.__gbuffer.albedoAlpha;
    _lm.textures[$ "gbufferNormal"] = self.__gbuffer.normalMetal;
    _lm.textures[$ "gbufferRoughnessAO"] = self.__gbuffer.roughnessAO;
    _lm.textures[$ "gbufferEmissive"] = self.__gbuffer.emissive;

    // Pass Depth Texture (of the first G-Buffer target, which holds the shared depth buffer)
    var _depthTex = surface_get_texture_depth(self.__gbuffer.albedoAlpha.surface);
    _lm.textures[$ "gbufferDepth"] = _depthTex;

    // Pass Inverse View-Projection Matrix for position reconstruction
    // We can multiply the pre-calculated inverses from the camera
    matrix_multiply(camera.projectionMatrixInverse, camera.matrixWorld, global.UE_MAT4_TEMP0);
    _lm.uniforms[$ "ueInvViewProj"].value = global.UE_MAT4_TEMP0;

    // Apply camera matrices for lighting pass
    _lm.use(self);

    global.UE_FULLSCREEN_QUAD.material = _lm;
    global.UE_FULLSCREEN_QUAD.render(undefined, true);

    // 3. Forward Pass (Transparent objects)
    camera_apply(camera.camera);
    if (array_length(__queueTransparent) > 0) {
      self.__restoreDepth(__queueOpaque);
    }

    self.__renderQueue(__queueTransparent, scene, true);

    // Reset the world after rendering
    __boundMaterial = undefined;
    shader_reset();
    matrix_set(matrix_world, global.UE_MAT4_IDENTITY);
    gpu_set_state(_gpuState);

    return self;
  }
}
