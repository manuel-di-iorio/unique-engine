/**
 * Shadow configuration for directional lights.
 * Manages the shadow camera, shadow map, and shadow-related parameters.
 * 
 * Uses an orthographic camera to capture shadows from a directional light source, simulating sunlight or other distant light sources.
 */
function UeDirectionalLightShadow(data = {}): UeLightShadow(data) constructor {
    // Shadow camera (orthographic for directional light)
    camera = new UeOrthographicCamera({
        left: -1000,
        right: 1000,
        top: -1000,
        bottom: 1000
    });

    // Shadow map / render target
    map = new UeShadowMap(2048, 2048)//mapSize.width, mapSize.height);

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
        map.width = width;
        map.height = height;
        map.create();
        return self;
    }
    
    /**
     * Updates the light space matrix and positions the shadow camera based on the light.
     * 
     * @param {Struct} light - The directional light that owns this shadow
     */
    function updateMatrices(light) {
        gml_pragma("forceinline");
        
        // Position shadow camera at the light's position
        camera.position.copy(light.position);
        
        // Look at the light's target position
        camera.target.copy(light.target.position);
        
        // Update camera matrices (recalculates view matrix)
        camera.updateMatrixWorld();
        
        // Apply camera matrices to GameMaker camera
        var _shadowCameraView = camera.camera; 
        camera_apply(_shadowCameraView);
        
        // Light space matrix = Projection * View
        matrix_multiply(camera.matrixWorldInverse.data, camera.projectionMatrix.data, lightSpaceMatrix.data)
        
        return self;
    }
    
    /**
     * Disposes of shadow resources.
     */
    function dispose() {
        camera.dispose();
        map.dispose();
        return self;
    }
}
