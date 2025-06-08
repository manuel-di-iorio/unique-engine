function Scene(data = {}): Object3D(data) constructor {
    lights = [];
    
    /// @param ...objects
    function add() {
        for (var i=0; i<argument_count; i++) {
            var child = argument[i];
            
            switch (child.type) {
                case "Light": 
                    array_push(lights, child); 
                break;
                
                default: 
                    removeFromParent(child);
                    array_push(children, child);
            }
            
            child.parent = self;
        } 
        
        return self;
    }
}