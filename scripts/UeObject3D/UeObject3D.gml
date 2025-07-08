global.UNIQUE_ENGINE_OBJECT_ID = 0;
global.UE_DEFAULT_VERTEX_FORMAT = new UeVertexFormat().position().normal().uv().color().build();

enum UE_UNIFORM_TYPE {
    FLOAT = 0,
    VEC2 = 1,
    VEC3 = 2,
    VEC4 = 3,
    MAT4 = 4,
    ARRAY = 5,
    BUFFER = 6
}

enum UE_FORMAT_ATTR {
    POSITION = 0,
    NORMAL = 1,
    UV = 2,
    COLOR = 3,
    CUSTOM = 4
}

/**
 * Object3D
 */
function UeObject3D(data = {}): UeTransform(data) constructor {
    isObject3D = true;
    type = "Object3D"; // @MissingDoc
    id = global.UNIQUE_ENGINE_OBJECT_ID++; 
    name = data[$ "name"] ?? undefined;
    uuid = ueUuid();
    visible = data[$ "visible"] ?? true;
    children = [];
    renderOrder = data[$ "renderOrder"] ?? 0;

    function render() {}
    
    /// @MissingDoc array of objects
    /// @param ...objects
    function add() {
        for (var i=0; i<argument_count; i++) {
            var objects = argument[i];
            if (!is_array(objects)) objects = [objects];

            for (var c = 0, cn = array_length(objects); c < cn; c++) {
                var object = objects[c];
                removeFromParent(object);
                object.parent = self;
                array_push(children, object);
            }
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