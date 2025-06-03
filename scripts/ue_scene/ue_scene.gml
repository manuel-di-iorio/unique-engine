function Scene(data = {}): Object3D(data) constructor {
    lights = [];
    
    function add(_children) {
        if (!is_array(_children)) _children = [_children];
            
        for (var i=0, len=array_length(_children); i<len; i++) {
            var child = _children[i];
            switch (child.type) {
                case "Light": array_push(lights, child); break;
                default: array_push(children, child);
            }
            
            child.parent = self;
        } 
        
        return self;
    }
}