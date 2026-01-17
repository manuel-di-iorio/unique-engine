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
  __cache = undefined;

  // Uniforms
  uniforms = data[$ "uniforms"] ?? {};
  __uniformsList = []; // Optimized list for iteration

  // Textures
  textures = {
    map: data[$ "map"],
  };
  __texturesList = []; // Optimized list for iteration

  function setUniform(name, value) {
    gml_pragma("forceinline");
    uniforms[$ name].value = value;
    return self;
  }

  function setTexture(name, texture) {
    gml_pragma("forceinline");
    textures[$ name] = texture;
    return self;
  }

  receiveShadow = data[$ "receiveShadow"] ?? true;
  lights = data[$ "lights"] ?? true;
  shadowQuality = data[$ "shadowQuality"] ?? UE_SHADOW_QUALITY.HIGH;

  // Cache uniform/sampler locations
  function build() {
    gml_pragma("forceinline");
    if (shader == undefined) return self;

    // Cache the core uniforms
    var cfg = global.UE_UNIFORM_NAMES_CONFIG;

    var _uCoreNames = ["modelPosition", "worldMatrix", "receiveShadow",
      "dirShadowEnabled", "dirShadowQuality", "dirShadowTexelSize", "dirShadowMatrix",
      "pointShadowEnabled", "pointShadowFar", "pointShadowNear", "pointShadowPos", "pointShadowTexelSize", "pointShadowQuality", "pointShadowMatrix",
      "spotShadowEnabled", "spotShadowMatrix", "spotShadowFar", "spotShadowNear", "spotShadowPos", "spotShadowTexelSize", "spotShadowQuality",
      "pointLightsData", "spotLightsData", "hemiLightDir", "hemiLightSkyColor", "hemiLightGroundColor", "hemiLightIntensity",
      "sceneData", "materialData", "mapFlags", "mapFlags2"
    ];
    var _sCoreNames = ["dirShadowMap", "pointShadowMap", "spotShadowMap"];

    __cache = {
      uniformsStandard: [], samplersStandard: [], uniformsCached: [], texturesCached: [],
      hasMapsFlags: { map: 0, alphaMap: 0, ormMap: 0, normalMap: 0, emissiveMap: 0, displacementMap: 0 }
    };

    for (var i = 0, il = array_length(_uCoreNames); i < il; i++) {
      var core = _uCoreNames[i];
      var cacheKey = "uniform" + string_upper(string_char_at(core, 1)) + string_delete(core, 1, 1) + "Loc";
      var loc = shader_get_uniform(shader, cfg[$ core]);
      __cache[$ cacheKey] = loc;

      // Register standard uniforms for automatic handling in use()
      if (core == "sceneData") array_push(__cache.uniformsStandard, [loc, core, UE_UNIFORM_TYPE.ARRAY]);
      else if (core == "materialData") array_push(__cache.uniformsStandard, [loc, core, UE_UNIFORM_TYPE.VEC3]);
      else if (core == "mapFlags") array_push(__cache.uniformsStandard, [loc, core, UE_UNIFORM_TYPE.VEC4]);
      else if (core == "mapFlags2") array_push(__cache.uniformsStandard, [loc, core, UE_UNIFORM_TYPE.VEC4]);
    }
    for (var i = 0, il = array_length(_sCoreNames); i < il; i++) {
      var core = _sCoreNames[i];
      var cacheKey = "sampler" + string_upper(string_char_at(core, 1)) + string_delete(core, 1, 1) + "Idx";
      __cache[$ cacheKey] = shader_get_sampler_index(shader, cfg[$ core]);
    }

    // Cache custom uniforms
    var uniformNames = variable_struct_get_names(uniforms);
    var uCount = array_length(uniformNames);
    __cache.uniformsCached = array_create(uCount);

    for (var u = 0; u < uCount; u++) {
      var uniformName = uniformNames[u];
      __cache.uniformsCached[u] = [
        uniforms[$ uniformName],
        shader_get_uniform(shader, "u_" + uniformName)
      ];
    }

    // Cache textures
    var textureNames = variable_struct_get_names(textures);
    var tCount = array_length(textureNames);
    __cache.texturesCached = [];

    // Reset flags
    __cache.hasMapsFlags.map = 0;
    __cache.hasMapsFlags.alphaMap = 0;
    __cache.hasMapsFlags.ormMap = 0;
    __cache.hasMapsFlags.normalMap = 0;
    __cache.hasMapsFlags.emissiveMap = 0;
    __cache.hasMapsFlags.displacementMap = 0;

    for (var t = 0; t < tCount; t++) {
      var textureName = textureNames[t];
      var texture = textures[$ textureName];
      if (textureName == "map") {
        __cache.hasMapsFlags.map = (texture == undefined) ? 0 : 1;
      }
      var samplerIdx = shader_get_sampler_index(shader, "s_" + textureName);
      if (samplerIdx != -1) {
        if (variable_struct_exists(__cache.hasMapsFlags, textureName)) {
          __cache.hasMapsFlags[$ textureName] = (texture == undefined) ? 0 : 1;
        }
        if (texture != undefined) {
          array_push(__cache.texturesCached, [texture, samplerIdx]);
        }
      }
    }
    
    return self;
  }

  function __setLightsUniforms() {
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

    // --- Directional Shadow ---
    if (__cache.uniformDirShadowEnabledLoc != -1) {
      var shadowLight = undefined;
      for (var i = 0; i < directionalCount; i++) {
        if (directionalState[i].castShadow) {
          shadowLight = directionalState[i];
          break;
        }
      }

      if (shadowLight != undefined && surface_exists(shadowLight.shadow.map.surface)) {
        shader_set_uniform_f(__cache.uniformDirShadowEnabledLoc, 1.0);
        shader_set_uniform_f(__cache.uniformDirShadowQualityLoc, shadowQuality);
        shader_set_uniform_f(__cache.uniformDirShadowTexelSizeLoc, 1.0 / shadowLight.shadow.map.width);
        shader_set_uniform_matrix_array(__cache.uniformDirShadowMatrixLoc, shadowLight.shadow.lightSpaceMatrix);
        texture_set_stage(__cache.samplerDirShadowMapIdx, shadowLight.shadow.map.getTexture());
      } else {
        shader_set_uniform_f(__cache.uniformDirShadowEnabledLoc, 0.0);
      }
    }

    // --- Point Shadow ---
    if (__cache.uniformPointShadowEnabledLoc != -1) {
      var pointShadowLight = undefined;
      for (var i = 0; i < pointLightCount; i++) {
        if (pointLightState[i].castShadow) {
          pointShadowLight = pointLightState[i];
          break;
        }
      }

      if (pointShadowLight != undefined && __cache.samplerPointShadowMapIdx != -1) {
        shader_set_uniform_f(__cache.uniformPointShadowEnabledLoc, 1.0);

        // These usually don't change every frame, but we can't easily cache them without more state
        shader_set_uniform_f(__cache.uniformPointShadowFarLoc, pointShadowLight.shadow.cameras[0].far);
        shader_set_uniform_f(__cache.uniformPointShadowNearLoc, pointShadowLight.shadow.cameras[0].near);

        var pointShadowMapWidth = pointShadowLight.shadow.mapSize.width;
        var pointShadowMapHeight = pointShadowLight.shadow.mapSize.height;
        shader_set_uniform_f(__cache.uniformPointShadowTexelSizeLoc, 1.0 / (pointShadowMapWidth * 3.0), 1.0 / (pointShadowMapHeight * 2.0));
        shader_set_uniform_f(__cache.uniformPointShadowQualityLoc, shadowQuality);

        pointShadowLight.getWorldPosition(uniformsCache);
        shader_set_uniform_f_array(__cache.uniformPointShadowPosLoc, uniformsCache);

        var matrices = array_create(16 * 6);
        for (var i = 0; i < 6; i++) {
          var cam = pointShadowLight.shadow.cameras[i];
          matrix_multiply(cam.matrixWorldInverse, cam.projectionMatrix, global.UE_MAT4_TEMP0);
          for (var m = 0; m < 16; m++) matrices[i * 16 + m] = global.UE_MAT4_TEMP0[m];
        }
        shader_set_uniform_f_array(__cache.uniformPointShadowMatrixLoc, matrices);
        texture_set_stage(__cache.samplerPointShadowMapIdx, pointShadowLight.shadow.map.getTexture());
      } else {
        shader_set_uniform_f(__cache.uniformPointShadowEnabledLoc, 0.0);
      }
    }

    // --- Spot Shadow ---
    if (__cache.uniformSpotShadowEnabledLoc != -1) {
      var spotShadowLight = undefined;
      for (var i = 0; i < spotLightCount; i++) {
        if (spotLightState[i].castShadow) {
          spotShadowLight = spotLightState[i];
          break;
        }
      }

      if (spotShadowLight != undefined && __cache.samplerSpotShadowMapIdx != -1) {
        shader_set_uniform_f(__cache.uniformSpotShadowEnabledLoc, 1.0);
        shader_set_uniform_matrix_array(__cache.uniformSpotShadowMatrixLoc, spotShadowLight.shadow.lightSpaceMatrix);
        shader_set_uniform_f(__cache.uniformSpotShadowFarLoc, spotShadowLight.shadow.camera.far);
        shader_set_uniform_f(__cache.uniformSpotShadowNearLoc, spotShadowLight.shadow.camera.near);
        shader_set_uniform_f(__cache.uniformSpotShadowPosLoc, spotShadowLight.position[0], spotShadowLight.position[1], spotShadowLight.position[2]);
        shader_set_uniform_f(__cache.uniformSpotShadowTexelSizeLoc, 1.0 / spotShadowLight.shadow.mapSize.width);
        shader_set_uniform_f(__cache.uniformSpotShadowQualityLoc, shadowQuality);
        texture_set_stage(__cache.samplerSpotShadowMapIdx, spotShadowLight.shadow.map.getTexture());
      } else {
        shader_set_uniform_f(__cache.uniformSpotShadowEnabledLoc, 0.0);
      }
    }

    // --- Point Lights Data ---
    if (__cache.uniformPointLightsDataLoc != -1) {
      var pointLightsData = array_create(8 * 16, 0);
      for (var i = 0; i < 8; i++) {
        if (i < pointLightCount) {
          var light = pointLightState[i];
          if (light.intensity <= 0) continue;

          light.getWorldPosition(uniformsCache);
          var offset = i * 16;

          // Row 0: pos.xyz, range
          pointLightsData[offset + 0] = uniformsCache[0];
          pointLightsData[offset + 1] = uniformsCache[1];
          pointLightsData[offset + 2] = uniformsCache[2];
          pointLightsData[offset + 3] = light.distance;

          // Row 1: color.rgb, intensity
          pointLightsData[offset + 4] = light.color[0];
          pointLightsData[offset + 5] = light.color[1];
          pointLightsData[offset + 6] = light.color[2];
          pointLightsData[offset + 7] = light.intensity;

          // Row 2: decay, ...
          pointLightsData[offset + 8] = light.decay;
        }
      }
      shader_set_uniform_f_array(__cache.uniformPointLightsDataLoc, pointLightsData);
    }

    // --- Spot Lights Data ---
    if (__cache.uniformSpotLightsDataLoc != -1) {
      var spotLightsData = array_create(8 * 16, 0);
      for (var i = 0; i < 8; i++) {
        if (i < spotLightCount) {
          var light = spotLightState[i];
          if (light.intensity <= 0) continue;

          light.getWorldPosition(uniformsCache);
          var offset = i * 16;

          // Row 0: pos.xyz, range
          spotLightsData[offset + 0] = uniformsCache[0];
          spotLightsData[offset + 1] = uniformsCache[1];
          spotLightsData[offset + 2] = uniformsCache[2];
          spotLightsData[offset + 3] = light.distance;

          // Row 1: color.rgb, intensity
          spotLightsData[offset + 4] = light.color[0];
          spotLightsData[offset + 5] = light.color[1];
          spotLightsData[offset + 6] = light.color[2];
          spotLightsData[offset + 7] = light.intensity;

          // Row 2: dir.xyz, decay
          var worldDir = global.UE_VEC3_TEMP1;
          light.getDirection(worldDir);
          spotLightsData[offset + 8] = worldDir[0];
          spotLightsData[offset + 9] = worldDir[1];
          spotLightsData[offset + 10] = worldDir[2];
          spotLightsData[offset + 11] = light.decay;

          // Row 3: angle, penumbra, ...
          spotLightsData[offset + 12] = cos(light.angle);
          spotLightsData[offset + 13] = cos(light.angle * (1.0 - light.penumbra));
        }
      }
      shader_set_uniform_f_array(__cache.uniformSpotLightsDataLoc, spotLightsData);
    }

    // --- Hemisphere Light ---
    if (__cache.uniformHemiLightIntensityLoc != -1) {
      if (hemiLightCount > 0) {
        var light = hemiLightState[0];
        var dir = global.UE_VEC3_TEMP1;
        vec3_copy(dir, light.position);
        vec3_normalize(dir);

        shader_set_uniform_f(__cache.uniformHemiLightDirLoc, dir[0], dir[1], dir[2]);
        shader_set_uniform_f_array(__cache.uniformHemiLightSkyColorLoc, light.skyColor);
        shader_set_uniform_f_array(__cache.uniformHemiLightGroundColorLoc, light.groundColor);
        shader_set_uniform_f(__cache.uniformHemiLightIntensityLoc, light.intensity);
      } else {
        shader_set_uniform_f(__cache.uniformHemiLightIntensityLoc, 0.0);
      }
    }
  }

  function use(renderer = undefined) {
    gml_pragma("forceinline");

    if (__cache == undefined) return self;
    shader_set(self.shader);

    // Set standard uniforms from the pre-built list
    var stdU = __cache.uniformsStandard;
    for (var i = 0, sl = array_length(stdU); i < sl; i++) {
      var uInfo = stdU[i];
      var loc = uInfo[0];
      var key = uInfo[1];
      var type = uInfo[2];
      var val = undefined;

      switch (key) {
        case "sceneData": val = global.UE_RENDERER_SCENE_DATA; break;
        case "materialData":
          var tm = (renderer != undefined) ? renderer.toneMapping : global.UE_RENDERER_TONE_MAPPING;
          var _exp = (renderer != undefined) ? renderer.toneMappingExposure : global.UE_RENDERER_TONE_MAPPING_EXPOSURE;
          var tmEnabled = (toneMapped && tm != UE_TONE_MAPPING.NONE) ? 1.0 : 0.0;
          val = [tm, _exp, tmEnabled];
          break;
        case "mapFlags":
          val = [__cache.hasMapsFlags.map, __cache.hasMapsFlags.alphaMap, __cache.hasMapsFlags.ormMap, __cache.hasMapsFlags.normalMap];
          break;
        case "mapFlags2":
          val = [__cache.hasMapsFlags.emissiveMap, __cache.hasMapsFlags.displacementMap, 0.0, 0.0];
          break;
      }

      if (val != undefined) {
        if (type == UE_UNIFORM_TYPE.FLOAT) {
          shader_set_uniform_f(loc, val);
        } else if (type == UE_UNIFORM_TYPE.VEC3) {
          shader_set_uniform_f(loc, val[0], val[1], val[2]);
        } else if (type == UE_UNIFORM_TYPE.VEC4) {
          shader_set_uniform_f(loc, val[0], val[1], val[2], val[3]);
        } else if (type == UE_UNIFORM_TYPE.ARRAY) {
          shader_set_uniform_f_array(loc, val);
        }
      }
    }

    // Set lights uniforms
    self.__setLightsUniforms();

    // Set custom uniforms
    var uCached = __cache.uniformsCached;
    for (var i = 0, il = array_length(uCached); i < il; i++) {
      var uData = uCached[i];
      var uObj = uData[0];
      var loc = uData[1];

      if (loc == -1) continue;

      var val = uObj.value;
      var type = uObj[$ "type"] ?? UE_UNIFORM_TYPE.FLOAT;

      switch (type) {
        case UE_UNIFORM_TYPE.FLOAT:
          shader_set_uniform_f(loc, val);
          break;
        case UE_UNIFORM_TYPE.VEC2:
          shader_set_uniform_f(loc, val[0], val[1]);
          break;
        case UE_UNIFORM_TYPE.VEC3:
          shader_set_uniform_f(loc, val[0], val[1], val[2]);
          break;
        case UE_UNIFORM_TYPE.VEC4:
          shader_set_uniform_f(loc, val[0], val[1], val[2], val[3]);
          break;
        case UE_UNIFORM_TYPE.MAT4: shader_set_uniform_matrix_array(loc, val); break;
        case UE_UNIFORM_TYPE.ARRAY: shader_set_uniform_f_array(loc, val); break;
        case UE_UNIFORM_TYPE.BUFFER:
          shader_set_uniform_f_buffer(loc, val, uObj[$ "offset"] ?? 0, uObj[$ "count"] ?? array_length(val));
          break;
      }
    }

    // Set textures from cache
    var tCached = __cache.texturesCached;
    for (var i = 0, tl = array_length(tCached); i < tl; i++) {
      var tData = tCached[i];
      var tex = tData[0];
      var sampler = tData[1];

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
    if (__cache == undefined) return;

    // Update the shader's model position uniform (for billboard sprites)
    if (mesh[$ "isSprite"]) {
      var _cacheUniformModelPositionLoc = __cache[$ "uniformModelPositionLoc"];
      if (_cacheUniformModelPositionLoc != undefined && _cacheUniformModelPositionLoc != -1) {
        shader_set_uniform_f_array(_cacheUniformModelPositionLoc, mesh.position);
      }
    }

    // Set world matrix
    var _cacheUniformWorldMatrixLoc = __cache[$ "uniformWorldMatrixLoc"];
    if (_cacheUniformWorldMatrixLoc != undefined && _cacheUniformWorldMatrixLoc != -1) {
      shader_set_uniform_matrix_array(_cacheUniformWorldMatrixLoc, mesh.matrixWorld);
    }

    // Set receive shadow uniform
    var _cacheUniformReceiveShadowLoc = __cache[$ "uniformReceiveShadowLoc"];
    if (_cacheUniformReceiveShadowLoc != undefined && _cacheUniformReceiveShadowLoc != -1) {
      shader_set_uniform_f(_cacheUniformReceiveShadowLoc, mesh.receiveShadow ? 1.0 : 0.0);
    }

    // Set the culling mode (can be overwritten by argument for transparent objects)
    gpu_set_cullmode(renderSide ?? side);

    return self;
  }

  /**
   * Clone the material
   */
  function clone() {
    gml_pragma("forceinline");
    return variable_clone(self);
  }

  function toJSON() {
    gml_pragma("forceinline");
    var keys = ["uuid", "type", "name", "transparent", "opacity", "depthTest", "side", "depthWrite", "depthFunc", "forceSinglePass", "alphaTest", "colorWrite", "blending", "blendEquation", "blendEquationAlpha", "blendSrc", "blendDst", "blendSrcAlpha", "blendDstAlpha", "lights", "toneMapped"];

    var out = {
      uniforms,
      textures: ueStructMap(textures, function (name, texture) {
        return texture != undefined ? texture.uuid : undefined;
      }),
      shader: shader_get_name(shader)
    };

    for (var i = 0, il = array_length(keys); i < il; i++) {
      var k = keys[i];
      out[$ k] = self[$ k];
    }
    return out;
  }

  function fromJSON(data, texturesByUUID = {}) {
    gml_pragma("forceinline");
    var fields = ["uuid", "name", "transparent", "opacity", "side", "depthTest", "depthWrite", "depthFunc", "forceSinglePass", "alphaTest", "colorWrite", "blending", "blendEquation", "blendEquationAlpha", "blendSrc", "blendDst", "blendSrcAlpha", "blendDstAlpha", "lights", "toneMapped"];
    for (var i = 0; i < array_length(fields); i++) {
      var field = fields[i];
      self[$ field] = data[$ field];
    }

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
