// Represents a list of instances for an object
function UeInstanceList(object) constructor {
    list = [];
    self.object = object;
    
    function add(instance) {
        gml_pragma("forceinline");
        array_push(list, instance);
        instance.object = object;
        return self;
    }
    
    function traverseInstances(cb) {
        gml_pragma("forceinline");
        for (var i = 0, l = array_length(list); i < l; i++) {
            with (list[i]) cb();
        }
        return self;
    }
    
    function remove(instance) {
        gml_pragma("forceinline");
        for (var i = array_length(list) - 1; i >= 0; i--) {
            var child = list[i];
            if (child == instance) {
                array_delete(list, i, 1);
                child.removeFromParent();
                break;
            }
        }
        return self;
    }
    
    function clear() {
        gml_pragma("forceinline");
        list = [];
        return self;
    }
    
    function count() {
        gml_pragma("forceinline");
        return array_length(list);
    }
}