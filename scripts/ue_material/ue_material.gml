function Material(data = {}): Object3D(data) constructor {
    color = data[$ "color"] ?? c_white;
    transparent = data[$ "transparent"] ?? false;
    opacity = data[$ "opacity"] ?? 1;
    side = data[$ "side"] ?? cull_counterclockwise;
    depthTest = data[$ "depthTest"] ?? true;
    depthWrite = data[$ "depthWrite"] ?? true;
    forceSinglePass = data[$ "forceSinglePass"] ?? false; // @todo: not supported for now
    alphaTest = data[$ "alphaTest"] ?? 0;

    // Shader
    shader = data[$ "shader"] ?? ue_shader_light;
    
    // Uniforms
    uniforms = data[$ "uniforms"] ?? {};
    _uniform_handlers = {};
    _sampler_handlers = {};
    
    uniforms[$ "ueModelPosition"] = { type: "array" };
    uniforms[$ "ueCameraPosition"] = { type: "array" };
    
    // Light uniforms
    lights = data[$ "lights"] ?? 1;
    if (lights) {
        uniforms[$ "ueAmbient"] = { type: "array" };
        
        for (var i=0; i<lights; i++) {
            uniforms[$ $"ueDirLightDir{i}"] = { type: "array" };
            uniforms[$ $"ueDirLightColor{i}"] = { type: "array" };
            uniforms[$ $"ueDirLightIntensity{i}"] = { type: "float" };
            
            uniforms[$ $"uePointLightPosition{i}"] = { type: "array" };
            uniforms[$ $"uePointLightRange{i}"] = { type: "float" };
            uniforms[$ $"uePointLightColor{i}"] = { type: "array" };
            uniforms[$ $"uePointLightIntensity{i}"] = { type: "float" };
        }
    }
    
    // Textures
    textures = {
        map: data[$ "map"] ?? undefined,
        normalMap: data[$ "normalMap"] ?? undefined,
        roughnessMap: data[$ "roughnessMap"] ?? undefined,
        metalnessMap: data[$ "metalnessMap"] ?? undefined,
        aoMap: data[$ "aoMap"] ?? undefined,
        emissiveMap: data[$ "emissiveMap"] ?? undefined,
    };
        
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
        gpu_set_ztestenable(true); // Enable depth testing
        gpu_set_zwriteenable(true); // Enable writing to the depth buffer
        gpu_set_alphatestenable(transparent);
        gpu_set_alphatestref(alphaTest);
        
        var lightState = renderState.lightState;
        var camera = renderState.camera;
        
        if (shader == undefined || !shader_is_compiled(shader)) return self;
        shader_set(shader);
        
        shader_set_uniform_f_array(_uniform_handlers[$ "ueModelPosition"], [mesh.position.x, mesh.position.y, mesh.position.z]);
        shader_set_uniform_f_array(_uniform_handlers[$ "ueCameraPosition"], [camera.position.x, camera.position.y, camera.position.z]);
        
        // Set the light uniform values
        if (lights) { 
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
                case "float": shader_set_uniform_f(loc, val); break;
                case "vec2": shader_set_uniform_f(loc, val[0], val[1]); break;
                case "vec3": shader_set_uniform_f(loc, val[0], val[1], val[2]); break;
                case "vec4": shader_set_uniform_f(loc, val[0], val[1], val[2], val[3]); break;
                case "mat4": shader_set_uniform_matrix(loc); break;
                case "array": shader_set_uniform_f_array(loc, val); break;
                case "buffer": shader_set_uniform_f_buffer(loc, val, uniform.offset, uniform.count); break;
            }
        });
        
        // Set the texture samplers
        struct_foreach(textures, function(name, texture) {
            if (texture == undefined) return;
            texture_set_stage(_sampler_handlers[$ name], texture);
        });
        
        return self;
    }
    
    build();
}