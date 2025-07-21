function UeMaterial(data = {}) constructor {
    isMaterial = true;
    type = "Material";
    uuid = ueUuid();
    name = data[$ "name"] ?? "";
    transparent = data[$ "transparent"] ?? false;
    opacity = data[$ "opacity"] ?? 1;
    visible = data[$ "visible"] ?? true; // @MissingDoc
    side = data[$ "side"] ?? cull_counterclockwise;
    depthTest = data[$ "depthTest"] ?? true;
    depthWrite = data[$ "depthWrite"] ?? true;
    depthFunc = data[$ "depthFunc"] ?? cmpfunc_lessequal;
    forceSinglePass = data[$ "forceSinglePass"] ?? false;
    alphaTest = data[$ "alphaTest"] ?? 0;
    colorWrite = data[$ "colorWrite"] ?? true;
    wireframe = data[$ "wireframe"] ?? false;
    userData = {}; // @MissingDoc
    
    // Blending
    blending = data[$ "blending"] ?? transparent;
    blendEquation = data[$ "blendEquation"] ?? bm_eq_add;
    blendEquationAlpha = data[$ "blendEquationAlpha "] ?? 1;
    blendSrc = data[$ "blendSrc"] ?? bm_src_alpha;
    blendDst = data[$ "blendDst"] ?? bm_inv_src_alpha;
    blendSrcAlpha = data[$ "blendSrcAlpha"] ?? 1;
    blendDstAlpha = data[$ "blendDstAlpha"] ?? 1; 

    // Shader
    shader = data[$ "shader"] ?? sh_ue_standard;
    
    // Uniforms
    uniforms = data[$ "uniforms"] ?? {};
    _uniform_handlers = {};
    _sampler_handlers = {};
    
    uniforms[$ "ueModelPosition"] = { type: UE_UNIFORM_TYPE.ARRAY };
    uniforms[$ "ueModelScale"] = { type: UE_UNIFORM_TYPE.ARRAY };
    uniforms[$ "ueCameraPosition"] = { type: UE_UNIFORM_TYPE.ARRAY };
    
    // Light uniforms
    lights = data[$ "lights"] ?? 2;
    if (lights) {
        uniforms[$ "ueAmbient"] = { type: UE_UNIFORM_TYPE.ARRAY };
        
        for (var i=0; i<lights; i++) {
            uniforms[$ $"ueDirLightDir{i}"] = { type: UE_UNIFORM_TYPE.ARRAY };
            uniforms[$ $"ueDirLightColor{i}"] = { type: UE_UNIFORM_TYPE.ARRAY };
            uniforms[$ $"ueDirLightIntensity{i}"] = { type: UE_UNIFORM_TYPE.FLOAT };
            
            uniforms[$ $"uePointLightPosition{i}"] = { type: UE_UNIFORM_TYPE.ARRAY };
            uniforms[$ $"uePointLightRange{i}"] = { type: UE_UNIFORM_TYPE.FLOAT };
            uniforms[$ $"uePointLightColor{i}"] = { type: UE_UNIFORM_TYPE.ARRAY };
            uniforms[$ $"uePointLightIntensity{i}"] = { type: UE_UNIFORM_TYPE.FLOAT };
        }
    }
  
    // Textures
    textures = {
       map: data[$ "map"] ?? global.UE_DEFAULT_TEXTURE
    };
    if (data[$ "normalMap"] != undefined) textures.normalMap = data[$ "normalMap"];
    if (data[$ "roughnessMap"] != undefined) textures.roughnessMap = data[$ "roughnessMap"];
    if (data[$ "metalnessMap"] != undefined) textures.metalnessMap = data[$ "metalnessMap"];
    if (data[$ "aoMap"] != undefined) textures.aoMap = data[$ "aoMap"];
    if (data[$ "emissiveMap"] != undefined) textures.emissiveMap = data[$ "emissiveMap"];
        
    
    function build() { 
        if (shader == undefined) return self;
            
        _uniform_handlers = {};
        _sampler_handlers = {};
        
        // Cache uniform locations
        struct_foreach(uniforms, function(name, uniform) {
            _uniform_handlers[$ name] = shader_get_uniform(shader, $"u_{name}"); 
        });
    
        // Cache sampler texture stages
        struct_foreach(textures, function(name, texture) {
            if (texture == undefined) return;
            _sampler_handlers[$ name] = shader_get_sampler_index(shader, $"s_{name}");
        });
        
        return self;
    }
    
    function __setGpuState(renderState) {
        var gpuState = global.UE_MATERIAL_GPU_STATE;
        
        var _side = renderState[$ "side"] ?? side;
        if (gpuState[UE_MATERIAL_GPU_STATE_ENUM.SIDE] != _side) {
            gpuState[UE_MATERIAL_GPU_STATE_ENUM.SIDE] = _side;
            gpu_set_cullmode(_side);
        }
        
        if (gpuState[UE_MATERIAL_GPU_STATE_ENUM.DEPTH_TEST] != depthTest) { 
            gpuState[UE_MATERIAL_GPU_STATE_ENUM.DEPTH_TEST] = depthTest;
            gpu_set_ztestenable(depthTest);
        }
        
        if (global.UE_MATERIAL_GPU_STATE[UE_MATERIAL_GPU_STATE_ENUM.DEPTH_WRITE] != depthWrite) {
            global.UE_MATERIAL_GPU_STATE[UE_MATERIAL_GPU_STATE_ENUM.DEPTH_WRITE] = depthWrite;
            gpu_set_zwriteenable(depthWrite);
        }
        
        if (gpuState[UE_MATERIAL_GPU_STATE_ENUM.DEPTH_FUNC] != depthFunc) {
            gpuState[UE_MATERIAL_GPU_STATE_ENUM.DEPTH_FUNC] = depthFunc;
            gpu_set_zfunc(depthFunc);
        }
        
        if (gpuState[UE_MATERIAL_GPU_STATE_ENUM.TRANSPARENT] != transparent) {
            gpuState[UE_MATERIAL_GPU_STATE_ENUM.TRANSPARENT] = transparent;
            gpu_set_alphatestenable(transparent);
        }
        
        if (gpuState[UE_MATERIAL_GPU_STATE_ENUM.ALPHA_TEST] != alphaTest) {
            gpuState[UE_MATERIAL_GPU_STATE_ENUM.ALPHA_TEST] = alphaTest;
            gpu_set_alphatestref(alphaTest);
        }
        
        if (gpuState[UE_MATERIAL_GPU_STATE_ENUM.COLOR_WRITE] != colorWrite) {
            gpuState[UE_MATERIAL_GPU_STATE_ENUM.COLOR_WRITE] = colorWrite;
            gpu_set_colorwriteenable(colorWrite, colorWrite, colorWrite, colorWrite);
        }
        
        if (gpuState[UE_MATERIAL_GPU_STATE_ENUM.BLENDING] != blending) {
            gpuState[UE_MATERIAL_GPU_STATE_ENUM.BLENDING] = blending;
            gpu_set_blendenable(blending);
        }

        if (gpuState[UE_MATERIAL_GPU_STATE_ENUM.BLEND_EQUATION] != blendEquation || 
            gpuState[UE_MATERIAL_GPU_STATE_ENUM.BLEND_EQUATION_ALPHA] != blendEquationAlpha) {
                
            gpuState[UE_MATERIAL_GPU_STATE_ENUM.BLEND_EQUATION] = blendEquation;
            gpuState[UE_MATERIAL_GPU_STATE_ENUM.BLEND_EQUATION_ALPHA] = blendEquationAlpha;
            gpu_set_blendequation_sepalpha(blendEquation, blendEquationAlpha);
        }

        if (gpuState[UE_MATERIAL_GPU_STATE_ENUM.BLEND_SRC] != blendSrc ||
            gpuState[UE_MATERIAL_GPU_STATE_ENUM.BLEND_DST] != blendDst ||
            gpuState[UE_MATERIAL_GPU_STATE_ENUM.BLEND_SRC_ALPHA] != blendSrcAlpha ||
            gpuState[UE_MATERIAL_GPU_STATE_ENUM.BLEND_DST_ALPHA] != blendDstAlpha ) {
            
            gpuState[UE_MATERIAL_GPU_STATE_ENUM.BLEND_SRC] = blendSrc;
            gpuState[UE_MATERIAL_GPU_STATE_ENUM.BLEND_DST] = blendDst;
            gpuState[UE_MATERIAL_GPU_STATE_ENUM.BLEND_SRC_ALPHA] = blendSrcAlpha;
            gpuState[UE_MATERIAL_GPU_STATE_ENUM.BLEND_DST_ALPHA] = blendDstAlpha;
            gpu_set_blendmode_ext_sepalpha(blendSrc, blendDst, blendSrcAlpha, blendDstAlpha);
        }
    }
    
    function __setMainUniforms(renderState, mesh) {
        var camera = renderState.camera; 
        var uniformsCache = global.UE_MATERIAL_UNIFORMS_SET_CACHE;
        
        uniformsCache[0] = mesh.position.x;
        uniformsCache[1] = mesh.position.y;
        uniformsCache[2] = mesh.position.z;
        shader_set_uniform_f_array(_uniform_handlers[$ "ueModelPosition"], uniformsCache);
        
        uniformsCache[0] = mesh.scale.x;
        uniformsCache[1] = mesh.scale.y;
        uniformsCache[2] = mesh.scale.z;
        shader_set_uniform_f_array(_uniform_handlers[$ "ueModelScale"], uniformsCache);
        
        uniformsCache[0] = camera.position.x;
        uniformsCache[1] = camera.position.y;
        uniformsCache[2] = camera.position.z;
        shader_set_uniform_f_array(_uniform_handlers[$ "ueCameraPosition"], uniformsCache);
    }
    
    function __setLightsUniforms() {
        if (!lights) return;
            
        var lightState = global.UE_RENDERER_LIGHT_STATE;
        var uniformsCache = global.UE_MATERIAL_UNIFORMS_SET_CACHE;
        
        var directionalState = lightState[UE_RENDERER_LIGHT_STATE_ENUM.DIRECTIONAL];
        var directionalCount = lightState[UE_RENDERER_LIGHT_STATE_ENUM.DIRECTIONAL_COUNT];
        var pointLightState = lightState[UE_RENDERER_LIGHT_STATE_ENUM.POINT_LIGHT];
        var pointLightCount = lightState[UE_RENDERER_LIGHT_STATE_ENUM.POINT_LIGHT_COUNT];

        shader_set_uniform_f_array(_uniform_handlers[$ "ueAmbient"], lightState[UE_RENDERER_LIGHT_STATE_ENUM.AMBIENT]);
        
        // Set directional lights
        for (var i = 0; i < lights; i++) {
            if (i < directionalCount) {
                var light = directionalState[i];
                var lightTarget = light.target;
                
                uniformsCache[0] = lightTarget.x;
                uniformsCache[1] = lightTarget.y;
                uniformsCache[2] = lightTarget.z;
                shader_set_uniform_f_array(_uniform_handlers[$ $"ueDirLightDir{i}"], uniformsCache);
                
                shader_set_uniform_f_array(_uniform_handlers[$ $"ueDirLightColor{i}"], light.color);
                shader_set_uniform_f(_uniform_handlers[$ $"ueDirLightIntensity{i}"], light.intensity);
            } else {
                // Reset unused light slots
                shader_set_uniform_f(_uniform_handlers[$ $"ueDirLightIntensity{i}"], 0);
            }
        }
        
        // Set point lights
        var lightColor;
        for (var i = 0; i < lights; i++) {
            if (i < pointLightCount) {
                var light = pointLightState[i];
                
                uniformsCache[0] = light.position.x;
                uniformsCache[1] = light.position.y;
                uniformsCache[2] = light.position.z;
                shader_set_uniform_f_array(_uniform_handlers[$ $"uePointLightPosition{i}"], uniformsCache);
                
                shader_set_uniform_f_array(_uniform_handlers[$ $"uePointLightColor{i}"], light.color);
                shader_set_uniform_f(_uniform_handlers[$ $"uePointLightRange{i}"], light.range);
                shader_set_uniform_f(_uniform_handlers[$ $"uePointLightIntensity{i}"], light.intensity);
            } else {
                // Reset unused light slots
                shader_set_uniform_f(_uniform_handlers[$ $"uePointLightIntensity{i}"], 0);
            }
        }
    }
     
    /// Apply material before drawing
    function use(renderState, mesh) {
        if (!visible) return self;
            
        __setGpuState(renderState);
        
        if (wireframe || shader == undefined || !shader_is_compiled(shader)) { 
            shader_reset();
            return self;
        } 

        shader_set(shader); 
        __setMainUniforms(renderState, mesh); 
        __setLightsUniforms();
   
        // Set the custom uniforms
        var uniformNames = variable_struct_get_names(uniforms);
        for (var u=0, ul = array_length(uniformNames); u<ul; u++) {
            var uniformName = uniformNames[u];
            var uniform = uniforms[$ uniformName];
            var loc = _uniform_handlers[$ uniformName];
            var val = uniform[$ "value"];
            if (val == undefined) continue;
        
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
        var texturesNames = variable_struct_get_names(textures);
        for (var t=0, tl = array_length(texturesNames); t<tl; t++) {
            var textureName = texturesNames[t];
            var texture = textures[$ textureName];
            if (texture == undefined || texture.image == undefined) continue;
            texture.use(_sampler_handlers[$ textureName]); 
        }
        
        return self;
    }
    
    function clone() {
        return variable_clone(self);
    }
    
    // @MissingDoc
    function toJSON() {
        return {
            uniforms,
            textures: ueStructMap(textures, function(name, texture) { return texture.uuid }),
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
    
    /** Internal export methods */
    function _compileData(data) {
        return { payload: toJSON() };
    }
    
    build();
}