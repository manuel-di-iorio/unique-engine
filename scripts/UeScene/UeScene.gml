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
