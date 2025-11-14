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

                // Check if the material is transparent
                var _material = object[$ "material"];
                var _transparent = _material != undefined ? _material.transparent : false;
                var _materialId = _material != undefined ? _material.id : 0xFF;

                // Get the quantized distance of the object from the camera
                var _nd = clamp(object.position.distanceToSquared(cameraPos) / 32000, 0, 1);
                var _quantDepth = floor(_nd * 2147483647); // 31 bit
                
                // Invert depth for transparent materials (XOR bitwise)
                _quantDepth ^= (-_transparent & 0x7FFFFFFF); // 31 bit invertiti se trasparente

                // Combine into a single sort key
                var _sortKey = 0;
                _sortKey |= (_transparent ? 1 : 0) << 51;          // 1 bit trasparenza
                _sortKey |= (object.renderOrder & 0xFF) << 43;     // 8 bit renderOrder
                _sortKey |= (_materialId & 0xFFF) << 31;           // 12 bit materialID
                _sortKey |= _quantDepth;                           // 31 bit depth
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
