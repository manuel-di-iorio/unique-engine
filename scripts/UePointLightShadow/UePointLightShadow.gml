/**
 * Shadow configuration for point lights.
 * Uses a cube shadow map approach packed into a 3x2 atlas.
 * This allows omnidirectional shadow casting from point lights using a single texture.
 */
function UePointLightShadow(data = {}): UeLightShadow(data) constructor {
    var _near = data[$ "near"] ?? 0.5;
    var _far = data[$ "far"] ?? 1000;
    
    // 6 cameras for the 6 faces of the cube
    self.cameras = array_create(6);
    for (var i = 0; i < 6; i++) {
        self.cameras[i] = new UePerspectiveCamera({
            fov: 90,
            aspect: 1,
            near: _near,
            far: _far
        });
    }
    
    // Single shadow map (atlas) - 3x2 grid of faces
    self.map = new UeShadowMap(sh_ue_point_shadow, mapSize.width * 3, mapSize.height * 2);
    
    // Temporary surface for rendering individual faces
    self.__faceSurface = -1;
    
    // Shader uniforms for sh_ue_point_shadow
    self.__uLightPosLoc = shader_get_uniform(sh_ue_point_shadow, "u_lightPos");
    self.__uNearLoc = shader_get_uniform(sh_ue_point_shadow, "u_near");
    self.__uFarLoc = shader_get_uniform(sh_ue_point_shadow, "u_far");
    
    // Face directions (LookAt targets relative to light position)
    self.__targets = [
        [0, 0, 1], [0, 0, -1], // 0, 1
        [0, 1, 0], [0, -1, 0], // 2, 3
        [1, 0, 0], [-1, 0, 0]  // 4, 5
    ];
    
    // Up vectors for each face
    self.__ups = [
        [0, 1, 0], [0, -1, 0], // Up vectors for the new Z-looking cameras (0,1)
        [0, 0, 1], [0, 0, 1],  // Up vectors for Y cameras
        [0, 0, 1], [0, 0, 1]   // Up vectors for the new X-looking cameras (4,5)
    ];
    
    /**
     * Updates the shadow map size.
     * @param {number} width - New face width
     * @param {number} height - New face height
     */
    function updateMapSize(width, height) {
        mapSize.width = width;
        mapSize.height = height;
        self.map.width = width * 3;
        self.map.height = height * 2;
        self.map.create();
        return self;
    }
    
    /**
     * Updates all 6 shadow cameras based on light position.
     * @param {Struct} light - The point light source
     */
    function updateMatrices(light) {
    gml_pragma("forceinline");
    
    // Use world position for shadow cameras
    var lp = global.UE_VEC3_TEMP1;
    light.getWorldPosition(lp);
    
    for (var i = 0; i < 6; i++) {
          var cam = self.cameras[i];
          var targetRel = self.__targets[i];
          var upRel = self.__ups[i];
          
          // Position at light
          vec3_copy(cam.position, lp);
          
          // Look at target
          cam.target[0] = lp[0] + targetRel[0];
          cam.target[1] = lp[1] + targetRel[1];
          cam.target[2] = lp[2] + targetRel[2];
          
          // Set up vector
            cam.upX = upRel[0];
            cam.upY = upRel[1];
            cam.upZ = upRel[2];
            
            // Update matrices
            cam.updateMatrixWorld();
      }
      return self;
    }
    
    /**
     * Renders the 6 faces of the shadow map into the atlas.
     */
    function render(light, scene, camera, __queue, __shadowIdx) {
        gml_pragma("forceinline");
        
        // Update all cameras and matrices first
        self.updateMatrices(light);
        
        if (!surface_exists(self.map.surface)) self.map.create();
        if (!surface_exists(self.__faceSurface)) {
            self.__faceSurface = surface_create(mapSize.width, mapSize.height, surface_r32float);
        }
        
        // Prepare the atlas surface
        surface_set_target(self.map.surface);
        // NOTE: draw_clear(c_white) clears to 1.0 in R channel (max depth).
        // If alpha test is added, clear should be maintained as 1.0 (far).
        draw_clear(c_white);
        surface_reset_target();

        // Render each face into the temporary surface and copy it to the atlas
        for (var i = 0; i < 6; i++) {
            var cam = self.cameras[i];
            
            // 1. Render face to temporary surface
            surface_set_target(self.__faceSurface);
            draw_clear(c_white);
            
            // Check if shader exists before setting
            if (shader_is_compiled(sh_ue_point_shadow)) {
                shader_set(sh_ue_point_shadow);
                
                // Set uniforms for linear depth
                var lp = global.UE_VEC3_TEMP1;
                light.getWorldPosition(lp);
                shader_set_uniform_f_array(self.__uLightPosLoc, lp);
                shader_set_uniform_f(self.__uNearLoc, cam.near);
                shader_set_uniform_f(self.__uFarLoc, cam.far);
            }
            
            // Apply camera for this face
            camera_apply(cam.camera);
            
            // Render objects
            var _frustum = cam.getFrustum();
            for (var j = 0; j < __shadowIdx; j++) {
                var object = __queue[j];
                if (!object.castShadow) continue;
                
                // Frustum culling
                if (object.frustumCulled) {
                    var s = object.__intersectionSphere;
                    if (s != undefined && !frustum_intersects_sphere(_frustum, s)) {
                        continue;
                    }
                }
                
                object.render();
            }
            
            surface_reset_target(); 
            
            // 2. Copy the face to the atlas
            // Calculate viewport in atlas (3x2 grid)
            // Row 0 (Top): 0, 1, 2
            // Row 1 (Bottom): 3, 4, 5
            var faceX = i % 3;
            var faceY = floor(i / 3);
            
            var vx = faceX * mapSize.width;
            var vy = faceY * mapSize.height;
            
            surface_set_target(self.map.surface);
            
            // Reset matrices for 2D top-left drawing
            var totalW = mapSize.width * 3;
            var totalH = mapSize.height * 2;
            matrix_set(matrix_view, matrix_build_lookat(totalW/2, totalH/2, 1, totalW/2, totalH/2, 0, 0, 1, 0));
            matrix_set(matrix_projection, matrix_build_projection_ortho(totalW, totalH, -1, 1));
            
            shader_reset(); 
            var _filter = gpu_get_tex_filter();
            gpu_set_tex_filter(false);
            gpu_set_blendenable(false);
            draw_surface(self.__faceSurface, vx, vy);
            gpu_set_blendenable(true);
            gpu_set_tex_filter(_filter);
            
            surface_reset_target();
        }
        
        return self;
    }
    
    /**
     * Disposes of all resources.
     */
    function dispose() {
        gml_pragma("forceinline");
        for (var i = 0; i < 6; i++) {
            self.cameras[i].dispose();
        }
        if (surface_exists(self.__faceSurface)) {
            surface_free(self.__faceSurface);
        }
        self.map.dispose();
        return self;
    }
}
