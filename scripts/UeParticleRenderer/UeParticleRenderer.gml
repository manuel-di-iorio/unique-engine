/**
 * @description Efficient renderer for particle systems using vertex batching and a dedicated shader.
 * CLEAN VERSION: Shadow logic commented out for testing.
 */
function UeParticleRenderer(_shaders = {}) constructor {
    // Vertex format for particles
    vertex_format_begin();
    vertex_format_add_position_3d(); // x, y, z (center position)
    vertex_format_add_colour();      // color (rgba)
    vertex_format_add_texcoord();    // uv (local 0..2)
    vertex_format_add_custom(vertex_type_float3, vertex_usage_normal); // size, rotation, 0
    self.format = vertex_format_end();

    self.vbuffer = vertex_create_buffer();
    
    // Configurable shaders
    var _mainShader = _shaders[$ "main"] ?? asset_get_index("sh_ue_particle");
    // var _shadowShader = _shaders[$ "shadow"] ?? asset_get_index("sh_ue_particle_shadow");

    self.shader = _mainShader;
    // self.shaderShadow = _shadowShader;
    
    // Cached uniform locations (Main Shader)
    if (self.shader != -1) {
        self.uRight = shader_get_uniform(self.shader, "u_ueCameraRight");
        self.uUp    = shader_get_uniform(self.shader, "u_ueCameraUp");
        self.uUVRegion = shader_get_uniform(self.shader, "u_ueUVRegion");
        self.uSoftFactor = shader_get_uniform(self.shader, "u_ueSoftFactor");
        self.uDepthTex = shader_get_sampler_index(self.shader, "u_ueDepthTexture");
        self.uNear = shader_get_uniform(self.shader, "u_ueNear");
        self.uFar = shader_get_uniform(self.shader, "u_ueFar");
        // self.uReceiveShadow = shader_get_uniform(self.shader, "u_ueReceiveShadow");
        // self.uShadowMap = shader_get_sampler_index(self.shader, "s_dirShadowMap");
        // self.uShadowMatrix = shader_get_uniform(self.shader, "u_ueDirShadowMatrix");
    }

    /*
    // Cached uniform locations (Shadow Shader)
    if (self.shaderShadow != -1) {
        self.uRightShadow = shader_get_uniform(self.shaderShadow, "u_ueCameraRight");
        self.uUpShadow    = shader_get_uniform(self.shaderShadow, "u_ueCameraUp");
    }
    */

    /**
     * Renders a particle system.
     */
    function render(system, camera, texture = -1, depthTexture = undefined, shadowConfig = undefined, isShadowPass = false) {
        gml_pragma("forceinline");
        
        // Skip rendering if shadow pass (shadows disabled for now)
        // if (isShadowPass) return;
        
        var pool = system.pool;
        var count = pool.aliveCount;
        if (count == 0 || self.shader == -1) return;

        // --- Billboarding Vectors ---
        var rx, ry, rz, ux, uy, uz;
        if (variable_struct_exists(camera, "matrixWorld")) {
            var m = camera.matrixWorld;
            rx = m[0]; ry = m[1]; rz = m[2]; 
            ux = m[4]; uy = m[5]; uz = m[6]; 
        } else {
            var vm = matrix_get(matrix_view);
            rx = vm[0]; ry = vm[4]; rz = vm[8];
            ux = vm[1]; uy = vm[5]; uz = vm[9];
        }

        // Rebuild Buffer
        vertex_begin(self.vbuffer, self.format);
        var sorted = system.sorted; // && !isShadowPass;
        
        // Fallback arrays for missing attributes
        var fallbackZero = array_create(count, 0);
        var fallbackOne  = array_create(count, 1);
        
        var _posX = pool[$ "posX"] ?? fallbackZero;
        var _posY = pool[$ "posY"] ?? fallbackZero;
        var _posZ = pool[$ "posZ"] ?? fallbackZero;
        var _size = pool[$ "size"] ?? fallbackOne;
        var _rot  = pool[$ "rotation"] ?? fallbackZero;
        var _alpha = pool[$ "alpha"] ?? fallbackOne;
        var _colR = pool[$ "colorR"] ?? fallbackOne;
        var _colG = pool[$ "colorG"] ?? fallbackOne;
        var _colB = pool[$ "colorB"] ?? fallbackOne;
        var _indices = pool.indices;

        for (var n = 0; n < count; n++) {
            var i = sorted ? _indices[n] : n;
            var px = _posX[i], py = _posY[i], pz = _posZ[i];
            var size = _size[i];
            var rot = degtorad(_rot[i]); 
            var col = make_color_rgb(_colR[i] * 255, _colG[i] * 255, _colB[i] * 255);
            var alpha = _alpha[i];

            // Big Triangle
            vertex_position_3d(self.vbuffer, px, py, pz); vertex_color(self.vbuffer, col, alpha); vertex_texcoord(self.vbuffer, 0, 0); vertex_float3(self.vbuffer, size, rot, 0);
            vertex_position_3d(self.vbuffer, px, py, pz); vertex_color(self.vbuffer, col, alpha); vertex_texcoord(self.vbuffer, 2, 0); vertex_float3(self.vbuffer, size, rot, 0);
            vertex_position_3d(self.vbuffer, px, py, pz); vertex_color(self.vbuffer, col, alpha); vertex_texcoord(self.vbuffer, 0, 2); vertex_float3(self.vbuffer, size, rot, 0);
        }
        vertex_end(self.vbuffer);

        // Submit
        shader_set(self.shader);
        
        var tex = texture;
        if (tex == -1) {
            var _sprIdx = asset_get_index("sprparticletest");
            if (_sprIdx > -1) tex = sprite_get_texture(_sprIdx, 0);
        }
        
        // Atlas mapping
        var uvs = texture_get_uvs(tex);
        shader_set_uniform_f(self.uUVRegion, uvs[0], uvs[1], uvs[2]-uvs[0], uvs[3]-uvs[1]);
        
        shader_set_uniform_f(self.uRight, rx, ry, rz);
        shader_set_uniform_f(self.uUp, ux, uy, uz);
        
        // Soft Particles
        // shader_set_uniform_f(self.uSoftFactor, system.softFactor);
        // if (system.softFactor > 0) {
        //     shader_set_uniform_f(self.uNear, camera.near);
        //     shader_set_uniform_f(self.uFar, camera.far);
        //     if (depthTexture != undefined) texture_set_stage(self.uDepthTex, depthTexture);
        // }
        
        /*
        // Shadow Receiving (Disabled)
        if (system.receiveShadow && shadowConfig != undefined) {
            shader_set_uniform_f(self.uReceiveShadow, 1.0);
            texture_set_stage(self.uShadowMap, shadowConfig.texture);
            shader_set_uniform_f_array(self.uShadowMatrix, shadowConfig.matrix);
        } else {
            shader_set_uniform_f(self.uReceiveShadow, 0.0);
        }
        */
        
        var _prevBlend = gpu_get_blendenable();
        var _prevCull = gpu_get_cullmode();
        var _prevZWrite = gpu_get_zwriteenable();
        var _prevZTest = gpu_get_ztestenable();
        
        gpu_set_blendenable(true);
        gpu_set_blendmode(bm_normal);
        gpu_set_cullmode(cull_noculling);
        gpu_set_ztestenable(true); 
        gpu_set_zwriteenable(false);

        vertex_submit(self.vbuffer, pr_trianglelist, tex);
        
        gpu_set_blendenable(_prevBlend);
        gpu_set_cullmode(_prevCull);
        gpu_set_zwriteenable(_prevZWrite);
        gpu_set_ztestenable(_prevZTest);
        
        shader_reset();
    }

    function dispose() {
        vertex_delete_buffer(self.vbuffer);
    }
}
