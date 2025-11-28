function UeRaycaster(_origin = undefined, _direction = undefined, _near = 0, _far = infinity) constructor {
    // Ray used for intersection tests
    self.ray = new UeRay(_origin, _direction);
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
        Mesh: {},
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
        self.ray.set(origin, direction);
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
            // For perspective camera, origin is camera position
            global.UE_DUMMY_VECTOR3.copy(camera.position);
            // Direction is computed by unprojecting NDC point and normalizing
            global.UE_DUMMY_VECTOR3_B.set(mouse.ndcX, mouse.ndcY, 0.5)
                .unproject(camera)
                .sub(camera.position)
                .normalize();
        } else if (camera.isOrthographicCamera) {
            // For orthographic camera, origin is unprojected NDC with depth, direction is fixed
            global.UE_DUMMY_VECTOR3.set(mouse.ndcX, mouse.ndcY, (camera.near + camera.far) / (camera.near - camera.far))
                .unproject(camera);
            global.UE_DUMMY_VECTOR3_B.copy(global.UE_OBJECT3D_DEFAULT_UP).transformDirection(camera.matrixWorld);
        }

        self.ray.set(global.UE_DUMMY_VECTOR3, global.UE_DUMMY_VECTOR3_B);
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
