function UeRenderer(data = {}): UeObject3D(data) constructor {
    isRenderer = true;
    type = "Renderer";
    sortObjects = data[$ "sortObjects"] ?? true;
    
    __lightIdx = 0;
    __queueIdx = 0;
    __lights = array_create(2);
    __queue = array_create(512);
    
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
                
            if (object.matrixWorldAutoUpdate) object.updateMatrixWorld();
            
            if (object[$ "geometry"] != undefined && object.visible) {
                // Test the frustum intersection
                if (object.frustumCulled) {
                    var _intersectionSphere = object.__intersectionSphere;
                    var _position = object.position;
                    if (_intersectionSphere != undefined &&
                        !sphere_is_visible(_position.x, _position.y, _position.z, _intersectionSphere.radius)) continue;
                }
                
                // ** Precompute the sort hash **

                // --- MATERIAL & TRANSPARENCY -------------------------------------------------
                // Determine whether the material is transparent.
                // Transparent objects must be rendered *after* opaque ones,
                // and sorted back-to-front inside their own group.
                var _material = object[$ "material"];
                var _transparent = _material != undefined ? _material.transparent : false;

                // Material ID (12-bit). If the object has no material, use 0xFF
                // so that "missing material" is sorted consistently and safely.
                var _materialId = _material != undefined ? _material.id : 0xFF;

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

    function __quickSortObjects(left, right) {
        gml_pragma("forceinline");
        if (left >= right) return;
        
        var array = __queue;
        var pivot = array[right].__sortKey;
        var i = left - 1;
        // var tmp;
        
        for (var j = left; j < right; j++) {
            if (array[j].__sortKey < pivot) {
                i++;
                var tmp = array[i];
                array[i] = array[j];
                array[j] = tmp;
            }
        }
        
        var tmp = array[i + 1];
        array[i + 1] = array[right];
        array[right] = tmp;
        
        var pivotIndex = i + 1;
        
        __quickSortObjects(left, pivotIndex - 1);
        __quickSortObjects(pivotIndex + 1, right);
    }
    
    function __renderObjects() {
        gml_pragma("forceinline");
        
        for (var i = 0; i < __queueIdx; i++) {
            var object = __queue[i];
            var onBeforeRender = object[$ "onBeforeRender"];
            var onAfterRender = object[$ "onAfterRender"];
            var material = object[$ "material"];
            var transparent = material != undefined ? material.transparent : false;

            if (onBeforeRender != undefined) onBeforeRender();
            
            // Render transparent objects with no culling to show both faces
            if (transparent && (material == undefined || !material.forceSinglePass)) {
                object.render(cull_noculling);
            } else {
                object.render();
            }
            
            if (onAfterRender != undefined) onAfterRender(); 
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

                case "PointLight":
                    pointLightState[pIdx++] = l;
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

        // Sort both queues before rendering
        if (sortObjects) __quickSortObjects(0, __queueIdx - 1);
        
        // Build the light and render state
        __buildLightState();
    
        global.UE_RENDERER_STATE[UE_RENDERER_STATE_ENUM.CAMERA] = camera;
        
        // Render the objects
        __renderObjects();
        
        // Reset the world after rendering
        shader_reset();  
        matrix_set(matrix_world, global.UE_MATRIX_IDENTITY);
        gpu_set_state(_gpuState);

        return self;
    }
}
