/// @desc Triangle functions using arrays of Vector3 [[x,y,z], [x,y,z], [x,y,z]]
/// All functions modify the target vector or triangle in-place when applicable.

// Global temp vectors for triangle operations
global.UE_TRI_VBA = vec3_create();
global.UE_TRI_VCA = vec3_create();
global.UE_TRI_VPA = vec3_create();
global.UE_TRI_VPB = vec3_create();
global.UE_TRI_VPC = vec3_create();
global.UE_TRI_VCB = vec3_create();
global.UE_TRI_BARY = vec3_create();

/// @func tri_create(a, b, c)
/// @desc Creates a new triangle.
/// @param {Array<Real>} [a] Corner A
/// @param {Array<Real>} [b] Corner B
/// @param {Array<Real>} [c] Corner C
/// @returns {Array<Array<Real>>} New triangle
function tri_create(a = undefined, b = undefined, c = undefined) {
    gml_pragma("forceinline");
    return [
        (a == undefined) ? vec3_create() : vec3_clone(a),
        (b == undefined) ? vec3_create() : vec3_clone(b),
        (c == undefined) ? vec3_create() : vec3_clone(c)
    ];
}

/// @func tri_set(tri, a, b, c)
/// @desc Sets the triangle vertices.
/// @param {Array<Array<Real>>} tri The triangle to modify
/// @param {Array<Real>} a Corner A
/// @param {Array<Real>} b Corner B
/// @param {Array<Real>} c Corner C
/// @returns {Array<Array<Real>>} The modified triangle
function tri_set(tri, a, b, c) {
    gml_pragma("forceinline");
    vec3_copy(tri[0], a);
    vec3_copy(tri[1], b);
    vec3_copy(tri[2], c);
    return tri;
}

/// @func tri_set_from_points_and_indices(tri, points, i0, i1, i2)
/// @desc Sets the triangle from a points array and indices.
/// @param {Array<Array<Real>>} tri The triangle to modify
/// @param {Array<Array<Real>>} points Points array
/// @param {Real} i0 Index 0
/// @param {Real} i1 Index 1
/// @param {Real} i2 Index 2
/// @returns {Array<Array<Real>>} The modified triangle
function tri_set_from_points_and_indices(tri, points, i0, i1, i2) {
    gml_pragma("forceinline");
    vec3_copy(tri[0], points[i0]);
    vec3_copy(tri[1], points[i1]);
    vec3_copy(tri[2], points[i2]);
    return tri;
}

/// @func tri_clone(tri)
/// @desc Clones the triangle.
/// @param {Array<Array<Real>>} tri The triangle to clone
/// @returns {Array<Array<Real>>} A new triangle
function tri_clone(tri) {
    gml_pragma("forceinline");
    return [
        vec3_clone(tri[0]),
        vec3_clone(tri[1]),
        vec3_clone(tri[2])
    ];
}

/// @func tri_copy(tri, src)
/// @desc Copies src triangle to tri.
/// @param {Array<Array<Real>>} tri The target triangle
/// @param {Array<Array<Real>>} src The source triangle
/// @returns {Array<Array<Real>>} The modified triangle
function tri_copy(tri, src) {
    gml_pragma("forceinline");
    vec3_copy(tri[0], src[0]);
    vec3_copy(tri[1], src[1]);
    vec3_copy(tri[2], src[2]);
    return tri;
}

/// @func tri_get_area(tri)
/// @desc Calculates the area of the triangle.
/// @param {Array<Array<Real>>} tri The triangle
/// @returns {Real} The area
function tri_get_area(tri) {
    gml_pragma("forceinline");
    var a = tri[0], b = tri[1], c = tri[2];
    vec3_sub_vectors(global.UE_TRI_VBA, b, a);
    vec3_sub_vectors(global.UE_TRI_VCA, c, a);
    vec3_cross(global.UE_TRI_VBA, global.UE_TRI_VCA);
    return vec3_length(global.UE_TRI_VBA) * 0.5;
}

/// @func tri_get_midpoint(tri, target)
/// @desc Calculates the midpoint of the triangle.
/// @param {Array<Array<Real>>} tri The triangle
/// @param {Array<Real>} target The target vector
/// @returns {Array<Real>} The target vector
function tri_get_midpoint(tri, target) {
    gml_pragma("forceinline");
    var a = tri[0], b = tri[1], c = tri[2];
    target[0] = (a[0] + b[0] + c[0]) / 3;
    target[1] = (a[1] + b[1] + c[1]) / 3;
    target[2] = (a[2] + b[2] + c[2]) / 3;
    return target;
}

/// @func tri_get_normal(tri, target)
/// @desc Calculates the normal of the triangle.
/// @param {Array<Array<Real>>} tri The triangle
/// @param {Array<Real>} target The target vector
/// @returns {Array<Real>} The target vector
function tri_get_normal(tri, target) {
    gml_pragma("forceinline");
    var a = tri[0], b = tri[1], c = tri[2];
    vec3_sub_vectors(target, c, b);
    vec3_sub_vectors(global.UE_TRI_VBA, a, b);
    vec3_cross(target, global.UE_TRI_VBA);
    
    var lenSq = target[0]*target[0] + target[1]*target[1] + target[2]*target[2];
    if (lenSq > 0) {
        return vec3_divide_scalar(target, sqrt(lenSq));
    }
    return vec3_set(target, 0, 0, 0);
}

/// @func tri_get_plane(tri, target)
/// @desc Calculates the plane of the triangle.
/// @param {Array<Array<Real>>} tri The triangle
/// @param {Array<Real>} target The target plane [nx, ny, nz, constant]
/// @returns {Array<Real>} The target plane
function tri_get_plane(tri, target) {
    gml_pragma("forceinline");
    return plane_set_from_coplanar_points(target, tri[0], tri[1], tri[2]);
}

/// @func tri_get_barycoord(tri, point, target)
/// @desc Calculates barycentric coordinates for a point.
/// @param {Array<Array<Real>>} tri The triangle
/// @param {Array<Real>} point The point
/// @param {Array<Real>} target The target vector
/// @returns {Array<Real>|undefined} Barycentric coordinates or undefined if degenerate
function tri_get_barycoord(tri, point, target) {
    gml_pragma("forceinline");
    var a = tri[0], b = tri[1], c = tri[2];
    vec3_sub_vectors(global.UE_TRI_VBA, c, a);
    vec3_sub_vectors(global.UE_TRI_VCA, b, a);
    vec3_sub_vectors(global.UE_TRI_VPA, point, a);

    var dot00 = vec3_dot(global.UE_TRI_VBA, global.UE_TRI_VBA);
    var dot01 = vec3_dot(global.UE_TRI_VBA, global.UE_TRI_VCA);
    var dot02 = vec3_dot(global.UE_TRI_VBA, global.UE_TRI_VPA);
    var dot11 = vec3_dot(global.UE_TRI_VCA, global.UE_TRI_VCA);
    var dot12 = vec3_dot(global.UE_TRI_VCA, global.UE_TRI_VPA);

    var denom = (dot00 * dot11 - dot01 * dot01);

    if (denom == 0) {
        // Degenerate triangle
        return undefined;
    }

    var invDenom = 1 / denom;
    var u = (dot11 * dot02 - dot01 * dot12) * invDenom;
    var v = (dot00 * dot12 - dot01 * dot02) * invDenom;

    target[0] = 1 - u - v;
    target[1] = v;
    target[2] = u;

    return target;
}

/// @func tri_contains_point(tri, point)
/// @desc Checks if the point lies within the triangle.
/// @param {Array<Array<Real>>} tri The triangle
/// @param {Array<Real>} point The point
/// @returns {Bool}
function tri_contains_point(tri, point) {
    gml_pragma("forceinline");
    if (tri_get_barycoord(tri, point, global.UE_TRI_BARY) == undefined) return false;
    var bary = global.UE_TRI_BARY;
    return (bary[0] >= 0) && (bary[1] >= 0) && (bary[0] + bary[1] <= 1);
}

/// @func tri_get_interpolation(tri, point, v1, v2, v3, target)
/// @desc Interpolates values v1, v2, v3 based on the point's position in the triangle.
/// @param {Array<Array<Real>>} tri The triangle
/// @param {Array<Real>} point The point
/// @param {Array<Real>} v1 Value at corner 1
/// @param {Array<Real>} v2 Value at corner 2
/// @param {Array<Real>} v3 Value at corner 3
/// @param {Array<Real>} target The target vector
/// @returns {Array<Real>|undefined} The target vector or undefined if outside
function tri_get_interpolation(tri, point, v1, v2, v3, target) {
    gml_pragma("forceinline");
    if (tri_get_barycoord(tri, point, global.UE_TRI_BARY) == undefined) return undefined;
    var bary = global.UE_TRI_BARY;
    target[0] = v1[0] * bary[0] + v2[0] * bary[1] + v3[0] * bary[2];
    target[1] = v1[1] * bary[0] + v2[1] * bary[1] + v3[1] * bary[2];
    target[2] = v1[2] * bary[0] + v2[2] * bary[1] + v3[2] * bary[2];
    return target;
}

/// @func tri_is_front_facing(tri, direction)
/// @desc Checks if the triangle is front-facing to the given direction.
/// @param {Array<Array<Real>>} tri The triangle
/// @param {Array<Real>} direction The direction vector
/// @returns {Bool}
function tri_is_front_facing(tri, direction) {
    gml_pragma("forceinline");
    tri_get_normal(tri, global.UE_TRI_VBA);
    return vec3_dot(global.UE_TRI_VBA, direction) < 0;
}

/// @func tri_closest_point_to_point(tri, p, target)
function tri_closest_point_to_point(tri, p, target) {
    gml_pragma("forceinline");
    var a = tri[0], b = tri[1], c = tri[2];
    var v, w;

    // algorithm is from Real-Time Collision Detection by Christer Ericson,
    // section 5.1.5, Closest Point on Triangle to Point

    vec3_sub_vectors(global.UE_TRI_VBA, b, a);
    vec3_sub_vectors(global.UE_TRI_VCA, c, a);
    vec3_sub_vectors(global.UE_TRI_VPA, p, a);
    var d1 = vec3_dot(global.UE_TRI_VBA, global.UE_TRI_VPA);
    var d2 = vec3_dot(global.UE_TRI_VCA, global.UE_TRI_VPA);
    if (d1 <= 0 && d2 <= 0) {
        return vec3_copy(target, a);
    }

    vec3_sub_vectors(global.UE_TRI_VPB, p, b);
    var d3 = vec3_dot(global.UE_TRI_VBA, global.UE_TRI_VPB);
    var d4 = vec3_dot(global.UE_TRI_VCA, global.UE_TRI_VPB);
    if (d3 >= 0 && d4 <= d3) {
        return vec3_copy(target, b);
    }

    var vc = d1 * d4 - d3 * d2;
    if (vc <= 0 && d1 >= 0 && d3 <= 0) {
        v = d1 / (d1 - d3);
        return vec3_add_scaled_vector(vec3_copy(target, a), global.UE_TRI_VBA, v);
    }

    vec3_sub_vectors(global.UE_TRI_VPC, p, c);
    var d5 = vec3_dot(global.UE_TRI_VBA, global.UE_TRI_VPC);
    var d6 = vec3_dot(global.UE_TRI_VCA, global.UE_TRI_VPC);
    if (d6 >= 0 && d5 <= d6) {
        return vec3_copy(target, c);
    }

    var vb = d5 * d2 - d1 * d6;
    if (vb <= 0 && d2 >= 0 && d6 <= 0) {
        w = d2 / (d2 - d6);
        return vec3_add_scaled_vector(vec3_copy(target, a), global.UE_TRI_VCA, w);
    }

    var va = d3 * d6 - d5 * d4;
    if (va <= 0 && (d4 - d3) >= 0 && (d5 - d6) >= 0) {
        vec3_sub_vectors(global.UE_TRI_VCB, c, b);
        w = (d4 - d3) / ((d4 - d3) + (d5 - d6));
        return vec3_add_scaled_vector(vec3_copy(target, b), global.UE_TRI_VCB, w);
    }

    // face region
    var denom = 1 / (va + vb + vc);
    v = vb * denom;
    w = vc * denom;

    return vec3_add_scaled_vector(vec3_add_scaled_vector(vec3_copy(target, a), global.UE_TRI_VBA, v), global.UE_TRI_VCA, w);
}

/// @func tri_equals(tri, other)
function tri_equals(tri, other) {
    gml_pragma("forceinline");
    return vec3_equals(tri[0], other[0]) && vec3_equals(tri[1], other[1]) && vec3_equals(tri[2], other[2]);
}

/// @func tri_intersects_box(tri, box)
function tri_intersects_box(tri, box) {
    gml_pragma("forceinline");
    return box3_intersects_triangle(box, tri[0], tri[1], tri[2]);
}
