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
     * We use a standard RGBA surface which includes a depth buffer for proper Z-testing.
     * The depth is written to the red channel by the depth shader.
     */
    function create() {
        gml_pragma("forceinline");
        if (surface_exists(self.surface)) {
            surface_free(self.surface);
        }
        // Use standard RGBA surface for compatibility
        self.surface = surface_create(width, height, surface_r32float);
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
        if (surface_exists(self.surface)) {
            return surface_get_texture(self.surface);
        }
        return -1;
    }
    
    create();
}
