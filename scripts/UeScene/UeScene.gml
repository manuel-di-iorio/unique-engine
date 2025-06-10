function Scene(data = {}): Object3D(data) constructor {
    isScene = true;
    lights = [];
    
    /// @param ...objects
    function add() {
        for (var i=0; i<argument_count; i++) {
            var child = argument[i];
            child.parent = self;
            
            if (child[$ "isLight"] != undefined) {
                array_push(lights, child); 
                continue;
            }
             
            if (child[$ "isMesh"] != undefined) {
                //removeFromParent(child);
                array_push(children, child);
                continue;
            }
        } 
        
        return self;
    }
}