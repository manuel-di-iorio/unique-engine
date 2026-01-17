/// @desc Bounding Volume Hierarchy for 3D spatial partitioning
/// Represented as an array: [aabb, left, right, data]
/// If it's a leaf, left and right are undefined, and data contains the objects.

enum BVH_NODE {
    aabb,   // [minX, minY, minZ, maxX, maxY, maxZ]
    left,   // BVH_NODE or undefined
    right,  // BVH_NODE or undefined
    data    // array of objects (if leaf) or undefined
}

/// @func bvh_create()
/// @desc Constructs a new BVH node.
/// @returns {Array} New BVH node
function bvh_create() {
    gml_pragma("forceinline");
    return [
        box3_create(),
        undefined,
        undefined,
        undefined
    ];
}

/// @func bvh_build(objects, get_aabb_fn)
/// @desc Builds a BVH from a list of objects.
/// @param {Array} objects Array of objects to include in the BVH
/// @param {Function} get_aabb_fn Function that takes an object and returns its Box3
/// @returns {Array} Root BVH node
function bvh_build(objects, get_aabb_fn) {
    var count = array_length(objects);
    if (count == 0) return undefined;

    var node = bvh_create();
    
    // Calculate total AABB
    var total_aabb = node[BVH_NODE.aabb];
    for (var i = 0; i < count; i++) {
        var obj_aabb = get_aabb_fn(objects[i]);
        box3_expand_by_point(total_aabb, [obj_aabb[0], obj_aabb[1], obj_aabb[2]]);
        box3_expand_by_point(total_aabb, [obj_aabb[3], obj_aabb[4], obj_aabb[5]]);
    }

    if (count <= 1) {
        node[BVH_NODE.data] = objects;
        return node;
    }

    // Split objects based on the longest axis
    var dx = total_aabb[3] - total_aabb[0];
    var dy = total_aabb[4] - total_aabb[1];
    var dz = total_aabb[5] - total_aabb[2];

    var axis = 0;
    if (dy > dx && dy > dz) axis = 1;
    else if (dz > dx && dz > dy) axis = 2;

    // Sort objects by their center on the chosen axis
    var context = {
        axis: axis,
        get_aabb: get_aabb_fn
    };
    
    // Create a copy of objects to avoid modifying the original array
    var objects_copy = [];
    array_copy(objects_copy, 0, objects, 0, count);
    
    array_sort(objects_copy, method(context, function(a, b) {
        var a_aabb = get_aabb(a);
        var b_aabb = get_aabb(b);
        var a_center = (a_aabb[axis] + a_aabb[axis + 3]) * 0.5;
        var b_center = (b_aabb[axis] + b_aabb[axis + 3]) * 0.5;
        return a_center - b_center;
    }));

    var mid = count div 2;
    var left_objs = [];
    var right_objs = [];
    array_copy(left_objs, 0, objects_copy, 0, mid);
    array_copy(right_objs, 0, objects_copy, mid, count - mid);

    node[BVH_NODE.left] = bvh_build(left_objs, get_aabb_fn);
    node[BVH_NODE.right] = bvh_build(right_objs, get_aabb_fn);

    return node;
}

/// @func bvh_query_box(node, box, results)
/// @desc Queries the BVH for objects whose AABB intersects the given box.
/// @param {Array} node The BVH node to start from
/// @param {Array<Real>} box The query box [minX, minY, minZ, maxX, maxY, maxZ]
/// @param {Array} results The array to store results in
function bvh_query_box(node, box, results) {
    if (node == undefined) return;
    if (!box3_intersects_box(node[BVH_NODE.aabb], box)) return;
    
    if (node[BVH_NODE.data] != undefined) {
        var objects = node[BVH_NODE.data];
        for (var i = 0; i < array_length(objects); i++) {
            array_push(results, objects[i]);
        }
        return;
    }
    
    if (node[BVH_NODE.left] != undefined) bvh_query_box(node[BVH_NODE.left], box, results);
    if (node[BVH_NODE.right] != undefined) bvh_query_box(node[BVH_NODE.right], box, results);
}

/// @func bvh_query_sphere(node, sphere, results)
/// @desc Queries the BVH for objects whose AABB intersects the given sphere.
/// @param {Array} node The BVH node to start from
/// @param {Array<Real>} sphere The query sphere [x, y, z, r]
/// @param {Array} results The array to store results in
function bvh_query_sphere(node, sphere, results) {
    if (node == undefined) return;
    if (!box3_intersects_sphere(node[BVH_NODE.aabb], sphere)) return;
    
    if (node[BVH_NODE.data] != undefined) {
        var objects = node[BVH_NODE.data];
        for (var i = 0; i < array_length(objects); i++) {
            array_push(results, objects[i]);
        }
        return;
    }
    
    if (node[BVH_NODE.left] != undefined) bvh_query_sphere(node[BVH_NODE.left], sphere, results);
    if (node[BVH_NODE.right] != undefined) bvh_query_sphere(node[BVH_NODE.right], sphere, results);
}

/// @func bvh_query_frustum(node, frustum, results)
/// @desc Queries the BVH for objects whose AABB intersects the given frustum.
/// @param {Array} node The BVH node to start from
/// @param {Array<Array<Real>>} frustum The query frustum
/// @param {Array} results The array to store results in
function bvh_query_frustum(node, frustum, results) {
    if (node == undefined) return;
    if (!frustum_intersects_box(frustum, node[BVH_NODE.aabb])) return;
    
    if (node[BVH_NODE.data] != undefined) {
        var objects = node[BVH_NODE.data];
        for (var i = 0; i < array_length(objects); i++) {
            array_push(results, objects[i]);
        }
        return;
    }
    
    if (node[BVH_NODE.left] != undefined) bvh_query_frustum(node[BVH_NODE.left], frustum, results);
    if (node[BVH_NODE.right] != undefined) bvh_query_frustum(node[BVH_NODE.right], frustum, results);
}

/// @func bvh_query_ray(node, ray, results)
/// @desc Queries the BVH for objects whose AABB intersects the given ray.
/// @param {Array} node The BVH node to start from
/// @param {Array<Real>} ray The query ray [ox, oy, oz, dx, dy, dz]
/// @param {Array} results The array to store results in
function bvh_query_ray(node, ray, results) {
    if (node == undefined) return;
    if (!ray_intersects_box(ray, node[BVH_NODE.aabb])) return;
    
    if (node[BVH_NODE.data] != undefined) {
        var objects = node[BVH_NODE.data];
        for (var i = 0; i < array_length(objects); i++) {
            array_push(results, objects[i]);
        }
        return;
    }
    
    if (node[BVH_NODE.left] != undefined) bvh_query_ray(node[BVH_NODE.left], ray, results);
    if (node[BVH_NODE.right] != undefined) bvh_query_ray(node[BVH_NODE.right], ray, results);
}

/// @func bvh_intersect_ray(node, ray)
/// @desc Finds the closest object intersection in the BVH.
/// @param {Array} node The BVH node
/// @param {Array<Real>} ray The ray
/// @returns {Struct|Undefined} A struct with {object, distance} or undefined
function bvh_intersect_ray(node, ray) {
    if (node == undefined) return undefined;
    var dist = ray_intersect_box(ray, node[BVH_NODE.aabb]);
    if (dist == -1) return undefined;
    
    if (node[BVH_NODE.data] != undefined) {
        return { object: node[BVH_NODE.data][0], distance: dist };
    }
    
    var left_hit = (node[BVH_NODE.left] != undefined) ? bvh_intersect_ray(node[BVH_NODE.left], ray) : undefined;
    var right_hit = (node[BVH_NODE.right] != undefined) ? bvh_intersect_ray(node[BVH_NODE.right], ray) : undefined;
    
    if (left_hit != undefined && right_hit != undefined) {
        return (left_hit.distance < right_hit.distance) ? left_hit : right_hit;
    }
    
    return left_hit ?? right_hit;
}
