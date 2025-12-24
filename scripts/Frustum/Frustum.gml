/// @desc Frustum functions. A frustum is an array of 6 planes.

function frustum_create() {
    gml_pragma("forceinline");
    return [
        plane_create(),
        plane_create(),
        plane_create(),
        plane_create(),
        plane_create(),
        plane_create()
    ];
}

function frustum_clone(f) {
    gml_pragma("forceinline");
    return [
        plane_clone(f[0]),
        plane_clone(f[1]),
        plane_clone(f[2]),
        plane_clone(f[3]),
        plane_clone(f[4]),
        plane_clone(f[5])
    ];
}

function frustum_copy(f, src) {
    gml_pragma("forceinline");
    plane_copy(f[0], src[0]);
    plane_copy(f[1], src[1]);
    plane_copy(f[2], src[2]);
    plane_copy(f[3], src[3]);
    plane_copy(f[4], src[4]);
    plane_copy(f[5], src[5]);
}

function frustum_set(f, p0, p1, p2, p3, p4, p5) {
    gml_pragma("forceinline");
    plane_copy(f[0], p0);
    plane_copy(f[1], p1);
    plane_copy(f[2], p2);
    plane_copy(f[3], p3);
    plane_copy(f[4], p4);
    plane_copy(f[5], p5);
}

/// @func frustum_set_from_matrix(f, m)
/// @desc Sets frustum planes from a projection (or view-projection) matrix.
function frustum_set_from_matrix(f, m) {
    gml_pragma("forceinline");
    
    var me0 = m[0], me1 = m[1], me2 = m[2], me3 = m[3];
    var me4 = m[4], me5 = m[5], me6 = m[6], me7 = m[7];
    var me8 = m[8], me9 = m[9], me10 = m[10], me11 = m[11];
    var me12 = m[12], me13 = m[13], me14 = m[14], me15 = m[15];

    var p0 = f[0], p1 = f[1], p2 = f[2];
    var p3 = f[3], p4 = f[4], p5 = f[5];

    // Left
    plane_set(p0, me3 + me0, me7 + me4, me11 + me8, me15 + me12);
    plane_normalize(p0);

    // Right
    plane_set(p1, me3 - me0, me7 - me4, me11 - me8, me15 - me12);
    plane_normalize(p1);

    // Bottom
    plane_set(p2, me3 + me1, me7 + me5, me11 + me9, me15 + me13);
    plane_normalize(p2);

    // Top
    plane_set(p3, me3 - me1, me7 - me5, me11 - me9, me15 - me13);
    plane_normalize(p3);

    // Near
    plane_set(p4, me3 + me2, me7 + me6, me11 + me10, me15 + me14);
    plane_normalize(p4);

    // Far
    plane_set(p5, me3 - me2, me7 - me6, me11 - me10, me15 - me14);
    plane_normalize(p5);
}

function frustum_set_from_projection_matrix(f, m, reversedDepth = false) {
    gml_pragma("forceinline");
    frustum_set_from_matrix(f, m);
    if (reversedDepth) {
        var tmp = plane_clone(f[4]);
        plane_copy(f[4], f[5]);
        plane_copy(f[5], tmp);
    }
}

/// @func frustum_intersects_sphere(f, s)
/// @desc Returns true if sphere intersects the frustum.
function frustum_intersects_sphere(f, s) {
    gml_pragma("forceinline");
    var _x = s[0], _y = s[1], _z = s[2], _r = s[3];
    var negR = -_r;
    
    for (var i = 0; i < 6; i++) {
        var p = f[i];
        var dist = p[0] * _x + p[1] * _y + p[2] * _z + p[3];
        if (dist < negR) return false;
    }
    return true;
}

/// @func frustum_contains_point(f, x, y, z)
/// @desc Returns true if point is inside frustum.
function frustum_contains_point(f, _x, _y, _z) {
    gml_pragma("forceinline");
    for (var i = 0; i < 6; i++) {
        var p = f[i];
        if (p[0] * _x + p[1] * _y + p[2] * _z + p[3] < 0) return false;
    }
    return true;
}

function frustum_contains_point_vec(f, v) {
    gml_pragma("forceinline");
    return frustum_contains_point(f, v[0], v[1], v[2]);
}

/// @func frustum_intersects_box(f, b)
/// @desc Returns true if box intersects frustum.
function frustum_intersects_box(f, b) {
    gml_pragma("forceinline");
    var minX = b[0], minY = b[1], minZ = b[2];
    var maxX = b[3], maxY = b[4], maxZ = b[5];

    // For each plane
    for (var i = 0; i < 6; i++) {
        var p = f[i];
        var nx = p[0], ny = p[1], nz = p[2], d = p[3];
        
        // Find point on positive side of plane (p-vertex)
        var px = (nx > 0) ? maxX : minX;
        var py = (ny > 0) ? maxY : minY;
        var pz = (nz > 0) ? maxZ : minZ;
        
        if (nx * px + ny * py + nz * pz + d < 0) {
            // This checks if the "positive" corner is behind the plane.
            // If the corner furthest in the normal direction is behind, then the whole box is behind (outside).
            return false;
        }
    }
    return true;
}

// Methods specific to Unique Engine
// function frustum_intersects_object(f, object) {
//     gml_pragma("forceinline");
//     var s = object.__intersectionSphere;
//     if (s == undefined) return true;
//     return frustum_intersects_sphere(f, s);
// }

// function frustum_intersects_sprite(f, sprite) {
//     gml_pragma("forceinline");
//     var s = sprite.__intersectionSphere;
//     if (s != undefined) return frustum_intersects_sphere(f, s);
//     return true;
// }
