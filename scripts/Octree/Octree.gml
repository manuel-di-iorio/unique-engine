/// @desc Hierarchical Octree for 3D space partitioning
/// Represented as an array: [box, bounds, triangles, subTrees, maxLevel, trianglesPerLeaf]

enum OCTREE {
    box,              // [minX, minY, minZ, maxX, maxY, maxZ]
    bounds,           // [minX, minY, minZ, maxX, maxY, maxZ]
    triangles,        // array of Triangle arrays
    subNodes,         // array of subTrees or undefined
    maxLevel,         // int
    trianglesPerLeaf  // int
}

// Internal temp variables for calculations
global.__UE_OCT_V1 = vec3_create();
global.__UE_OCT_V2 = vec3_create();
global.__UE_OCT_P1 = vec3_create();
global.__UE_OCT_P2 = vec3_create();
global.__UE_OCT_PLANE = plane_create();
global.__UE_OCT_LINE1 = line3_create();
global.__UE_OCT_LINE2 = line3_create();
global.__UE_OCT_BOX = box3_create();
global.__UE_OCT_SPHERE = [0,0,0,0];

/// @func octree_create(box)
/// @desc Constructs a new Octree.
/// @param {Array<Real>} [box] The base box that encloses the Octree
/// @returns {Array} New octree node
function octree_create(box = undefined) {
    gml_pragma("forceinline");
    return [
        box ?? box3_create(),
        box3_create(),
        [],
        undefined,
        16,
        8
    ];
}

/// @func octree_add_triangle(octree, triangle)
/// @desc Adds a triangle to the octree and expands the bounds.
/// @param {Array} octree The octree
/// @param {Array} triangle The triangle [[x,y,z], [x,y,z], [x,y,z]]
/// @returns {Array} The octree
function octree_add_triangle(octree, triangle) {
    gml_pragma("forceinline");
    box3_expand_by_point(octree[OCTREE.bounds], triangle[0]);
    box3_expand_by_point(octree[OCTREE.bounds], triangle[1]);
    box3_expand_by_point(octree[OCTREE.bounds], triangle[2]);
    array_push(octree[OCTREE.triangles], triangle);
    return octree;
}

/// @func octree_calc_box(octree)
/// @desc Prepares the containing box for the build.
/// @param {Array} octree The octree
/// @returns {Array} The octree
function octree_calc_box(octree) {
    gml_pragma("forceinline");
    box3_copy(octree[OCTREE.box], octree[OCTREE.bounds]);
    box3_expand_by_scalar(octree[OCTREE.box], 0.01);
    return octree;
}

/// @func octree_split(octree, level)
/// @desc Recursively splits the octree node.
/// @param {Array} octree The octree
/// @param {Real} level Current depth level
/// @returns {Array} The octree
function octree_split(octree, level) {
    gml_pragma("forceinline");
    if (octree[OCTREE.box] == undefined) return octree;
    
    var subTrees = [];
    var box = octree[OCTREE.box];
    var minX = box[0], minY = box[1], minZ = box[2];
    var maxX = box[3], maxY = box[4], maxZ = box[5];
    
    var hx = (maxX - minX) * 0.5;
    var hy = (maxY - minY) * 0.5;
    var hz = (maxZ - minZ) * 0.5;
    
    for (var _x = 0; _x < 2; _x++) {
        for (var _y = 0; _y < 2; _y++) {
            for (var _z = 0; _z < 2; _z++) {
                var subBox = [
                    minX + _x * hx, minY + _y * hy, minZ + _z * hz,
                    minX + (_x + 1) * hx, minY + (_y + 1) * hy, minZ + (_z + 1) * hz
                ];
                var subNode = octree_create(subBox);
                subNode[OCTREE.maxLevel] = octree[OCTREE.maxLevel];
                subNode[OCTREE.trianglesPerLeaf] = octree[OCTREE.trianglesPerLeaf];
                array_push(subTrees, subNode);
            }
        }
    }
    
    var triangles = octree[OCTREE.triangles];
    while (array_length(triangles) > 0) {
        var triangle = array_pop(triangles);
        for (var i = 0; i < 8; i++) {
            if (box3_intersects_triangle(subTrees[i][OCTREE.box], triangle[0], triangle[1], triangle[2])) {
                array_push(subTrees[i][OCTREE.triangles], triangle);
            }
        }
    }
    
    octree[OCTREE.subNodes] = [];
    for (var i = 0; i < 8; i++) {
        var len = array_length(subTrees[i][OCTREE.triangles]);
        if (len > octree[OCTREE.trianglesPerLeaf] && level < octree[OCTREE.maxLevel]) {
            octree_split(subTrees[i], level + 1);
        }
        
        if (len > 0) {
            array_push(octree[OCTREE.subNodes], subTrees[i]);
        }
    }
    
    return octree;
}

/// @func octree_build(octree)
/// @desc Builds the octree.
/// @param {Array} octree The octree
/// @returns {Array} The octree
function octree_build(octree) {
    gml_pragma("forceinline");
    octree_calc_box(octree);
    octree_split(octree, 0);
    return octree;
}

/// @func octree_clear(octree)
/// @desc Clears the octree.
/// @param {Array} octree The octree
/// @returns {Array} The octree
function octree_clear(octree) {
    gml_pragma("forceinline");
    box3_make_empty(octree[OCTREE.box]);
    box3_make_empty(octree[OCTREE.bounds]);
    octree[OCTREE.triangles] = [];
    octree[OCTREE.subNodes] = undefined;
    return octree;
}

/// @func octree_get_ray_triangles(octree, ray, triangles)
function octree_get_ray_triangles(octree, ray, triangles) {
    gml_pragma("forceinline");
    if (octree[OCTREE.subNodes] != undefined) {
        var subNodes = octree[OCTREE.subNodes];
        var n = array_length(subNodes);
        for (var i = 0; i < n; i++) {
            var sub = subNodes[i];
            if (!ray_intersects_box(ray, sub[OCTREE.box])) continue;
            
            if (array_length(sub[OCTREE.triangles]) > 0) {
                var triSource = sub[OCTREE.triangles];
                var m = array_length(triSource);
                for (var j = 0; j < m; j++) {
                    if (array_get_index(triangles, triSource[j]) == -1) {
                        array_push(triangles, triSource[j]);
                    }
                }
            } else {
                octree_get_ray_triangles(sub, ray, triangles);
            }
        }
    }
}

/// @func octree_get_sphere_triangles(octree, sphere, triangles)
function octree_get_sphere_triangles(octree, sphere, triangles) {
    gml_pragma("forceinline");
    if (octree[OCTREE.subNodes] != undefined) {
        var subNodes = octree[OCTREE.subNodes];
        var n = array_length(subNodes);
        for (var i = 0; i < n; i++) {
            var sub = subNodes[i];
            if (!sphere_intersects_box(sphere, sub[OCTREE.box])) continue;
            
            if (array_length(sub[OCTREE.triangles]) > 0) {
                var triSource = sub[OCTREE.triangles];
                var m = array_length(triSource);
                for (var j = 0; j < m; j++) {
                    if (array_get_index(triangles, triSource[j]) == -1) {
                        array_push(triangles, triSource[j]);
                    }
                }
            } else {
                octree_get_sphere_triangles(sub, sphere, triangles);
            }
        }
    }
}

/// @func octree_get_capsule_triangles(octree, capsule, triangles)
function octree_get_capsule_triangles(octree, capsule, triangles) {
    gml_pragma("forceinline");
    if (octree[OCTREE.subNodes] != undefined) {
        var subNodes = octree[OCTREE.subNodes];
        var n = array_length(subNodes);
        
        var tempBox = global.__UE_OCT_BOX;
        var tempSphere = global.__UE_OCT_SPHERE;
        
        tempSphere[0] = capsule[0]; tempSphere[1] = capsule[1]; tempSphere[2] = capsule[2]; tempSphere[3] = capsule[6];
        box3_set_from_sphere(tempBox, tempSphere);
        tempSphere[0] = capsule[3]; tempSphere[1] = capsule[4]; tempSphere[2] = capsule[5]; tempSphere[3] = capsule[6];
        box3_expand_by_sphere(tempBox, tempSphere);
        
        for (var i = 0; i < n; i++) {
            var sub = subNodes[i];
            if (!box3_intersects_box(tempBox, sub[OCTREE.box])) continue;
            
            if (array_length(sub[OCTREE.triangles]) > 0) {
                var triSource = sub[OCTREE.triangles];
                var m = array_length(triSource);
                for (var j = 0; j < m; j++) {
                    if (array_get_index(triangles, triSource[j]) == -1) {
                        array_push(triangles, triSource[j]);
                    }
                }
            } else {
                octree_get_capsule_triangles(sub, capsule, triangles);
            }
        }
    }
}

/// @func octree_get_box_triangles(octree, box, triangles)
function octree_get_box_triangles(octree, box, triangles) {
    gml_pragma("forceinline");
    if (octree[OCTREE.subNodes] != undefined) {
        var subNodes = octree[OCTREE.subNodes];
        var n = array_length(subNodes);
        for (var i = 0; i < n; i++) {
            var sub = subNodes[i];
            if (!box3_intersects_box(box, sub[OCTREE.box])) continue;
            
            if (array_length(sub[OCTREE.triangles]) > 0) {
                var triSource = sub[OCTREE.triangles];
                var m = array_length(triSource);
                for (var j = 0; j < m; j++) {
                    if (array_get_index(triangles, triSource[j]) == -1) {
                        array_push(triangles, triSource[j]);
                    }
                }
            } else {
                octree_get_box_triangles(sub, box, triangles);
            }
        }
    }
}

/// @func octree_triangle_sphere_intersect(octree, sphere, triangle)
function octree_triangle_sphere_intersect(octree, sphere, triangle) {
    gml_pragma("forceinline");
    var center = [sphere[0], sphere[1], sphere[2]];
    var target = global.__UE_OCT_V1;
    tri_closest_point_to_point(triangle, center, target);
    
    var distSq = vec3_distance_to_squared(center, target);
    var radius = sphere[3];
    
    if (distSq <= radius * radius) {
        var dist = sqrt(distSq);
        var normal = vec3_create();
        vec3_sub_vectors(normal, center, target);
        vec3_normalize(normal);
        
        return {
            normal: normal,
            point: vec3_clone(target),
            depth: radius - dist
        };
    }
    return false;
}

/// @func octree_triangle_capsule_intersect(octree, capsule, triangle)
function octree_triangle_capsule_intersect(octree, capsule, triangle) {
    gml_pragma("forceinline");
    var start = [capsule[0], capsule[1], capsule[2]];
    var _end = [capsule[3], capsule[4], capsule[5]];
    var radius = capsule[6];
    var r2 = radius * radius;
    
    var bestDistSq = infinity;
    var bestPoint = undefined;
    var bestNormal = undefined;

    // 1. Check if segment intersects triangle interior
    var plane = global.__UE_OCT_PLANE;
    tri_get_plane(triangle, plane);
    var lineArr = [start[0], start[1], start[2], _end[0], _end[1], _end[2]];
    var intersectPoint = global.__UE_OCT_V1;
    if (plane_intersect_line(plane, lineArr, intersectPoint) != undefined) {
        if (tri_contains_point(triangle, intersectPoint)) {
            bestDistSq = 0;
            bestPoint = vec3_clone(intersectPoint);
            bestNormal = vec3_create(plane[0], plane[1], plane[2]);
            // Point normal towards capsule start point
            if (vec3_dot(bestNormal, start) + plane[3] < 0) {
                vec3_negate(bestNormal);
            }
        }
    }

    // 2. Check endpoints against triangle
    if (bestDistSq > 0) {
        var p = global.__UE_OCT_P1;
        
        // Start point
        tri_closest_point_to_point(triangle, start, p);
        var d2 = vec3_distance_to_squared(start, p);
        if (d2 < bestDistSq) {
            bestDistSq = d2;
            bestPoint = vec3_clone(p);
            bestNormal = vec3_create();
            vec3_sub_vectors(bestNormal, start, p);
            vec3_normalize(bestNormal);
        }
        
        // End point
        tri_closest_point_to_point(triangle, _end, p);
        d2 = vec3_distance_to_squared(_end, p);
        if (d2 < bestDistSq) {
            bestDistSq = d2;
            bestPoint = vec3_clone(p);
            bestNormal = vec3_create();
            vec3_sub_vectors(bestNormal, _end, p);
            vec3_normalize(bestNormal);
        }
    }

    // 3. Check segment against triangle edges
    if (bestDistSq > 0) {
        var line1 = global.__UE_OCT_LINE1;
        line3_set(line1, start, _end);
        var p0 = triangle[0], p1 = triangle[1], p2 = triangle[2];
        var edges = [[p0, p1], [p1, p2], [p2, p0]];
        for (var i = 0; i < 3; i++) {
            var line2 = global.__UE_OCT_LINE2;
            line3_set(line2, edges[i][0], edges[i][1]);
            var cp1 = global.__UE_OCT_P1;
            var cp2 = global.__UE_OCT_P2;
            var d2 = line3_distance_sq_to_line3(line1, line2, cp1, cp2);
            if (d2 < bestDistSq) {
                bestDistSq = d2;
                bestPoint = vec3_clone(cp2);
                bestNormal = vec3_create();
                vec3_sub_vectors(bestNormal, cp1, cp2);
                vec3_normalize(bestNormal);
            }
        }
    }

    if (bestDistSq < r2) {
        return {
            normal: bestNormal,
            point: bestPoint,
            depth: radius - sqrt(bestDistSq)
        };
    }
    
    return false;
}

/// @func octree_triangle_box_intersect(octree, box, triangle)
function octree_triangle_box_intersect(octree, box, triangle) {
    gml_pragma("forceinline");
    if (!box3_intersects_triangle(box, triangle[0], triangle[1], triangle[2])) return false;
    
    var center = global.__UE_OCT_V1;
    box3_get_center(box, center);
    
    var target = global.__UE_OCT_V2;
    tri_closest_point_to_point(triangle, center, target);
    
    var normal = vec3_create();
    vec3_sub_vectors(normal, target, center);
    vec3_normalize(normal);
    
    return {
        normal: normal,
        point: vec3_clone(target),
        depth: box3_distance_to_point(box, target)
    };
}

/// @func octree_sphere_intersect(octree, sphere)
function octree_sphere_intersect(octree, sphere) {
    gml_pragma("forceinline");
    var triangles = [];
    octree_get_sphere_triangles(octree, sphere, triangles);
    
    var result = false;
    var n = array_length(triangles);
    for (var i = 0; i < n; i++) {
        var res = octree_triangle_sphere_intersect(octree, sphere, triangles[i]);
        if (res != false) {
            if (result == false || res.depth > result.depth) {
                result = res;
            }
        }
    }
    return result;
}

/// @func octree_capsule_intersect(octree, capsule)
function octree_capsule_intersect(octree, capsule) {
    gml_pragma("forceinline");
    var triangles = [];
    octree_get_capsule_triangles(octree, capsule, triangles);
    
    var result = false;
    var n = array_length(triangles);
    for (var i = 0; i < n; i++) {
        var res = octree_triangle_capsule_intersect(octree, capsule, triangles[i]);
        if (res != false) {
            if (result == false || res.depth > result.depth) {
                result = res;
            }
        }
    }
    return result;
}

/// @func octree_box_intersect(octree, box)
function octree_box_intersect(octree, box) {
    gml_pragma("forceinline");
    var triangles = [];
    octree_get_box_triangles(octree, box, triangles);
    
    var result = false;
    var n = array_length(triangles);
    for (var i = 0; i < n; i++) {
        var res = octree_triangle_box_intersect(octree, box, triangles[i]);
        if (res != false) {
            if (result == false || res.depth > result.depth) {
                result = res;
            }
        }
    }
    return result;
}

/// @func octree_ray_intersect(octree, ray)
function octree_ray_intersect(octree, ray) {
    gml_pragma("forceinline");
    if (!ray_intersects_box(ray, octree[OCTREE.box])) return false;
    
    var triangles = [];
    octree_get_ray_triangles(octree, ray, triangles);
    
    var bestResult = false;
    var minDistance = infinity;
    
    var n = array_length(triangles);
    for (var i = 0; i < n; i++) {
        var tri = triangles[i];
        var hit = ray_intersect_triangle(ray, tri[0], tri[1], tri[2], false, global.__UE_OCT_V1);
        if (hit != undefined) {
            var dist = vec3_distance_to(global.__UE_OCT_V1, [ray[0], ray[1], ray[2]]);
            if (dist < minDistance) {
                minDistance = dist;
                var normal = vec3_create();
                tri_get_normal(tri, normal);
                bestResult = {
                    distance: dist,
                    point: vec3_clone(global.__UE_OCT_V1),
                    normal: normal,
                    triangle: tri
                };
            }
        }
    }
    return bestResult;
}
