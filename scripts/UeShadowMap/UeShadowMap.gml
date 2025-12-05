/**
 * Shadow map container for a light source.
 * Manages the render target (surface) used to store shadow depth information.
 * Uses r32float surface for high-precision depth storage.
 * @param {number} width - Shadow map width (default: 1024)
 * @param {number} height - Shadow map height (default: 1024)
 */
function UeShadowMap(width = 1024, height = 1024) constructor {
    self.width = width;
    self.height = height;
    self.surface = -1;
    
    /**
     * Creates the shadow map surface.
     */
    function create() {
        gml_pragma("forceinline");
        if (surface_exists(self.surface)) {
            surface_free(self.surface);
        }
        
        self.surface = surface_create(width, height, surface_r32float);
        return self;
    }
    
    function render(light, scene, camera, __queue, __shadowIdx) {
        gml_pragma("forceinline");
        
        var _shadow = light.shadow;
        var _shadowCamera = _shadow.camera;
        var _shadowCameraView = _shadow.camera.camera;
        var _shadowMap = _shadow.map;

        // Set render target
        if (!surface_exists(_shadowMap.surface)) _shadowMap.create();
        surface_set_target(_shadowMap.surface);
       
        // Update shadow camera position and light space matrix
        // This positions the camera based on light direction and updates all matrices
        _shadow.updateMatrices(light);
        
        // Clear to white (1.0) because it represents the farthest depth.
        draw_clear(c_white);
        
        // Set shadow depth shader to write depth values to color buffer
        shader_set(sh_ue_shadow_map);

        // Render objects from the pre-collected queue
        for (var i = 0; i < __shadowIdx; i++) {
            var object = __queue[i];
            if (!object.castShadow) continue;
            var _onBeforeShadow = object[$ "onBeforeShadow"];
            var _onAfterShadow = object[$ "onAfterShadow"];
            
            if (_onBeforeShadow != undefined) _onBeforeShadow();
            object.render();
            if (_onAfterShadow != undefined) _onAfterShadow();
        } 
        return self;
    }
    
    /**
     * Disposes of the shadow map surface.
     */
    function dispose() {
        gml_pragma("forceinline");
        if (surface_exists(self.surface)) {
            surface_free(self.surface);
            self.surface = -1;
        }
        return self;
    }
    
    /**
     * Gets the texture ID for use in shaders.
     * @returns {pointer} The texture ID
     */
    function getTexture() {
        gml_pragma("forceinline");
        return surface_get_texture(self.surface);
    }
     
    create();
}
