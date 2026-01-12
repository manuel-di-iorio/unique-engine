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

  // Uniforms
  uniforms = data[$ "uniforms"] ?? {};
  __uniformsCached = [];
  __uniformsCachedCount = 0;
  __texturesCached = [];
  __texturesCachedCount = 0;

  __uniformModelPositionLoc = undefined;
  __uniformWorldMatrixLoc = undefined;
  __uniformCameraPositionLoc = undefined;
  __uniformDirShadowMatrixLoc = undefined;
  __uniformDirShadowEnabledLoc = undefined;
  __uniformPointShadowEnabledLoc = undefined;
  __uniformReceiveShadowLoc = undefined;
  __samplerDirShadowMapIdx = undefined;
  __samplerPointShadowMapIdx = undefined;
  __uniformPointShadowFarLoc = undefined;
  __uniformPointShadowNearLoc = undefined;
  __uniformPointShadowPosLoc = undefined;
  __uniformSpotShadowEnabledLoc = undefined;
  __uniformSpotShadowMatrixLoc = undefined;
  __uniformSpotShadowQualityLoc = undefined;
  __uniformSpotShadowTexelSizeLoc = undefined;
  __uniformSpotShadowFarLoc = undefined;
  __uniformSpotShadowNearLoc = undefined;
  __uniformSpotShadowPosLoc = undefined;
  __samplerSpotShadowMapIdx = -1;
  __uniformHemiLightDirLoc = undefined;
  __uniformHemiLightSkyColorLoc = undefined;
  __uniformHemiLightGroundColorLoc = undefined;
  __uniformHemiLightIntensityLoc = undefined;
  __uniformEmissiveIntensityLoc = undefined;
  __uniformToneMappingLoc = undefined;
  __uniformToneMappingExposureLoc = undefined;
  __uniformToneMappedLoc = undefined;

  // Spot light uniforms
  __uniformSpotLightsPos = undefined;
  __uniformSpotLightsDir = undefined;
  __uniformSpotLightsColor = undefined;
  __uniformSpotLightsRange = undefined;
  __uniformSpotLightsIntensity = undefined;
  __uniformSpotLightsDecay = undefined;
  __uniformSpotLightsAngle = undefined;
  __uniformSpotLightsPenumbra = undefined;

  // Has maps uniforms
  __uniformHasMapLoc = undefined;
  __uniformHasAlphaMapLoc = undefined;
  __uniformHasOrmMapLoc = undefined;
  __uniformHasNormalMapLoc = undefined;
  __uniformHasEmissiveMapLoc = undefined;
  __uniformHasDisplacementMapLoc = undefined;
  __hasMapsFlags = {
    map: 0,
    alphaMap: 0,
    ormMap: 0,
    normalMap: 0,
    emissiveMap: 0,
    displacementMap: 0
  };

  // Fog uniforms
  __uniformFogColorLoc = undefined;
  __uniformFogDensityLoc = undefined;
  __uniformFogNearLoc = undefined;
  __uniformFogFarLoc = undefined;

  // Light uniforms
  lights = data[$ "lights"] ?? true;
  __uniformLightsAmbientLoc = undefined;
  __uniformLightsDir = [];
  __uniformLightsPos = undefined;
  __uniformLightsColor = undefined;
  __uniformLightsRange = undefined;
  __uniformLightsIntensity = undefined;
  __uniformLightsDecay = undefined;

  // Shadow quality
  shadowQuality = data[$ "shadowQuality"] ?? UE_SHADOW_QUALITY.HIGH;
  __uniformDirShadowQualityLoc = undefined;
  __uniformDirShadowTexelSizeLoc = undefined;

  // Uniform names config
  __uniformNamesConfig = global.UE_UNIFORM_NAMES_CONFIG;

  // Textures
  __baseTexture = undefined;
  textures = {
    map: data[$ "map"],
  };

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

   // Cache shadow uniforms
   __uniformDirShadowMatrixLoc = shader_get_uniform(shader, cfg.lightSpaceMatrix);
   __uniformDirShadowEnabledLoc = shader_get_uniform(shader, cfg.shadowEnabled);
   __uniformPointShadowEnabledLoc = shader_get_uniform(shader, cfg.pointShadowEnabled);
   __uniformReceiveShadowLoc = shader_get_uniform(shader, cfg.receiveShadow);
   __uniformDirShadowQualityLoc = shader_get_uniform(shader, cfg.shadowQuality);
   __uniformDirShadowTexelSizeLoc = shader_get_uniform(shader, cfg.shadowTexelSize);
   __samplerDirShadowMapIdx = shader_get_sampler_index(shader, cfg.shadowMapSampler);
   
   __samplerPointShadowMapIdx = shader_get_sampler_index(shader, cfg.pointShadowMapSampler);
   __uniformPointShadowFarLoc = shader_get_uniform(shader, cfg.pointShadowFar);
   __uniformPointShadowNearLoc = shader_get_uniform(shader, cfg.pointShadowNear);
   __uniformPointShadowPosLoc = shader_get_uniform(shader, cfg.pointShadowPos);
   __uniformPointShadowTexelSizeLoc = shader_get_uniform(shader, cfg.pointShadowTexelSize);
   __uniformPointShadowQualityLoc = shader_get_uniform(shader, cfg.pointShadowQuality);
   __uniformPointShadowMatrixLoc = shader_get_uniform(shader, "u_uePointShadowMatrix");
   
   __uniformSpotShadowEnabledLoc = shader_get_uniform(shader, cfg.spotShadowEnabled);
   __uniformSpotShadowMatrixLoc = shader_get_uniform(shader, cfg.spotShadowMatrix);
   __samplerSpotShadowMapIdx = shader_get_sampler_index(shader, cfg.spotShadowMapSampler);
   __uniformSpotShadowFarLoc = shader_get_uniform(shader, cfg.spotShadowFar);
   __uniformSpotShadowNearLoc = shader_get_uniform(shader, cfg.spotShadowNear);
   __uniformSpotShadowPosLoc = shader_get_uniform(shader, cfg.spotShadowPos);
   __uniformSpotShadowTexelSizeLoc = shader_get_uniform(shader, cfg.spotShadowTexelSize);
   __uniformSpotShadowQualityLoc = shader_get_uniform(shader, cfg.spotShadowQuality);

   // Cache tone mapping uniforms
   __uniformToneMappingLoc = shader_get_uniform(shader, cfg.toneMapping);
   __uniformToneMappingExposureLoc = shader_get_uniform(shader, cfg.toneMappingExposure);
   __uniformToneMappedLoc = shader_get_uniform(shader, cfg.toneMapped);

   // Cache has maps uniforms
   __uniformHasMapLoc = shader_get_uniform(shader, cfg.hasMap);
   __uniformHasAlphaMapLoc = shader_get_uniform(shader, cfg.hasAlphaMap);
   __uniformHasOrmMapLoc = shader_get_uniform(shader, cfg.hasOrmMap);
   __uniformHasNormalMapLoc = shader_get_uniform(shader, cfg.hasNormalMap);
   __uniformHasEmissiveMapLoc = shader_get_uniform(shader, cfg.hasEmissiveMap);
   __uniformHasDisplacementMapLoc = shader_get_uniform(shader, cfg.hasDisplacementMap);

   // Cache fog uniforms
   __uniformFogColorLoc = shader_get_uniform(shader, cfg.fogColor);
   __uniformFogDensityLoc = shader_get_uniform(shader, cfg.fogDensity);
   __uniformFogNearLoc = shader_get_uniform(shader, cfg.fogNear);
   __uniformFogFarLoc = shader_get_uniform(shader, cfg.fogFar);
 
   __uniformLightsDir = array_create(1);
   
   for (var l = 0; l < 1; l++) {
     __uniformLightsDir[l] = [
       shader_get_uniform(shader, $"{cfg.dirLightDir}{l}"),
       shader_get_uniform(shader, $"{cfg.dirLightColor}{l}"),
       shader_get_uniform(shader, $"{cfg.dirLightIntensity}{l}"),
     ];
   }

   __uniformLightsPos = shader_get_uniform(shader, cfg.pointLightPosition);
   __uniformLightsColor = shader_get_uniform(shader, cfg.pointLightColor);
   __uniformLightsRange = shader_get_uniform(shader, cfg.pointLightRange);
   __uniformLightsIntensity = shader_get_uniform(shader, cfg.pointLightIntensity);
  __uniformLightsDecay = shader_get_uniform(shader, cfg.pointLightDecay);

  __uniformSpotLightsPos = shader_get_uniform(shader, cfg.spotLightPosition);
  __uniformSpotLightsDir = shader_get_uniform(shader, cfg.spotLightDirection);
  __uniformSpotLightsColor = shader_get_uniform(shader, cfg.spotLightColor);
  __uniformSpotLightsRange = shader_get_uniform(shader, cfg.spotLightRange);
  __uniformSpotLightsIntensity = shader_get_uniform(shader, cfg.spotLightIntensity);
  __uniformSpotLightsDecay = shader_get_uniform(shader, cfg.spotLightDecay);
  __uniformSpotLightsAngle = shader_get_uniform(shader, cfg.spotLightAngle);
  __uniformSpotLightsPenumbra = shader_get_uniform(shader, cfg.spotLightPenumbra);

  // Cache hemisphere light uniforms
  __uniformHemiLightDirLoc = shader_get_uniform(shader, cfg.hemiLightDirection);
  __uniformHemiLightSkyColorLoc = shader_get_uniform(shader, cfg.hemiLightSkyColor);
  __uniformHemiLightGroundColorLoc = shader_get_uniform(shader, cfg.hemiLightGroundColor);
  __uniformHemiLightIntensityLoc = shader_get_uniform(shader, cfg.hemiLightIntensity);

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
  __baseTexture = undefined;
  
  // Reset has maps flags
  __hasMapsFlags.map = 0;
  __hasMapsFlags.alphaMap = 0;
  __hasMapsFlags.ormMap = 0;
  __hasMapsFlags.normalMap = 0;
  __hasMapsFlags.emissiveMap = 0;
  __hasMapsFlags.displacementMap = 0;

   for (var t = 0; t < textureNamesCount; t++) {
    var textureName = textureNames[t];
    var texture = textures[$ textureName];
    
    var isDefault = false;

    // Special case for base map
    if (textureName == "map") {
      __baseTexture = texture;
      __hasMapsFlags.map = (texture == undefined) ? 0 : 1;
      continue;
    }

    var samplerIdx = shader_get_sampler_index(shader, $"s_{textureName}");
    if (samplerIdx != -1) {
      // If texture is undefined or not a struct (invalid), it's considered default
      if (texture == undefined || !is_struct(texture)) {
        isDefault = true;
      }

      // Set the "hasMap" flag for known maps
      if (variable_struct_exists(__hasMapsFlags, textureName)) {
          __hasMapsFlags[$ textureName] = isDefault ? 0 : 1;
      }

      // Special case for displacement map in vertex shader
      if (textureName == "displacementMap") {
          __hasMapsFlags.displacementMap = isDefault ? 0 : 1;
      }

      // Only cache for texture_set_stage if it's NOT a default texture
      if (!isDefault) {
          __texturesCached[__texturesCachedCount] = [
            texture,
            samplerIdx
          ];
          __texturesCachedCount++;
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

  shader_set_uniform_f_array(__uniformLightsAmbientLoc, lightState[UE_RENDERER_LIGHT_STATE_ENUM.AMBIENT]);
 
   // Set directional lights (max 1)
   for (var i = 0; i < 1; i++) {
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
 
   if (shadowLight != undefined && surface_exists(shadowLight.shadow.map.surface)) {
     shader_set_uniform_f(__uniformDirShadowEnabledLoc, 1.0);
     shader_set_uniform_f(__uniformDirShadowQualityLoc, shadowQuality);
 
     // Calculate texel size based on shadow map resolution
     var shadowMapWidth = shadowLight.shadow.map.width;
     var texelSize = 1.0 / shadowMapWidth;
     shader_set_uniform_f(__uniformDirShadowTexelSizeLoc, texelSize);
 
     shader_set_uniform_matrix_array(__uniformDirShadowMatrixLoc, shadowLight.shadow.lightSpaceMatrix);
     texture_set_stage(__samplerDirShadowMapIdx, shadowLight.shadow.map.getTexture());
   } else if (__uniformDirShadowEnabledLoc != undefined) {
     shader_set_uniform_f(__uniformDirShadowEnabledLoc, 0.0);
   }

   // Set point shadow uniforms (from the first shadow-casting point light)
  var pointShadowLight = undefined;
  for (var i = 0; i < pointLightCount; i++) {
    if (pointLightState[i].castShadow) {
      pointShadowLight = pointLightState[i];
      break;
    }
  }

  if (pointShadowLight != undefined && __samplerPointShadowMapIdx != -1) {
    shader_set_uniform_f(__uniformPointShadowEnabledLoc, 1.0);
    shader_set_uniform_f(__uniformPointShadowFarLoc, pointShadowLight.shadow.cameras[0].far);
    shader_set_uniform_f(__uniformPointShadowNearLoc, pointShadowLight.shadow.cameras[0].near);
    
    // Set texel size for point shadows
    var pointShadowMapWidth = pointShadowLight.shadow.mapSize.width;
    var pointShadowMapHeight = pointShadowLight.shadow.mapSize.height;
    if (__uniformPointShadowTexelSizeLoc != undefined) {
      shader_set_uniform_f(__uniformPointShadowTexelSizeLoc, 1.0 / (pointShadowMapWidth * 3.0), 1.0 / (pointShadowMapHeight * 2.0));
    }
    
    if (__uniformPointShadowQualityLoc != undefined) {
      shader_set_uniform_f(__uniformPointShadowQualityLoc, shadowQuality);
    }
    
    // Use world position for point shadow origin
    var worldPos = global.UE_VEC3_TEMP1;
    pointShadowLight.getWorldPosition(worldPos);
    shader_set_uniform_f_array(__uniformPointShadowPosLoc, worldPos);
    
    // Set point shadow matrices (6 faces)
    if (__uniformPointShadowMatrixLoc != -1) {
        var matrices = array_create(16 * 6);
        for (var i = 0; i < 6; i++) {
            var cam = pointShadowLight.shadow.cameras[i];
            matrix_multiply(cam.matrixWorldInverse, cam.projectionMatrix, global.UE_MAT4_TEMP0);
            for (var m = 0; m < 16; m++) {
                matrices[i * 16 + m] = global.UE_MAT4_TEMP0[m];
            }
        }
        shader_set_uniform_f_array(__uniformPointShadowMatrixLoc, matrices);
    }
    
    texture_set_stage(__samplerPointShadowMapIdx, pointShadowLight.shadow.map.getTexture());
  } else if (__uniformPointShadowEnabledLoc != undefined) {
    shader_set_uniform_f(__uniformPointShadowEnabledLoc, 0.0);
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
      var worldPos = global.UE_VEC3_TEMP1;
      light.getWorldPosition(worldPos);
      
      posArr[i * 3 + 0] = worldPos[0];
      posArr[i * 3 + 1] = worldPos[1];
      posArr[i * 3 + 2] = worldPos[2];
      
      colorArr[i * 3 + 0] = light.color[0];
      colorArr[i * 3 + 1] = light.color[1];
      colorArr[i * 3 + 2] = light.color[2];
      
      rangeArr[i] = light.distance;
      intensityArr[i] = light.intensity;
      decayArr[i] = light.decay;
    }
  }

  shader_set_uniform_f_array(__uniformLightsPos, posArr);
  shader_set_uniform_f_array(__uniformLightsColor, colorArr);
  shader_set_uniform_f_array(__uniformLightsRange, rangeArr);
  shader_set_uniform_f_array(__uniformLightsIntensity, intensityArr);
  shader_set_uniform_f_array(__uniformLightsDecay, decayArr);

  // Set spot shadow uniforms (from the first shadow-casting spot light)
  var spotShadowLight = undefined;
  for (var i = 0; i < spotLightCount; i++) {
    if (spotLightState[i].castShadow) {
      spotShadowLight = spotLightState[i];
      break;
    }
  }

  if (spotShadowLight != undefined && __samplerSpotShadowMapIdx != -1) {
    shader_set_uniform_f(__uniformSpotShadowEnabledLoc, 1.0);
    shader_set_uniform_matrix_array(__uniformSpotShadowMatrixLoc, spotShadowLight.shadow.lightSpaceMatrix);
    
    if (__uniformSpotShadowFarLoc != undefined) shader_set_uniform_f(__uniformSpotShadowFarLoc, spotShadowLight.shadow.camera.far);
    if (__uniformSpotShadowNearLoc != undefined) shader_set_uniform_f(__uniformSpotShadowNearLoc, spotShadowLight.shadow.camera.near);
    if (__uniformSpotShadowPosLoc != undefined) shader_set_uniform_f(__uniformSpotShadowPosLoc, spotShadowLight.position[0], spotShadowLight.position[1], spotShadowLight.position[2]);
    if (__uniformSpotShadowTexelSizeLoc != undefined) shader_set_uniform_f(__uniformSpotShadowTexelSizeLoc, 1.0 / spotShadowLight.shadow.mapSize.width);
    if (__uniformSpotShadowQualityLoc != undefined) shader_set_uniform_f(__uniformSpotShadowQualityLoc, shadowQuality);

    texture_set_stage(__samplerSpotShadowMapIdx, spotShadowLight.shadow.map.getDepthTexture());
  } else if (__uniformSpotShadowEnabledLoc != undefined) {
    shader_set_uniform_f(__uniformSpotShadowEnabledLoc, 0.0);
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
      
      var worldPos = global.UE_VEC3_TEMP1;
      light.getWorldPosition(worldPos);
      sPosArr[i * 3 + 0] = worldPos[0];
      sPosArr[i * 3 + 1] = worldPos[1];
      sPosArr[i * 3 + 2] = worldPos[2];
      
      var worldDir = light.getDirection();
      sDirArr[i * 3 + 0] = worldDir[0];
      sDirArr[i * 3 + 1] = worldDir[1];
      sDirArr[i * 3 + 2] = worldDir[2];
      
      sColorArr[i * 3 + 0] = light.color[0];
      sColorArr[i * 3 + 1] = light.color[1];
      sColorArr[i * 3 + 2] = light.color[2];
      
      sRangeArr[i] = light.distance;
      sIntensityArr[i] = light.intensity;
      sDecayArr[i] = light.decay;
      sAngleArr[i] = dcos(light.angle); // Send cosine for easier shader math
      sPenumbraArr[i] = dcos(light.angle * (1.0 - light.penumbra));
    }
  }

  if (__uniformSpotLightsPos != undefined) {
    shader_set_uniform_f_array(__uniformSpotLightsPos, sPosArr);
    shader_set_uniform_f_array(__uniformSpotLightsDir, sDirArr);
    shader_set_uniform_f_array(__uniformSpotLightsColor, sColorArr);
    shader_set_uniform_f_array(__uniformSpotLightsRange, sRangeArr);
    shader_set_uniform_f_array(__uniformSpotLightsIntensity, sIntensityArr);
    shader_set_uniform_f_array(__uniformSpotLightsDecay, sDecayArr);
    shader_set_uniform_f_array(__uniformSpotLightsAngle, sAngleArr);
    shader_set_uniform_f_array(__uniformSpotLightsPenumbra, sPenumbraArr);
  }

  // Set hemisphere light (max 1)
  if (hemiLightCount > 0 && __uniformHemiLightIntensityLoc != undefined) {
    var light = hemiLightState[0];
    
    // Direction is normalized position
    var dir = global.UE_VEC3_TEMP1;
    vec3_copy(dir, light.position);
    vec3_normalize(dir);
    
    shader_set_uniform_f(__uniformHemiLightDirLoc, dir[0], dir[1], dir[2]);
    shader_set_uniform_f_array(__uniformHemiLightSkyColorLoc, light.skyColor);
    shader_set_uniform_f_array(__uniformHemiLightGroundColorLoc, light.groundColor);
    shader_set_uniform_f(__uniformHemiLightIntensityLoc, light.intensity);
  } else if (__uniformHemiLightIntensityLoc != undefined) {
    shader_set_uniform_f(__uniformHemiLightIntensityLoc, 0.0);
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
    var fogState = global.UE_RENDERER_FOG_STATE;
    var materialFogEnabled = self[$ "fog"] ?? true;

    if (fogState.enabled && materialFogEnabled) {
      if (__uniformFogColorLoc != undefined) shader_set_uniform_f_array(__uniformFogColorLoc, fogState.color);
      if (__uniformFogDensityLoc != undefined) shader_set_uniform_f(__uniformFogDensityLoc, fogState.density);
      if (__uniformFogNearLoc != undefined) shader_set_uniform_f(__uniformFogNearLoc, fogState.near);
      if (__uniformFogFarLoc != undefined) shader_set_uniform_f(__uniformFogFarLoc, fogState.far);
    } else {
      // Disable fog by setting density to 0 or far plane to infinity
      if (__uniformFogDensityLoc != undefined) shader_set_uniform_f(__uniformFogDensityLoc, 0);
      if (__uniformFogFarLoc != undefined) shader_set_uniform_f(__uniformFogFarLoc, 0);
    }
  
    // Reset emissive uniforms
    if (__uniformEmissiveIntensityLoc != undefined) {
      shader_set_uniform_f(__uniformEmissiveIntensityLoc, emissiveIntensity);
    }

    // Set tone mapping uniforms
    if (__uniformToneMappingLoc != undefined) {
      shader_set_uniform_f(__uniformToneMappingLoc, global.UE_RENDERER_TONE_MAPPING);
    }
    if (__uniformToneMappingExposureLoc != undefined) {
      shader_set_uniform_f(__uniformToneMappingExposureLoc, global.UE_RENDERER_TONE_MAPPING_EXPOSURE);
    }
    if (__uniformToneMappedLoc != undefined) {
      shader_set_uniform_f(__uniformToneMappedLoc, toneMapped ? 1.0 : 0.0);
    }

    // Set has maps uniforms
    if (__uniformHasMapLoc != undefined) shader_set_uniform_f(__uniformHasMapLoc, __hasMapsFlags.map);
    if (__uniformHasAlphaMapLoc != undefined) shader_set_uniform_f(__uniformHasAlphaMapLoc, __hasMapsFlags.alphaMap);
    if (__uniformHasOrmMapLoc != undefined) shader_set_uniform_f(__uniformHasOrmMapLoc, __hasMapsFlags.ormMap);
    if (__uniformHasNormalMapLoc != undefined) shader_set_uniform_f(__uniformHasNormalMapLoc, __hasMapsFlags.normalMap);
    if (__uniformHasEmissiveMapLoc != undefined) shader_set_uniform_f(__uniformHasEmissiveMapLoc, __hasMapsFlags.emissiveMap);
    if (__uniformHasDisplacementMapLoc != undefined) shader_set_uniform_f(__uniformHasDisplacementMapLoc, __hasMapsFlags.displacementMap);

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
    if (mesh[$ "isSprite"]) {
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
