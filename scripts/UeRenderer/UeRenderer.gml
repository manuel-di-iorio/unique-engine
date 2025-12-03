function UeRenderer(data = {}): UeObject3D(data) constructor {
    isRenderer = true;
    type = "Renderer";
    sortObjects = data[$ "sortObjects"] ?? true;

    // Shadow map configuration for the renderer
    shadowMap = data[$ "shadowMap"] ?? {};
    shadowMap.enabled = shadowMap[$ "enabled"] ?? false;
    shadowMap.autoUpdate = shadowMap[$ "autoUpdate"] ?? true;
    shadowMap.needsUpdate = shadowMap[$ "needsUpdate"] ?? false;
    
    __boundMaterial = undefined; // Material that is currently bound
    __lightIdx = 0;
    __queueIdx = 0;
    __lights = array_create(2);
    __queue = array_create(512);
    __shadowIdx = 0;
    
    // Recursively collect renderable objects and precompute their sort key
    function __collectObjectQueues(objects, camera) {
        gml_pragma("forceinline");
        var cameraPos = camera.position;
        var cameraLayers = camera.layers;
        
        for (var i = 0, len = array_length(objects); i < len; i++) {
            var object = objects[i];
            if (!object.layers.test(cameraLayers)) continue;
            
            if (object[$ "isLight"]) {
                __lights[__lightIdx++] = object;
                continue;
            }
                
            // Update matrices for dynamic objects
            if (object.matrixAutoUpdate && object.matrixWorldAutoUpdate) object.updateMatrixWorld();
            
            /* Frustum intersection && sort key calculation */
            if (object.visible) {
               if (object[$ "geometry"] != undefined && object.geometry[$ "vb"] != undefined) {
                   // Test the frustum intersection, only for parent meshes
                   if (object[$ "isMesh"] && object.frustumCulled && object.parent == undefined) {
                       var _position = object.position;
                       var _boundingSphere = object[$ "__intersectionSphere"];
   
                       if (_boundingSphere != undefined &&
                           !sphere_is_visible(_position.x, _position.y, _position.z, _boundingSphere.radius)) continue;
                   }
                   
                   // ** Precompute the sort hash **
   
                   // --- MATERIAL & TRANSPARENCY -------------------------------------------------
                   // Determine whether the material is transparent.
                   // Transparent objects must be rendered *after* opaque ones,
                   // and sorted back-to-front inside their own group.
                   var _material = object[$ "material"];
                   var _transparent = _material.transparent;
   
                   // Material ID (12-bit)
                   var _materialId = _material.id;
   
                   // --- DEPTH QUANTIZATION (31 bits) -------------------------------------------
                   // We convert the object distance into a normalized value (0..1),
                   // then map it into a 31-bit integer range (0..2^31-1).
                   //
                   // Why quantize instead of using the raw float distance?
                   // - Floating-point precision becomes poor for large distances.
                   // - Sorting with floats introduces instability and z-fighting-like errors.
                   // - By converting to a 31-bit integer, we guarantee a stable and uniform
                   //   precision distribution across the whole range.
                   var _nd = clamp(object.position.distanceToSquared(cameraPos) / 32000, 0, 1);
                   var _quantDepth = floor(_nd * 0x7FFFFFFF);  // 31-bit integer depth value
   
                   // --- DEPTH INVERSION FOR TRANSPARENT OBJECTS --------------------------------
                   // Transparent objects must be sorted *back-to-front*, while opaque objects
                   // are sorted *front-to-back*.
                   //
                   // Instead of using two different sort passes, we invert the depth integer
                   // when the object is transparent.
                   //
                   // Bitwise trick:
                   //     _quantDepth ^= mask
                   //
                   // The mask is (0x7FFFFFFF) when the object is transparent,
                   // and (0) when opaque. This works because:
                   //
                   //     -_transparent  →  0xFFFFFFFF when true, 0x00000000 when false
                   //     & 0x7FFFFFFF   →  either full-mask or zero-mask
                   //
                   // Result: all 31 bits of depth are flipped only when needed.
                   _quantDepth ^= (-_transparent & 0x7FFFFFFF);
   
                   // --- SORT KEY COMPOSITION (52 bits) ------------------------------------------
                   // We pack all sorting criteria into a single integer key.
                   // Higher-order bits have higher sorting priority.
                   //
                   // Bit layout (from MSB → LSB):
                   //
                   //  [51]        : 1 bit   → transparency flag (opaque first, transparent later)
                   //  [50..43]    : 8 bits  → renderOrder (explicit user sorting)
                   //  [42..31]    : 12 bits → material ID (minimizes shader/material switches)
                   //  [30..0]     : 31 bits → quantized depth (front-to-back or inverted)
                   //
                   // The final 52-bit key ensures a single fast integer comparison for sorting.
                   var _sortKey = 0;
                   _sortKey |= (_transparent ? 1 : 0) << 51;      // 1 bit  transparency flag
                   _sortKey |= (object.renderOrder & 0xFF) << 43; // 8 bits renderOrder
                   _sortKey |= (_materialId & 0xFFF) << 31;       // 12 bits material ID
                   _sortKey |= _quantDepth;                       // 31 bits depth
                   object.__sortKey = _sortKey;
   
                   __queue[__queueIdx++] = object;
               }
            
              // Traverse child objects
              __collectObjectQueues(object.children, camera);
            }
        } 
    }    
   
    function __quickSortObjects(left, right) {
        gml_pragma("forceinline");
        if (left >= right) return;
        
        var array = __queue;
        var pivot = array[right].__sortKey;
        var i = left - 1;
        var tmp;
        
        for (var j = left; j < right; j++) {
            if (array[j].__sortKey < pivot) {
                i++;
                tmp = array[i];
                array[i] = array[j];
                array[j] = tmp;
            }
        }
        
        tmp = array[i + 1];
        array[i + 1] = array[right];
        array[right] = tmp;
        
        var pivotIndex = i + 1;
        
        __quickSortObjects(left, pivotIndex - 1);
        __quickSortObjects(pivotIndex + 1, right);
    }
    
    function __renderDirectionalLightShadow(light, scene, camera) {
        gml_pragma("forceinline");
        
        var _shadow = light.shadow;
        var _shadowCamera = _shadow.camera;
        var _shadowMap = _shadow.map;
        var _viewCamera = camera.camera;
        
        // Position shadow camera along light direction
        // Light target is the direction vector
        var _lightDir = light.target; // This is the direction the light points
        var _distance = 200; // Distance from scene center
        
        // Position camera opposite to light direction
        _shadowCamera.position.set(
            -_lightDir.x * _distance,
            -_lightDir.y * _distance,
            -_lightDir.z * _distance
        );
        
        // Look at scene center
        _shadowCamera.target.set(0, 0, 0);
        
        _shadowCamera.updateMatrixWorld();

        // Update shadow camera
        // _shadow.updateForCamera(camera); // DISABLED FOR DEBUG
        
        // Set matrices
        camera_set_view_mat(_viewCamera, _shadowCamera.matrixWorldInverse.data);
        camera_set_proj_mat(_viewCamera, _shadowCamera.projectionMatrix.data);
        camera_apply(_viewCamera);
        
        // Configure GPU state for shadow depth pass
        var _prevCull = gpu_get_cullmode();
        var _prevZTest = gpu_get_ztestenable();
        var _prevZWrite = gpu_get_zwriteenable();
        var _prevBlend = gpu_get_blendenable();
        gpu_set_cullmode(cull_counterclockwise);
        gpu_set_ztestenable(true);
        gpu_set_zwriteenable(true);
        gpu_set_blendenable(false);
        
        // Set render target
        if (!surface_exists(_shadowMap.surface)) _shadowMap.create();
        surface_set_target(_shadowMap.surface);
        draw_clear(c_black);
        
        // Set shadow depth shader to write depth values to color buffer
        shader_set(sh_ue_shadow_map);

        //shader_set_uniform_f(shader_get_uniform(sh_ue_shadow_map, "u_near"), camera.near);
        //shader_set_uniform_f(shader_get_uniform(sh_ue_shadow_map, "u_far"), camera.far);
        
        // Render objects from the pre-collected shadow queue
        for (var i = 0; i < __shadowIdx; i++) {
            var object = __queue[i];
            if (!object.castShadow) continue;
            if (object.onBeforeShadow != undefined) object.onBeforeShadow();
            object.render();
            if (object.onAfterShadow != undefined) object.onAfterShadow();
        }

        // Restore previous GPU state
        shader_reset();
        surface_reset_target();
        gpu_set_cullmode(_prevCull);
        gpu_set_ztestenable(_prevZTest);
        gpu_set_zwriteenable(_prevZWrite);
        gpu_set_blendenable(_prevBlend);
        camera_set_view_mat(_viewCamera, camera.matrixWorldInverse.data);
        camera_set_proj_mat(_viewCamera, camera.projectionMatrix.data);
        camera_apply(_viewCamera);
    }

    /**
     * Renders shadow maps for all shadow-casting lights.
     * This must be called before the main render pass.
     * @param {Struct} scene - The scene to render
     */
    function __renderShadowMaps(scene, camera) {
        gml_pragma("forceinline");
        
        for (var i = 0; i < __lightIdx; i++) {
            var light = __lights[i];
            if (!light.castShadow) continue;
            
            switch (light.lightType) {
                case "DirectionalLight":
                    __renderDirectionalLightShadow(light, scene, camera);
                    break;
            }
        }
    }

    // Aggregate light data from scene lights
    function __buildLightState() {
        gml_pragma("forceinline");

        var lights = __lights;
        var ambientState = global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.AMBIENT];
        ambientState[0] = 0;
        ambientState[1] = 0;
        ambientState[2] = 0;
        
        var directionalState = global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.DIRECTIONAL];
        var pointLightState = global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.POINT_LIGHT];
        
        var dIdx = 0;
        var pIdx = 0;
        
        for (var i = 0; i < __lightIdx; i++) {
            var l = lights[i];
            if (!l.enabled) continue;
                
            switch (l.lightType) {
                case "AmbientLight":
                    // Accumulate ambient light contributions
                    ambientState[0] += l.color[0] * l.intensity;
                    ambientState[1] += l.color[1] * l.intensity;
                    ambientState[2] += l.color[2] * l.intensity;
                    break;

                case "DirectionalLight":
                    directionalState[dIdx++] = l;
                    break;
            }
        }
        
        global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.DIRECTIONAL_COUNT] = dIdx;
        global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.POINT_LIGHT_COUNT] = pIdx;
        
        // Clamp ambient light to prevent over-exposure
        ambientState[0] = clamp(ambientState[0], 0, 1);
        ambientState[1] = clamp(ambientState[1], 0, 1);
        ambientState[2] = clamp(ambientState[2], 0, 1);
    }

    /**
     * Render the main scene
     */
    function __renderObjects() {
        gml_pragma("forceinline");
        
        for (var i = 0; i < __queueIdx; i++) {
            var _object = __queue[i];
            var _onBeforeRender = _object[$ "onBeforeRender"];
            var _onAfterRender = _object[$ "onAfterRender"];
            var _material = _object[$ "material"];

            // Wireframes material applies the default material
            var _wireframe = _material.wireframe;
            if (_wireframe) {
                _material = global.UE_DEFAULT_MATERIAL_WIREFRAME;
            }

            // Use the material
            if (_material.visible) {
                if (_material != __boundMaterial) {
                    __boundMaterial = _material;
                    _material.use();
                }

                _material.useByMesh(_object, _material.transparent && !_material.forceSinglePass);
            }

            if (_onBeforeRender != undefined) _onBeforeRender();
            
            // Render the mesh
            _object.render(_wireframe);

            if (_onAfterRender != undefined) _onAfterRender(); 
        }
    }
    
    /// Render the scene
    function render(scene, camera) {
        gml_pragma("forceinline");
        if (view_current != camera.view) return;
        var _gpuState = gpu_get_state();
        
        // Collect and classify all renderable objects
        if (camera.matrixAutoUpdate) camera.updateMatrixWorld();
    
        __lightIdx = 0;
        __queueIdx = 0;
        __collectObjectQueues(scene.children, camera);
        __shadowIdx = __queueIdx;

        // **PASS 1: Render shadow maps for shadow-casting lights**
        if (shadowMap.enabled && (shadowMap.autoUpdate || shadowMap.needsUpdate)) {
            __renderShadowMaps(scene, camera);
            shadowMap.needsUpdate = false;
        }

        // Build the light state after shadow maps so matrices and textures are current
        __buildLightState();

        // Sort both queues before rendering
        if (sortObjects) __quickSortObjects(0, __queueIdx - 1);
    
        global.UE_RENDERER_STATE[UE_RENDERER_STATE_ENUM.CAMERA] = camera;
        
        // **PASS 2: Render the main scene**
        __renderObjects();
        
        // Reset the world after rendering
        __boundMaterial = undefined;
        shader_reset();  
        matrix_set(matrix_world, global.UE_MATRIX_IDENTITY);
        gpu_set_state(_gpuState);

        return self;
    }
}
