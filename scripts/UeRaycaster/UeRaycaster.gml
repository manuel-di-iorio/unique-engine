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
     * @param {Real} mx - device_mouse_get_x() or device_mouse_x_to_gui(0)
     * @param {Real} my - device_mouse_get_y() or device_mouse_y_to_gui(0)
     * @param {Struct} camera - Camera object used for unprojection
     */
    function setFromCamera(mx, my, camera) {
        self.camera = camera;
        
        // Normalize the mouse coordinates
        // @todo May use a more generalized way to obtain the screen size
        var screenW = window_get_width();
        var screenH = window_get_height();
        if (!screenW || !screenH) return self;
            
        var ndcX = (mx / window_get_width()) * 2 - 1;
        var ndcY = ((my / window_get_width()) * 2 - 1); 

        // Initialize origin and direction vectors
        var origin = new UeVector3();
        var dir = new UeVector3();

        if (camera.isPerspectiveCamera) {
            // For perspective camera, origin is camera position
            origin.copy(camera.position);
            // Direction is computed by unprojecting NDC point and normalizing
            dir.set(ndcX, ndcY, 0.5).unproject(camera).sub(camera.position).normalize();
        } else if (camera.isOrthographicCamera) {
            // For orthographic camera, origin is unprojected NDC with depth, direction is fixed
            origin.set(ndcX, ndcY, (camera.near + camera.far) / (camera.near - camera.far)).unproject(camera);
            dir.set(0, 0, -1).transformDirection(camera.matrixWorld);
        }

        self.ray.set(origin, dir);
        return self;
    }

    /**
     * Intersects the ray with an object and optionally its descendants recursively
     * @param {Struct} object - The object to test for intersections
     * @param {bool} recursive - Whether to check children recursively (default: true)
     * @param {Array} hits - Optional array to store intersection results
     * @returns {Array} Sorted array of intersection hits, closest first
     */
    function intersectObject(object, recursive = true, hits = []) {
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
     * @param {Array} hits - Optional array to store intersection results
     * @returns {Array} Sorted array of intersection hits, closest first
     */
    function intersectObjects(objects, recursive = true, hits = []) {
        for (var i = 0, n = array_length(objects); i < n; i++) {
            intersectObject(objects[i], recursive, hits);
        }

        // Sort intersections by distance ascending
        array_sort(hits, function (a, b) { return a.distance - b.distance; });

        return hits;
    }
}
