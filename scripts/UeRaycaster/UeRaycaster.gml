function UeRaycaster(_origin = undefined, _direction = undefined, _near = 0, _far = infinity) constructor {
    // Ray used for intersection tests (array: [ox,oy,oz, dx,dy,dz])
    self.ray = ray_create(
        0, 0, 0,
        0, 0, -1
    );
    // Near and far clipping distances for raycasting
    self.near = _near;
    self.far = _far;
    // Camera associated with this raycaster (used for coordinate conversions)
    self.camera = undefined;
    // Raycaster layers. Objects being tested must share at least one layer with the raycaster
    self.layers = new UeLayers(); 
    
    /**
     * Raycasting parameters for different object types
     * @property {Struct} Mesh - Parameters for mesh intersection
     * @property {Struct} Line - Parameters for line intersection (e.g. threshold)
     * @property {Struct} Points - Parameters for points intersection (e.g. threshold)
     */
    self.params = {
        Mesh: { precise: false },
        Line: { threshold: 4 },
        Points: { threshold: 1 },
    };
   
    /**
     * Sets the ray's origin and direction
     * @param {Struct} origin - The origin point of the ray
     * @param {Struct} direction - The normalized direction vector of the ray
     */
    function set(origin, direction) {
        gml_pragma("forceinline");
        var ox, oy, oz, dx, dy, dz;
        ox = origin[0]; oy = origin[1]; oz = origin[2];
        dx = direction[0]; dy = direction[1]; dz = direction[2];
        var len = sqrt(dx*dx + dy*dy + dz*dz);
        if (len > 0) { var inv = 1/len; dx*=inv; dy*=inv; dz*=inv; }
        ray_set(self.ray, ox, oy, oz, dx, dy, dz);
        return self;
    }

    /**
     * Sets the ray from normalized device coordinates (NDC) and camera
     * Converts mouse coordinates into a world-space ray
     * @param {Struct} camera - Camera object used for unprojection
     */
    function setFromCamera(camera) {
        gml_pragma("forceinline");
        self.camera = camera;
        
        var mouse = global.UE_MOUSE.get();

        if (camera.isPerspectiveCamera) {
            var origin = camera.position;
            
            var ndc = global.UE_VEC3_TEMP0;
            vec3_set(ndc, mouse.ndcX, mouse.ndcY, 0.5);
            
            var worldPoint = global.UE_VEC3_TEMP1;
            vec3_copy(worldPoint, ndc);
            vec3_apply_matrix4(worldPoint, camera.projectionMatrixInverse);
            vec3_apply_matrix4(worldPoint, camera.matrixWorld);
            
            var dir = global.UE_VEC3_TEMP2;
            vec3_sub_vectors(dir, worldPoint, origin);
            vec3_normalize(dir);
            ray_set(self.ray, origin[0], origin[1], origin[2], dir[0], dir[1], dir[2]);
          
        } else if (camera.isOrthographicCamera) {
            var invProj = global.UE_MAT4_TEMP0;
            mat4_copy(invProj, camera.projectionMatrix);
            mat4_invert(invProj);
            
            var originVec = global.UE_VEC3_TEMP0;
            vec3_set(originVec, mouse.ndcX, mouse.ndcY, (camera.near + camera.far) / (camera.near - camera.far));
            vec3_apply_matrix4(originVec, invProj);
            vec3_apply_matrix4(originVec, camera.matrixWorld);
            
            var dirVec = global.UE_VEC3_TEMP1;
            vec3_set(dirVec, 0, 1, 0);
            vec3_transform_direction(dirVec, camera.matrixWorld);
            ray_set(self.ray, originVec[0], originVec[1], originVec[2], dirVec[0], dirVec[1], dirVec[2]);
        }
        return self;
    }

    /**
     * Intersects the ray with an object and optionally its descendants recursively
     * @param {Struct} object - The object to test for intersections
     * @param {bool} recursive - Whether to check children recursively (default: true)
     * @param {bool} sort - Whether to automatically sort the hits based on the camera distance
     * @param {Array} hits - Optional array to store intersection results
     * @returns {Array} Sorted array of intersection hits, closest first
     */
    function intersectObject(object, recursive = true, sort = true, hits = undefined) {
        gml_pragma("forceinline");
        hits ??= [];
        
        // If the object has a raycast method, invoke it
        if (object.visible && object[$ "geometry"] && layers.test(object.layers)) {
            var objectRaycast = object[$ "raycast"];
            if (objectRaycast != undefined) { 
                objectRaycast(self, hits);
            }
        }

        // Recursively test child objects if requested
        if (recursive) {
            for (var i = 0, n = array_length(object.children); i < n; i++) {
                intersectObject(object.children[i], true, sort, hits);
            }
        }

        // Sort intersections by distance ascending
        if (sort) array_sort(hits, function (a, b) { return a.distance - b.distance; });

        return hits;
    }

    /**
     * Intersects the ray with multiple objects
     * @param {Array} objects - Array of objects to test intersections
     * @param {bool} recursive - Whether to check children recursively (default: true)
     * @param {bool} sort - Whether to automatically sort the hits based on the camera distance
     * @param {Array} hits - Optional array to store intersection results
     * @returns {Array} Sorted array of intersection hits, closest first
     */
    function intersectObjects(objects, recursive = true, sort = true, hits = undefined) {
        gml_pragma("forceinline");
        hits ??= [];
        for (var i = 0, n = array_length(objects); i < n; i++) {
            intersectObject(objects[i], recursive, false, hits);
        }

        // Sort intersections by distance ascending
        if (sort) array_sort(hits, function (a, b) { return a.distance - b.distance; });

        return hits;
    }
}
