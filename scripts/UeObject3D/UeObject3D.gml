/**
 * Object3D
 */
function UeObject3D(data = {}): UeTransform(data) constructor {
    isObject3D = true;
    type = "Object3D";
    id = global.UE_OBJECT_ID++; 
    name = data[$ "name"] ?? "";
    uuid = ueUuid();
    visible = data[$ "visible"] ?? true;
    children = [];
    renderOrder = data[$ "renderOrder"] ?? 0;
    layers = new UeLayers();
    userData = {};
    frustumCulled = true;

    object = undefined; // @doc
    instances = new UeInstanceList(self); // @doc    
    isInstance = false; // @doc
    
    //animations = []; // @todo
    //castShadow = false; // @todo
    //receiveShadow = false; // @todo

    // Abstract methods
    function render() {}
    function onBeforeRender() {}
    function onAfterRender() {}
    //function onBeforeShadow() {} // @todo
    //function onAfterShadow() {} // @todo
    
    /**
     * Returns a clone of this object and optionally all descendants.
     * @param {bool} recursive If true, descendants of the object are also cloned. Default is true
     */
    function clone(recursive = true) {
        gml_pragma("forceinline");
        // @todo need to test the children array
        return variable_clone(self, recursive ? 128 : 0);
    }
    
    /// @param ...objects
    function add() {
        gml_pragma("forceinline");
        for (var i=0; i<argument_count; i++) {
            var objects = argument[i];
            if (!is_array(objects)) objects = [objects];

            for (var c = 0, cn = array_length(objects); c < cn; c++) {
                var object = objects[c];
                self.removeFromParent(object);
                object.parent = self;
                array_push(self.children, object);
            }
        }
        
        return self;
    }
    
    // Adds object as a child of this, while maintaining the object's world transform.
    // Note: This method does not support parents with non-uniform scaling.
    function attach(child) {
        gml_pragma("forceinline");
        removeFromParent(child);
        add(child);
        
        // Convert child's world transform into local relative to this object
        var localMatrix = matrixWorld.clone().invert().multiply(child.matrixWorld);
    
        // Decompose localMatrix into TRS and assign to child
        child.position.setFromMatrixPosition(localMatrix);
        child.rotation.setFromRotationMatrix(localMatrix);
        child.scale.setFromMatrixScale(localMatrix);
        
        // Immediately update the child matrixes to reflect the new transform
        child.updateWorldMatrix(false, true);
    
        return self;
    }

    /// Remove a child
    function remove(child) {
        gml_pragma("forceinline");
        removeFromParent(child);
        return self;
    }
    
    /// Remove this object from its parent
    function removeFromParent(_object = undefined) {
        gml_pragma("forceinline");
        _object = _object ?? self;
        if (_object.parent == undefined) return;
        var parentChildren = _object.parent.children;
        
        for (var i = array_length(parentChildren) - 1; i >= 0; i--) {
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
        gml_pragma("forceinline");
        for (var i=0, len=array_length(children); i<len; i++) {
            var child = children[i];
            child.clear();
        }
        
        children = [];
        parent = undefined; 
        return self;
    }
    
    /// Execute a callback on this object and its children
    /// Note: Modifying the scene graph inside the callback is discouraged.
    function traverse(callback) {
        gml_pragma("forceinline");
        callback(self);
        
        for (var i=0, len=array_length(children); i<len; i++) {
            children[i].traverse(callback);
        }
        
        return self;
    }
    
    /// Execute a callback on this object and its children, but only if they are visible.
    /// Descendants of invisible objects are not traversed.
    /// Note: Modifying the scene graph inside the callback is discouraged.
    function traverseVisible(callback) {
        gml_pragma("forceinline");
        if (visible) callback(self);
        
        for (var i=0, len=array_length(children); i<len; i++) {
            var child = children[i];
            if (child.visible) child.traverseVisible(callback);
        }
        
        return self;
    }
    
    // Executes the callback on all ancestors.
    // Note: Modifying the scene graph inside the callback is discouraged
    function traverseAncestors(callback) {
        gml_pragma("forceinline");
        var current = parent;
        while (current != undefined) {
            callback(current);
            current = current.parent;
        }
        return self;
    }
    
    // Executes the callback on all children of this object (not on the object itself)
    // @doc
    function traverseChildren(callback) {
        for (var i=0, len=array_length(children); i<len; i++) {
            with (children[i]) {
                callback();
                traverseChildren(callback);
            }
        }
        return self;
    }
    
    // Executes the callback on all instances of this object
    // @doc
    function traverseInstances(callback) {
        return instances.traverseInstances(callback);
    }
    
    /**
     * Copies the given object variables into this object. Note: Event listeners and user-defined callbacks (eg. .onAfterRender and .onBeforeRender) are not copied
     * @param {Struct} source object to copy into this one
     * @param {bool} recursive If set to true, descendants of the object are copied next to the existing ones. If set to false, descendants are left unchanged. Default is true.
     */
    function copy(source, recursive = true) {
        gml_pragma("forceinline");
        name = source.name;
        visible = source.visible;
        renderOrder = source.renderOrder;
        layers = variable_clone(source.layers);
        userData = variable_clone(source.userData);

        position.copy(source.position);
        rotation.copy(source.rotation);
        scale.copy(source.scale);
        up.copy(source.up);
        
        if (recursive) {
            for (var i = 0, n = array_length(source.children); i < n; i++) {
                add(source.children[i].clone(true));
            }
        }
        
        return self;
    }
    
    /**
     * Searches through an object and its children, starting with the object itself, and returns the first with a matching id.
     * Note that ids are assigned in chronological order: 1, 2, 3, ..., incrementing by one for each new object.     
     */
    function getObjectById(targetId) {
        gml_pragma("forceinline");
        if (self.id == targetId) return self;

        for (var i = 0, n = array_length(children); i < n; i++) {
            var result = children[i].getObjectById(targetId);
            if (result != undefined) return result;
        }
    
        return undefined;
    }
    
    /**
     * Searches through an object and its children, starting with the object itself, and returns the first with a matching name.
     * Note that for most objects the name is an empty string by default. You will have to set it manually to make use of this method.
     */
    function getObjectByName(name) {
        gml_pragma("forceinline");
        if (self.name == name) return self;

        for (var i = 0, n = array_length(children); i < n; i++) {
            var result = children[i].getObjectByName(name);
            if (result != undefined) return result;
        }
    
        return undefined;
    }
    
    /**
     * Searches through an object and its children, starting with the object itself, and returns the first with a property that matches the value given.
     */
    function getObjectByProperty(name, value) {
        gml_pragma("forceinline");
        if (self[$ name] == value) return self;
            
        for (var i = 0, n = array_length(children); i < n; i++) {
            var result = children[i].getObjectByProperty(name, value);
            if (result != undefined) return result;
        }
    
        return undefined;
    }
    
    /**
     * Searches through an object and its children, starting with the object itself, and returns all the objects with a property that matches the value given.
     * @param {string} name the property name to search for
     * @param {any} value value of the given property
     * @param {array} optionalTarget (optional) target to set the result. Otherwise a new Array is instantiated.
     */
    function getObjectsByProperty(name, value, optionalTarget = []) {
        gml_pragma("forceinline");
        if (self[$ name] == value) {
            array_push(optionalTarget, self);
        }
    
        for (var i = 0, n = array_length(children); i < n; i++) {
            children[i].getObjectsByProperty(name, value, optionalTarget);
        }
    
        return optionalTarget;
    }
    /**
     * Creates an instance with proper master-instance relationship (Unity Prefab-style)
     */
    function createInstance() {
        gml_pragma("forceinline");
        var instance = self.clone(true);
        instance.isInstance = true;
        instance.object = self;
        
        // Set isInstance = true on all descendants of the instance
        // instance.traverse(function(obj) {
        //     obj.isInstance = true;
        //     obj.object = self; // Point to the master object
        // });
        
        // Add to instances list
        instances.add(instance);
        
        return instance;
    }

    /**
     * Propagates multiple properties at once to all instances
     * @param {struct} properties - Object containing property-value pairs to propagate
     */
    function propagatePropsToInstances(properties) {
        gml_pragma("forceinline");
        var propertyNames = variable_struct_get_names(properties);
        
        for (var i = 0; i < array_length(propertyNames); i++) {
            var propName = propertyNames[i];
            self[$ propName] = properties[$ propName];
        }
        
        return self;
    }
  
    
    // Initial matrix build
    updateMatrix();
}
