/**
 * Object3D
 */

// @todo add static
// Ctrl+H function\s+(\w+)\((?!.*\)\s*constructor) static $1 = function(
function UeObject3D(data = {}): UeTransform(data) constructor {
    isObject3D = true;
    type = "Object3D";
    id = global.UE_OBJECT_ID++;
    name = data[$ "name"] ?? "";
    uuid = ueUuid();
    visible = data[$ "visible"] ?? true;
    renderOrder = data[$ "renderOrder"] ?? 0;
    layers = new UeLayers();
    userData = {};
    frustumCulled = true;
    castShadow = data[$ "castShadow"] ?? false;
    receiveShadow = data[$ "receiveShadow"] ?? false;
    selectable = data[$ "selectable"] ?? true;
    gmObject = data[$ "gmObject"] ?? undefined;
    gmLayer = data[$ "gmLayer"] ?? "Instances";

    // /** @type {Struct} Map of properties that have been overridden locally on this instance */
    // __localOverrides = data[$ "__localOverrides"] ?? {};
    /** @type {UeObject3D} Reference to the prefab this object is an instance of (Scene Editor) */
    prefab = data[$ "prefab"] ?? undefined;

    /** @type {Array<UeAnimation>} List of animations associated with this node */
    animations = [];

    /** @type {UeSkeleton} The skeleton associated with this object for skinning (
     * @note This is not actually used in Object3D, only in Meshes) */
    skeleton = undefined;

    // Abstract methods
    function render() { }
    function onBeforeRender() { }
    function onAfterRender() { }
    function onBeforeShadow() { }
    function onAfterShadow() { }

    // @todo
    /**
     * Set a property and mark it as a local override if this is an instance
     * @param {string} field The property name
     * @param {any} value The new value
     */
    // function setOverride(field, value) {
    //     self[$ field] = value;
    //     if (prefab != undefined) {
    //         __localOverrides[$ field] = true;
    //     }
    // }

    /**
     * Sync properties from a prefab, respecting local overrides
     * @param {UeObject3D} prefabSource The source prefab
     */
    // function syncFromPrefab(prefabSource) {
    //     if (prefabSource == undefined) return;
        
    //     var fields = ["name", "visible", "renderOrder", "frustumCulled", "castShadow", "receiveShadow", "gmObject", "gmLayer", "matrixAutoUpdate"];
    //     for (var i = 0; i < array_length(fields); i++) {
    //         var f = fields[i];
    //         if (__localOverrides[$ f] == undefined) {
    //             self[$ f] = prefabSource[$ f];
    //         }
    //     }

    //     // Sync transforms if not overridden
    //     if (__localOverrides[$ "position"] == undefined) vec3_copy(position, prefabSource.position);
    //     if (__localOverrides[$ "rotation"] == undefined) quat_copy(rotation, prefabSource.rotation);
    //     if (__localOverrides[$ "scale"] == undefined) vec3_copy(scale, prefabSource.scale);
        
    //     // Update matrix after sync
    //     updateMatrix();
    // }

    /**
     * Returns a clone of this object and optionally all descendants.
     * @param {bool} recursive If true, descendants of the object are also cloned. Default is true
     */
    function clone(recursive = true) {
        gml_pragma("forceinline");
        var _clone = new UeObject3D();
        _clone.copy(self, recursive);
        return _clone;
    }

    /// @param ...objects
    function add() {
        gml_pragma("forceinline");
        for (var i = 0; i < argument_count; i++) {
            var objects = argument[i];
            if (!is_array(objects)) objects = [objects];

            for (var c = 0, cn = array_length(objects); c < cn; c++) {
                var object = objects[c];
                self.removeFromParent(object);
                object.parent = self;
                array_push(self.children, object);
                object.dispatch({ type: "added" });
                self.dispatch({ type: "childAdded" });
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
        var localMatrix = mat4_clone(matrixWorld);
        matrix_inverse(localMatrix, localMatrix);
        mat4_multiply(localMatrix, child.matrixWorld);

        // Decompose localMatrix into TRS and assign to child
        vec3_set_from_matrix_position(child.position, localMatrix);
        quat_set_from_rotation_matrix(child.rotation, localMatrix);
        vec3_set_from_matrix_scale(child.scale, localMatrix);

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
        var _parent = _object.parent;
        var parentChildren = _parent.children;

        for (var i = array_length(parentChildren) - 1; i >= 0; i--) {
            if (parentChildren[i] == _object) {
                array_delete(parentChildren, i, 1);
                break;
            }
        }

        _object.dispatch({ type: "removed" });
        _parent.dispatch({ type: "childRemoved" });
        _object.parent = undefined;
        return self;
    }

    /// Remove all children
    function clear(recursive = false) {
        gml_pragma("forceinline");

        for (var i = array_length(children) - 1; i >= 0; i--) {
            var child = children[i];

            if (recursive) {
                child.clear(true);
            }

            child.parent = undefined;
            child.dispatch({ type: "removed" });
        }

        children = [];
        self.dispatch({ type: "childRemoved" });
        return self;
    }

    /// Execute a callback on this object and its children
    /// Note: Modifying the scene graph inside the callback is discouraged.
    function traverse(callback) {
        gml_pragma("forceinline");
        callback(self);

        for (var i = 0, len = array_length(children); i < len; i++) {
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

        for (var i = 0, len = array_length(children); i < len; i++) {
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
        for (var i = 0, len = array_length(children); i < len; i++) {
            with (children[i]) {
                callback();
                traverseChildren(callback);
            }
        }
        return self;
    }

    /**
     * Synchronizes properties from the source prefab, respecting local overrides.
     * @param {Struct} source - The prefab object to sync from
     */
    // function syncFromPrefab(source) {
    //     gml_pragma("forceinline");
    //     // Only sync if it's the correct prefab
    //     if (self.prefab != source) return;

    //     // Sync basic properties (can be expanded with local overrides logic)
    //     visible = source.visible;
    //     renderOrder = source.renderOrder;
    //     layers.mask = source.layers.mask;
    //     frustumCulled = source.frustumCulled;
    //     castShadow = source.castShadow;
    //     receiveShadow = source.receiveShadow;
        
    //     // Sync Mesh specific properties
    //     if (struct_exists(self, "isMesh") && self.isMesh && struct_exists(source, "isMesh") && source.isMesh) {
    //         geometry = source.geometry;
    //         material = source.material;
    //     }

    //     // Note: position, rotation, scale are usually NOT synced from prefab 
    //     // as instances have their own transforms in the scene.
    // }

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
        layers.mask = source.layers.mask;
        userData = variable_clone(source.userData);
        frustumCulled = source.frustumCulled;
        castShadow = source.castShadow;
        receiveShadow = source.receiveShadow;
        selectable = source.selectable;
        gmObject = source[$ "gmObject"];
        gmLayer = source[$ "gmLayer"];
        matrixAutoUpdate = source.matrixAutoUpdate;
        matrixWorldAutoUpdate = source.matrixWorldAutoUpdate;
        prefab = source[$ "prefab"];
        // __localOverrides = variable_clone(source[$ "__localOverrides"] ?? {});

        var _sourceGeometry = source[$ "geometry"];
        if (_sourceGeometry != undefined) {
            geometry = _sourceGeometry;
        }

        var _sourceMaterial = source[$ "material"];
        if (_sourceMaterial != undefined) {
            material = _sourceMaterial;
        }

        vec3_copy(position, source.position);
        quat_copy(rotation, source.rotation);
        vec3_copy(scale, source.scale);
        vec3_copy(up, source.up);

        if (recursive) {
            for (var i = 0, n = array_length(source.children); i < n; i++) {
                add(source.children[i].clone(true));
            }
        }

        return self;
    }

    function toJSON(recursive = false) {
        gml_pragma("forceinline");
        return {
            uuid,
            type,
            name,
            children: recursive 
                ? array_map(children, function (child) { return child.toJSON(true); })
                : array_map(children, function (child) { return child.uuid }),
            visible,
            parent: parent ? parent.uuid : undefined,
            renderOrder,
            layers: layers.mask,
            matrixAutoUpdate,
            frustumCulled,
            castShadow,
            receiveShadow,
            selectable,
            gmObject,
            gmLayer,
            prefab: prefab ? prefab.uuid : undefined,
            // __localOverrides,

            position,
            rotation,
            scale,
            up,
            sourcePath: self[$ "sourcePath"],
        };
    }

    function fromJSON(data, objectsByUUID = {}, materialsByUUID = {}, geometriesByUUID = {}) {
        gml_pragma("forceinline");
        uuid = data[$ "uuid"] ?? uuid;
        name = data[$ "name"] ?? name;
        sourcePath = data[$ "sourcePath"] ?? undefined;
        visible = data[$ "visible"] ?? true;
        renderOrder = data[$ "renderOrder"] ?? 0;

        if (data[$ "layers"] != undefined) layers.mask = data.layers;

        if (data[$ "position"] != undefined) vec3_copy(position, data.position);
        if (data[$ "rotation"] != undefined) quat_copy(rotation, data.rotation);
        if (data[$ "scale"] != undefined) vec3_copy(scale, data.scale);
        if (data[$ "up"] != undefined) vec3_copy(up, data.up);

        matrixAutoUpdate = data[$ "matrixAutoUpdate"] ?? true;
        frustumCulled = data[$ "frustumCulled"] ?? true;
        castShadow = data[$ "castShadow"] ?? false;
        receiveShadow = data[$ "receiveShadow"] ?? false;
        selectable = data[$ "selectable"] ?? true;
        gmObject = data[$ "gmObject"];
        gmLayer = data[$ "gmLayer"] ?? "Instances";
        // __localOverrides = data[$ "__localOverrides"] ?? {};

        if (data[$ "prefab"] != undefined) {
            var prefabUuid = data.prefab;
            if (objectsByUUID[$ prefabUuid] != undefined) {
                self.prefab = objectsByUUID[$ prefabUuid];
            }
        }

        // Subclass-specific data
        if (struct_exists(self, "isMesh") && self.isMesh) {
            if (data[$ "material"] != undefined) {
                self.materialUUID = data.material;
                if (materialsByUUID[$ self.materialUUID] != undefined) {
                    self.material = materialsByUUID[$ self.materialUUID];
                }
            }
            if (data[$ "geometry"] != undefined && is_struct(data.geometry)) {
                var geoUuid = data.geometry[$ "uuid"];
                if (geoUuid != undefined && geometriesByUUID[$ geoUuid] != undefined) {
                    self.geometry = geometriesByUUID[$ geoUuid];
                } else {
                    self.geometry = new UeGeometry();
                    self.geometry.fromJSON(data.geometry);
                    if (self.geometry.position != undefined) self.geometry.build();
                }
            }
        } else if (struct_exists(self, "isLight") && self.isLight) {
            if (data[$ "intensity"] != undefined) self.intensity = data.intensity;
            if (data[$ "color"] != undefined) self.color = data.color;
            if (data[$ "enabled"] != undefined) self.enabled = data.enabled;
            if (data[$ "range"] != undefined) self.range = data.range;
            
            // SpotLight specific
            if (struct_exists(self, "isSpotLight") && self.isSpotLight) {
                if (data[$ "distance"] != undefined) self.distance = data.distance;
                if (data[$ "angle"] != undefined) self.angle = data.angle;
                if (data[$ "penumbra"] != undefined) self.penumbra = data.penumbra;
                if (data[$ "decay"] != undefined) self.decay = data.decay;
            }
            // HemisphereLight specific
            if (struct_exists(self, "isHemisphereLight") && self.isHemisphereLight) {
                if (data[$ "skyColor"] != undefined) self.skyColor = data.skyColor;
                if (data[$ "groundColor"] != undefined) self.groundColor = data.groundColor;
            }
        } else if (struct_exists(self, "isBone") && self.isBone) {
            if (data[$ "offsetMatrix"] != undefined) self.offsetMatrix = data.offsetMatrix;
            if (data[$ "index"] != undefined) self.index = data.index;
        }

        if (data[$ "children"] != undefined && is_array(data.children)) {
            var childrenData = data.children;
            
            // Map current children by UUID for quick lookup and deduplication
            var currentChildren = {};
            for (var i = 0, il = array_length(children); i < il; i++) {
                currentChildren[$ children[i].uuid] = children[i];
            }

            for (var i = 0, il = array_length(childrenData); i < il; i++) {
                var childData = childrenData[i];
                var child = undefined;
                var childUuid = is_string(childData) ? childData : childData[$ "uuid"];

                // 1. Try to find existing instance in current children or global cache
                if (childUuid != undefined) {
                    child = currentChildren[$ childUuid] ?? objectsByUUID[$ childUuid];
                }

                // 2. If not found and data is a struct, create new instance
                if (child == undefined && is_struct(childData)) {
                    var childType = childData[$ "type"] ?? "Object3D";
                    switch (childType) {
                        case "Mesh": child = new UeStaticMesh(); break;
                        case "Object3D": child = new UeObject3D(); break;
                        case "Light":
                            var lightType = childData[$ "lightType"] ?? "PointLight";
                            switch (lightType) {
                                case "PointLight": child = new UePointLight(); break;
                                case "DirectionalLight": child = new UeDirectionalLight(); break;
                                case "AmbientLight": child = new UeAmbientLight(); break;
                                case "SpotLight": child = new UeSpotLight(); break;
                                case "HemisphereLight": child = new UeHemisphereLight(); break;
                                default: child = new UeLight(); break;
                            }
                            break;
                        case "Bone": child = new UeBone(); break;
                        case "Camera": child = new UeObject3D(); child.type = "Camera"; child.isCamera = true; break;
                        case "Scene": child = new UeScene(); break;
                        default: child = new UeObject3D(); break;
                    }
                }
                
                // 3. Update the child from JSON (whether new or existing)
                if (child != undefined) {
                    if (is_struct(childData)) {
                        child.fromJSON(childData, objectsByUUID, materialsByUUID, geometriesByUUID);
                    }
                    
                    self.add(child);
                }
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

    // Initial matrix build
    updateMatrix();
}
