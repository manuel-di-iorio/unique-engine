function Object3D(data = {}): Transform(data) constructor {
    name = data[$ "name"] ?? undefined; 
    visible = data[$ "visible"] ?? true;
    parent = data[$ "parent"] ?? undefined;
    children = [];

    /// Add a child. If the child already has a parent, it will be removed from it parent first
    function add(_children) {
        if (!is_array(_children)) _children = [_children];
            
        for (var i=0, len=array_length(_children); i<len; i++) {
            var child = _children[i];
            removeFromParent(child);
            array_push(children, child);
            child.parent = self;
        }
        
        return self;
    }

    /// Remove a child
    function remove(child) {
        removeFromParent(child);
        return self;
    }
    
    /// Remove this object from its parent
    function removeFromParent(_object = undefined) {
        _object = _object ?? self;
        if (!_object.parent) return;
        var parentChildren = _object.parent.children;
        
        for (var i = 0, len = array_length(parentChildren); i < len; i++) {
            if (parentChildren[i] == child) {
                array_delete(parentChildren, i, 1);
                break;
            }
        }
        
        object.parent = undefined;
        return self;
    }
    
    /// Remove all children
    function clear() {
        for (var i=0, len=array_length(children); i<len; i++) {
            var child = children[i];
            child.clear();
        }
        
        children = [];
        parent = undefined; 
    }
    
    /// Execute a callback on this object and its children
    function traverse(callback) {
        callback(self);
        
        for (var i=0, len=array_length(children); i<len; i++) {
            callback(children[i]);
        }
    }
    
    /// Execute a callback on this object and its children, but only if they are visible
    function traverseVisible(callback) {
        if (visible) callback(self);
        
        for (var i=0, len=array_length(_children); i<len; i++) {
            var child = children[i];
            if (child.visible) callback(child);
        }
    }
}