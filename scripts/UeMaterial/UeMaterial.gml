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

  // Uniforms
  uniforms = data[$ "uniforms"] ?? {};
  __uniformsCached = [];
  __uniformsCachedCount = 0;
  __texturesCached = [];
  __texturesCachedCount = 0;

  __uniformModelPositionLoc = undefined;
  __uniformWorldMatrixLoc = undefined;
  __uniformCameraPositionLoc = undefined;
  __uniformLightSpaceMatrixLoc = undefined;
  __uniformShadowEnabledLoc = undefined;
  __uniformReceiveShadowLoc = undefined;
  __samplerShadowMapIdx = undefined;
  __uniformEmissiveIntensityLoc = undefined;
  //__uniformAoIntensityLoc = undefined;
  //__uniformAoMapIntensityLoc = undefined;

  // Fog uniforms
  //__uniformFogColorLoc = undefined;
  //__uniformFogDensityLoc = undefined;
  //__uniformFogNearLoc = undefined;
  //__uniformFogFarLoc = undefined;

  // Light uniforms
  lights = data[$ "lights"] ?? 2;
  __uniformLightsAmbientLoc = undefined;
  __uniformLightsDir = [];
  __uniformLightsPos = [];

  // Shadow quality
  shadowQuality = data[$ "shadowQuality"] ?? UE_SHADOW_QUALITY.HIGH;
  __uniformShadowQualityLoc = undefined;
  __uniformShadowTexelSizeLoc = undefined;

  // Uniform names config
  __uniformNamesConfig = global.UE_UNIFORM_NAMES_CONFIG;

  // Textures
  __baseTexture = global.UE_TEXTURE_DEFAULT_WHITE;
  textures = {
    map: data[$ "map"] ?? global.UE_TEXTURE_DEFAULT_WHITE,
  };

  //aoIntensity = data[$ "aoIntensity"] ?? 1;
  //aoMapIntensity = data[$ "aoMapIntensity"] ?? 1;
  emissiveIntensity = data[$ "emissiveIntensity"] ?? 0;
  receiveShadow = data[$ "receiveShadow"] ?? true;

  // Cache uniform/sampler locations
  function build() {
   gml_pragma("forceinline");
   if (shader == undefined) return;
   var cfg = __uniformNamesConfig;

   // Cache the engine uniforms
   __uniformModelPositionLoc = shader_get_uniform(shader, cfg.modelPosition);
   __uniformWorldMatrixLoc = shader_get_uniform(shader, cfg.worldMatrix);
   __uniformCameraPositionLoc = shader_get_uniform(shader, cfg.cameraPosition);
   __uniformLightsAmbientLoc = shader_get_uniform(shader, cfg.ambient);
   __uniformEmissiveIntensityLoc = shader_get_uniform(shader, cfg.emissiveIntensity);
   //__uniformAoIntensityLoc = shader_get_uniform(shader, cfg.aoIntensity);
   //__uniformAoMapIntensityLoc = shader_get_uniform(shader, cfg.aoMapIntensity);

   // Cache shadow uniforms
   __uniformLightSpaceMatrixLoc = shader_get_uniform(shader, cfg.lightSpaceMatrix);
   __uniformShadowEnabledLoc = shader_get_uniform(shader, cfg.shadowEnabled);
   __uniformReceiveShadowLoc = shader_get_uniform(shader, cfg.receiveShadow);
   __uniformShadowQualityLoc = shader_get_uniform(shader, cfg.shadowQuality);
   __uniformShadowTexelSizeLoc = shader_get_uniform(shader, cfg.shadowTexelSize);
   __samplerShadowMapIdx = shader_get_sampler_index(shader, cfg.shadowMapSampler);

   // Cache fog uniforms
   //__uniformFogColorLoc = shader_get_uniform(shader, cfg.fogColor);
   //__uniformFogDensityLoc = shader_get_uniform(shader, cfg.fogDensity);
   //__uniformFogNearLoc = shader_get_uniform(shader, cfg.fogNear);
   //__uniformFogFarLoc = shader_get_uniform(shader, cfg.fogFar);
 
   __uniformLightsDir = array_create(lights);
   __uniformLightsPos = array_create(lights);
 
   for (var l = 0; l < lights; l++) {
     __uniformLightsDir[l] = [
       shader_get_uniform(shader, $"{cfg.dirLightDir}{l}"),
       shader_get_uniform(shader, $"{cfg.dirLightColor}{l}"),
       shader_get_uniform(shader, $"{cfg.dirLightIntensity}{l}"),
     ];
 
     __uniformLightsPos[l] = [
       shader_get_uniform(shader, $"{cfg.pointLightPosition}{l}"),
       shader_get_uniform(shader, $"{cfg.pointLightColor}{l}"),
       shader_get_uniform(shader, $"{cfg.pointLightRange}{l}"),
       shader_get_uniform(shader, $"{cfg.pointLightIntensity}{l}"),
     ];
   }
 
   // Cache the uniforms
   var uniformNames = variable_struct_get_names(uniforms);
   __uniformsCachedCount = array_length(uniformNames);
   __uniformsCached = array_create(__uniformsCachedCount);
 
   for (var u = 0; u < __uniformsCachedCount; u++) {
     var uniformName = uniformNames[u];
     var uniformLoc = shader_get_uniform(shader, $"u_{uniformName}");
 
     __uniformsCached[u] = [
       uniforms[$ uniformName],
       uniformLoc
     ];
   }
 
   // Cache the textures
   var textureNames = variable_struct_get_names(textures);
   var textureNamesCount = array_length(textureNames);
 
   __texturesCached = array_create(textureNamesCount);
   __texturesCachedCount = 0;
   __baseTexture = global.UE_TEXTURE_DEFAULT_WHITE;
 
   for (var t = 0; t < textureNamesCount; t++) {
    var textureName = textureNames[t];
    if (textureName == "map") {
      __baseTexture = textures.map ?? global.UE_TEXTURE_DEFAULT_WHITE;
      continue;
     }
    
    var samplerIdx = shader_get_sampler_index(shader, $"s_{textureName}");
    if (samplerIdx != -1) {
      __texturesCached[__texturesCachedCount] = [
        textures[$ textureName],
        samplerIdx
      ];
      __texturesCachedCount++;
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
 
   shader_set_uniform_f_array(__uniformLightsAmbientLoc, lightState[UE_RENDERER_LIGHT_STATE_ENUM.AMBIENT]);
 
   // Set directional lights
   for (var i = 0; i < lights; i++) {
     var lightLoc = __uniformLightsDir[i];
 
     if (i < directionalCount) {
       var light = directionalState[i];
 
       // Get light direction (from position to target)
       light.getDirection();
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
 
   if (shadowLight != undefined) {
     shader_set_uniform_f(__uniformShadowEnabledLoc, 1.0);
     shader_set_uniform_f(__uniformShadowQualityLoc, shadowQuality);
 
     // Calculate texel size based on shadow map resolution
     var shadowMapWidth = shadowLight.shadow.map.width;
     var texelSize = 1.0 / shadowMapWidth;
     shader_set_uniform_f(__uniformShadowTexelSizeLoc, texelSize);
 
     shader_set_uniform_matrix_array(__uniformLightSpaceMatrixLoc, shadowLight.shadow.lightSpaceMatrix);
     texture_set_stage(__samplerShadowMapIdx, shadowLight.shadow.map.getTexture());
   } else {
     shader_set_uniform_f(__uniformShadowEnabledLoc, 0.0);
   }
 
   // Set point lights
   var lightColor;
   for (var i = 0; i < lights; i++) {
     var lightLoc = __uniformLightsPos[i];
 
     if (i < pointLightCount) {
       var light = pointLightState[i];
       shader_set_uniform_f_array(lightLoc[0], light.position);
       shader_set_uniform_f_array(lightLoc[1], light.color);
       shader_set_uniform_f(lightLoc[2], light.range);
       shader_set_uniform_f(lightLoc[3], light.intensity);
     } else {
       // Reset unused light slots
       shader_set_uniform_f(lightLoc[3], 0);
     }
   }
 }

  /// Apply material before drawing
  function use() {
    gml_pragma("forceinline");
  
    shader_set(shader);
    __setLightsUniforms();

    // Set camera position
    if (__uniformCameraPositionLoc != undefined) {
      shader_set_uniform_f_array(__uniformCameraPositionLoc, global.UE_RENDERER_CAMERA_POSITION);
    }

    // Set fog uniforms
    //var fogState = global.UE_RENDERER_FOG_STATE;
    //var materialFogEnabled = self[$ "fog"] ?? true;
//
    //if (fogState.enabled && materialFogEnabled) {
      //if (__uniformFogColorLoc != undefined) shader_set_uniform_f_array(__uniformFogColorLoc, fogState.color);
      //if (__uniformFogDensityLoc != undefined) shader_set_uniform_f(__uniformFogDensityLoc, fogState.density);
      //if (__uniformFogNearLoc != undefined) shader_set_uniform_f(__uniformFogNearLoc, fogState.near);
      //if (__uniformFogFarLoc != undefined) shader_set_uniform_f(__uniformFogFarLoc, fogState.far);
    //} else {
      //// Disable fog by setting density to 0 or far plane to infinity
      //if (__uniformFogDensityLoc != undefined) shader_set_uniform_f(__uniformFogDensityLoc, 0);
      //if (__uniformFogFarLoc != undefined) shader_set_uniform_f(__uniformFogFarLoc, 0);
    //}
  
    // Reset emissive uniforms
    if (__uniformEmissiveIntensityLoc != undefined) {
      shader_set_uniform_f(__uniformEmissiveIntensityLoc, emissiveIntensity);
    }
    //if (__uniformAoIntensityLoc != undefined) {
      //shader_set_uniform_f(__uniformAoIntensityLoc, aoIntensity);
    //}
    //if (__uniformAoMapIntensityLoc != undefined) {
      //shader_set_uniform_f(__uniformAoMapIntensityLoc, aoMapIntensity);
    //}

    // Apply the uniforms on the shader
    for (var u = 0; u < __uniformsCachedCount; u++) {
      var uniformCached = __uniformsCached[u];
      var uniform = uniformCached[0];
  
      var val = uniform.value;
      if (val == undefined) continue;
  
      var loc = uniformCached[1];
      switch (uniform.type) {
        case UE_UNIFORM_TYPE.FLOAT: shader_set_uniform_f(loc, val); break;
        case UE_UNIFORM_TYPE.VEC2: shader_set_uniform_f(loc, val[0], val[1]); break;
        case UE_UNIFORM_TYPE.VEC3: shader_set_uniform_f(loc, val[0], val[1], val[2]); break;
        case UE_UNIFORM_TYPE.VEC4: shader_set_uniform_f(loc, val[0], val[1], val[2], val[3]); break;
        case UE_UNIFORM_TYPE.MAT4: shader_set_uniform_matrix_array(loc, val); break;
        case UE_UNIFORM_TYPE.ARRAY: shader_set_uniform_f_array(loc, val); break;
        case UE_UNIFORM_TYPE.BUFFER: shader_set_uniform_f_buffer(loc, val, uniform.offset, uniform.count); break;
      }
    }
  
    // Set the texture samplers
    for (var t = 0; t < __texturesCachedCount; t++) {
      var textureCached = __texturesCached[t];
      if (textureCached == undefined) continue;
      textureCached[0].__use(textureCached[1]);
    }
  
    gpu_set_ztestenable(depthTest);
    gpu_set_zwriteenable(transparent ? false : depthWrite);
    gpu_set_zfunc(depthFunc);
    gpu_set_alphatestenable(transparent);
    gpu_set_alphatestref(alphaTest);
    gpu_set_colorwriteenable(colorWrite, colorWrite, colorWrite, colorWrite);
    gpu_set_blendenable(blending);
    gpu_set_blendequation_sepalpha(blendEquation, blendEquationAlpha);
    gpu_set_blendmode_ext_sepalpha(blendSrc, blendDst, blendSrcAlpha, blendDstAlpha);
  
    return self;
  }
  
  function useByMesh(mesh, renderSide = undefined) {
    gml_pragma("forceinline");
  
    // Update the shader's model position uniform (for billboard sprites)
    if (mesh.isSprite) {
      shader_set_uniform_f_array(__uniformModelPositionLoc, mesh.position);
    }

    // Set world matrix
    if (__uniformWorldMatrixLoc != undefined) {
      shader_set_uniform_matrix_array(__uniformWorldMatrixLoc, mesh.matrixWorld);
    }
  
    // Set receive shadow uniform
    if (__uniformReceiveShadowLoc != undefined) {
      shader_set_uniform_f(__uniformReceiveShadowLoc, mesh.receiveShadow ? 1.0 : 0.0);
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
            // Check if it's a default texture
            if (textureUUID == global.UE_TEXTURE_DEFAULT_WHITE.uuid) {
              textures[$ textureName] = global.UE_TEXTURE_DEFAULT_WHITE;
            } else if (textureUUID == global.UE_TEXTURE_DEFAULT_BLACK.uuid) {
              textures[$ textureName] = global.UE_TEXTURE_DEFAULT_BLACK;
            } else if (textureUUID == global.UE_TEXTURE_DEFAULT_NORMAL.uuid) {
              textures[$ textureName] = global.UE_TEXTURE_DEFAULT_NORMAL;
            } else if (textureUUID == global.UE_TEXTURE_DEFAULT_ORM.uuid) {
              textures[$ textureName] = global.UE_TEXTURE_DEFAULT_ORM;
            } else {
              // Keep UUID for later linking (texture not found)
              textures[$ textureName] = textureUUID;
            }
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
