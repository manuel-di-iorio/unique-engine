function UeMaterial(data = {}) constructor {
    isMaterial = true;
    type = "Material";
    uuid = ueUuid();
    name = data[$ "name"] ?? undefined;
    color = data[$ "color"] ?? c_white;
    transparent = data[$ "transparent"] ?? false;
    opacity = data[$ "opacity"] ?? 1;
    side = data[$ "side"] ?? cull_counterclockwise;
    depthTest = data[$ "depthTest"] ?? true;
    depthWrite = data[$ "depthWrite"] ?? true;
    depthFunc = data[$ "depthFunc"] ?? cmpfunc_lessequal;
    forceSinglePass = data[$ "forceSinglePass"] ?? false;
    alphaTest = data[$ "alphaTest"] ?? 0;
    colorWrite = data[$ "colorWrite"] ?? true;
    wireframe = data[$ "wireframe"] ?? false; // @MissingDoc
    
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
    //if (data[$ "map"] != undefined) textures.map = data[$ "map"];
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
     
    /// Apply material before drawing
    function use(renderState, mesh) {
        gpu_set_cullmode(renderState[$ "side"] ?? side); // Set the backface culling mode
        gpu_set_ztestenable(depthTest); // Enable depth testing
        gpu_set_zwriteenable(depthWrite); // Enable writing to the depth buffer
        gpu_set_zfunc(depthFunc);
        gpu_set_alphatestenable(transparent);
        gpu_set_alphatestref(alphaTest);
        gpu_set_colorwriteenable(colorWrite, colorWrite, colorWrite, colorWrite);
        gpu_set_blendenable(blending);
        gpu_set_blendequation_sepalpha(blendEquation, blendEquationAlpha);
        gpu_set_blendmode_ext_sepalpha(blendSrc, blendDst, blendSrcAlpha, blendDstAlpha); 
        
        var lightState = renderState.lightState;
        var camera = renderState.camera;
        
        if (shader == undefined) return self;
        shader_set(shader);
        
        shader_set_uniform_f_array(_uniform_handlers[$ "ueModelPosition"], [mesh.position.x, mesh.position.y, mesh.position.z]);
        shader_set_uniform_f_array(_uniform_handlers[$ "ueModelScale"], [mesh.scale.x, mesh.scale.y, mesh.scale.z]);
        shader_set_uniform_f_array(_uniform_handlers[$ "ueCameraPosition"], [camera.position.x, camera.position.y, camera.position.z]);
        
        // Reset the light uniforms (shaders cache their values)
        for (var i=0, n=lights-1; i<n; i++) {
            shader_set_uniform_f_array(_uniform_handlers[$ $"ueDirLightDir{i}"], [0, 0, 0]);
            shader_set_uniform_f_array(_uniform_handlers[$ $"ueDirLightColor{i}"], [0, 0, 0]);
            shader_set_uniform_f(_uniform_handlers[$ $"ueDirLightIntensity{i}"], 0);
            
            shader_set_uniform_f_array(_uniform_handlers[$ $"uePointLightPosition{i}"], [0, 0, 0]);
            shader_set_uniform_f(_uniform_handlers[$ $"uePointLightRange{i}"], 0);
            shader_set_uniform_f_array(_uniform_handlers[$ $"uePointLightColor{i}"], [0, 0, 0]);
            shader_set_uniform_f(_uniform_handlers[$ $"uePointLightIntensity{i}"], 0);
        }
        
        // Vertex white color in wireframe mode
        if (wireframe) {
            shader_set_uniform_f_array(_uniform_handlers[$ "ueAmbient"], [1, 1, 1]);
        }

        // Set the light uniform values
        if (lights && !wireframe) { 
            shader_set_uniform_f_array(_uniform_handlers[$ "ueAmbient"], lightState.ambient);
            
            var dirLightsNum = array_length(lightState.directional);
            
            if (dirLightsNum) {
                for (var i=0; i<dirLightsNum; i++) {
                    var light = lightState.directional[i];
                    var lightTarget = light.target;
                    shader_set_uniform_f_array(_uniform_handlers[$ $"ueDirLightDir{i}"], [lightTarget.x, lightTarget.y, lightTarget.z]);
                    shader_set_uniform_f_array(_uniform_handlers[$ $"ueDirLightColor{i}"], light.color);
                    shader_set_uniform_f(_uniform_handlers[$ $"ueDirLightIntensity{i}"], light.intensity);
                }
            }
            
            var pointLightsNum = array_length(lightState.point);
            if (pointLightsNum) {
                for (var i=0; i<pointLightsNum; i++) {
                    var light = lightState.point[i];
                    shader_set_uniform_f_array(_uniform_handlers[$ $"uePointLightPosition{i}"], [light.position.x, light.position.y, light.position.z]);
                    shader_set_uniform_f(_uniform_handlers[$ $"uePointLightRange{i}"], light.range);
                    shader_set_uniform_f_array(_uniform_handlers[$ $"uePointLightColor{i}"], light.color);
                    shader_set_uniform_f(_uniform_handlers[$ $"uePointLightIntensity{i}"], light.intensity);
                }
            }
        } 
        
        // Set the custom uniforms
        struct_foreach(uniforms, function(name, uniform) {
            var loc = _uniform_handlers[$ name];
            var val = uniform[$ "value"];
            if (val == undefined) return;
        
            switch (uniform.type) {
                case UE_UNIFORM_TYPE.FLOAT: shader_set_uniform_f(loc, val); break;
                case UE_UNIFORM_TYPE.VEC2: shader_set_uniform_f(loc, val[0], val[1]); break;
                case UE_UNIFORM_TYPE.VEC3: shader_set_uniform_f(loc, val[0], val[1], val[2]); break;
                case UE_UNIFORM_TYPE.VEC4: shader_set_uniform_f(loc, val[0], val[1], val[2], val[3]); break;
                case UE_UNIFORM_TYPE.MAT4: shader_set_uniform_matrix(loc); break;
                case UE_UNIFORM_TYPE.ARRAY: shader_set_uniform_f_array(loc, val); break;
                case UE_UNIFORM_TYPE.BUFFER: shader_set_uniform_f_buffer(loc, val, uniform.offset, uniform.count); break;
            }
        });
        
        // Set the texture samplers
        struct_foreach(textures, function(name, texture) {
            if (texture == undefined || texture.image == undefined) return;
            texture.use(_sampler_handlers[$ name], wireframe); 
        }); 
        
        return self;
    }
    
    function clone() {
        return variable_clone(self);
    }
    
    /** Internal export methods */
    function _compileData(data) {
        var _self = self;
        var payload = {
            uniforms,
            textures: ueStructMap(textures, function(name, texture) { return texture.uuid }),
            shader: shader_get_name(shader),
            color,
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
        
        return { obj: _self, payload };
    }
    
    build();
}