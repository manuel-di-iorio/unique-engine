function Renderer(data = {}): Object3D(data) constructor {
    gpu_set_ztestenable(true);
    gpu_set_zwriteenable(true);
    gpu_set_texrepeat(true);
	gpu_set_alphatestenable(data[$ "alphatestenable"] ?? true);
	gpu_set_tex_filter(true);
	gpu_set_tex_mip_enable(true);
    gpu_set_cullmode(data[$ "cullmode"] ?? cull_noculling);
    
    /// Render the scene
    function render(scene) {
        draw_set_color(c_white);
        var lightState = _buildLightState(scene.lights);
        
        for (var i = 0, len = array_length(scene.children); i < len; i++) {
            var child = scene.children[i];
            child.render(lightState);
        }
        
        matrix_set(matrix_world, matrix_build_identity()); 
        return self;
    }
    
    function _buildLightState(lights) {
        var state = {
            ambient: [0, 0, 0],
            directional: [],
            point: []
        };
        
        for (var i = 0, len = array_length(lights); i < len; i++) {
            var l = lights[i];
            if (!l.enabled) continue;
                
            switch (l.lightType) {
                case "AmbientLight":
                    state.ambient[0] += l.color[0] * l.intensity;
                    state.ambient[1] += l.color[1] * l.intensity;
                    state.ambient[2] += l.color[2] * l.intensity;
                    break;
    
                case "DirectionalLight":
                    array_push(state.directional, l);
                    break;
    
                case "PointLight":
                    array_push(state.point, l);
                    break;
            }
        }
        
        return state;
    }
}