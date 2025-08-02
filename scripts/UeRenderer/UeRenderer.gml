function UeRenderer(data = {}): UeObject3D(data) constructor {
    isRenderer = true;
    type = "Renderer";
    sortObjects = data[$ "sortObjects"] ?? true;
    
    __frustum = new UeFrustum(); 
    __opaqueIdx = 0;
    __transparentIdx = 0;
    __lightIdx = 0;
    __opaqueQueue = array_create(512);
    __transparentQueue = array_create(128);
    __lights = array_create(2);
    
    // Recursively collect renderable objects and split them into opaque and transparent queues
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
                // @todo not working correctly
                if (object.frustumCulled && !__frustum.intersectsObject(object)) continue;
                 
                // Precompute distance from camera for sorting
                object.__ueSortDistanceToCam = object.position.distanceToSquared(cameraPos);
    
                // Push to transparent or opaque queue based on material property
                var material = object.material;
                if (material != undefined && material.transparent) {
                    __transparentQueue[__transparentIdx++] = object;
                } else {
                    __opaqueQueue[__opaqueIdx++] = object;
                }
            }
            
            // Traverse child objects
            __collectObjectQueues(object.children, camera);
        } 
    }
    
    /**
     * [Complexity] average case: O(n log n), worst case: O(n^2)
     */
    function __quickSortOpaqueObjects(left, right) {
        gml_pragma("forceinline");
        if (left >= right) return;
        
        var array = __opaqueQueue;
        var pivot = array[right];
        var i = left - 1;
        
        for (var j = left; j < right; j++) {
            var objA = array[j];
            var objB = pivot;
            
            if (objA.renderOrder != objB.renderOrder ?
                objA.renderOrder < objB.renderOrder :
                objA.__ueSortDistanceToCam < objB.__ueSortDistanceToCam
            ) {
                i++;
                var temp = array[i];
                array[i] = array[j];
                array[j] = temp;
            }
        }
        
        var temp = array[i + 1];
        array[i + 1] = array[right];
        array[right] = temp;
        
        var pivotIndex = i + 1;
        
        __quickSortOpaqueObjects(left, pivotIndex - 1);
        __quickSortOpaqueObjects(pivotIndex + 1, right);
    }

    function __quickSortTransparentObjects(left, right) {
        gml_pragma("forceinline");
        if (left >= right) return;
        
        var array = __transparentQueue;
        var pivot = array[right];
        var i = left - 1;
        
        for (var j = left; j < right; j++) {
            var objA = array[j];
            var objB = pivot;
            
            if (objA.renderOrder != objB.renderOrder ?
                objA.renderOrder > objB.renderOrder :
                objA.__ueSortDistanceToCam > objB.__ueSortDistanceToCam) {
                i++;
                var temp = array[i];
                array[i] = array[j];
                array[j] = temp;
            }
        }
        
        var temp = array[i + 1];
        array[i + 1] = array[right];
        array[right] = temp;
        
        var pivotIndex = i + 1;
        
        __quickSortTransparentObjects(left, pivotIndex - 1);
        __quickSortTransparentObjects(pivotIndex + 1, right);
    }
    
    // Render a list of opaque objects
    function __renderOpaqueObjects() {
        gml_pragma("forceinline");
        var objects = __opaqueQueue;
        
        for (var i = 0; i < __opaqueIdx; i++) {
            var object = objects[i];
            var onBeforeRender = object[$ "onBeforeRender"];
            var onAfterRender = object[$ "onAfterRender"];

            if (onBeforeRender != undefined) onBeforeRender();
            object.render();
            if (onAfterRender != undefined) onAfterRender(); 
        } 
    }
    
    // Render a list of transparent objects with zwrite disabled
    // Also make a double draw call (if allowed) to mitigate transparency artifacts
    function __renderTransparentObjects() {
        gml_pragma("forceinline");
        var objects = __transparentQueue;
        
        for (var i = 0; i < __transparentIdx; i++) {
            var object = objects[i];
            var onBeforeRender = object[$ "onBeforeRender"];
            var onAfterRender = object[$ "onAfterRender"];
            var material = object.material;
            
            if (onBeforeRender != undefined) onBeforeRender();
            
            if (material != undefined && material.forceSinglePass) {
                object.render();
            } else {
                object.render(cull_noculling);
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
        var currentBlendEnable = gpu_get_blendenable();
        var currentCullMode = gpu_get_cullmode();
        
        // Collect and classify all renderable objects
        if (camera.matrixAutoUpdate) camera.updateMatrixWorld();
    
        // Frustum updated from camera. 
        // It needs to test using world coords, so we multiply the matrixes from camera space to world space 
        __frustum.setFromProjectionMatrix(
            matrix_multiply(camera.matrixWorldInverse.data, camera.projectionMatrix.data)
        ); 
        
        __lightIdx = 0;
        __opaqueIdx = 0;
        __transparentIdx = 0;
        
        __collectObjectQueues(scene.children, camera);

        // Sort both queues before rendering
        if (sortObjects) {
            __quickSortOpaqueObjects(0, __opaqueIdx-1); // Front-to-back
            __quickSortTransparentObjects(0, __transparentIdx-1); // Back-to-front
        }
        
        // Build the light and render state
        __buildLightState();
    
        global.UE_RENDERER_STATE[UE_RENDERER_STATE_ENUM.CAMERA] = camera;
        
        // Render the objects opaque objects first
        __renderOpaqueObjects();
        __renderTransparentObjects();
        
        // Reset the world after rendering
        shader_reset();  
        matrix_set(matrix_world, matrix_build_identity()); 
        gpu_set_blendenable(currentBlendEnable);
        gpu_set_cullmode(currentCullMode);

        return self;
    }
}
