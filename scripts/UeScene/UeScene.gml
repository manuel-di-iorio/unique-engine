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
     * Write the scene data to a JSON object
     */
    function toJSON() {
        gml_pragma("forceinline");
        return {
            uuid,
            type,
            name,
            children: array_map(children, function(child) { 
                return child.toJSON();
            })
        };
    }
    
    /*
     * Load scene data from JSON
     * The children are linked using the objectsByUUID and materialsByUUID
     * Accepts an optional materialsByUUID parameter to link materials
     */
    function fromJSON(data, objectsByUUID = {}, materialsByUUID = {}) {
        gml_pragma("forceinline");

        uuid = data[$ "uuid"];
        name = data[$ "name"];

        for (var i = 0, il = array_length(data.children); i < il; i++) {
            var childData = data.children[i];
            
            if (is_struct(childData)) {
                var child;
                var type = childData[$ "type"];
                
                switch (type) {
                    case "Mesh": child = new UeMesh(); break;
                    case "Object3D": child = new UeObject3D(); break;
                    case "AmbientLight": child = new UeAmbientLight(); break;
                    case "PointLight": child = new UePointLight(); break;
                    case "DirectionalLight": child = new UeDirectionalLight(); break;
                    case "SpotLight": child = new UeSpotLight(); break;
                    case "HemisphereLight": child = new UeHemisphereLight(); break;
                    case "PerspectiveCamera": child = new UePerspectiveCamera(); break;
                    case "OrthographicCamera": child = new UeOrthographicCamera(); break;
                    default: child = new UeObject3D(); break;
                }
                
                // Recursively load child data
                if (type == "Mesh" || type == "Object3D" || type == "AmbientLight" || type == "PointLight" || type == "DirectionalLight" || type == "SpotLight" || type == "HemisphereLight") {
                    child.fromJSON(childData, objectsByUUID, materialsByUUID);
                } else {
                    child.fromJSON(childData);
                }
                
                add(child);
                
                // Link material if this is a mesh
                if (type == "Mesh") {
                    var matUUID = childData[$ "material"];
                    if (matUUID != undefined && materialsByUUID[$ matUUID] != undefined) {
                        child.material = materialsByUUID[$ matUUID];
                    }
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
