function UeRaycaster(_origin = new UeVector3(), _direction = new UeVector3(0, 0, -1), _near = 0, _far = infinity) constructor {
    // Ray used for intersection tests
    self.ray = new UeRay(_origin, _direction);
    // Near and far clipping distances for raycasting
    self.near = _near;
    self.far = _far;
    // Camera associated with this raycaster (used for coordinate conversions)
    self.camera = undefined;

    // Parameters for intersection tests per object type
    // @todo unused for now
    self.params = {
        Mesh: {},
        Line: { threshold: 1 },
        LOD: {},
        Points: { threshold: 1 },
        Sprite: {}
    };
   
    /**
     * Sets the ray's origin and direction
     * @param {Struct} origin - The origin point of the ray
     * @param {Struct} direction - The normalized direction vector of the ray
     */
    function set(origin, direction) {
        self.ray.set(origin, direction);
        return self;
    }

    /**
     * Sets the ray from normalized device coordinates (NDC) and camera
     * Converts screen coordinates into a world-space ray
     * @param {UeVector3} coords - Coordinates in NDC space (-1 to 1)
     * @param {Object} camera - Camera object used for unprojection
     */
    function setFromCamera(coords, camera) {
        self.camera = camera;

        // Initialize origin and direction vectors
        var origin = new UeVector3();
        var dir = new UeVector3();

        if (camera.isPerspectiveCamera) {
            // For perspective camera, origin is camera position
            origin.copy(camera.position);
            // Direction is computed by unprojecting NDC point and normalizing
            dir.set(coords.x, coords.y, 0.5).unproject(camera).sub(camera.position).normalize();
        } else if (camera.isOrthographicCamera) {
            // For orthographic camera, origin is unprojected NDC with depth, direction is fixed
            origin.set(coords.x, coords.y, (camera.near + camera.far) / (camera.near - camera.far)).unproject(camera);
            dir.set(0, 0, -1).transformDirection(camera.matrixWorld);
        }

        self.ray.set(origin, direction);
        return self;
    }

    /**
     * Intersects the ray with an object and optionally its descendants recursively
     * @param {Struct} object - The object to test for intersections
     * @param {bool} recursive - Whether to check children recursively (default: true)
     * @param {Array} optionalTarget - Optional array to store intersection results
     * @returns {Array} Sorted array of intersection hits, closest first
     */
    function intersectObject(object, recursive = true, optionalTarget = []) {
        var hits = optionalTarget ?? [];

        // If the object has a raycast method, invoke it
        var objectRaycast = object[$ "raycast"];
        if (objectRaycast != undefined) {
            objectRaycast(self, hits);
        }

        // Recursively test child objects if requested
        if (recursive) {
            for (var i = 0, n = array_length(object.children); i < n; i++) {
                intersectObject(object.children[i], true, hits);
            }
        }

        // Sort intersections by distance ascending
        array_sort(hits, function (a, b) { return a.distance - b.distance; });

        return hits;
    }

    /**
     * Intersects the ray with multiple objects
     * @param {Array} objects - Array of objects to test intersections
     * @param {bool} recursive - Whether to check children recursively (default: true)
     * @param {Array} optionalTarget - Optional array to store intersection results
     * @returns {Array} Sorted array of intersection hits, closest first
     */
    function intersectObjects(objects, recursive = true, optionalTarget = []) {
        var hits = optionalTarget ?? [];

        for (var i = 0, n = array_length(objects); i < n; i++) {
            intersectObject(objects[i], recursive, hits);
        }

        // Sort intersections by distance ascending
        array_sort(hits, function (a, b) { return a.distance - b.distance; });

        return hits;
    }
}
