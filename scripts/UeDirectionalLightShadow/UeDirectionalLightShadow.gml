/**
 * Shadow configuration for directional lights.
 * Manages the shadow camera, shadow map, and shadow-related parameters.
 * 
 * Uses an orthographic camera to capture shadows from a directional light source, simulating sunlight or other distant light sources.
 */
function UeDirectionalLightShadow(data = {}): UeLightShadow(data) constructor {
    // Shadow camera (orthographic for directional light)
    camera = new UeOrthographicCamera({
        left: data[$ "left"] ?? -1000,
        right: data[$ "right"] ?? 1000,
        top: data[$ "top"] ?? -1000,
        bottom: data[$ "bottom"] ?? 1000,
        far: data[$ "far"] ?? 2000
    });

    // Shadow map / render target
    map = new UeShadowMap(mapSize.width, mapSize.height);

    // Light space transformation matrix
    lightSpaceMatrix = mat4_create();
    
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
        vec3_copy(camera.position, light.position);
        
        // Look at the light's target position
        vec3_copy(camera.target, light.target.position);
        
        // Update camera matrices (recalculates view matrix)
        camera.updateMatrixWorld();
        
        // Apply camera matrices to GameMaker camera
        var _shadowCameraView = camera.camera; 
        camera_apply(_shadowCameraView);
        
        // Light space matrix = Projection * View
        matrix_multiply(camera.matrixWorldInverse, camera.projectionMatrix, lightSpaceMatrix);
        
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
