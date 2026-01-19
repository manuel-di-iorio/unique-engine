function UeRenderer(data = {}): UeObject3D(data) constructor {
  isRenderer = true;
  type = "Renderer";
  sortObjects = data[$ "sortObjects"] ?? true;
  width = data[$ "width"] ?? display_get_width();
  height = data[$ "height"] ?? display_get_height();
  autoClear = data[$ "autoClear"] ?? false;
  autoClearColor = data[$ "autoClearColor"] ?? true;
  autoClearDepth = data[$ "autoClearDepth"] ?? true;
  autoClearStencil = data[$ "autoClearStencil"] ?? true;
  __clearColor = c_white;
  __clearAlpha = 1;
  __renderTarget = undefined;

  // Shadow map configuration for the renderer
  shadowMap = data[$ "shadowMap"] ?? {};
  shadowMap.enabled = shadowMap[$ "enabled"] ?? false;
  shadowMap.autoUpdate = shadowMap[$ "autoUpdate"] ?? true;
  shadowMap.needsUpdate = shadowMap[$ "needsUpdate"] ?? false;

  // Tone Mapping
  toneMapping = data[$ "toneMapping"] ?? UE_TONE_MAPPING.NONE;
  toneMappingExposure = data[$ "toneMappingExposure"] ?? 1.0;

  self.renderPath = data[$ "renderPath"] ?? UE_RENDER_PATH.FORWARD;
  self.shadowQuality = data[$ "shadowQuality"] ?? UE_SHADOW_QUALITY.HIGH;

  function setSize(width, height) {
    gml_pragma("forceinline");
    self.width = width;
    self.height = height;
  }

  function getSize(target = undefined) {
    gml_pragma("forceinline");
    target ??= {};
    target.width = self.width;
    target.height = self.height;
    return target;
  }

  __boundMaterial = undefined; // Material that is currently bound
  __lights = [];
  __queueShadow = [];
  __queueOpaque = [];
  __queueTransparent = [];

  function clear(color = true, depth = true, stencil = true) {
    if (color) draw_clear_alpha(self.__clearColor, self.__clearAlpha);
    if (depth) draw_clear_depth(1);
    if (stencil) draw_clear_stencil(0);
  }

  function clearColor() {
    draw_clear_alpha(self.__clearColor, self.__clearAlpha);
  }

  function clearDepth() {
    draw_clear_depth(1);
  }

  function clearStencil() {
    draw_clear_stencil(0);
  }

  function getClearColor() {
    return self.__clearColor;
  }

  function getClearAlpha() {
    return self.__clearAlpha;
  }

  function setClearAlpha(alpha) {
    self.__clearAlpha = alpha;
  }

  function setClearColor(color, alpha) {
    self.__clearColor = color;
    self.__clearAlpha = alpha;
  }

  function setRenderTarget(target) {
    // If we currently have a target, we need to reset it first
    if (self.__renderTarget != undefined) {
      surface_reset_target();
    }

    // Now set the new target if provided
    if (target != undefined) {
      if (!surface_exists(target.surface)) target.create();
      surface_set_target(target.surface);
    }

    self.__renderTarget = target;
  }

  function getRenderTarget() {
    return self.__renderTarget;
  }

  // Recursively collect renderable objects and precompute their sort key
  function __collectObjectQueues(objects, camera) {
    gml_pragma("forceinline");
    var cameraPos = camera.position;
    var cameraLayers = camera.layers;
    var _maxDistSq = camera.far * camera.far;

    for (var i = 0, len = array_length(objects); i < len; i++) {
      var object = objects[i];

      // Skip invisible objects and their children
      if (!object.visible || !object.layers.test(cameraLayers)) continue;

      // Update matrices for dynamic objects
      if (object.matrixAutoUpdate && object.matrixWorldAutoUpdate) object.updateMatrixWorld();

      // Precompute distance to camera for LOD and transparency sorting
      // We use the world matrix position for accuracy even if parented
      var _mw = object.matrixWorld;
      var _ox = _mw[12], _oy = _mw[13], _oz = _mw[14];
      var _cx = cameraPos[0], _cy = cameraPos[1], _cz = cameraPos[2];
      var _distSq = (_ox - _cx) * (_ox - _cx) + (_oy - _cy) * (_oy - _cy) + (_oz - _cz) * (_oz - _cz);
      object.__distanceToCameraSq = _distSq;

      if (object[$ "isLOD"] && object.autoUpdate) {
        object.update(camera);
      }

      if (object[$ "isLight"]) {
        array_push(__lights, object);
        continue;
      }

      /* Frustum intersection && sort key calculation */
      var _isRenderable = (object[$ "geometry"] != undefined && object.geometry[$ "vb"] != undefined);
      if (_isRenderable) {
        // 1. Shadow Pass Collection (All shadow casters)
        // We collect them here, but the actual frustum culling per light happens in __renderShadowMaps
        if (object.castShadow) {
          array_push(__queueShadow, object);
        }

        // 2. Camera Pass Collection (Frustum Culling)
        if (object.frustumCulled) {
          var _s = object.__intersectionSphere;
          if (_s != undefined && !sphere_is_visible(_s[0], _s[1], _s[2], _s[3])) continue;
        }

        var _material = object[$ "material"] ?? global.UE_FALLBACK_MATERIAL;

        if (_material.transparent) {
          // ---- TRANSPARENT ----
          // 16 bit renderOrder | 32 bit inverted depth
          var nd = clamp(_distSq / _maxDistSq, 0, 1);
          var depth32 = floor(nd * 0xFFFFFFFF);

          // back-to-front → invert
          depth32 = 0xFFFFFFFF - depth32;

          object.__transparentSortKey =
            ((object.renderOrder & 0xFFFF) << 32) |
            depth32;

          array_push(__queueTransparent, object);

        } else {
          // ---- OPAQUE ----
          // 16 bit renderOrder | 16 bit materialId
          object.__opaqueSortKey =
            ((object.renderOrder & 0xFFFF) << 16) |
            (_material.id & 0xFFFF);

          array_push(__queueOpaque, object);
        }
      }

      // Traverse child objects
      if (array_length(object.children) > 0) __collectObjectQueues(object.children, camera);
    }
  }

  /**
   * Renders shadow maps for all shadow-casting lights.
   * This must be called before the main render pass.
   * @param {Struct} scene - The scene to render
   */
  function __renderShadowMaps(scene, camera) {
    gml_pragma("forceinline");

    // Configure GPU state for shadow depth pass
    var _prevCull = gpu_get_cullmode();
    var _prevZTest = gpu_get_ztestenable();
    var _prevZWrite = gpu_get_zwriteenable();
    var _prevBlend = gpu_get_blendenable();
    gpu_set_cullmode(cull_counterclockwise);
    gpu_set_ztestenable(true);
    gpu_set_zwriteenable(true);
    gpu_set_blendenable(false);

    var _shadowCount = array_length(__queueShadow);
    for (var i = 0, len = array_length(__lights); i < len; i++) {
      var light = __lights[i];
      if (!light.castShadow) continue;

      switch (light.lightType) {
        case "DirectionalLight":
          light.shadow.map.render(light, scene, camera, __queueShadow, _shadowCount);
          break;

        case "PointLight":
          light.shadow.render(light, scene, camera, __queueShadow, _shadowCount);
          break;

        case "SpotLight":
          light.shadow.render(light, scene, camera, __queueShadow, _shadowCount);
          break;
      }
    }

    // Restore previous GPU state
    shader_reset();
    gpu_set_cullmode(_prevCull);
    gpu_set_ztestenable(_prevZTest);
    gpu_set_zwriteenable(_prevZWrite);
    gpu_set_blendenable(_prevBlend);
    camera_apply(camera.camera);
  }

  __lightStateVersion = 0;
  __lastLightHash = 0; // Numeric hash

  // Aggregate light data from scene lights
  function __buildLightState() {
    gml_pragma("forceinline");
    var lights = self.__lights;
    var len = array_length(lights);
    var lightState = global.UE_RENDERER_LIGHT_STATE;
    
    // 1. Unified loop for hashing and state classification
    var _newHash = 2166136261; // FNV-1a offset basis
    
    var ambientState = lightState[UE_RENDERER_LIGHT_STATE_ENUM.AMBIENT];
    ambientState[0] = 0; ambientState[1] = 0; ambientState[2] = 0;

    var directionalState = lightState[UE_RENDERER_LIGHT_STATE_ENUM.DIRECTIONAL];
    var pointLightState = lightState[UE_RENDERER_LIGHT_STATE_ENUM.POINT_LIGHT];
    var spotLightState = lightState[UE_RENDERER_LIGHT_STATE_ENUM.SPOT_LIGHT];
    var hemiLightState = lightState[UE_RENDERER_LIGHT_STATE_ENUM.HEMI_LIGHT];

    var dIdx = 0, pIdx = 0, sIdx = 0, hIdx = 0;
    
    for (var i = 0; i < len; i++) {
        var l = lights[i];
        if (!l.enabled) continue;
        
        // FNV-1a hash update (numeric)
        _newHash = ((_newHash ^ l.id) * 16777619) & 0xFFFFFFFF;
        _newHash = ((_newHash ^ l.version) * 16777619) & 0xFFFFFFFF;
        _newHash = ((_newHash ^ l.paramsVersion) * 16777619) & 0xFFFFFFFF;

        // Classify and accumulate
        switch (l.lightType) {
            case "AmbientLight":
                ambientState[0] += l.color[0] * l.intensity;
                ambientState[1] += l.color[1] * l.intensity;
                ambientState[2] += l.color[2] * l.intensity;
                break;
            case "DirectionalLight": directionalState[dIdx++] = l; break;
            case "PointLight": pointLightState[pIdx++] = l; break;
            case "SpotLight": spotLightState[sIdx++] = l; break;
            case "HemisphereLight": hemiLightState[hIdx++] = l; break;
        }
    }

    if (_newHash == self.__lastLightHash) return;
    self.__lastLightHash = _newHash;
    self.__lightStateVersion++;

    global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.DIRECTIONAL_COUNT] = dIdx;
    global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.POINT_LIGHT_COUNT] = pIdx;
    global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.SPOT_LIGHT_COUNT] = sIdx;
    global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.HEMI_LIGHT_COUNT] = hIdx;

    // Clamp ambient light
    ambientState[0] = clamp(ambientState[0], 0, 1);
    ambientState[1] = clamp(ambientState[1], 0, 1);
    ambientState[2] = clamp(ambientState[2], 0, 1);

    // 2. Pre-pack light data for shaders (Optimized with direct matrix access and versioning)
    var _maxPoints = global.UE_MAX_POINT_LIGHTS;
    var _maxSpots = global.UE_MAX_SPOT_LIGHTS;

    // --- Point Lights Data ---
    var pointLightsData = global.UE_POINT_LIGHTS_DATA_BUFFER;
    for (var i = 0; i < _maxPoints; i++) {
        var offset = i * 16;
        if (i < pIdx) {
            var l = pointLightState[i];
            // Only repack if version changed
            if (l.version != (l[$ "__cachedV"] ?? -1) || l.paramsVersion != (l[$ "__cachedPV"] ?? -1)) {
                var _mw = l.matrixWorld;
                pointLightsData[offset + 0] = _mw[12];
                pointLightsData[offset + 1] = _mw[13];
                pointLightsData[offset + 2] = _mw[14];
                pointLightsData[offset + 3] = l.distance;
                pointLightsData[offset + 4] = l.color[0];
                pointLightsData[offset + 5] = l.color[1];
                pointLightsData[offset + 6] = l.color[2];
                pointLightsData[offset + 7] = l.intensity;
                pointLightsData[offset + 8] = l.decay;
                l.__cachedV = l.version;
                l.__cachedPV = l.paramsVersion;
            }
        } else {
            pointLightsData[offset + 7] = 0; // Intensity = 0
        }
    }

    // --- Spot Lights Data ---
    var spotLightsData = global.UE_SPOT_LIGHTS_DATA_BUFFER;
    for (var i = 0; i < _maxSpots; i++) {
        var offset = i * 16;
        if (i < sIdx) {
            var l = spotLightState[i];
            if (l.version != (l[$ "__cachedV"] ?? -1) || l.paramsVersion != (l[$ "__cachedPV"] ?? -1) || l.target.version != (l[$ "__cachedTV"] ?? -1)) {
                var _mw = l.matrixWorld;
                spotLightsData[offset + 0] = _mw[12];
                spotLightsData[offset + 1] = _mw[13];
                spotLightsData[offset + 2] = _mw[14];
                spotLightsData[offset + 3] = l.distance;
                spotLightsData[offset + 4] = l.color[0];
                spotLightsData[offset + 5] = l.color[1];
                spotLightsData[offset + 6] = l.color[2];
                spotLightsData[offset + 7] = l.intensity;
                
                var worldDir = global.UE_VEC3_TEMP4;
                l.getDirection(worldDir); // Still using getDirection for now as it handles normalization/target
                spotLightsData[offset + 8] = worldDir[0];
                spotLightsData[offset + 9] = worldDir[1];
                spotLightsData[offset + 10] = worldDir[2];
                spotLightsData[offset + 11] = l.decay;
                spotLightsData[offset + 12] = cos(degtorad(l.angle));
                spotLightsData[offset + 13] = cos(degtorad(l.angle * (1.0 - l.penumbra)));
                
                l.__cachedV = l.version;
                l.__cachedPV = l.paramsVersion;
                l.__cachedTV = l.target.version;
            }
        } else {
            spotLightsData[offset + 7] = 0;
        }
    }

    // --- Primary Directional Light Data ---
    if (dIdx > 0) {
        var l = directionalState[0];
        if (l.version != (l[$ "__cachedV"] ?? -1) || l.paramsVersion != (l[$ "__cachedPV"] ?? -1) || l.target.version != (l[$ "__cachedTV"] ?? -1)) {
            var dir = global.UE_VEC3_TEMP4;
            l.getDirection(dir);
            global.UE_DIR_LIGHT_DATA.direction[0] = dir[0];
            global.UE_DIR_LIGHT_DATA.direction[1] = dir[1];
            global.UE_DIR_LIGHT_DATA.direction[2] = dir[2];
            global.UE_DIR_LIGHT_DATA.color = l.color;
            global.UE_DIR_LIGHT_DATA.intensity = l.intensity;
            l.__cachedV = l.version;
            l.__cachedPV = l.paramsVersion;
            l.__cachedTV = l.target.version;
        }
    } else {
        global.UE_DIR_LIGHT_DATA.intensity = 0;
    }

    // --- Hemisphere Light Data ---
    if (hIdx > 0) {
        var l = hemiLightState[0];
        if (l.version != (l[$ "__cachedV"] ?? -1) || l.paramsVersion != (l[$ "__cachedPV"] ?? -1)) {
            var _mw = l.matrixWorld;
            var _nx = _mw[12], _ny = _mw[13], _nz = _mw[14];
            var _invLen = 1.0 / sqrt(_nx*_nx + _ny*_ny + _nz*_nz);
            global.UE_HEMI_LIGHT_DATA.direction[0] = _nx * _invLen;
            global.UE_HEMI_LIGHT_DATA.direction[1] = _ny * _invLen;
            global.UE_HEMI_LIGHT_DATA.direction[2] = _nz * _invLen;
            global.UE_HEMI_LIGHT_DATA.skyColor = l.skyColor;
            global.UE_HEMI_LIGHT_DATA.groundColor = l.groundColor;
            global.UE_HEMI_LIGHT_DATA.intensity = l.intensity;
            l.__cachedV = l.version;
            l.__cachedPV = l.paramsVersion;
        }
    } else {
        global.UE_HEMI_LIGHT_DATA.intensity = 0;
    }

    // --- Point Shadow Matrices ---
    // Optimization: Cache the shadow caster index to avoid scanning every frame
    var pointShadowLight = undefined;
    var _cachedIdx = self[$ "__cachedPointShadowIdx"] ?? -1;
    if (_cachedIdx >= 0 && _cachedIdx < pIdx && pointLightState[_cachedIdx].castShadow) {
        pointShadowLight = pointLightState[_cachedIdx];
    } else {
        for (var i = 0; i < pIdx; i++) {
            if (pointLightState[i].castShadow) {
                pointShadowLight = pointLightState[i];
                self.__cachedPointShadowIdx = i;
                break;
            }
        }
    }
    
    if (pointShadowLight != undefined) {
        var matrices = global.UE_POINT_SHADOW_MATRICES_BUFFER;
        for (var i = 0; i < 6; i++) {
            var cam = pointShadowLight.shadow.cameras[i];
            matrix_multiply(cam.matrixWorldInverse, cam.projectionMatrix, global.UE_MAT4_TEMP0);
            for (var m = 0; m < 16; m++) matrices[i * 16 + m] = global.UE_MAT4_TEMP0[m];
        }
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
        if (_material != __boundMaterial) {
          __boundMaterial = _material;
          shader_set(_material.shader);
          _material.use(self);
        }
        _material.useByMesh(_object);
      }

      if (_onBeforeRender != undefined) _onBeforeRender();
      _object.render(_wireframe);
      if (_onAfterRender != undefined) _onAfterRender();
    }
  }

  function __restoreDepth(queue) {
    gml_pragma("forceinline");
    if (array_length(queue) == 0) return;

    shader_set(sh_ue_depth_restoration);
    gpu_set_colorwriteenable(false, false, false, false);
    gpu_set_zwriteenable(true);
    gpu_set_ztestenable(true);
    gpu_set_cullmode(cull_counterclockwise);

    for (var i = 0, len = array_length(queue); i < len; i++) {
      var _object = queue[i];
      if (_object.geometry == undefined) continue;
      _object.render(false);
    }

    gpu_set_colorwriteenable(true, true, true, true);
    shader_reset();
  }

  function __prepareFrame(scene, camera) {
    gml_pragma("forceinline");

    // When rendering to a surface (render target), skip the view check since
    // there's no active view. Otherwise, ensure we're on the correct view.
    if (self.__renderTarget == undefined && view_current != camera.view) return false;

    // Collect and classify all renderable objects
    if (camera.matrixAutoUpdate) camera.updateMatrixWorld();

    array_resize(__lights, 0);
    array_resize(__queueShadow, 0);
    array_resize(__queueOpaque, 0);
    array_resize(__queueTransparent, 0);

    // Collect all renderable objects
    __collectObjectQueues(scene.children, camera);

    // **PASS 1: Render shadow maps for shadow-casting lights**
    if (shadowMap.enabled && (shadowMap.autoUpdate || shadowMap.needsUpdate)) {
      __renderShadowMaps(scene, camera);
      shadowMap.needsUpdate = false;
    }

    // Build the light state after shadow maps so matrices and textures are current
    __buildLightState();

    // Set camera position and tone mapping state for materials
    global.UE_RENDERER_ACTIVE_CAMERA = camera;
    global.UE_RENDERER_CAMERA_POSITION = camera.position;
    global.UE_RENDERER_TONE_MAPPING = self.toneMapping;
    global.UE_RENDERER_TONE_MAPPING_EXPOSURE = self.toneMappingExposure;

    // Pack Scene Data into a single array for shaders
    var sceneFog = scene.fog;
    var fogEnabled = sceneFog != undefined ? sceneFog.enabled : false;
    var fogColor = sceneFog != undefined ? sceneFog.color : [0.5, 0.5, 0.5];
    var fogDensity = fogEnabled ? sceneFog.density : 0;
    var fogNear = fogEnabled ? sceneFog.near : 0;
    var fogFar = fogEnabled ? sceneFog.far : 0;

    // Scene Data [3] vec4
    var sceneData = global.UE_SCENE_DATA_BUFFER; // Use a pre-allocated array to avoid GC

    // [0] CameraPos.xyz, FogDensity
    sceneData[0] = camera.position[0];
    sceneData[1] = camera.position[1];
    sceneData[2] = camera.position[2];
    sceneData[3] = fogDensity;

    // [1] Ambient.rgb, FogNear
    var _ambientState = global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.AMBIENT];
    sceneData[4] = _ambientState[0];
    sceneData[5] = _ambientState[1];
    sceneData[6] = _ambientState[2];
    sceneData[7] = fogNear;

    // [2] FogColor.rgb, FogFar
    sceneData[8] = fogColor[0];
    sceneData[9] = fogColor[1];
    sceneData[10] = fogColor[2];
    sceneData[11] = fogFar;

    // [3] Dir Light Dir + Intensity
    var _dlData = global.UE_DIR_LIGHT_DATA;

    if (_dlData.intensity > 0) {
      sceneData[12] = _dlData.direction[0];
      sceneData[13] = _dlData.direction[1];
      sceneData[14] = _dlData.direction[2];
      sceneData[15] = _dlData.intensity;

      // [4] Dir Light Color
      sceneData[16] = _dlData.color[0];
      sceneData[17] = _dlData.color[1];
      sceneData[18] = _dlData.color[2];
      sceneData[19] = 1.0; // shadow enabled? 1.0 if yes, 0.0 if no
    } else {
      // No directional light, set default values
      sceneData[12] = 0; sceneData[13] = -1; sceneData[14] = 0; sceneData[15] = 0;
      sceneData[16] = 0; sceneData[17] = 0; sceneData[18] = 0; sceneData[19] = 0;
    }

    global.UE_RENDERER_SCENE_DATA = sceneData;

    // Sort both queues before rendering
    if (sortObjects) {
      // OPAQUE
      array_sort(__queueOpaque, function (a, b) {
        return a.__opaqueSortKey - b.__opaqueSortKey;
      });

      // TRANSPARENT
      array_sort(__queueTransparent, function (a, b) {
        return a.__transparentSortKey - b.__transparentSortKey;
      });
    }

    // Auto clear
    if (self.autoClear) {
      self.clear(self.autoClearColor, self.autoClearDepth, self.autoClearStencil);
    }

    return true;
  }

  /// Render the scene
  function render(scene, camera) {
    gml_pragma("forceinline");

    if (!self.__prepareFrame(scene, camera)) return self;

    var _gpuState = gpu_get_state();

    // **PASS 2: Main camera pass**
    __renderQueue(__queueOpaque, scene);
    __renderQueue(__queueTransparent, scene);

    // Reset the world after rendering
    __boundMaterial = undefined;
    shader_reset();
    matrix_set(matrix_world, global.UE_MAT4_IDENTITY);
    gpu_set_state(_gpuState);

    return self;
  }
}
