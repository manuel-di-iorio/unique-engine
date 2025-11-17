function UeScene(data = {}): UeObject3D(data) constructor {
    isScene = true;
    type = "Scene";
    
    /**
     * Override toJSON for scenes
     */
    function toJSON() {
        gml_pragma("forceinline");
        return {
            uuid,
            type,
            name,
            children: array_map(children, function(child) { 
                // For instances, save full metadata including transform
                if (child[$ "type"] == "ModelInstance") {
                    return {
                        uuid: child.uuid,
                        type: "ModelInstance",
                        name: child.name,
                        model: child.object != undefined ? child.object.uuid : undefined,
                        position: child.position.toArray(),
                        rotation: child.rotation.toArray(),
                        scale: child.scale.toArray(),
                        visible: child.visible,
                    };
                }
                // For other children, just save UUID
                return child[$ "uuid"];
            }),
        };
    }

    /*
     * Load scene data from JSON
     * The children are linked using the objectsByUUID
     */
    function fromJSON(data, objectsByUUID) {
        gml_pragma("forceinline");

        uuid = data[$ "uuid"];
        name = data[$ "name"];

        for (var i = 0, il = array_length(data.children); i < il; i++) {
            var child = data.children[i];
            
            // Check if child is a struct (ModelInstance with metadata) or just a UUID string
            if (is_struct(child)) {
                // ModelInstance: create instance from model and apply transform
                var modelUUID = child[$ "model"];
                if (modelUUID != undefined && objectsByUUID[$ modelUUID] != undefined) {
                    var model = objectsByUUID[$ modelUUID];
                    
                    // Create new instance with same geometry and material
                    var instance = new UeMesh(model.geometry, model.material);
                    instance.uuid = child[$ "uuid"];
                    instance.name = child[$ "name"];
                    instance.type = "ModelInstance";
                    instance.object = model;
                    instance.isInstance = true;
                    
                    // Apply transform
                    if (child[$ "position"] != undefined) instance.position.fromArray(child.position);
                    if (child[$ "rotation"] != undefined) instance.rotation.fromArray(child.rotation);
                    if (child[$ "scale"] != undefined) instance.scale.fromArray(child.scale);
                    if (child[$ "visible"] != undefined) instance.visible = child.visible;
                    
                    add(instance);
                }
            } else {
                // UUID string: link existing object
                var childUUID = child;
                if (objectsByUUID[$ childUUID] != undefined) {
                    var childObject = objectsByUUID[$ childUUID];
                    add(childObject);
                }
            }
        }
        
        return self;
    }
}
