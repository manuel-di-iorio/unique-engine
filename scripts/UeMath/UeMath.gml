// ============================================================================
// BOX3
// ============================================================================

function box3_set_from_object(b, object) {
    gml_pragma("forceinline");
    box3_make_empty(b);

    // Se l'oggetto ha geometria
    var geom = object[$ "geometry"];
    if (geom != undefined) {
        // Assicurati che la geometria abbia il bounding box
        if (geom[$ "boundingBox"] == undefined) {
            geom[$ "boundingBox"] = box3_create();
            box3_set_from_array(geom[$ "boundingBox"], geom[$ "position"] ?? []);
        }
        var localBox = box3_clone(geom[$ "boundingBox"]);

        // Trasforma nel world space
        var m = object[$ "matrixWorld"];
        if (m != undefined) box3_apply_matrix4(localBox, m);

        box3_union(b, localBox);
    }

    // Richiama la stessa funzione sui figli
    var children = object[$ "children"];
    if (children != undefined) {
        var n = array_length(children);
        for (var i = 0; i < n; i++) {
          var childBox = box3_create();
          box3_set_from_object(childBox, children[i]);
          box3_union(b, childBox);
        }
    }

    return b;
}

function sphere_set_from_object(s, object) {
    gml_pragma("forceinline");
    sphere_make_empty(s);

    // Se l'oggetto ha geometria
    var geom = object[$ "geometry"];
    if (geom != undefined) {
        // Assicurati che la geometria abbia il bounding sphere
        if (geom[$ "boundingSphere"] == undefined) {
            geom.computeBoundingSphere();
        }
        
        if (geom[$ "boundingSphere"] != undefined) {
            var localSphere = sphere_clone(geom.boundingSphere);

            // Trasforma nel world space
            var m = object[$ "matrixWorld"];
            if (m != undefined) sphere_apply_matrix4(localSphere, m);

            sphere_union(s, localSphere);
        }
    }

    // Richiama la stessa funzione sui figli
    var children = object[$ "children"];
    if (children != undefined) {
        var n = array_length(children);
        for (var i = 0; i < n; i++) {
          var childSphere = sphere_create([0,0,0], -1);
          sphere_set_from_object(childSphere, children[i]);
          sphere_union(s, childSphere);
        }
    }

    return s;
}

// ============================================================================
// VECTOR3 - CAMERA PROJECTION
// ============================================================================

/// @func vec3_project(vec, camera)
/// @desc Projects this vector from world space into normalized device coordinate (NDC) space.
/// @param {Array<Real>} vec The vector to project
/// @param {Struct} camera The camera struct with matrixWorldInverse and projectionMatrix
function vec3_project(vec, camera) {
    gml_pragma("forceinline");
    // Apply view matrix (matrixWorldInverse) first, then projection matrix
    vec3_apply_matrix4(vec, camera.matrixWorldInverse);
    vec3_apply_matrix4(vec, camera.projectionMatrix);
}

/// @func vec3_unproject(vec, camera)
/// @desc Unprojects this vector from normalized device coordinate (NDC) space into world space.
/// @param {Array<Real>} vec The vector to unproject
/// @param {Struct} camera The camera struct with projectionMatrixInverse and matrixWorld
function vec3_unproject(vec, camera) {
    gml_pragma("forceinline");
    // Apply inverse projection first, then matrixWorld
    vec3_apply_matrix4(vec, camera.projectionMatrixInverse);
    vec3_apply_matrix4(vec, camera.matrixWorld);
}
