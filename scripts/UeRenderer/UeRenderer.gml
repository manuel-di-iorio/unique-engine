// @todo This entire class is slow! Need to avoid to do things if they have not changed and cache as much as possible
// @todo implement frustum culling check on objects
function UeRenderer(data = {}): UeObject3D(data) constructor {
    isRenderer = true;
    type = "Renderer";
    
    __projScreenMatrix = new UeMatrix4();
    __frustum = new UeFrustum(); 
    
    // Recursively collect renderable objects and split them into opaque and transparent queues
    function __collectObjectQueues(objects, lights, camera, opaqueQueue, transparentQueue) {
        var cameraPos = camera.position;
        var cameraLayers = camera.layers;
        
        for (var i = 0, len = array_length(objects); i < len; i++) {
            var object = objects[i];
            
            if (!object.layers.test(cameraLayers)) continue;
            
            if (object[$ "isLight"]) {
                lights[__lightIdx++] = object;
                continue;
            }
                
            object.updateMatrixWorld(__frustum);
            
            if (object[$ "geometry"] && object.visible) {
                // Test the frustum intersection
                //if (object.frustumCulled && !__frustum.intersectsObject(object)) continue;
                 
                // Precompute distance from camera for sorting
                object.__ueSortDistanceToCam = object.position.distanceToSquared(cameraPos);
    
                // Push to transparent or opaque queue based on material property
                var material = object.material;
                if (material != undefined && material.transparent) {
                    transparentQueue[__transparentIdx++] = object;
                } else {
                    opaqueQueue[__opaqueIdx++] = object;
                }
            }
            
            // Traverse child objects
            __collectObjectQueues(object.children, lights, camera, opaqueQueue, transparentQueue);
        } 
    }
    
    /**
     * [Complexity] average case: O(n log n), worst case: O(n^2)
     */
    function __quickSortOpaqueObjects(array, left, right) {
        if (left >= right) return;
        
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
        
        __quickSortOpaqueObjects(array, left, pivotIndex - 1);
        __quickSortOpaqueObjects(array, pivotIndex + 1, right);
    }

    function __quickSortTransparentObjects(array, left, right) {
        if (left >= right) return;
        
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
        
        __quickSortTransparentObjects(array, left, pivotIndex - 1);
        __quickSortTransparentObjects(array, pivotIndex + 1, right);
    }
    
    // Render a list of opaque objects
    function __renderOpaqueObjects(objects, renderState) {
        for (var i = 0; i < __opaqueIdx; i++) {
            var object = objects[i];
            var onBeforeRender = object[$ "onBeforeRender"];
            var onAfterRender = object[$ "onAfterRender"];
            
            if (onBeforeRender != undefined) onBeforeRender(renderState);
            object.render(renderState);
            if (onAfterRender != undefined) onAfterRender(renderState);
        }
    }
    
    // Render a list of transparent objects with zwrite disabled
    // Also make a double draw call (if allowed) to mitigate transparency artifacts
    function __renderTransparentObjects(objects, renderState) {
        var currentZWriteEnable = gpu_get_zwriteenable();
        gpu_set_zwriteenable(false);
        
        for (var i = 0; i < __transparentIdx; i++) {
            var object = objects[i];
            var onBeforeRender = object[$ "onBeforeRender"];
            var onAfterRender = object[$ "onAfterRender"];
            var material = object.material;
            
            if (onBeforeRender != undefined) onBeforeRender(renderState);
            
            if (material != undefined && material.forceSinglePass) {
                object.render(renderState);
            } else {
                renderState.side = cull_noculling;
                object.render(renderState);
                delete renderState.side;
            }
            
            if (onAfterRender != undefined) onAfterRender(renderState);
        }
        
        gpu_set_zwriteenable(currentZWriteEnable);
    }
    
    // Aggregate light data from scene lights
    function __buildLightState(lights) {
        var state = {
            ambient: [0, 0, 0],
            directional: [],
            point: []
        };
        
        for (var i = 0; i < __lightIdx; i++) {
            var l = lights[i];
            if (!l.enabled) continue;
                
            switch (l.lightType) {
                case "AmbientLight":
                    // Accumulate ambient light contributions
                    state.ambient[0] += l.color[0] * l.intensity;
                    state.ambient[1] += l.color[1] * l.intensity;
                    state.ambient[2] += l.color[2] * l.intensity;
                    break;

                case "DirectionalLight":
                    array_push(state.directional, l);
                    break;

                case "PointLight":
                    array_push(state.point, l);
                    break;
            }
        }
        
        // Clamp ambient light to prevent over-exposure
        state.ambient[0] = clamp(state.ambient[0], 0, 1);
        state.ambient[1] = clamp(state.ambient[1], 0, 1);
        state.ambient[2] = clamp(state.ambient[2], 0, 1);
        
        return state;
    }
    
    /// Render the scene
    function render(scene, camera) {
        if (camera.matrixAutoUpdate) camera.updateMatrixWorld();
        
        // Frustum updated from camera. 
        // It needs to test using world coords, so we multiply the matrixes from camera space to world space 
        __projScreenMatrix.multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse);
        __frustum.setFromProjectionMatrix(__projScreenMatrix);
        
        var currentBlendEnable = gpu_get_blendenable();
        var currentCullMode = gpu_get_cullmode();
        
        // Collect and classify all renderable objects
        __lightIdx = 0;
        __opaqueIdx = 0;
        __transparentIdx = 0;
        var opaqueQueue = array_create(512);
        var transparentQueue = array_create(512);
        var lights = array_create(8);
        __collectObjectQueues(scene.children, lights, camera, opaqueQueue, transparentQueue);

        // Sort both queues before rendering
        __quickSortOpaqueObjects(opaqueQueue, 0, __opaqueIdx-1); // Front-to-back
        __quickSortTransparentObjects(transparentQueue, 0, __transparentIdx-1); // Back-to-front
        
        // Build the light and render state
        var lightState = __buildLightState(lights);
        var renderState = { renderer: self, scene, lightState, camera };
        
        // Render the objects opaque objects first
        __renderOpaqueObjects(opaqueQueue, renderState);
        __renderTransparentObjects(transparentQueue, renderState);
        
        // Reset world matrix after rendering
        matrix_set(matrix_world, matrix_build_identity()); 
        gpu_set_blendenable(currentBlendEnable);
        gpu_set_cullmode(currentCullMode);

        return self;
    }
}
