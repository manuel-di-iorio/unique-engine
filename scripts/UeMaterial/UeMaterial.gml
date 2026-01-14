function UeMaterial(data = {}) constructor {
  type = "Material";
  isMaterial = true;
  id = global.UE_OBJECT_ID++;
  uuid = ueUuid();
  name = data[$ "name"] ?? "";
  transparent = data[$ "transparent"] ?? false;
  opacity = data[$ "opacity"] ?? 1;
  visible = data[$ "visible"] ?? true;
  side = data[$ "side"] ?? cull_counterclockwise;
  depthTest = data[$ "depthTest"] ?? true;
  depthWrite = data[$ "depthWrite"] ?? true;
  depthFunc = data[$ "depthFunc"] ?? cmpfunc_lessequal;
  forceSinglePass = data[$ "forceSinglePass"] ?? false;
  alphaTest = data[$ "alphaTest"] ?? 0;
  colorWrite = data[$ "colorWrite"] ?? true;
  wireframe = data[$ "wireframe"] ?? false;
  allowOverride = data[$ "allowOverride"] ?? true;
  toneMapped = data[$ "toneMapped"] ?? true;
  userData = {};

  // Blending
  blending = data[$ "blending"] ?? false;
  blendEquation = data[$ "blendEquation"] ?? bm_eq_add;
  blendEquationAlpha = data[$ "blendEquationAlpha"] ?? bm_eq_add;
  blendSrc = data[$ "blendSrc"] ?? bm_src_alpha;
  blendDst = data[$ "blendDst"] ?? bm_inv_src_alpha;
  blendSrcAlpha = data[$ "blendSrcAlpha"] ?? bm_one;
  blendDstAlpha = data[$ "blendDstAlpha"] ?? bm_inv_src_alpha;

  // Shader
  shader = data[$ "shader"];

  // Cache management
  __caches = {}; // Stores cached uniform/sampler locations per shader
  __currentCache = undefined;

  // Uniforms
  uniforms = data[$ "uniforms"] ?? {};

  // Has maps flags
  __hasMapsFlags = {
    map: 0,
    alphaMap: 0,
    ormMap: 0,
    normalMap: 0,
    emissiveMap: 0,
    displacementMap: 0
  };

  // Uniform names config
  __uniformNamesConfig = global.UE_UNIFORM_NAMES_CONFIG;

  // Textures
  __baseTexture = undefined;
  textures = {
    map: data[$ "map"],
  };

  emissiveIntensity = data[$ "emissiveIntensity"] ?? 0;
  receiveShadow = data[$ "receiveShadow"] ?? true;
  lights = data[$ "lights"] ?? true;
  shadowQuality = data[$ "shadowQuality"] ?? UE_SHADOW_QUALITY.HIGH;

  // Cache uniform/sampler locations
  function build(targetShader = undefined) {
    gml_pragma("forceinline");
    var _shader = targetShader ?? self.shader;
    if (_shader == undefined) return self;

    var __currentCache = __caches[$ _shader];
    if (__currentCache != undefined) {
      return self;
    }

    var cfg = __uniformNamesConfig;
    var cache = {
      uniformModelPositionLoc: shader_get_uniform(_shader, cfg.modelPosition),
      uniformWorldMatrixLoc: shader_get_uniform(_shader, cfg.worldMatrix),
      uniformCameraPositionLoc: shader_get_uniform(_shader, cfg.cameraPosition),
      uniformLightsAmbientLoc: shader_get_uniform(_shader, cfg.ambient),
      uniformEmissiveIntensityLoc: shader_get_uniform(_shader, cfg.emissiveIntensity),

      uniformDirShadowMatrixLoc: shader_get_uniform(_shader, cfg.lightSpaceMatrix),
      uniformDirShadowEnabledLoc: shader_get_uniform(_shader, cfg.shadowEnabled),
      uniformPointShadowEnabledLoc: shader_get_uniform(_shader, cfg.pointShadowEnabled),
      uniformReceiveShadowLoc: shader_get_uniform(_shader, cfg.receiveShadow),
      uniformDirShadowQualityLoc: shader_get_uniform(_shader, cfg.shadowQuality),
      uniformDirShadowTexelSizeLoc: shader_get_uniform(_shader, cfg.shadowTexelSize),
      samplerDirShadowMapIdx: shader_get_sampler_index(_shader, cfg.shadowMapSampler),

      samplerPointShadowMapIdx: shader_get_sampler_index(_shader, cfg.pointShadowMapSampler),
      uniformPointShadowFarLoc: shader_get_uniform(_shader, cfg.pointShadowFar),
      uniformPointShadowNearLoc: shader_get_uniform(_shader, cfg.pointShadowNear),
      uniformPointShadowPosLoc: shader_get_uniform(_shader, cfg.pointShadowPos),
      uniformPointShadowTexelSizeLoc: shader_get_uniform(_shader, cfg.pointShadowTexelSize),
      uniformPointShadowQualityLoc: shader_get_uniform(_shader, cfg.pointShadowQuality),
      uniformPointShadowMatrixLoc: shader_get_uniform(_shader, cfg.pointShadowMatrix),

      uniformSpotShadowEnabledLoc: shader_get_uniform(_shader, cfg.spotShadowEnabled),
      uniformSpotShadowMatrixLoc: shader_get_uniform(_shader, cfg.spotShadowMatrix),
      samplerSpotShadowMapIdx: shader_get_sampler_index(_shader, cfg.spotShadowMapSampler),
      uniformSpotShadowFarLoc: shader_get_uniform(_shader, cfg.spotShadowFar),
      uniformSpotShadowNearLoc: shader_get_uniform(_shader, cfg.spotShadowNear),
      uniformSpotShadowPosLoc: shader_get_uniform(_shader, cfg.spotShadowPos),
      uniformSpotShadowTexelSizeLoc: shader_get_uniform(_shader, cfg.spotShadowTexelSize),
      uniformSpotShadowQualityLoc: shader_get_uniform(_shader, cfg.spotShadowQuality),

      uniformToneMappingLoc: shader_get_uniform(_shader, cfg.toneMapping),
      uniformToneMappingExposureLoc: shader_get_uniform(_shader, cfg.toneMappingExposure),
      uniformToneMappedLoc: shader_get_uniform(_shader, cfg.toneMapped),

      uniformHasMapLoc: shader_get_uniform(_shader, cfg.hasMap),
      uniformHasAlphaMapLoc: shader_get_uniform(_shader, cfg.hasAlphaMap),
      uniformHasOrmMapLoc: shader_get_uniform(_shader, cfg.hasOrmMap),
      uniformHasNormalMapLoc: shader_get_uniform(_shader, cfg.hasNormalMap),
      uniformHasEmissiveMapLoc: shader_get_uniform(_shader, cfg.hasEmissiveMap),
      uniformHasDisplacementMapLoc: shader_get_uniform(_shader, cfg.hasDisplacementMap),

      uniformFogColorLoc: shader_get_uniform(_shader, cfg.fogColor),
      uniformFogDensityLoc: shader_get_uniform(_shader, cfg.fogDensity),
      uniformFogNearLoc: shader_get_uniform(_shader, cfg.fogNear),
      uniformFogFarLoc: shader_get_uniform(_shader, cfg.fogFar),

      uniformLightsDir: array_create(1),
      uniformSpotLightsPos: shader_get_uniform(_shader, cfg.spotLightPosition),
      uniformSpotLightsDir: shader_get_uniform(_shader, cfg.spotLightDirection),
      uniformSpotLightsColor: shader_get_uniform(_shader, cfg.spotLightColor),
      uniformSpotLightsRange: shader_get_uniform(_shader, cfg.spotLightRange),
      uniformSpotLightsIntensity: shader_get_uniform(_shader, cfg.spotLightIntensity),
      uniformSpotLightsDecay: shader_get_uniform(_shader, cfg.spotLightDecay),
      uniformSpotLightsAngle: shader_get_uniform(_shader, cfg.spotLightAngle),
      uniformSpotLightsPenumbra: shader_get_uniform(_shader, cfg.spotLightPenumbra),

      uniformHemiLightDirLoc: shader_get_uniform(_shader, cfg.hemiLightDirection),
      uniformHemiLightSkyColorLoc: shader_get_uniform(_shader, cfg.hemiLightSkyColor),
      uniformHemiLightGroundColorLoc: shader_get_uniform(_shader, cfg.hemiLightGroundColor),
      uniformHemiLightIntensityLoc: shader_get_uniform(_shader, cfg.hemiLightIntensity),

      uniformLightsPos: shader_get_uniform(_shader, cfg.pointLightPosition),
      uniformLightsColor: shader_get_uniform(_shader, cfg.pointLightColor),
      uniformLightsRange: shader_get_uniform(_shader, cfg.pointLightRange),
      uniformLightsIntensity: shader_get_uniform(_shader, cfg.pointLightIntensity),
      uniformLightsDecay: shader_get_uniform(_shader, cfg.pointLightDecay),

      uniformsCached: [],
      texturesCached: [],
      hasMapsFlags: {
        map: 0, alphaMap: 0, ormMap: 0, normalMap: 0, emissiveMap: 0, displacementMap: 0
      }
    };

    for (var l = 0; l < 1; l++) {
      cache.uniformLightsDir[l] = [
        shader_get_uniform(_shader, $"{cfg.dirLightDir}{l}"),
        shader_get_uniform(_shader, $"{cfg.dirLightColor}{l}"),
        shader_get_uniform(_shader, $"{cfg.dirLightIntensity}{l}"),
      ];
    }

    // Cache the uniforms
    var uniformNames = variable_struct_get_names(uniforms);
    var uCount = array_length(uniformNames);
    cache.uniformsCached = array_create(uCount);

    for (var u = 0; u < uCount; u++) {
      var uniformName = uniformNames[u];
      cache.uniformsCached[u] = [
        uniforms[$ uniformName],
        shader_get_uniform(_shader, $"u_{uniformName}")
     ];
    }

    // Cache the textures
    var textureNames = variable_struct_get_names(textures);
    var tCount = array_length(textureNames);
    cache.texturesCached = [];

    for (var t = 0; t < tCount; t++) {
      var textureName = textureNames[t];
      var texture = textures[$ textureName];
      if (textureName == "map") {
        cache.hasMapsFlags.map = (texture == undefined) ? 0 : 1;
        continue;
      }
      var samplerIdx = shader_get_sampler_index(_shader, $"s_{textureName}");
      if (samplerIdx != -1) {
        if (variable_struct_exists(cache.hasMapsFlags, textureName)) {
          cache.hasMapsFlags[$ textureName] = (texture == undefined || !is_struct(texture)) ? 0 : 1;
        }
        if (texture != undefined && is_struct(texture)) {
          array_push(cache.texturesCached, [texture, samplerIdx]);
        }
      }
    }

    __caches[$ _shader] = cache;
    __currentCache = cache;
    return self;
  }

  function __setLightsUniforms(cache) {
    gml_pragma("forceinline");
    if (!lights) return;

    var lightState = global.UE_RENDERER_LIGHT_STATE;
    var uniformsCache = global.UE_VEC3_TEMP0;

    var directionalState = lightState[UE_RENDERER_LIGHT_STATE_ENUM.DIRECTIONAL];
    var directionalCount = lightState[UE_RENDERER_LIGHT_STATE_ENUM.DIRECTIONAL_COUNT];
    var pointLightState = lightState[UE_RENDERER_LIGHT_STATE_ENUM.POINT_LIGHT];
    var pointLightCount = lightState[UE_RENDERER_LIGHT_STATE_ENUM.POINT_LIGHT_COUNT];
    var spotLightState = lightState[UE_RENDERER_LIGHT_STATE_ENUM.SPOT_LIGHT];
    var spotLightCount = lightState[UE_RENDERER_LIGHT_STATE_ENUM.SPOT_LIGHT_COUNT];
    var hemiLightState = lightState[UE_RENDERER_LIGHT_STATE_ENUM.HEMI_LIGHT];
    var hemiLightCount = lightState[UE_RENDERER_LIGHT_STATE_ENUM.HEMI_LIGHT_COUNT];

    // Set ambient light
    shader_set_uniform_f_array(cache.uniformLightsAmbientLoc, lightState[UE_RENDERER_LIGHT_STATE_ENUM.AMBIENT]);

    // Set directional lights (max 1)
    for (var i = 0; i < 1; i++) {
      var lightLoc = cache.uniformLightsDir[i];

      if (i < directionalCount) {
        var light = directionalState[i];

        // Get light direction (from position to target)
        light.getDirection(uniformsCache);
        shader_set_uniform_f_array(lightLoc[0], uniformsCache);
        shader_set_uniform_f_array(lightLoc[1], light.color);
        shader_set_uniform_f(lightLoc[2], light.intensity);

      } else {
        // Reset unused light slots
        shader_set_uniform_f(lightLoc[2], 0);
      }
    }

    // Set shadow uniforms (from the first shadow-casting directional light)
    var shadowLight = undefined;
    for (var i = 0; i < directionalCount; i++) {
      if (directionalState[i].castShadow) {
        shadowLight = directionalState[i];
        break;
      }
    }

    if (shadowLight != undefined && surface_exists(shadowLight.shadow.map.surface)) {
      shader_set_uniform_f(cache.uniformDirShadowEnabledLoc, 1.0);
      shader_set_uniform_f(cache.uniformDirShadowQualityLoc, shadowQuality);

      // Calculate texel size based on shadow map resolution
      var shadowMapWidth = shadowLight.shadow.map.width;
      var texelSize = 1.0 / shadowMapWidth;
      shader_set_uniform_f(cache.uniformDirShadowTexelSizeLoc, texelSize);

      shader_set_uniform_matrix_array(cache.uniformDirShadowMatrixLoc, shadowLight.shadow.lightSpaceMatrix);

      texture_set_stage(cache.samplerDirShadowMapIdx, shadowLight.shadow.map.getTexture());
    } else if (cache.uniformDirShadowEnabledLoc != undefined) {
      shader_set_uniform_f(cache.uniformDirShadowEnabledLoc, 0.0);
    }

    // Set point shadow uniforms (from the first shadow-casting point light)
    var pointShadowLight = undefined;
    for (var i = 0; i < pointLightCount; i++) {
      if (pointLightState[i].castShadow) {
        pointShadowLight = pointLightState[i];
        break;
      }
    }

    if (pointShadowLight != undefined && cache.samplerPointShadowMapIdx != -1) {
      shader_set_uniform_f(cache.uniformPointShadowEnabledLoc, 1.0);
      shader_set_uniform_f(cache.uniformPointShadowFarLoc, pointShadowLight.shadow.cameras[0].far);
      shader_set_uniform_f(cache.uniformPointShadowNearLoc, pointShadowLight.shadow.cameras[0].near);

      var pointShadowMapWidth = pointShadowLight.shadow.mapSize.width;
      var pointShadowMapHeight = pointShadowLight.shadow.mapSize.height;
      if (cache.uniformPointShadowTexelSizeLoc != undefined) {
        shader_set_uniform_f(cache.uniformPointShadowTexelSizeLoc, 1.0 / (pointShadowMapWidth * 3.0), 1.0 / (pointShadowMapHeight * 2.0));
      }

      if (cache.uniformPointShadowQualityLoc != undefined) {
        shader_set_uniform_f(cache.uniformPointShadowQualityLoc, shadowQuality);
      }

      // Use world position for point shadow origin
      pointShadowLight.getWorldPosition(uniformsCache);
      shader_set_uniform_f_array(cache.uniformPointShadowPosLoc, uniformsCache);

      // Set point shadow matrices (6 faces)
      if (cache.uniformPointShadowMatrixLoc != -1) {
        var matrices = array_create(16 * 6);
        for (var i = 0; i < 6; i++) {
          var cam = pointShadowLight.shadow.cameras[i];
          matrix_multiply(cam.matrixWorldInverse, cam.projectionMatrix, global.UE_MAT4_TEMP0);
          for (var m = 0; m < 16; m++) {
            matrices[i * 16 + m] = global.UE_MAT4_TEMP0[m];
          }
        }
        shader_set_uniform_f_array(cache.uniformPointShadowMatrixLoc, matrices);
      }

      texture_set_stage(cache.samplerPointShadowMapIdx, pointShadowLight.shadow.map.getTexture());
    } else if (cache.uniformPointShadowEnabledLoc != undefined) {
      shader_set_uniform_f(cache.uniformPointShadowEnabledLoc, 0.0);
    }

    // Set point lights (max 8) using uniform arrays
    var posArr = array_create(8 * 3, 0);
    var colorArr = array_create(8 * 3, 0);
    var rangeArr = array_create(8, 0);
    var intensityArr = array_create(8, 0);
    var decayArr = array_create(8, 0);

    for (var i = 0; i < 8; i++) {
      if (i < pointLightCount) {
        var light = pointLightState[i];

        // Get world position for the shader
        light.getWorldPosition();

        posArr[i * 3 + 0] = uniformsCache[0];
        posArr[i * 3 + 1] = uniformsCache[1];
        posArr[i * 3 + 2] = uniformsCache[2];

        colorArr[i * 3 + 0] = light.color[0];
        colorArr[i * 3 + 1] = light.color[1];
        colorArr[i * 3 + 2] = light.color[2];

        rangeArr[i] = light.distance;
        intensityArr[i] = light.intensity;
        decayArr[i] = light.decay;
      }
    }

    shader_set_uniform_f_array(cache.uniformLightsPos, posArr);
    shader_set_uniform_f_array(cache.uniformLightsColor, colorArr);
    shader_set_uniform_f_array(cache.uniformLightsRange, rangeArr);
    shader_set_uniform_f_array(cache.uniformLightsIntensity, intensityArr);
    shader_set_uniform_f_array(cache.uniformLightsDecay, decayArr);

    // Set spot shadow uniforms (from the first shadow-casting spot light)
    var spotShadowLight = undefined;
    for (var i = 0; i < spotLightCount; i++) {
      if (spotLightState[i].castShadow) {
        spotShadowLight = spotLightState[i];
        break;
      }
    }

    if (spotShadowLight != undefined && cache.samplerSpotShadowMapIdx != -1) {
      shader_set_uniform_f(cache.uniformSpotShadowEnabledLoc, 1.0);
      shader_set_uniform_matrix_array(cache.uniformSpotShadowMatrixLoc, spotShadowLight.shadow.lightSpaceMatrix);

      if (cache.uniformSpotShadowFarLoc != undefined) shader_set_uniform_f(cache.uniformSpotShadowFarLoc, spotShadowLight.shadow.camera.far);
      if (cache.uniformSpotShadowNearLoc != undefined) shader_set_uniform_f(cache.uniformSpotShadowNearLoc, spotShadowLight.shadow.camera.near);
      if (cache.uniformSpotShadowPosLoc != undefined) shader_set_uniform_f(cache.uniformSpotShadowPosLoc, spotShadowLight.position[0], spotShadowLight.position[1], spotShadowLight.position[2]);
      if (cache.uniformSpotShadowTexelSizeLoc != undefined) shader_set_uniform_f(cache.uniformSpotShadowTexelSizeLoc, 1.0 / spotShadowLight.shadow.mapSize.width);
      if (cache.uniformSpotShadowQualityLoc != undefined) shader_set_uniform_f(cache.uniformSpotShadowQualityLoc, shadowQuality);

      texture_set_stage(cache.samplerSpotShadowMapIdx, spotShadowLight.shadow.map.getDepthTexture());
    } else if (cache.uniformSpotShadowEnabledLoc != undefined) {
      shader_set_uniform_f(cache.uniformSpotShadowEnabledLoc, 0.0);
    }

    // Set spot lights (max 4)
    var sPosArr = array_create(4 * 3, 0);
    var sDirArr = array_create(4 * 3, 0);
    var sColorArr = array_create(4 * 3, 0);
    var sRangeArr = array_create(4, 0);
    var sIntensityArr = array_create(4, 0);
    var sDecayArr = array_create(4, 0);
    var sAngleArr = array_create(4, 0);
    var sPenumbraArr = array_create(4, 0);

    for (var i = 0; i < 4; i++) {
      if (i < spotLightCount) {
        var light = spotLightState[i];

        light.getWorldPosition(uniformsCache);

        sPosArr[i * 3 + 0] = uniformsCache[0];
        sPosArr[i * 3 + 1] = uniformsCache[1];
        sPosArr[i * 3 + 2] = uniformsCache[2];

        // Get spot light direction
        var worldPos = global.UE_VEC3_TEMP1;
        light.getDirection(worldPos);
        sDirArr[i * 3 + 0] = worldPos[0];
        sDirArr[i * 3 + 1] = worldPos[1];
        sDirArr[i * 3 + 2] = worldPos[2];

        sColorArr[i * 3 + 0] = light.color[0];
        sColorArr[i * 3 + 1] = light.color[1];
        sColorArr[i * 3 + 2] = light.color[2];

        sRangeArr[i] = light.distance;
        sIntensityArr[i] = light.intensity;
        sDecayArr[i] = light.decay;
        sAngleArr[i] = cos(light.angle);
        sPenumbraArr[i] = cos(light.angle * (1.0 - light.penumbra));
      }
    }

    if (cache.uniformSpotLightsPos != undefined) {
      shader_set_uniform_f_array(cache.uniformSpotLightsPos, sPosArr);
      shader_set_uniform_f_array(cache.uniformSpotLightsDir, sDirArr);
      shader_set_uniform_f_array(cache.uniformSpotLightsColor, sColorArr);
      shader_set_uniform_f_array(cache.uniformSpotLightsRange, sRangeArr);
      shader_set_uniform_f_array(cache.uniformSpotLightsIntensity, sIntensityArr);
      shader_set_uniform_f_array(cache.uniformSpotLightsDecay, sDecayArr);
      shader_set_uniform_f_array(cache.uniformSpotLightsAngle, sAngleArr);
      shader_set_uniform_f_array(cache.uniformSpotLightsPenumbra, sPenumbraArr);
    }

    // Set hemisphere light (max 1)
    if (hemiLightCount > 0 && cache.uniformHemiLightIntensityLoc != undefined) {
      var light = hemiLightState[0];

      // Direction is normalized position
      var dir = global.UE_VEC3_TEMP1;
      vec3_copy(dir, light.position);
      vec3_normalize(dir);

      shader_set_uniform_f(cache.uniformHemiLightDirLoc, dir[0], dir[1], dir[2]);
      shader_set_uniform_f_array(cache.uniformHemiLightSkyColorLoc, light.skyColor);
      shader_set_uniform_f_array(cache.uniformHemiLightGroundColorLoc, light.groundColor);
      shader_set_uniform_f(cache.uniformHemiLightIntensityLoc, light.intensity);
    } else if (cache.uniformHemiLightIntensityLoc != undefined) {
      shader_set_uniform_f(cache.uniformHemiLightIntensityLoc, 0.0);
    }
  }

  function use(renderer = undefined, _targetShader = undefined) {
    gml_pragma("forceinline");

    var _shader = _targetShader ?? self.shader;
    shader_set(_shader);

    // Ensure we have the correct cache for this shader
    self.build(_shader);
    var cache = __currentCache;

    // Set standard uniforms
    if (cache.uniformCameraPositionLoc != -1) {
      var camPos = global.UE_RENDERER_CAMERA_POSITION;
      shader_set_uniform_f(cache.uniformCameraPositionLoc, camPos[0], camPos[1], camPos[2]);
    }

    if (cache.uniformEmissiveIntensityLoc != -1) {
      shader_set_uniform_f(cache.uniformEmissiveIntensityLoc, self.emissiveIntensity);
    }

    if (cache.uniformReceiveShadowLoc != -1) {
      shader_set_uniform_f(cache.uniformReceiveShadowLoc, self.receiveShadow ? 1.0 : 0.0);
    }

    // Set tone mapping uniforms
    if (cache.uniformToneMappingLoc != -1) {
      var toneMapping = (renderer != undefined) ? renderer.toneMapping : global.UE_RENDERER_TONE_MAPPING;
      var exposure = (renderer != undefined) ? renderer.toneMappingExposure : global.UE_RENDERER_TONE_MAPPING_EXPOSURE;

      shader_set_uniform_f(cache.uniformToneMappingLoc, toneMapping);
      shader_set_uniform_f(cache.uniformToneMappingExposureLoc, exposure);
      shader_set_uniform_f(cache.uniformToneMappedLoc, (toneMapped && toneMapping != UE_TONE_MAPPING.NONE) ? 1.0 : 0.0);
    }

    // Set fog uniforms
    if (cache.uniformFogDensityLoc != -1) {
      var fog = global.UE_RENDERER_FOG_STATE;
      var materialFogEnabled = self[$ "fog"] ?? true;

      if (fog.enabled && materialFogEnabled) {
        shader_set_uniform_f_array(cache.uniformFogColorLoc, fog.color);
        shader_set_uniform_f(cache.uniformFogDensityLoc, fog.density);
        shader_set_uniform_f(cache.uniformFogNearLoc, fog.near);
        shader_set_uniform_f(cache.uniformFogFarLoc, fog.far);
      } else {
        shader_set_uniform_f(cache.uniformFogDensityLoc, 0.0);
        shader_set_uniform_f(cache.uniformFogFarLoc, 0.0);
      }
    }

    // Set lights uniforms
    self.__setLightsUniforms(cache);

    // Set custom uniforms
    var uCached = cache.uniformsCached;
    for (var i = 0, il = array_length(uCached); i < il; i++) {
      var uData = uCached[i];
      var uObj = uData[0];
      var loc = uData[1];

      if (loc == -1) continue;

      var val = uObj.value;
      var type = uObj[$ "type"] ?? UE_UNIFORM_TYPE.FLOAT;

      switch (type) {
        case UE_UNIFORM_TYPE.FLOAT: shader_set_uniform_f(loc, val); break;
        case UE_UNIFORM_TYPE.VEC2: shader_set_uniform_f(loc, val[0], val[1]); break;
        case UE_UNIFORM_TYPE.VEC3: shader_set_uniform_f(loc, val[0], val[1], val[2]); break;
        case UE_UNIFORM_TYPE.VEC4: shader_set_uniform_f(loc, val[0], val[1], val[2], val[3]); break;
        case UE_UNIFORM_TYPE.MAT4: shader_set_uniform_matrix_array(loc, val); break;
        case UE_UNIFORM_TYPE.ARRAY: shader_set_uniform_f_array(loc, val); break;
        case UE_UNIFORM_TYPE.BUFFER:
          shader_set_uniform_f_buffer(loc, val, uObj[$ "offset"] ?? 0, uObj[$ "count"] ?? array_length(val));
          break;
      }
    }

    // Set textures
    var texKeys = variable_struct_get_names(self.textures);

    // Update hasMaps flags
    __hasMapsFlags.map = (self.textures[$ "map"] != undefined) ?1.0 : 0.0;
    __hasMapsFlags.alphaMap = (self.textures[$ "alphaMap"] != undefined) ?1.0 : 0.0;
    __hasMapsFlags.ormMap = (self.textures[$ "ormMap"] != undefined) ?1.0 : 0.0;
    __hasMapsFlags.normalMap = (self.textures[$ "normalMap"] != undefined) ?1.0 : 0.0;
    __hasMapsFlags.emissiveMap = (self.textures[$ "emissiveMap"] != undefined) ?1.0 : 0.0;
    __hasMapsFlags.displacementMap = (self.textures[$ "displacementMap"] != undefined) ?1.0 : 0.0;

    if (cache.uniformHasMapLoc != -1) {
      shader_set_uniform_f(cache.uniformHasMapLoc, __hasMapsFlags.map);
      shader_set_uniform_f(cache.uniformHasAlphaMapLoc, __hasMapsFlags.alphaMap);
      shader_set_uniform_f(cache.uniformHasOrmMapLoc, __hasMapsFlags.ormMap);
      shader_set_uniform_f(cache.uniformHasNormalMapLoc, __hasMapsFlags.normalMap);
      shader_set_uniform_f(cache.uniformHasEmissiveMapLoc, __hasMapsFlags.emissiveMap);
      shader_set_uniform_f(cache.uniformHasDisplacementMapLoc, __hasMapsFlags.displacementMap);
    }

    // Base texture (map)
    __baseTexture = self.textures[$ "map"];

    for (var i = 0; i < array_length(texKeys); i++) {
      var key = texKeys[i];
      if (key == "map") continue; // Already handled as base texture

      var tex = self.textures[$ key];
      if (tex == undefined) continue;

      var sampler = shader_get_sampler_index(_shader, $"s_{key}");
      if (sampler == -1) continue;

      if (is_struct(tex) && variable_struct_exists(tex, "__use")) {
        tex.__use(sampler);
      } else if (is_struct(tex) && variable_struct_exists(tex, "getTexture")) {
        texture_set_stage(sampler, tex.getTexture());
      } else {
        texture_set_stage(sampler, tex);
      }
    }

    // Set GPU State
    gpu_set_ztestenable(depthTest);
    gpu_set_zwriteenable(depthWrite);
    gpu_set_zfunc(depthFunc);
    gpu_set_alphatestenable(alphaTest > 0);
    gpu_set_alphatestref(alphaTest);

    if (blending) {
      gpu_set_blendenable(true);
      gpu_set_blendequation_sepalpha(blendEquation, blendEquationAlpha);
      gpu_set_blendmode_ext_sepalpha(blendSrc, blendDst, blendSrcAlpha, blendDstAlpha);
    } else {
      gpu_set_blendenable(false);
    }

    gpu_set_colorwriteenable(colorWrite, colorWrite, colorWrite, colorWrite);

    return self;
  }

  function useByMesh(mesh, renderSide = undefined) {
    gml_pragma("forceinline");
    var cache = __currentCache;
    if (cache == undefined) return;

    // Update the shader's model position uniform (for billboard sprites)
    if (mesh[$ "isSprite"] && cache.uniformModelPositionLoc != -1) {
      shader_set_uniform_f_array(cache.uniformModelPositionLoc, mesh.position);
    }

    // Set world matrix
    if (cache.uniformWorldMatrixLoc != -1) {
      shader_set_uniform_matrix_array(cache.uniformWorldMatrixLoc, mesh.matrixWorld);
    }

    // Set receive shadow uniform
    if (cache.uniformReceiveShadowLoc != -1) {
      shader_set_uniform_f(cache.uniformReceiveShadowLoc, mesh.receiveShadow ? 1.0 : 0.0);
    }

    // Set the culling mode (can be overwritten by argument for transparent objects)
    gpu_set_cullmode(renderSide ?? side);

    return self;
  }

  /**
   * Set the value of a cached uniform that will be passed to the shader in the next frame
   */
  function setUniform(name, value) {
    gml_pragma("forceinline");
    uniforms[$ name].value = value;
    return self;
  }

  /**
   * Set the texture given the name
   * @todo check if this is documented
   */
  function setTexture(name, value) {
    gml_pragma("forceinline");
    textures[$ name] = value;
    return self;
  }

  /**
   * Clone the marial
   */
  function clone() {
    gml_pragma("forceinline");
    return variable_clone(self);
  }

  function toJSON() {
    gml_pragma("forceinline");
    return {
      uuid,
      type,
      name,
      uniforms,
      textures: ueStructMap(textures, function (name, texture) {
        return texture != undefined ? texture.uuid : undefined;
      }),
      shader: shader_get_name(shader),
      transparent,
      opacity,
      depthTest,
      side,
      depthTest,
      depthWrite,
      depthFunc,
      forceSinglePass,
      alphaTest,
      colorWrite,
      blending,
      blendEquation,
      blendEquationAlpha,
      blendSrc,
      blendDst,
      blendSrcAlpha,
      blendDstAlpha,
      lights,
      toneMapped,
    };
  }

  function fromJSON(data, texturesByUUID = {}) {
    gml_pragma("forceinline");
    uuid = data[$ "uuid"];
    name = data[$ "name"];
    transparent = data[$ "transparent"];
    opacity = data[$ "opacity"];
    side = data[$ "side"];
    depthTest = data[$ "depthTest"];
    depthWrite = data[$ "depthWrite"];
    depthFunc = data[$ "depthFunc"];
    forceSinglePass = data[$ "forceSinglePass"];
    alphaTest = data[$ "alphaTest"];
    colorWrite = data[$ "colorWrite"];
    blending = data[$ "blending"];
    blendEquation = data[$ "blendEquation"];
    blendEquationAlpha = data[$ "blendEquationAlpha"];
    blendSrc = data[$ "blendSrc"];
    blendDst = data[$ "blendDst"];
    blendSrcAlpha = data[$ "blendSrcAlpha"];
    blendDstAlpha = data[$ "blendDstAlpha"];
    lights = data[$ "lights"];
    toneMapped = data[$ "toneMapped"];

    // Merge uniforms instead of replacing them to preserve defaults
    ueStructMerge(uniforms, data[$ "uniforms"]);

    // Load shader
    var shaderName = data[$ "shader"];
    if (shaderName != undefined && shaderName != "") {
      shader = asset_get_index(shaderName);
    }

    // Load textures
    var texturesData = data[$ "textures"];
    if (texturesData != undefined) {
      var textureNames = variable_struct_get_names(texturesData);
      for (var i = 0, il = array_length(textureNames); i < il; i++) {
        var textureName = textureNames[i];
        var textureUUID = texturesData[$ textureName];

        if (textureUUID != undefined) {
          if (texturesByUUID[$ textureUUID] != undefined) {
            // Link to existing texture object
            textures[$ textureName] = texturesByUUID[$ textureUUID];
          } else {
            // Remove textures not found
            delete textures[$ textureName];
          }
        }
      }
    }

    build();

    return self;
  }

  /** Internal export methods */
  function _compileData(data) {
    gml_pragma("forceinline");
    return { payload: toJSON() };
  }

  build();
}
