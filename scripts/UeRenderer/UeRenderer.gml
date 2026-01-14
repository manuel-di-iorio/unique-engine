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
  function __collectObjectQueues(objects, camera, frustum = undefined) {
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
          var nd = clamp(vec3_distance_to_squared(object.position, cameraPos) / _maxDistSq, 0, 1);
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
      if (array_length(object.children) > 0) __collectObjectQueues(object.children, camera, frustum);
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

  // Aggregate light data from scene lights
  function __buildLightState() {
    gml_pragma("forceinline");
    var lights = self.__lights;
    var len = array_length(lights);
    var lightState = global.UE_RENDERER_LIGHT_STATE;
    
    // Check if something changed (simple version for now: count and types)
    // In a more complex engine, we'd check positions/colors too.
    var _oldHash = string(len); 

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
      _oldHash += l.lightType + string(l.id);

      switch (l.lightType) {
        case "AmbientLight":
          // Accumulate ambient light contributions
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

    global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.DIRECTIONAL_COUNT] = dIdx;
    global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.POINT_LIGHT_COUNT] = pIdx;
    global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.SPOT_LIGHT_COUNT] = sIdx;
    global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.HEMI_LIGHT_COUNT] = hIdx;

    // Clamp ambient light to prevent over-exposure
    ambientState[0] = clamp(ambientState[0], 0, 1);
    ambientState[1] = clamp(ambientState[1], 0, 1);
    ambientState[2] = clamp(ambientState[2], 0, 1);
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

    // Get camera frustum for culling
    var _frustum = camera.getFrustum();

    // Collect all renderable objects
    __collectObjectQueues(scene.children, camera, _frustum);

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
    var fogColor = sceneFog != undefined ? sceneFog.color : c_black;
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
    var fogLinear;
    if (is_array(fogColor)) {
      fogLinear = [fogColor[0], fogColor[1], fogColor[2]];
    } else {
      fogLinear = [color_get_red(fogColor) / 255, color_get_green(fogColor) / 255, color_get_blue(fogColor) / 255];
    }
    sceneData[8] = fogLinear[0];
    sceneData[9] = fogLinear[1];
    sceneData[10] = fogLinear[2];
    sceneData[11] = fogFar;

    // [3] Dir Light Dir + Intensity
    var _dlCount = global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.DIRECTIONAL_COUNT];
    var _dl = (_dlCount > 0) ? global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.DIRECTIONAL][0] : undefined;

    if (_dl != undefined) {
      var _dir = _dl.getDirection();
      sceneData[12] = _dir[0];
      sceneData[13] = _dir[1];
      sceneData[14] = _dir[2];
      sceneData[15] = _dl.intensity;

      // [4] Dir Light Color
      sceneData[16] = _dl.color[0];
      sceneData[17] = _dl.color[1];
      sceneData[18] = _dl.color[2];
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
