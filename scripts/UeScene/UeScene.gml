function UeScene(data = {}): UeObject3D(data) constructor {
    isScene = true;
    type = "Scene";
    lights = [];
    
    /// @param ...objects
    function add() {
        for (var i=0; i<argument_count; i++) {
            var objects = argument[i];
            if (!is_array(objects)) objects = [objects];

            for (var c = 0, cn = array_length(objects); c < cn; c++) {
                var object = objects[c];
                object.parent = self;
                
                switch (object.type) {
                    case "Light": 
                        array_push(lights, object); 
                        break;
                    
                    case "Mesh":
                        removeFromParent(object);
                        array_push(children, object);
                        break;
                }
            }
        } 
        
        return self;
    }
}