function UeScene(data = {}): UeObject3D(data) constructor {
    isScene = true;
    type = "Scene";
    overrideMaterial = data[$ "overrideMaterial"];
    
    // Fog configuration
    self.fog = data[$ "fog"] ?? {
        color: [0.5, 0.5, 0.5],
        density: 0,
        near: 1,
        far: 1000,
        enabled: false
    };
    
    /**
     * Helper function to serialize a ModelInstance recursively
     */
    function __serializeInstance(instance) {
        var data = {
            uuid: instance.uuid,
            type: instance.type,
            name: instance.name,
            model: instance.object != undefined ? instance.object.uuid : undefined,
            position: instance.position,
            rotation: instance.rotation,
            scale: instance.scale,
            visible: instance.visible,
            castShadow: instance.castShadow,
            receiveShadow: instance.receiveShadow
        };
        
        // Recursively serialize children (submeshes)
        if (array_length(instance.children) > 0) {
            data.children = array_map(instance.children, function(child) {
                if (child[$ "isInstance"] == true) {
                    return __serializeInstance(child);
                }
                // For non-instance children, just save UUID
                return child[$ "uuid"];
            });
        }
        
        return data;
    }
    
    /**
     * Write the scene data to a JSON object
     */
    function toJSON() {
        gml_pragma("forceinline");
        return {
            uuid,
            type,
            name,
            children: array_map(children, function(child) { 
                // For instances, save full metadata including transform and children
                if (child[$ "isInstance"] == true) {
                    return __serializeInstance(child);
                }
                // For other children, just save UUID
                return child[$ "uuid"];
            })
        };
    }
    
    /**
     * Helper function to deserialize a ModelInstance recursively
     */
    function __deserializeInstance(data, objectsByUUID, parent) {
        var modelUUID = data[$ "model"];
        
        if (modelUUID == undefined || objectsByUUID[$ modelUUID] == undefined) {
            return undefined;
        }
        
        var model = objectsByUUID[$ modelUUID];
        var instance;
        
        if (data.type == "Object3DInstance") {
             instance = new UeObject3D();
        } else {
             // Create new instance with same geometry and material
             instance = new UeMesh(model.geometry, model.material);
        }

        instance.uuid = data[$ "uuid"];
        instance.name = data[$ "name"];
        instance.type = data[$ "type"];
        instance.object = model;
        instance.isInstance = true;
        
        // Register instance in the master model's instances list
        model.instances.add(instance);
        
        // Apply transform
        if (data[$ "position"] != undefined) {
            vec3_copy(instance.position, data.position);
        }
        if (data[$ "rotation"] != undefined) {
            quat_copy(instance.rotation, data.rotation);
        }
        if (data[$ "scale"] != undefined) {
            vec3_copy(instance.scale, data.scale);
        }
        if (data[$ "visible"] != undefined) {
            instance.visible = data.visible;
        }
        
        instance.castShadow = data[$ "castShadow"] ?? false;
        instance.receiveShadow = data[$ "receiveShadow"] ?? false;

        if (data[$ "matrixAutoUpdate"] != undefined) {
            instance.matrixAutoUpdate = data.matrixAutoUpdate;
        }
        if (data[$ "frustumCulled"] != undefined) {
            instance.frustumCulled = data.frustumCulled;
        }
        
        // Initialize editor-specific rotation tracker
        instance.__rotationEuler = euler_clone(instance.rotation);
        
        instance.updateMatrix();
        
        // Recursively load children (submeshes)
        if (data[$ "children"] != undefined && array_length(data.children) > 0) {
            for (var i = 0; i < array_length(data.children); i++) {
                var childData = data.children[i];
                
                if (is_struct(childData)) {
                    // Recursive ModelInstance
                    var childInstance = __deserializeInstance(childData, objectsByUUID, instance);
                    if (childInstance != undefined) {
                        instance.add(childInstance);
                    }
                } else {
                    // UUID reference
                    var childUUID = childData;
                    if (objectsByUUID[$ childUUID] != undefined) {
                        instance.add(objectsByUUID[$ childUUID]);
                    }
                }
            }
        }
        
        return instance;
    }

    /*
     * Load scene data from JSON
     * The children are linked using the objectsByUUID
     */
    function fromJSON(data, objectsByUUID = {}) {
        gml_pragma("forceinline");

        uuid = data[$ "uuid"];
        name = data[$ "name"];

        for (var i = 0, il = array_length(data.children); i < il; i++) {
            var child = data.children[i];
            
            // Check if child is a struct (ModelInstance with metadata) or just a UUID string
            if (is_struct(child)) {
                // ModelInstance: create instance from model and apply transform recursively
                var instance = __deserializeInstance(child, objectsByUUID, self);
                if (instance != undefined) {
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

    /**
     * Returns a clone of this scene and optionally all descendants.
     */
    function clone(recursive = true) {
         var _newScene = new UeScene();
         _newScene.overrideMaterial = self.overrideMaterial;
         _newScene.copy(self, recursive);
         
         return _newScene;
    }
}
