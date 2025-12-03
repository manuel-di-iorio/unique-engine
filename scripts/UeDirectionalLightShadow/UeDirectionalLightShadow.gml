/**
 * Shadow configuration for directional lights.
 * Manages the shadow camera, shadow map, and shadow-related parameters.
 * 
 * Uses an orthographic camera to capture shadows from a directional light source, simulating sunlight or other distant light sources.
 */
function UeDirectionalLightShadow(data = {}): UeLightShadow(data) constructor {
    // Shadow camera (orthographic for directional light)
    camera = new UeOrthographicCamera({
        left: -500,
        right: 500,
        top: 500,
        bottom: -500,
        near: 0.1,
        far: 500
    });

    // Shadow map / render target
    map = new UeShadowMap(mapSize.width, mapSize.height);

    // Light space transformation matrix
    lightSpaceMatrix = new UeMatrix4();
    
    /**
     * Updates the shadow map size and recreates the render target.
     * @param {number} width - New width
     * @param {number} height - New height
     */
    function updateMapSize(width, height) {
        mapSize.width = width;
        mapSize.height = height;
        map.dispose();
        map = new UeShadowMap(width, height);
        return self;
    }
    
    /**
     * Updates the light space matrix based on the shadow camera's matrices.
     * This matrix is used in shaders to transform world positions to light space.
     */
    function updateMatrices() {
        gml_pragma("forceinline");
        
        // Light space matrix = Projection * View
        lightSpaceMatrix.copy(camera.projectionMatrix).multiply(camera.matrixWorldInverse);
        
        return self;
    }
    
    /**
     * Disposes of shadow resources.
     */
    function dispose() {
        map.dispose();
        camera.dispose();
        return self;
    }
}
