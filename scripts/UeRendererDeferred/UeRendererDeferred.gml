/**
 * @note Experimental and the Lightning pass needs to be reworked on in order to use light volumes.
 */
function UeRendererDeferred(data = {}): UeRenderer(data) constructor {
  self.type = "RendererDeferred";
  self.renderPath = UE_RENDER_PATH.DEFERRED;

  // G-Buffer (for Deferred Rendering)
  self.__gbuffer = undefined;
  self.__gbufferMaterial = new UeDeferredGBufferMaterial();
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

  function __syncGBufferMaterial(source) {
    gml_pragma("forceinline");
    var target = self.__gbufferMaterial;
    
    // Copy textures
    var sT = source.textures;
    target.textures.map = sT[$ "map"];
    target.textures.alphaMap = sT[$ "alphaMap"];
    target.textures.ormMap = sT[$ "ormMap"];
    target.textures.normalMap = sT[$ "normalMap"];
    target.textures.emissiveMap = sT[$ "emissiveMap"];
    target.textures.displacementMap = sT[$ "displacementMap"];
    
    // Copy uniforms (only if they exist in source)
    var uS = source.uniforms;
    var uT = target.uniforms;
    
    if (variable_struct_exists(uS, "ueColor")) uT.ueColor.value = uS.ueColor.value;
    else if (variable_struct_exists(source, "color")) uT.ueColor.value = source.color;
    
    if (variable_struct_exists(uS, "ueEmissive")) uT.ueEmissive.value = uS.ueEmissive.value;
    else if (variable_struct_exists(source, "emissive")) uT.ueEmissive.value = source.emissive;
    
    if (variable_struct_exists(uS, "ueMetalness")) uT.ueMetalness.value = uS.ueMetalness.value;
    else if (variable_struct_exists(source, "metalness")) uT.ueMetalness.value = source.metalness;
    
    if (variable_struct_exists(uS, "ueRoughness")) uT.ueRoughness.value = uS.ueRoughness.value;
    else if (variable_struct_exists(source, "roughness")) uT.ueRoughness.value = source.roughness;
    if (variable_struct_exists(uS, "ueAoIntensity")) uT.ueAoIntensity.value = uS.ueAoIntensity.value;
    if (variable_struct_exists(uS, "ueAoMapIntensity")) uT.ueAoMapIntensity.value = uS.ueAoMapIntensity.value;
    if (variable_struct_exists(uS, "ueNormalMapScale")) uT.ueNormalMapScale.value = uS.ueNormalMapScale.value;
    if (variable_struct_exists(uS, "ueDisplacementScale")) uT.ueDisplacementScale.value = uS.ueDisplacementScale.value;
    if (variable_struct_exists(uS, "ueDisplacementBias")) uT.ueDisplacementBias.value = uS.ueDisplacementBias.value;
    if (variable_struct_exists(uS, "ueFlatShading")) uT.ueFlatShading.value = uS.ueFlatShading.value;
    
    // Some properties might be directly on the material instead of uniforms
    if (variable_struct_exists(source, "receiveShadow")) uT.ueReceiveShadow.value = source.receiveShadow;
    if (variable_struct_exists(source, "flatShading")) uT.ueFlatShading.value = source.flatShading;
    
    // We need to re-build to update flags and texture cache
    target.build();
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
          self.__syncGBufferMaterial(_material);
          self.__gbufferMaterial.use(self);
          self.__gbufferMaterial.useByMesh(_object);
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

    // Clear G-Buffer
    draw_clear_alpha(c_black, 0);
    draw_clear_depth(1);

    camera_apply(camera.camera);

    self.__renderQueue(__queueOpaque, scene, false);

    surface_reset_target();

    // Reset shader and bound material
    shader_reset();
    __boundMaterial = undefined;

    // 2. Lighting Pass
    self.setRenderTarget(_oldRT);

    if (self.autoClear) self.clear(self.autoClearColor, self.autoClearDepth, self.autoClearStencil);

    // DEBUG: If you see white, uncomment this to see only Albedo
    // draw_surface(self.__gbuffer.albedoAlpha.surface, 0, 0); return self;

    var _lm = self.__deferredLightingMaterial;
    _lm.textures[$ "gbufferAlbedo"] = self.__gbuffer.albedoAlpha;
    _lm.textures[$ "gbufferNormal"] = self.__gbuffer.normalMetal;
    _lm.textures[$ "gbufferRoughnessAO"] = self.__gbuffer.roughnessAO;
    _lm.textures[$ "gbufferEmissive"] = self.__gbuffer.emissive;
    _lm.textures[$ "s_dirShadowMap"] = global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.DIRECTIONAL_COUNT] > 0 && global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.DIRECTIONAL][0].castShadow ? global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.DIRECTIONAL][0].shadow.map : undefined;
    _lm.textures[$ "s_pointShadowMap"] = global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.POINT_LIGHT_COUNT] > 0 && global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.POINT_LIGHT][0].castShadow ? global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.POINT_LIGHT][0].shadow.map : undefined;
    _lm.textures[$ "s_spotShadowMap"] = global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.SPOT_LIGHT_COUNT] > 0 && global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.SPOT_LIGHT][0].castShadow ? global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.SPOT_LIGHT][0].shadow.map : undefined;
    
    // IMPORTANT: Reset bound material to force lighting material to bind its own textures
    __boundMaterial = undefined;

    // Pass Depth Texture (of the first G-Buffer target, which holds the shared depth buffer)
    var _depthTex = surface_get_texture_depth(self.__gbuffer.albedoAlpha.surface);
    _lm.textures[$ "gbufferDepth"] = _depthTex;

    // Pass Inverse View-Projection Matrix for position reconstruction
    // World = Vinv * Pinv * Clip
    matrix_multiply(camera.projectionMatrixInverse, camera.matrixWorld, global.UE_MAT4_TEMP0);
    _lm.uniforms[$ "ueInvViewProj"].value = global.UE_MAT4_TEMP0;

    // Add lighting uniforms for shadow calculation
    var _dlCount = global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.DIRECTIONAL_COUNT];
    var _dl = (_dlCount > 0) ? global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.DIRECTIONAL][0] : undefined;
    if (_dl != undefined && _dl.castShadow) {
        _lm.setUniform("ueDirShadowMatrix", _dl.shadow.lightSpaceMatrix);
        _lm.setUniform("ueDirShadowEnabled", 1.0);
        _lm.setUniform("ueDirShadowQuality", self.shadowQuality);
        _lm.setUniform("ueDirShadowInvTexelSize", 1.0 / _dl.shadow.map.width);
    } else {
        _lm.setUniform("ueDirShadowEnabled", 0.0);
    }
    
    // Point shadows (simplified for now, only 1st shadow light)
    var _plCount = global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.POINT_LIGHT_COUNT];
    var _pl = undefined;
    for (var i = 0; i < _plCount; i++) {
        if (global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.POINT_LIGHT][i].castShadow) {
            _pl = global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.POINT_LIGHT][i];
            break;
        }
    }
    if (_pl != undefined) {
        _lm.setUniform("uePointShadowEnabled", 1.0);
        _lm.setUniform("uePointShadowFar", _pl.shadow.cameras[0].far);
        _lm.setUniform("uePointShadowNear", _pl.shadow.cameras[0].near);
        _lm.setUniform("uePointShadowPos", _pl.position);
        _lm.setUniform("uePointShadowQuality", self.shadowQuality);
        _lm.setUniform("uePointShadowInvTexelSize", [1.0 / (_pl.shadow.mapSize.width * 3.0), 1.0 / (_pl.shadow.mapSize.height * 2.0)]);
        
        var matrices = array_create(16 * 6);
        for (var i = 0; i < 6; i++) {
            var cam = _pl.shadow.cameras[i];
            matrix_multiply(cam.matrixWorldInverse, cam.projectionMatrix, global.UE_MAT4_TEMP0);
            for (var m = 0; m < 16; m++) matrices[i * 16 + m] = global.UE_MAT4_TEMP0[m];
        }
        _lm.setUniform("uePointShadowMatrix", matrices);
    } else {
        _lm.setUniform("uePointShadowEnabled", 0.0);
    }

    // Spot shadows
    var _slCount = global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.SPOT_LIGHT_COUNT];
    var _sl = undefined;
    for (var i = 0; i < _slCount; i++) {
        if (global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.SPOT_LIGHT][i].castShadow) {
            _sl = global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.SPOT_LIGHT][i];
            break;
        }
    }
    if (_sl != undefined) {
        _lm.setUniform("ueSpotShadowEnabled", 1.0);
        _lm.setUniform("ueSpotShadowMatrix", _sl.shadow.lightSpaceMatrix);
        _lm.setUniform("ueSpotShadowFar", _sl.shadow.camera.far);
        _lm.setUniform("ueSpotShadowNear", _sl.shadow.camera.near);
        _lm.setUniform("ueSpotShadowPos", _sl.position);
        _lm.setUniform("ueSpotShadowQuality", self.shadowQuality);
        _lm.setUniform("ueSpotShadowInvTexelSize", 1.0 / _sl.shadow.mapSize.width);
    } else {
        _lm.setUniform("ueSpotShadowEnabled", 0.0);
    }

    // Re-build material to update texture bindings
    _lm.build();

    // Apply camera matrices for lighting pass
    _lm.use(self);

    global.UE_FULLSCREEN_QUAD.material = _lm;
    global.UE_FULLSCREEN_QUAD.render(self.__gbuffer.albedoAlpha.getTexture(), true);
    
    shader_reset(); // Reset lighting shader before forward pass

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
