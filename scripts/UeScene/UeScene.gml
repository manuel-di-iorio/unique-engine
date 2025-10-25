function UeScene(data = {}): UeObject3D(data) constructor {
    isScene = true;
    type = "Scene";
    
    /**
     * Override toJSON for scenes
     */
    function toJSON() {
        gml_pragma("forceinline");
        return {
            children: array_map(children, function(child) { return child[$ "uuid"] }),
        };
    }

    /*
     * Load scene data from JSON
     * The children are linked using the objectsByUUID
     */
    function fromJSON(data, objectsByUUID) {
        gml_pragma("forceinline");

        for (var i = 0, il = array_length(data.children); i < il; i++) {
            var child = data.children[i];
            var uuid = child.uuid;

            if (objectsByUUID[$ uuid] != undefined) {
                var childObject = objectsByUUID[$ uuid];
                add(childObject);
            }
        }
    }
}
