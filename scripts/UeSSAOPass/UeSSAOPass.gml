function UeSSAOPass(data = {}) : UePass() constructor {
    self.name = "SSAOPass";
    
    // SSAO Parameters
    self.radius = data[$ "radius"] ?? 0.5;
    self.bias = data[$ "bias"] ?? 0.025;
    self.power = data[$ "power"] ?? 1.0;
    self.intensity = data[$ "intensity"] ?? 1.0;
    
    // Internal surfaces
    self.surfaceNormals = undefined;
    self.surfaceAO = undefined;
    self.surfaceBlur = undefined;
    
    // Shaders
    self.shaderNormals = sh_ue_normals_view; // We'll need view-space normals
    self.shaderSSAO = sh_ue_ssao;
    self.shaderBlur = sh_ue_ssao_blur;
    
    // Kernel and Noise
    self.kernelSize = 32; // @todo also test 16 or 12 for performance
    self.kernel = array_create(self.kernelSize * 3);
    self.__generateKernel();
    
    self.noiseSize = 4;
    self.noiseTexture = undefined;
    self.__generateNoiseTexture();

    static __generateKernel = function() {
        for (var i = 0; i < self.kernelSize; i++) {
            var _sample = [
                random_range(-1, 1),
                random_range(-1, 1),
                random_range(0, 1) // Hemisphere
            ];
            // Normalize
            var _len = sqrt(_sample[0]*_sample[0] + _sample[1]*_sample[1] + _sample[2]*_sample[2]);
            _sample[0] /= _len;
            _sample[1] /= _len;
            _sample[2] /= _len;
            
            // Scale samples so they're more clustered near origin
            var _scale = i / self.kernelSize;
            _scale = lerp(0.1, 1.0, _scale * _scale);
            _sample[0] *= _scale;
            _sample[1] *= _scale;
            _sample[2] *= _scale;
            
            self.kernel[i * 3 + 0] = _sample[0];
            self.kernel[i * 3 + 1] = _sample[1];
            self.kernel[i * 3 + 2] = _sample[2];
        }
    }
    
    static __generateNoiseTexture = function() {
        var _size = self.noiseSize;
        var _surf = surface_create(_size, _size);
        surface_set_target(_surf);
        draw_clear_alpha(c_black, 0);
        for (var yy = 0; yy < _size; yy++) {
            for (var xx = 0; xx < _size; xx++) {
                var _vx = random_range(-1, 1);
                var _vy = random_range(-1, 1);
                var _c = make_color_rgb((_vx * 0.5 + 0.5) * 255, (_vy * 0.5 + 0.5) * 255, 0);
                draw_point_color(xx, yy, _c);
            }
        }
        surface_reset_target();
        self.noiseTexture = sprite_create_from_surface(_surf, 0, 0, _size, _size, false, false, 0, 0);
        surface_free(_surf);
    }

    function render(renderer, writeTarget, readTarget) {
        var _width = readTarget.width;
        var _height = readTarget.height;
        
        // 1. Ensure surfaces exist
        if (self.surfaceNormals == undefined || !surface_exists(self.surfaceNormals)) {
            self.surfaceNormals = surface_create(_width, _height);
        }
        if (self.surfaceAO == undefined || !surface_exists(self.surfaceAO)) {
            self.surfaceAO = surface_create(_width, _height); // Could be half res
        }
        if (self.surfaceBlur == undefined || !surface_exists(self.surfaceBlur)) {
            self.surfaceBlur = surface_create(_width, _height);
        }
        
        var _camera = global.UE_RENDERER_ACTIVE_CAMERA;
        if (_camera == undefined) return;
        
        // 2. Normal Pass (View Space)
        surface_set_target(self.surfaceNormals);
        draw_clear_alpha(c_black, 0);
        draw_clear_depth(1);
        
        var _oldOverride = renderer[$ "overrideMaterial"];
        var _normalMat = new UeMaterial({ shader: self.shaderNormals });
        _normalMat.build();
        
        // We need to render the scene again for normals in view space
        // Optimization: only opaque objects
        shader_set(self.shaderNormals);
        // Set view matrix for the shader
        var _uViewMat = shader_get_uniform(self.shaderNormals, "uViewMatrix");
        shader_set_uniform_matrix_array(_uViewMat, _camera.matrixWorldInverse);
        
        // Render opaque queue
        var _queue = renderer.__queueOpaque;
        for (var i = 0, len = array_length(_queue); i < len; i++) {
            var _obj = _queue[i];
            _obj.render();
        }
        shader_reset();
        surface_reset_target();
        
        // 3. SSAO Pass
        surface_set_target(self.surfaceAO);
        draw_clear(c_white);
        shader_set(self.shaderSSAO);
        
        var _texDepth = surface_get_texture_depth(readTarget.surface);
        var _texNormals = surface_get_texture(self.surfaceNormals);
        var _texNoise = sprite_get_texture(self.noiseTexture, 0);
        
        texture_set_stage(shader_get_sampler_index(self.shaderSSAO, "uDepthTex"), _texDepth);
        texture_set_stage(shader_get_sampler_index(self.shaderSSAO, "uNormalTex"), _texNormals);
        texture_set_stage(shader_get_sampler_index(self.shaderSSAO, "uNoiseTex"), _texNoise);
        
        shader_set_uniform_f_array(shader_get_uniform(self.shaderSSAO, "uKernel"), self.kernel);
        shader_set_uniform_f(shader_get_uniform(self.shaderSSAO, "uRadius"), self.radius);
        shader_set_uniform_f(shader_get_uniform(self.shaderSSAO, "uBias"), self.bias);
        shader_set_uniform_f(shader_get_uniform(self.shaderSSAO, "uPower"), self.power);
        shader_set_uniform_f(shader_get_uniform(self.shaderSSAO, "uNoiseScale"), _width / self.noiseSize, _height / self.noiseSize);
        shader_set_uniform_matrix_array(shader_get_uniform(self.shaderSSAO, "uProjectionMatrix"), _camera.projectionMatrix);
        shader_set_uniform_matrix_array(shader_get_uniform(self.shaderSSAO, "uInvProjectionMatrix"), _camera.projectionMatrixInverse);
        
        draw_surface_stretched(readTarget.surface, 0, 0, _width, _height); // Just to trigger the fragment shader on a quad
        shader_reset();
        surface_reset_target();
        
        // 4. Blur Pass (Bilateral)
        surface_set_target(self.surfaceBlur);
        shader_set(self.shaderBlur);
        var _uTexelSize = shader_get_uniform(self.shaderBlur, "uTexelSize");
        shader_set_uniform_f(_uTexelSize, 1.0/_width, 1.0/_height);
        draw_surface(self.surfaceAO, 0, 0);
        shader_reset();
        surface_reset_target();
        
        // 5. Final Composition
        renderer.setRenderTarget(self.renderToScreen ? undefined : writeTarget);
        var _shaderCombine = sh_ue_ssao_combine;
        shader_set(_shaderCombine);
        texture_set_stage(shader_get_sampler_index(_shaderCombine, "uAOTex"), surface_get_texture(self.surfaceBlur));
        shader_set_uniform_f(shader_get_uniform(_shaderCombine, "uIntensity"), self.intensity);
        draw_surface(readTarget.surface, 0, 0);
        shader_reset();
        
        renderer.setRenderTarget(undefined);
    }
}
