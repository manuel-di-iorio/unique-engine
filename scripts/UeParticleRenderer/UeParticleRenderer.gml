/**
 * @description Efficient renderer for particle systems using vertex batching and a dedicated shader.
 */
function UeParticleRenderer() constructor {
    // Vertex format for particles
    vertex_format_begin();
    vertex_format_add_position_3d(); // x, y, z (center position)
    vertex_format_add_colour();      // color (rgba)
    vertex_format_add_texcoord();    // uv
    vertex_format_add_normal();      // size, rotation, 0
    self.format = vertex_format_end();

    self.vbuffer = vertex_create_buffer();
    self.shader = sh_ue_particle;
    self.shaderShadow = sh_ue_particle_shadow;
    
    // Cached uniform locations (Main Shader)
    self.uRight = shader_get_uniform(self.shader, "u_ueCameraRight");
    self.uUp    = shader_get_uniform(self.shader, "u_ueCameraUp");
    self.uSoftFactor = shader_get_uniform(self.shader, "u_ueSoftFactor");
    self.uDepthTex = shader_get_sampler_index(self.shader, "u_ueDepthTexture");
    self.uNear = shader_get_uniform(self.shader, "u_ueNear");
    self.uFar = shader_get_uniform(self.shader, "u_ueFar");
    self.uReceiveShadow = shader_get_uniform(self.shader, "u_ueReceiveShadow");
    self.uShadowMap = shader_get_sampler_index(self.shader, "s_dirShadowMap");
    self.uShadowMatrix = shader_get_uniform(self.shader, "u_ueDirShadowMatrix");

    // Cached uniform locations (Shadow Shader)
    self.uRightShadow = shader_get_uniform(self.shaderShadow, "u_ueCameraRight");
    self.uUpShadow    = shader_get_uniform(self.shaderShadow, "u_ueCameraUp");

    /**
     * Renders a particle system.
     * @param {Struct} system The UeParticleSystem to render.
     * @param {Struct} camera The camera used for billboarding.
     * @param {Asset.GMTexture} [texture] Optional texture to use.
     * @param {Bool} [isShadowPass] Whether this is a shadow depth pass.
     */
    function render(system, camera, texture = -1, isShadowPass = false) {
        gml_pragma("forceinline");
        
        var pool = system.pool;
        var count = pool.aliveCount;
        if (count == 0) return;

        // Get camera right and up vectors from its world matrix
        var m = camera.matrixWorld;
        var rx = m[0], ry = m[1], rz = m[2];
        var ux = m[4], uy = m[5], uz = m[6];

        // Build vertex buffer
        vertex_begin(self.vbuffer, self.format);
        
        var sorted = system.sorted && !isShadowPass;
        for (var n = 0; n < count; n++) {
            var i = sorted ? pool.indices[n] : n;
            
            var px = pool.posX[i], py = pool.posY[i], pz = pool.posZ[i];
            var size = pool.size[i];
            var rot = degtorad(pool.rotation[i]);
            var col = make_color_rgb(pool.colorR[i] * 255, pool.colorG[i] * 255, pool.colorB[i] * 255);
            var alpha = pool.alpha[i];

            // Corner 1: Top-Left (UV: 0,0)
            vertex_position_3d(self.vbuffer, px, py, pz);
            vertex_color(self.vbuffer, col, alpha);
            vertex_texcoord(self.vbuffer, 0, 0);
            vertex_normal(self.vbuffer, size, rot, 0);

            // Corner 2: Top-Right (UV: 1,0)
            vertex_position_3d(self.vbuffer, px, py, pz);
            vertex_color(self.vbuffer, col, alpha);
            vertex_texcoord(self.vbuffer, 1, 0);
            vertex_normal(self.vbuffer, size, rot, 0);

            // Corner 3: Bottom-Left (UV: 0,1)
            vertex_position_3d(self.vbuffer, px, py, pz);
            vertex_color(self.vbuffer, col, alpha);
            vertex_texcoord(self.vbuffer, 0, 1);
            vertex_normal(self.vbuffer, size, rot, 0);

            // Triangle 2
            // Corner 3: Bottom-Left (UV: 0,1)
            vertex_position_3d(self.vbuffer, px, py, pz);
            vertex_color(self.vbuffer, col, alpha);
            vertex_texcoord(self.vbuffer, 0, 1);
            vertex_normal(self.vbuffer, size, rot, 0);

            // Corner 2: Top-Right (UV: 1,0)
            vertex_position_3d(self.vbuffer, px, py, pz);
            vertex_color(self.vbuffer, col, alpha);
            vertex_texcoord(self.vbuffer, 1, 0);
            vertex_normal(self.vbuffer, size, rot, 0);

            // Corner 4: Bottom-Right (UV: 1,1)
            vertex_position_3d(self.vbuffer, px, py, pz);
            vertex_color(self.vbuffer, col, alpha);
            vertex_texcoord(self.vbuffer, 1, 1);
            vertex_normal(self.vbuffer, size, rot, 0);
        }
        vertex_end(self.vbuffer);

        // Submit to GPU
        var sh = isShadowPass ? self.shaderShadow : self.shader;
        shader_set(sh);
        
        if (isShadowPass) {
            shader_set_uniform_f(self.uRightShadow, rx, ry, rz);
            shader_set_uniform_f(self.uUpShadow, ux, uy, uz);
        } else {
            shader_set_uniform_f(self.uRight, rx, ry, rz);
            shader_set_uniform_f(self.uUp, ux, uy, uz);
            
            // Soft Particles
            shader_set_uniform_f(self.uSoftFactor, system.softFactor);
            if (system.softFactor > 0) {
                shader_set_uniform_f(self.uNear, camera.near);
                shader_set_uniform_f(self.uFar, camera.far);
                
                // Try to get depth texture from the current renderer or global state
                var depthTex = global[$ "UE_RENDERER_DEPTH_TEXTURE"];
                if (depthTex != undefined) {
                    texture_set_stage(self.uDepthTex, depthTex);
                }
            }
            
            // Shadow Receiving
            if (system.receiveShadow) {
                shader_set_uniform_f(self.uReceiveShadow, 1.0);
                // Get directional shadow map from global light state
                var dirLightCount = global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.DIRECTIONAL_COUNT];
                if (dirLightCount > 0) {
                    var dirLight = global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.DIRECTIONAL][0];
                    if (dirLight != undefined && dirLight.castShadow) {
                        texture_set_stage(self.uShadowMap, dirLight.shadow.map.getTexture());
                        shader_set_uniform_f_array(self.uShadowMatrix, dirLight.shadow.lightSpaceMatrix);
                    }
                }
            } else {
                shader_set_uniform_f(self.uReceiveShadow, 0.0);
            }
        }
        
        var tex = (texture == -1) ? sprite_get_texture(sprUiPointLight, 0) : texture;
        vertex_submit(self.vbuffer, pr_trianglelist, tex);
        
        shader_reset();
    }

    /**
     * Dispose of resources.
     */
    function dispose() {
        vertex_delete_buffer(self.vbuffer);
    }
}
