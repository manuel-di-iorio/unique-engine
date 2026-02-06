global.UE_DEFAULT_UP = vec3_create(0, 0, -1);
global.UE_DEFAULT_MATRIX_AUTO_UPDATE = true;
global.UE_DEFAULT_MATRIX_WORLD_AUTO_UPDATE = true;

function UeTransform(_data = undefined): UeEventDispatcher(_data) constructor {

    // Optional initialization data
    var data = _data ?? {};

    // === Local transform properties ===

    /// Local position vector
    position = data[$ "position"] ?? vec3_create(data[$ "x"] ?? 0, data[$ "y"] ?? 0, data[$ "z"] ?? 0);
    rotation = data[$ "rotation"] ?? quat_create(data[$ "rx"] ?? 0, data[$ "ry"] ?? 0, data[$ "rz"] ?? 0);
    scale = data[$ "scale"]    ?? vec3_create(data[$ "sx"] ?? 1, data[$ "sy"] ?? 1, data[$ "sz"] ?? 1);

    /// Local up direction (used for lookAt and world direction)
    up = data[$ "up"] ?? global.UE_DEFAULT_UP;

    // === Matrices ===

    /// Local transformation matrix
    matrix = data[$ "matrix"] ?? mat4_create();

    /// World transformation matrix
    matrixWorld = data[$ "matrixWorld"] ?? mat4_create();

    // === Hierarchy ===

    /// Parent transform (undefined if root)
    parent = data[$ "parent"] ?? undefined;

    /// Child transforms
    children = data[$ "children"] ?? [];

    // === Matrix update flags ===

    /// Automatically update local matrix from position/rotation/scale
    matrixAutoUpdate = data[$ "matrixAutoUpdate"]
        ?? global.UE_DEFAULT_MATRIX_AUTO_UPDATE;

    /// Automatically update world matrix
    matrixWorldAutoUpdate = data[$ "matrixWorldAutoUpdate"]
        ?? global.UE_DEFAULT_MATRIX_WORLD_AUTO_UPDATE;

    /// Marks whether the world matrix needs updating
    matrixWorldNeedsUpdate = false;

    /// Versioning for transform updates
    version = 0;

    // === Cached intersection sphere (world space) ===
    __intersectionSphere = undefined;

    // -------------------------------------------------------------------------
    // MATRIX UPDATE METHODS
    // -------------------------------------------------------------------------

    /// Recomputes the local matrix from position, rotation, and scale
    function updateMatrix() {
        gml_pragma("forceinline");
        mat4_compose(matrix, position, rotation, scale);
        matrixWorldNeedsUpdate = true;
        return self;
    }

    /// Updates the world matrix and optionally forces update on children
    function updateMatrixWorld(force = false, recursive = true) {
        gml_pragma("forceinline");

        // Update local matrix if enabled
        if (matrixAutoUpdate) {
            updateMatrix();
        }

        // Update world matrix if needed
        if (matrixWorldNeedsUpdate || force) {

            if (parent == undefined) {
                // Root object
                mat4_copy(matrixWorld, matrix);
            } else {
                // Child object
                matrix_multiply(matrix, parent.matrixWorld, matrixWorld);
            }

            matrixWorldNeedsUpdate = false;
            self.version++;
            force = true;

            // Update cached world-space bounding sphere if geometry exists
            var geometry = self[$ "geometry"];
            if (geometry != undefined) {
                var boundingSphere = geometry[$ "boundingSphere"];
                if (boundingSphere != undefined) {
                    __intersectionSphere ??= sphere_create();
                    sphere_copy(__intersectionSphere, boundingSphere);
                    sphere_apply_matrix4(__intersectionSphere, matrixWorld);
                }
            }
        }

        if (recursive) {
            // Propagate update to children
            for (var i = 0, len = array_length(children); i < len; i++) {
                children[i].updateMatrixWorld(force, true);
            }

            // Update skeleton if present (AFTER children/bones have updated their world matrices)
            if (self.skeleton != undefined) {
                self.skeleton.update();
            }
        }

        return self;
    }

    /// Updates world matrices with optional parent/child propagation
    function updateWorldMatrix(updateParents = false, updateChildren = false) {
        gml_pragma("forceinline");

        // Update parents first if requested
        if (updateParents && parent != undefined) {
            parent.updateWorldMatrix(true, false);
        }

        if (matrixAutoUpdate) updateMatrix();

        if (matrixWorldAutoUpdate) {
            if (parent == undefined) {
                mat4_copy(matrixWorld, matrix);
            } else {
                matrix_multiply(matrix, parent.matrixWorld, matrixWorld);
            }

            // Update cached world-space bounding sphere if geometry exists
            var geometry = self[$ "geometry"];
            if (geometry != undefined) {
                var boundingSphere = geometry[$ "boundingSphere"];
                if (boundingSphere != undefined) {
                    __intersectionSphere ??= sphere_create();
                    sphere_copy(__intersectionSphere, boundingSphere);
                    sphere_apply_matrix4(__intersectionSphere, matrixWorld);
                }
            }
        }

        // Update children if requested
        if (updateChildren) {
            for (var i = 0, len = array_length(children); i < len; i++) {
                children[i].updateWorldMatrix(false, true);
            }
        }

        // Update skeleton if present
        if (self.skeleton != undefined) {
            self.skeleton.update();
        }

        return self;
    }

    /**
     * @description Forces an update of the local and world matrices on this object and its children. Also static objects will be updated. Optionally starting the update from the root object.
     * @warning: This should only be called once on scene start when you want to globally update all matrices, local and world, even on static objects. An example would be that you have a scene with a lot of static objects that you have transformed and you don't want to call updateMatrix() singularly on all of them. Be aware that this is an expensive operation  and prone to anti-pattern, use only if you know what you are doing.
     */
    function forceUpdate(startFromRoot = false) {
        gml_pragma("forceinline");

        // If requested, start the update from the root parent to ensure the entire hierarchy is correct
        if (startFromRoot && parent != undefined) {
            var root = parent;
            while (root.parent != undefined) {
                root = root.parent;
            }
            root.forceUpdate();
            return;
        }

        // Update local matrix
        mat4_compose(matrix, position, rotation, scale);

        if (parent == undefined) {
            // Root object
            mat4_copy(matrixWorld, matrix);
        } else {
            // Child object
            matrix_multiply(matrix, parent.matrixWorld, matrixWorld);
        }

        // Update cached world-space bounding sphere if geometry exists
        var geometry = self[$ "geometry"];
        if (geometry != undefined) {
            var boundingSphere = geometry[$ "boundingSphere"];
            if (boundingSphere != undefined) {
                __intersectionSphere ??= sphere_create();
                sphere_copy(__intersectionSphere, boundingSphere);
                sphere_apply_matrix4(__intersectionSphere, matrixWorld);
            }
        }

        // Update children
        for (var i = 0, len = array_length(children); i < len; i++) {
            children[i].forceUpdate();
        }

        // Update skeleton if present
        if (self.skeleton != undefined) {
            self.skeleton.update();
        }
    }

    // -------------------------------------------------------------------------
    // TRANSLATION
    // -------------------------------------------------------------------------

    /// Sets local position
    function setPosition(x, y, z) {
        gml_pragma("forceinline");
        vec3_set(position, x, y, z);
        return self;
    }

    /// Translates along a local axis
    function translateOnAxis(axis, distance) {
        gml_pragma("forceinline");

        var v = global.UE_VEC3_TEMP0;
        vec3_copy(v, axis);
        vec3_apply_quaternion(v, rotation);
        vec3_add_scaled_vector(position, v, distance);

        return self;
    }

    /// Translates in local space
    function translate(x, y, z) {
        gml_pragma("forceinline");

        var v = global.UE_VEC3_TEMP0;
        vec3_set(v, x, y, z);
        vec3_add(position, v);

        return self;
    }

    function translateX(value) {
        gml_pragma("forceinline");
        position[@0] += value;
        return self;
    }

    function translateY(value) {
        gml_pragma("forceinline");
        position[@1] += value;
        return self;
    }

    function translateZ(value) {
        gml_pragma("forceinline");
        position[@2] += value;
        return self;
    }

    // -------------------------------------------------------------------------
    // ROTATION
    // -------------------------------------------------------------------------

    /// Rotates the object to face a target vector
    function lookAtVec(target) {
        gml_pragma("forceinline");

        var m = global.UE_MAT4_TEMP0;
        mat4_look_at(m, position, target, up);
        quat_set_from_rotation_matrix(rotation, m);

        return self;
    }

    /// Rotates the object to face a target position
    function lookAt(x, y, z) {
        gml_pragma("forceinline");

        var t = global.UE_VEC3_TEMP0;
        vec3_set(t, x, y, z);
        return lookAtVec(t);
    }

    /// Sets rotation from Euler angles
    function setRotation(x, y, z) {
        gml_pragma("forceinline");
        quat_set_from_euler(rotation, x, y, z);
        return self;
    }

    /// Sets rotation from a matrix
    function setRotationFromMatrix(mat) {
        gml_pragma("forceinline");
        quat_set_from_rotation_matrix(rotation, mat);
        return self;
    }

    /// Copies a quaternion into rotation
    function setRotationFromQuaternion(quat) {
        gml_pragma("forceinline");
        quat_copy(rotation, quat);
        return self;
    }

    /// Applies Euler rotation increment
    function rotate(x, y, z) {
        gml_pragma("forceinline");

        var q = global.UE_QUAT_TEMP0;
        quat_set_from_euler(q, x, y, z);
        quat_multiply(rotation, q);

        return self;
    }

    /// Rotates around local X axis
    function rotateX(value) {
        gml_pragma("forceinline");

        var axis = global.UE_VEC3_TEMP0;
        vec3_set(axis, 1, 0, 0);

        var q = global.UE_QUAT_TEMP0;
        quat_set_from_axis_angle(q, axis, value);
        quat_multiply(rotation, q);

        return self;
    }

    /// Rotates around local Y axis
    function rotateY(value) {
        gml_pragma("forceinline");

        var axis = global.UE_VEC3_TEMP0;
        vec3_set(axis, 0, 1, 0);

        var q = global.UE_QUAT_TEMP0;
        quat_set_from_axis_angle(q, axis, value);
        quat_multiply(rotation, q);

        return self;
    }

    /// Rotates around local Z axis
    function rotateZ(value) {
        gml_pragma("forceinline");

        var axis = global.UE_VEC3_TEMP0;
        vec3_set(axis, 0, 0, 1);

        var q = global.UE_QUAT_TEMP0;
        quat_set_from_axis_angle(q, axis, value);
        quat_multiply(rotation, q);

        return self;
    }

    /// Rotates around an arbitrary local axis
    function rotateOnAxis(axis, angle) {
        gml_pragma("forceinline");

        var q = global.UE_QUAT_TEMP0;
        quat_set_from_axis_angle(q, axis, angle);
        quat_multiply(rotation, q);

        return self;
    }

    /// Rotates around a world-space axis
    function rotateOnWorldAxis(axis, angle) {
        gml_pragma("forceinline");

        var q = global.UE_QUAT_TEMP0;
        quat_set_from_axis_angle(q, axis, angle);
        quat_premultiply(rotation, q);

        return self;
    }

    // -------------------------------------------------------------------------
    // SCALE
    // -------------------------------------------------------------------------

    function setScale(x, y, z) {
        gml_pragma("forceinline");
        vec3_set(scale, x, y, z);
        return self;
    }

    function scaleX(value) {
        gml_pragma("forceinline");
        scale[@0] += value;
        return self;
    }

    function scaleY(value) {
        gml_pragma("forceinline");
        scale[@1] += value;
        return self;
    }

    function scaleZ(value) {
        gml_pragma("forceinline");
        scale[@2] += value;
        return self;
    }

    // -------------------------------------------------------------------------
    // MATRIX / SPACE CONVERSION
    // -------------------------------------------------------------------------

    /// Applies a matrix and decomposes it back into components
    function applyMatrix4(mat4) {
        gml_pragma("forceinline");

        mat4_multiply(matrix, mat4);
        mat4_decompose(matrix, position, rotation, scale);

        return self;
    }

    /// Applies a quaternion rotation
    function applyQuaternion(quat) {
        gml_pragma("forceinline");
        quat_multiply(rotation, quat);
        return self;
    }

    /**
     * @description Gets the world-space position.
     * @param {Array} [target] Optional target array to store the result.
     * @returns {Array} The world-space position.
     */
    function getWorldPosition(target = undefined) {
        gml_pragma("forceinline");
        target ??= vec3_create();
        vec3_set_from_matrix_position(target, matrixWorld);
        return target;
    }

    /**
     * @description Gets the world-space rotation quaternion.
     * @param {Array} [target] Optional target array to store the result.
     * @returns {Array} The world-space rotation quaternion.
     */
    function getWorldQuaternion(target = undefined) {
        gml_pragma("forceinline");
        target ??= quat_create();

        var v = global.UE_VEC3_TEMP0;
        mat4_decompose(matrixWorld, v, target, v);

        return target;
    }

    /**
     * @description Gets the world-space scale.
     * @param {Array} [target] Optional target array to store the result.
     * @returns {Array} The world-space scale.
     */
    function getWorldScale(target = undefined) {
        gml_pragma("forceinline");
        target ??= vec3_create();

        var v = global.UE_VEC3_TEMP0;
        mat4_decompose(matrixWorld, v, global.__QUAT_TEMP, target);

        return target;
    }

    /**
     * @description Gets the forward direction in world space.
     * @param {Array} [target] Optional target array to store the result.
     * @returns {Array} The world-space forward direction.
     */
    function getWorldDirection(target = undefined) {
        gml_pragma("forceinline");

        target ??= vec3_create();
        vec3_copy(target, up);
        vec3_transform_direction(target, matrixWorld);

        return target;
    }

    /// Converts a vector from local space to world space
    function localToWorld(vec) {
        gml_pragma("forceinline");
        vec3_apply_matrix4(vec, matrixWorld);
        return vec;
    }

    /// Converts a vector from world space to local space
    function worldToLocal(vec) {
        gml_pragma("forceinline");

        var inv = global.UE_MAT4_TEMP0;
        mat4_copy(inv, matrixWorld);
        matrix_inverse(inv, inv);
        vec3_apply_matrix4(vec, inv);

        return vec;
    }
}
