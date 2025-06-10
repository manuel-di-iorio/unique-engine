global.UNIQUE_ENGINE_OBJECT_ID = 0;

function Object3D(data = {}): Transform(data) constructor {
    isObject3D = true;
    id = global.UNIQUE_ENGINE_OBJECT_ID++; 
    name = data[$ "name"] ?? undefined;
    uuid = uuid_generate();
    visible = data[$ "visible"] ?? true;
    parent = data[$ "parent"] ?? undefined;
    children = [];
    renderOrder = data[$ "renderOrder"] ?? 0;

    function render() {}
    
    /// @param ...objects
    function add() {
        for (var i=0; i<argument_count; i++) {
            var child = argument[i];
            child.parent = self;
            //removeFromParent(child);
            array_push(children, child);
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
        if (_object.parent == undefined) return;
        var parentChildren = _object.parent.children;
        
        for (var i = 0, len = array_length(parentChildren); i < len; i++) {
            if (parentChildren[i] == _object) {
                array_delete(parentChildren, i, 1);
                break;
            }
        }
        
        _object.parent = undefined;
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