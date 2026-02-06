/**
 * Shadow configuration for spot lights.
 * Manages the shadow camera, shadow map, and shadow-related parameters.
 * 
 * Uses a perspective camera to capture shadows from a spot light source.
 */
function UeSpotLightShadow(data = {}): UeLightShadow(data) constructor {
    // Shadow camera (perspective for spot light)
    camera = new UePerspectiveCamera({
        fov: data[$ "fov"] ?? 90, // Will be updated based on light angle
        aspect: 1,
        near: data[$ "near"] ?? 0.5,
        far: data[$ "far"] ?? 2000
    });

    // Shadow map / render target
    map = new UeShadowMap(sh_ue_spot_shadow, mapSize.width, mapSize.height);

    // Light space transformation matrix
    lightSpaceMatrix = mat4_create();

    // Uniform locations
    __uLightViewProjLoc = shader_get_uniform(sh_ue_spot_shadow, "uLightViewProj");
    __uNearLoc = shader_get_uniform(sh_ue_spot_shadow, "u_near");
    __uFarLoc = shader_get_uniform(sh_ue_spot_shadow, "u_far");

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
     * @param {Struct} light - The spot light that owns this shadow
     */
    function updateMatrices(light) {
        gml_pragma("forceinline");

        // Update camera FOV based on light angle (angle is half-angle in degrees)
        camera.fov = light.angle * 2;
        camera.updateProjectionMatrix();

        // Use world position and target position for shadow camera
        var lp = global.UE_VEC3_TEMP1;
        var tp = global.UE_VEC3_TEMP2;

        light.updateWorldMatrix(true, false);
        light.target.updateWorldMatrix(true, false);

        light.getWorldPosition(lp);
        light.target.getWorldPosition(tp);

        vec3_copy(camera.position, lp);
        vec3_copy(camera.target, tp);

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
     * Renders the shadow map.
     */
    function render(light, scene, camera, __queue, __shadowIdx) {
        gml_pragma("forceinline");

        if (!surface_exists(map.surface)) map.create();
        surface_set_target(map.surface);

        var _gpuCullMode = gpu_get_cullmode();
        gpu_set_cullmode(cull_noculling);

        // Update matrices and apply camera
        updateMatrices(light);

        global.UE_RENDERER_ACTIVE_SHADOW_CAMERA = self.camera;
        draw_clear(c_white);

        global.UE_RENDERER_ACTIVE_SHADOW_SHADER = sh_ue_spot_shadow;
        shader_set(sh_ue_spot_shadow);

        // Set light view projection matrix
        shader_set_uniform_f_array(__uLightViewProjLoc, lightSpaceMatrix);

        // Set near and far planes for linear depth
        shader_set_uniform_f(__uNearLoc, self.camera.near);
        shader_set_uniform_f(__uFarLoc, self.camera.far);

        var _shadowFrustum = self.camera.getFrustum();
        for (var i = 0; i < __shadowIdx; i++) {
            var object = __queue[i];
            if (!object.castShadow || object.geometry == undefined) continue;

            if (object.frustumCulled) {
                var s = object.__intersectionSphere;
                if (s != undefined && !frustum_intersects_sphere(_shadowFrustum, s)) {
                    continue;
                }
            }

            var _onBeforeShadow = object[$ "onBeforeShadow"];
            var _onAfterShadow = object[$ "onAfterShadow"];

            if (_onBeforeShadow != undefined) _onBeforeShadow();
            object.render();
            if (_onAfterShadow != undefined) _onAfterShadow();
        }

        // Restore previous cull mode
        gpu_set_cullmode(_gpuCullMode);

        shader_reset();
        surface_reset_target();
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
