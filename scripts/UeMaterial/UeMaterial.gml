function UeMaterial(data = {}) constructor {
    isMaterial = true;
    id = global.UE_OBJECT_ID++;
    type = "Material";
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
    userData = {};
    
    // Blending
    blending = data[$ "blending"] ?? false;
    blendEquation = data[$ "blendEquation"] ?? bm_eq_add;
    blendEquationAlpha = data[$ "blendEquationAlpha "] ?? bm_eq_add;
    blendSrc = data[$ "blendSrc"] ?? bm_src_alpha;
    blendDst = data[$ "blendDst"] ?? bm_inv_src_alpha;
    blendSrcAlpha = data[$ "blendSrcAlpha"] ?? bm_one;
    blendDstAlpha = data[$ "blendDstAlpha"] ?? bm_inv_src_alpha; 

    // Shader
    shader = data[$ "shader"] ?? sh_ue_standard;
    
    // Uniforms
    uniforms = data[$ "uniforms"] ?? {};
    __uniformsCached = [];
    __uniformsCachedCount = 0;
    __texturesCached = []; 
    __texturesCachedCount = 0;
     
    __uniformModelPositionLoc = undefined;
    __uniformLightSpaceMatrixLoc = undefined;
    __uniformShadowEnabledLoc = undefined;
    __uniformReceiveShadowLoc = undefined;
    __samplerShadowMapIdx = undefined;
    
    // Light uniforms
    lights = data[$ "lights"] ?? 2;
    __uniformLightsAmbientLoc = undefined;
    __uniformLightsDir = [];
    __uniformLightsPos = [];
    
    // Shadow quality
    shadowQuality = data[$ "shadowQuality"] ?? UE_SHADOW_QUALITY.HIGH;
    __uniformShadowQualityLoc = undefined;
    
    // Textures
    textures = {
       map: data[$ "map"] ?? global.UE_TEXTURE_MAP.clone(),
    };
    if (data[$ "normalMap"] != undefined) textures.normalMap = data[$ "normalMap"];
    if (data[$ "roughnessMap"] != undefined) textures.roughnessMap = data[$ "roughnessMap"];
    if (data[$ "metalnessMap"] != undefined) textures.metalnessMap = data[$ "metalnessMap"];
    if (data[$ "aoMap"] != undefined) textures.aoMap = data[$ "aoMap"];
    if (data[$ "emissiveMap"] != undefined) textures.emissiveMap = data[$ "emissiveMap"];
        
    // Cache uniform/sampler locations
    function build() { 
        gml_pragma("forceinline");
        if (shader == undefined) return self;
            
        // Cache the engine uniforms
        __uniformModelPositionLoc = shader_get_uniform(shader, "u_ueModelPosition");
        __uniformLightsAmbientLoc = shader_get_uniform(shader, "u_ueAmbient");
        __uniformEmissiveIntensityLoc = shader_get_uniform(shader, "u_ueEmissiveIntensity");
        
        // Cache shadow uniforms
        __uniformLightSpaceMatrixLoc = shader_get_uniform(shader, "u_ueLightSpaceMatrix");
        __uniformShadowEnabledLoc = shader_get_uniform(shader, "u_ueShadowEnabled");
        __uniformReceiveShadowLoc = shader_get_uniform(shader, "u_ueReceiveShadow");
        __uniformShadowQualityLoc = shader_get_uniform(shader, "u_ueShadowQuality");
        __uniformShadowTexelSizeLoc = shader_get_uniform(shader, "u_ueShadowTexelSize");
        __samplerShadowMapIdx = shader_get_sampler_index(shader, "s_shadowMap");
        
        __uniformLightsDir = array_create(lights);
        __uniformLightsPos = array_create(lights);
        
        for (var l=0; l<lights; l++) { 
            __uniformLightsDir[l] = [
                shader_get_uniform(shader, $"u_ueDirLightDir{l}"),
                shader_get_uniform(shader, $"u_ueDirLightColor{l}"),
                shader_get_uniform(shader, $"u_ueDirLightIntensity{l}"),
            ];
            
            __uniformLightsPos[l] = [
                shader_get_uniform(shader, $"u_uePointLightPosition{l}"),
                shader_get_uniform(shader, $"u_uePointLightColor{l}"),
                shader_get_uniform(shader, $"u_uePointLightRange{l}"),
                shader_get_uniform(shader, $"u_uePointLightIntensity{l}"),
            ];
        }
            
        // Cache the uniforms
        var uniformNames = variable_struct_get_names(uniforms);
        __uniformsCachedCount = array_length(uniformNames);
        __uniformCached = array_create(__uniformsCachedCount);
        
        for (var u=0; u<__uniformsCachedCount; u++) {
            var uniformName = uniformNames[u];
            var uniformLoc = shader_get_uniform(shader, $"u_{uniformName}");
            
            __uniformCached[u] = [
                uniforms[$ uniformName],
                shader_get_uniform(shader, $"u_{uniformName}")
            ];
        }
        
        // Cache the textures        
        var textureNames = variable_struct_get_names(textures);
        var textureNamesCount = array_length(textureNames);
    
        __texturesCached = array_create(textureNamesCount, undefined);
        __texturesCachedCount = 0;
        
        for (var t=0; t<textureNamesCount; t++) {
            var textureName = textureNames[t];
            var texture = textures[$ textureName];
            if (texture == undefined || texture.sprite == undefined) continue;
            __texturesCached[t] = [
                texture,
                shader_get_sampler_index(shader, $"s_{textureName}")
            ];
            __texturesCachedCount++;
        }
        
        return self;
    }
    
    function __setLightsUniforms() {
        gml_pragma("forceinline");
        if (!lights) return;
            
        var lightState = global.UE_RENDERER_LIGHT_STATE;
        var uniformsCache = global.UE_DUMMY_ARRAY3;
        
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
                var lightDirection = light.getDirection();
                
                uniformsCache[0] = lightDirection.x;
                uniformsCache[1] = lightDirection.y;
                uniformsCache[2] = lightDirection.z;
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
        for(var i=0; i<directionalCount; i++) {
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
             
             shader_set_uniform_matrix_array(__uniformLightSpaceMatrixLoc, shadowLight.shadow.lightSpaceMatrix.data);
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
                
                uniformsCache[0] = light.position.x;
                uniformsCache[1] = light.position.y;
                uniformsCache[2] = light.position.z;
                shader_set_uniform_f_array(lightLoc[0], uniformsCache);
                
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
        
        // Reset emissive uniforms
        shader_set_uniform_f(__uniformEmissiveIntensityLoc, 0);
   
        // Apply the uniforms on the shader
        for (var u=0; u<__uniformsCachedCount; u++) {
            var uniformCached = __uniformCached[u];
            var uniform = uniformCached[0];
            
            var val = uniform[$ "value"];
            if (val == undefined) continue;
        
            var loc = uniformCached[1];
            switch (uniform.type) {
                case UE_UNIFORM_TYPE.FLOAT: shader_set_uniform_f(loc, val); break;
                case UE_UNIFORM_TYPE.VEC2: shader_set_uniform_f(loc, val[0], val[1]); break;
                case UE_UNIFORM_TYPE.VEC3: shader_set_uniform_f(loc, val[0], val[1], val[2]); break;
                case UE_UNIFORM_TYPE.VEC4: shader_set_uniform_f(loc, val[0], val[1], val[2], val[3]); break;
                case UE_UNIFORM_TYPE.MAT4: shader_set_uniform_matrix(loc); break;
                case UE_UNIFORM_TYPE.ARRAY: shader_set_uniform_f_array(loc, val); break;
                case UE_UNIFORM_TYPE.BUFFER: shader_set_uniform_f_buffer(loc, val, uniform.offset, uniform.count); break;
            }
        }
        
        // Set the texture samplers
        for (var t=0; t<__texturesCachedCount; t++) {
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
        if (mesh[$ "isSprite"] != undefined) {
            var uniformsCache = global.UE_DUMMY_ARRAY3;
            var meshPosition = mesh.position;
            uniformsCache[0] = meshPosition.x;
            uniformsCache[1] = meshPosition.y;
            uniformsCache[2] = meshPosition.z;
            shader_set_uniform_f_array(__uniformModelPositionLoc, uniformsCache);
        }
        
        // Set receive shadow uniform
        if (mesh.receiveShadow) {
            shader_set_uniform_f(__uniformReceiveShadowLoc, 1);
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
        uniforms[$ name] = value;
        return self;
    }
    
    /**
     * Set the texture given the name
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
            textures: ueStructMap(textures, function(name, texture) {
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
        uniforms = data[$ "uniforms"];
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
                        if (textureUUID == global.UE_TEXTURE_MAP.uuid) {
                            textures[$ textureName] = global.UE_TEXTURE_MAP;
                        } else if (textureUUID == global.UE_TEXTURE_EMISSIVE.uuid) {
                            textures[$ textureName] = global.UE_TEXTURE_EMISSIVE;
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
