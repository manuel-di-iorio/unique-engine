function Object3D(data = {}): Transform(data) constructor {
    name = data[$ "name"] ?? undefined; 
    visible = data[$ "visible"] ?? true;
    parent = data[$ "parent"] ?? undefined;
    children = [];
    matrixAutoUpdate = true;

    /// Add a child
    function add(_children) {
        if (!is_array(_children)) _children = [_children];
            
        for (var i=0, len=array_length(_children); i<len; i++) {
            var child = _children[i];
            array_push(children, child);
            child.parent = self;
        }
        
        return self;
    }

    /// Remove a child
    function remove(child) {
        for (var i = 0, len = array_length(children); i < len; i++) {
            if (children[i] == child) {
                array_delete(children, i, 1);
                break;
            }
        }
        child.parent = undefined;
        return self;
    }
}
