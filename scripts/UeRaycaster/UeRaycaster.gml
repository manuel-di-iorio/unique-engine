/// @MissingDoc UeRaycaster
function UeRaycaster(_origin = new UeVector3(), _direction = new UeVector3(0, 0, -1), _near = 0, _far = infinity) constructor {
    self.ray = new UeRay(_origin, _direction);
    self.near = _near;
    self.far = _far;
    self.camera = undefined;
    self.params = {
        Mesh: {},
        Line: { threshold: 1 },
        LOD: {},
        Points: { threshold: 1 },
        Sprite: {}
    };
   
    function set(origin, direction) {
        self.ray.set(origin, direction);
    }

    function setFromCamera(coords, camera) {
        self.camera = camera;

        // NDC -> World space
        var origin = new UeVector3();
        var dir = new UeVector3();

        if (camera.isPerspectiveCamera) {
            origin.copy(camera.position);
            dir.set(coords.x, coords.y, 0.5).unproject(camera).sub(camera.position).normalize();
        } else if (camera.isOrthographicCamera) {
            origin.set(coords.x, coords.y, (camera.near + camera.far) / (camera.near - camera.far)).unproject(camera);
            dir.set(0, 0, -1).transformDirection(camera.matrixWorld);
        }

        self.ray.set(origin, direction);
    }

    function intersectObject(object, recursive = true, optionalTarget = []) {
        var hits = optionalTarget ?? [];

        var objectRaycast = object[$ "raycast"];
        if (objectRaycast != undefined) {
            objectRaycast(self, hits);
        }

        if (recursive) {
            for (var i = 0, n = array_length(object.children); i < n; i++) {
                intersectObject(object.children[i], true, hits);
            }
        }

        array_sort(hits, function (a, b) { return a.distance - b.distance; });

        return hits;
    }

    function intersectObjects(objects, recursive = true, optionalTarget = []) {
        var hits = optionalTarget ?? [];

        for (var i = 0, n = array_length(objects); i < n; i++) {
            intersectObject(objects[i], recursive, hits);
        }

        array_sort(hits, function (a, b) { return a.distance - b.distance; });

        return hits;
    }
}
