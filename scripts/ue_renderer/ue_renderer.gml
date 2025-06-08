function Renderer(data = {}): Object3D(data) constructor {
    
    // Recursively collect renderable objects and split them into opaque and transparent queues
    function _collectObjectQueues(objects, cameraPos, opaqueQueue, transparentQueue) {
        for (var i = 0, len = array_length(objects); i < len; i++) {
            var object = objects[i];
            if (object.visible && object.geometry) {
                // Precompute distance from camera for sorting
                object.__ueSortDistanceToCam = object.position.distanceSquaredTo(cameraPos);

                // Push to transparent or opaque queue based on material property
                array_push(object.material != undefined && object.material.transparent ? transparentQueue : opaqueQueue, object);
            }
            
            // Traverse child objects
            _collectObjectQueues(object.children, cameraPos, opaqueQueue, transparentQueue);
        } 
    }
    
    // Sort the objects of the same material type by using QuickSort.
    // Complexity: O(n log n) average, O(n^2) worst-case
    function _sortObjectsByCamDistance(arr, left, right, backToFront) {
        if (left >= right) return;

        // Use midpoint as pivot
        var pivot_dist = arr[(left + right) div 2].__ueSortDistanceToCam;
        var i = left;
        var j = right;
        var temp;

        while (i <= j) {
            if (backToFront) {
                // Transparent objects: sort back-to-front (increasing distance)
                while (arr[i].__ueSortDistanceToCam < pivot_dist) i++;
                while (arr[j].__ueSortDistanceToCam > pivot_dist) j--;
            } else {
                // Opaque objects: sort front-to-back (decreasing distance)
                while (arr[i].__ueSortDistanceToCam > pivot_dist) i++;
                while (arr[j].__ueSortDistanceToCam < pivot_dist) j--;
            }

            if (i <= j) {
                temp = arr[i];
                arr[i] = arr[j];
                arr[j] = temp;
                i++;
                j--;
            }
        }

        // Recursively sort the two partitions
        if (left < j) _sortObjectsByCamDistance(arr, left, j, backToFront);
        if (i < right) _sortObjectsByCamDistance(arr, i, right, backToFront);
    }
    
    // Render a list of opaque objects
    function _renderOpaqueObjects(objects, renderState) {
        for (var i = 0, len = array_length(objects); i < len; i++) {
            var child = objects[i];
            child.render(renderState);
        }
    }
    
    // Render a list of transparent objects with zwrite disabled
    // Also make a double draw call (if allowed) to mitigate transparency artifacts
    function _renderTransparentObjects(objects, renderState) {
        gpu_set_zwriteenable(false);
        
        for (var i = 0, len = array_length(objects); i < len; i++) {
            var child = objects[i];
            
            if (child.material != undefined && child.material.forceSinglePass) {
                child.render(renderState);
            } else {
                renderState.side = cull_clockwise;
                child.render(renderState);
                renderState.side = cull_counterclockwise;
                child.render(renderState);
                delete renderState.side;
            }
        }
        
        gpu_set_zwriteenable(true);
    }
    
    /// Render the scene
    function render(scene, camera) {
        var lightState = _buildLightState(scene.lights);
        var renderState = { scene, lightState, camera };
        
        // Collect and classify all renderable objects
        var opaqueQueue = [];
        var transparentQueue = [];
        var cameraPos = camera.position;
        _collectObjectQueues(scene.children, cameraPos, opaqueQueue, transparentQueue);

        // Sort both queues before rendering
        _sortObjectsByCamDistance(opaqueQueue, 0, array_length(opaqueQueue) - 1, false); // Front-to-back
        _sortObjectsByCamDistance(transparentQueue, 0, array_length(transparentQueue) - 1, true); // Back-to-front
        
        // Render the objects opaque objects first
        _renderOpaqueObjects(opaqueQueue, renderState);gpu_set_cullmode(cull_noculling);
        _renderTransparentObjects(transparentQueue, renderState); 
        
        // Reset world matrix after rendering
        matrix_set(matrix_world, matrix_build_identity()); 
        return self;
    }
    
    // Aggregate light data from scene lights
    function _buildLightState(lights) {
        var state = {
            ambient: [0, 0, 0],
            directional: [],
            point: []
        };
        
        for (var i = 0, len = array_length(lights); i < len; i++) {
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
        
        return state;
    }
}
