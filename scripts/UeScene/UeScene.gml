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
}
