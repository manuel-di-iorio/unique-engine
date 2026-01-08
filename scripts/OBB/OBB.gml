/// @desc Oriented Bounding Box (OBB) implementation using arrays.
/// Layout: [cX, cY, cZ, hX, hY, hZ, r0, r1, r2, r3, r4, r5, r6, r7, r8]
/// center (0-2), halfSize (3-5), rotation mat3 (6-14)

enum OBB {
    cX = 0, cY = 1, cZ = 2,
    hX = 3, hY = 4, hZ = 5,
    r0 = 6, r1 = 7, r2 = 8,
    r3 = 9, r4 = 10, r5 = 11,
    r6 = 12, r7 = 13, r8 = 14
}

// Global temp OBBs to avoid allocations
global.UE_OBB_TEMP0 = obb_create();
global.UE_OBB_TEMP1 = obb_create();
global.UE_OBB_TEMP2 = obb_create();

// Internal temp arrays for SAT and other calculations
global.UE_OBB_INTERNAL_MAT3 = mat3_create();
global.UE_OBB_INTERNAL_VEC3_0 = vec3_create();
global.UE_OBB_INTERNAL_VEC3_1 = vec3_create();
global.UE_OBB_INTERNAL_VEC3_2 = vec3_create();

/// @func obb_create(center, halfSize, rotation)
/// @desc Creates a new OBB array.
/// @param {Array<Real>} [center=[0,0,0]] The center of the OBB
/// @param {Array<Real>} [halfSize=[1,1,1]] The half-extents of the OBB
/// @param {Array<Real>} [rotation=Identity] The 3x3 rotation matrix
/// @returns {Array<Real>} A new OBB array [15]
function obb_create(center = undefined, halfSize = undefined, rotation = undefined) {
    var _obb = array_create(15, 0);
    
    if (center != undefined) {
        _obb[0] = center[0]; _obb[1] = center[1]; _obb[2] = center[2];
    } else {
        _obb[0] = 0; _obb[1] = 0; _obb[2] = 0;
    }
    
    if (halfSize != undefined) {
        _obb[3] = halfSize[0]; _obb[4] = halfSize[1]; _obb[5] = halfSize[2];
    } else {
        _obb[3] = 1; _obb[4] = 1; _obb[5] = 1;
    }
    
    if (rotation != undefined) {
        for (var i = 0; i < 9; i++) _obb[6 + i] = rotation[i];
    } else {
        _obb[6] = 1; _obb[7] = 0; _obb[8] = 0;
        _obb[9] = 0; _obb[10] = 1; _obb[11] = 0;
        _obb[12] = 0; _obb[13] = 0; _obb[14] = 1;
    }
    
    return _obb;
}

/// @func obb_set(obb, center, halfSize, rotation)
/// @desc Sets the OBB components.
/// @param {Array<Real>} obb The OBB to modify
/// @param {Array<Real>} center The center
/// @param {Array<Real>} halfSize The half-extents
/// @param {Array<Real>} rotation The rotation matrix
/// @returns {Array<Real>} The modified OBB
function obb_set(obb, center, halfSize, rotation) {
    gml_pragma("forceinline");
    obb[0] = center[0]; obb[1] = center[1]; obb[2] = center[2];
    obb[3] = halfSize[0]; obb[4] = halfSize[1]; obb[5] = halfSize[2];
    for (var i = 0; i < 9; i++) obb[6 + i] = rotation[i];
    return obb;
}

/// @func obb_copy(obb, src)
/// @desc Copies values from another OBB.
/// @param {Array<Real>} obb The OBB to modify
/// @param {Array<Real>} src The OBB to copy from
/// @returns {Array<Real>} The modified OBB
function obb_copy(obb, src) {
    gml_pragma("forceinline");
    array_copy(obb, 0, src, 0, 15);
    return obb;
}

/// @func obb_clone(obb)
/// @desc Clones the OBB.
/// @param {Array<Real>} obb The OBB to clone
/// @returns {Array<Real>} A new OBB array
function obb_clone(obb) {
    gml_pragma("forceinline");
    var _new = array_create(15);
    array_copy(_new, 0, obb, 0, 15);
    return _new;
}

/// @func obb_equals(obb1, obb2)
/// @desc Checks if two OBBs are equal.
function obb_equals(obb1, obb2) {
    gml_pragma("forceinline");
    for (var i = 0; i < 15; i++) {
        if (obb1[i] != obb2[i]) return false;
    }
    return true;
}

/// @func obb_get_center(obb, out=undefined)
/// @desc Gets the center of the OBB.
function obb_get_center(obb, out = undefined) {
    gml_pragma("forceinline");
    out ??= array_create(3);
    out[0] = obb[0]; out[1] = obb[1]; out[2] = obb[2];
    return out;
}

/// @func obb_get_half_size(obb, out=undefined)
/// @desc Gets the half-size of the OBB.
function obb_get_half_size(obb, out = undefined) {
    gml_pragma("forceinline");
    out ??= array_create(3);
    out[0] = obb[3]; out[1] = obb[4]; out[2] = obb[5];
    return out;
}

/// @func obb_get_rotation(obb, out=undefined)
/// @desc Gets the rotation matrix of the OBB.
function obb_get_rotation(obb, out = undefined) {
    gml_pragma("forceinline");
    out ??= array_create(9);
    array_copy(out, 0, obb, 6, 9);
    return out;
}

/// @func obb_contains_point(obb, point)
/// @desc Checks if the OBB contains a point.
function obb_contains_point(obb, point) {
    gml_pragma("forceinline");
    var px = point[0] - obb[0];
    var py = point[1] - obb[1];
    var pz = point[2] - obb[2];
    
    var dx = px * obb[6] + py * obb[7] + pz * obb[8];
    var dy = px * obb[9] + py * obb[10] + pz * obb[11];
    var dz = px * obb[12] + py * obb[13] + pz * obb[14];
    
    return abs(dx) <= obb[3] && abs(dy) <= obb[4] && abs(dz) <= obb[5];
}

/// @func obb_clamp_point(obb, point, out=undefined)
/// @desc Clamps a point to the OBB.
function obb_clamp_point(obb, point, out = undefined) {
    gml_pragma("forceinline");
    out ??= array_create(3);
    
    var px = point[0] - obb[0];
    var py = point[1] - obb[1];
    var pz = point[2] - obb[2];
    
    var dx = px * obb[6] + py * obb[7] + pz * obb[8];
    var dy = px * obb[9] + py * obb[10] + pz * obb[11];
    var dz = px * obb[12] + py * obb[13] + pz * obb[14];
    
    dx = clamp(dx, -obb[3], obb[3]);
    dy = clamp(dy, -obb[4], obb[4]);
    dz = clamp(dz, -obb[5], obb[5]);
    
    out[0] = obb[0] + dx * obb[6] + dy * obb[9] + dz * obb[12];
    out[1] = obb[1] + dx * obb[7] + dy * obb[10] + dz * obb[13];
    out[2] = obb[2] + dx * obb[8] + dy * obb[11] + dz * obb[14];
    
    return out;
}

/// @func obb_intersects_sphere(obb, sphere)
/// @desc Checks if OBB intersects a sphere.
function obb_intersects_sphere(obb, sphere) {
    gml_pragma("forceinline");
    var closest = obb_clamp_point(obb, sphere, global.UE_VEC3_TEMP0);
    var dx = closest[0] - sphere[0];
    var dy = closest[1] - sphere[1];
    var dz = closest[2] - sphere[2];
    var distSq = dx*dx + dy*dy + dz*dz;
    return distSq <= (sphere[3] * sphere[3]);
}

/// @func obb_intersects_box3(obb, box3)
/// @desc Checks if OBB intersects an AABB.
function obb_intersects_box3(obb, box3) {
    gml_pragma("forceinline");
    var obb2 = global.UE_OBB_TEMP0;
    obb_from_box3(obb2, box3);
    return obb_intersects_obb(obb, obb2);
}

/// @func obb_intersects_plane(obb, plane)
/// @desc Checks if OBB intersects a plane.
function obb_intersects_plane(obb, plane) {
    gml_pragma("forceinline");
    var nx = plane[0], ny = plane[1], nz = plane[2];
    
    var r = obb[3] * abs(nx * obb[6] + ny * obb[7] + nz * obb[8]) +
            obb[4] * abs(nx * obb[9] + ny * obb[10] + nz * obb[11]) +
            obb[5] * abs(nx * obb[12] + ny * obb[13] + nz * obb[14]);
            
    var dist = nx * obb[0] + ny * obb[1] + nz * obb[2] - plane[3];
    return abs(dist) <= r;
}

/// @func obb_intersects_obb(obb1, obb2)
/// @desc Checks if two OBBs intersect using SAT.
function obb_intersects_obb(obb1, obb2) {
    var eps = 0.000001;
    
    // Rotation of B relative to A: R = A^T * B
    var aX = global.UE_OBB_INTERNAL_VEC3_0;
    var aY = global.UE_OBB_INTERNAL_VEC3_1;
    var aZ = global.UE_OBB_INTERNAL_VEC3_2;
    vec3_set(aX, obb1[6], obb1[7], obb1[8]);
    vec3_set(aY, obb1[9], obb1[10], obb1[11]);
    vec3_set(aZ, obb1[12], obb1[13], obb1[14]);
    
    var bX = global.UE_VEC3_TEMP0;
    var bY = global.UE_VEC3_TEMP1;
    var bZ = global.UE_VEC3_TEMP2;
    vec3_set(bX, obb2[6], obb2[7], obb2[8]);
    vec3_set(bY, obb2[9], obb2[10], obb2[11]);
    vec3_set(bZ, obb2[12], obb2[13], obb2[14]);
    
    var R = global.UE_OBB_INTERNAL_MAT3;
    R[0] = vec3_dot(aX, bX); R[3] = vec3_dot(aX, bY); R[6] = vec3_dot(aX, bZ);
    R[1] = vec3_dot(aY, bX); R[4] = vec3_dot(aY, bY); R[7] = vec3_dot(aY, bZ);
    R[2] = vec3_dot(aZ, bX); R[5] = vec3_dot(aZ, bY); R[8] = vec3_dot(aZ, bZ);
    
    var tArr = global.UE_VEC3_TEMP3;
    vec3_set(tArr, obb2[0] - obb1[0], obb2[1] - obb1[1], obb2[2] - obb1[2]);
    var t = global.UE_VEC3_TEMP4;
    vec3_set(t, vec3_dot(tArr, aX), vec3_dot(tArr, aY), vec3_dot(tArr, aZ));
    
    var AbsR = global.UE_MAT3_TEMP0;
    for (var i = 0; i < 9; i++) AbsR[i] = abs(R[i]) + eps;
    
    var ra, rb;
    
    for (var i = 0; i < 3; i++) {
        ra = obb1[3 + i];
        rb = obb2[3] * AbsR[i] + obb2[4] * AbsR[i + 3] + obb2[5] * AbsR[i + 6];
        if (abs(t[i]) > ra + rb) return false;
    }
    
    for (var i = 0; i < 3; i++) {
        ra = obb1[3] * AbsR[i*3] + obb1[4] * AbsR[i*3 + 1] + obb1[5] * AbsR[i*3 + 2];
        rb = obb2[3 + i];
        if (abs(t[0]*R[i*3] + t[1]*R[i*3+1] + t[2]*R[i*3+2]) > ra + rb) return false;
    }
    
    ra = obb1[4] * AbsR[2] + obb1[5] * AbsR[1];
    rb = obb2[4] * AbsR[6] + obb2[5] * AbsR[3];
    if (abs(t[2]*R[1] - t[1]*R[2]) > ra + rb) return false;
    
    ra = obb1[4] * AbsR[5] + obb1[5] * AbsR[4];
    rb = obb2[3] * AbsR[6] + obb2[5] * AbsR[0];
    if (abs(t[2]*R[4] - t[1]*R[5]) > ra + rb) return false;
    
    ra = obb1[4] * AbsR[8] + obb1[5] * AbsR[7];
    rb = obb2[3] * AbsR[3] + obb2[4] * AbsR[0];
    if (abs(t[2]*R[7] - t[1]*R[8]) > ra + rb) return false;
    
    ra = obb1[3] * AbsR[2] + obb1[5] * AbsR[0];
    rb = obb2[4] * AbsR[7] + obb2[5] * AbsR[4];
    if (abs(t[0]*R[2] - t[2]*R[0]) > ra + rb) return false;
    
    ra = obb1[3] * AbsR[5] + obb1[5] * AbsR[3];
    rb = obb2[3] * AbsR[7] + obb2[5] * AbsR[1];
    if (abs(t[0]*R[5] - t[2]*R[3]) > ra + rb) return false;
    
    ra = obb1[3] * AbsR[8] + obb1[5] * AbsR[6];
    rb = obb2[3] * AbsR[4] + obb2[4] * AbsR[1];
    if (abs(t[0]*R[8] - t[2]*R[6]) > ra + rb) return false;
    
    ra = obb1[3] * AbsR[1] + obb1[4] * AbsR[0];
    rb = obb2[4] * AbsR[8] + obb2[5] * AbsR[5];
    if (abs(t[1]*R[0] - t[0]*R[1]) > ra + rb) return false;
    
    ra = obb1[3] * AbsR[4] + obb1[4] * AbsR[3];
    rb = obb2[3] * AbsR[8] + obb2[5] * AbsR[2];
    if (abs(t[1]*R[3] - t[0]*R[4]) > ra + rb) return false;
    
    ra = obb1[3] * AbsR[7] + obb1[4] * AbsR[6];
    rb = obb2[3] * AbsR[5] + obb2[4] * AbsR[2];
    if (abs(t[1]*R[6] - t[0]*R[7]) > ra + rb) return false;
    
    return true;
}

/// @func obb_intersect_ray(obb, ray, out=undefined)
/// @desc Checks if ray intersects OBB.
function obb_intersect_ray(obb, ray, out = undefined) {
    var rx = ray[0] - obb[0];
    var ry = ray[1] - obb[1];
    var rz = ray[2] - obb[2];
    
    var lOrigin = global.UE_VEC3_TEMP0;
    vec3_set(lOrigin,
        rx * obb[6] + ry * obb[7] + rz * obb[8],
        rx * obb[9] + ry * obb[10] + rz * obb[11],
        rx * obb[12] + ry * obb[13] + rz * obb[14]
    );
    
    var lDir = global.UE_VEC3_TEMP1;
    vec3_set(lDir,
        ray[3] * obb[6] + ray[4] * obb[7] + ray[5] * obb[8],
        ray[3] * obb[9] + ray[4] * obb[10] + ray[5] * obb[11],
        ray[3] * obb[12] + ray[4] * obb[13] + ray[5] * obb[14]
    );
    
    var tMin = -infinity, tMax = infinity;
    
    for (var i = 0; i < 3; i++) {
        var dimMin = -obb[3 + i];
        var dimMax = obb[3 + i];
        
        if (abs(lDir[i]) < 0.000001) {
            if (lOrigin[i] < dimMin || lOrigin[i] > dimMax) return undefined;
        } else {
            var t1 = (dimMin - lOrigin[i]) / lDir[i];
            var t2 = (dimMax - lOrigin[i]) / lDir[i];
            tMin = max(tMin, min(t1, t2));
            tMax = min(tMax, max(t1, t2));
        }
    }
    
    if (tMax < 0 || tMin > tMax) return undefined;
    
    var t = tMin < 0 ? tMax : tMin;
    if (out != undefined) {
        out[0] = ray[0] + ray[3] * t;
        out[1] = ray[1] + ray[4] * t;
        out[2] = ray[2] + ray[5] * t;
    }
    return t;
}

/// @func obb_from_box3(obb, box3)
/// @desc Sets OBB from an AABB.
function obb_from_box3(obb, box3) {
    gml_pragma("forceinline");
    obb[0] = (box3[0] + box3[3]) * 0.5;
    obb[1] = (box3[1] + box3[4]) * 0.5;
    obb[2] = (box3[2] + box3[5]) * 0.5;
    
    obb[3] = (box3[3] - box3[0]) * 0.5;
    obb[4] = (box3[4] - box3[1]) * 0.5;
    obb[5] = (box3[5] - box3[2]) * 0.5;
    
    obb[6] = 1; obb[7] = 0; obb[8] = 0;
    obb[9] = 0; obb[10] = 1; obb[11] = 0;
    obb[12] = 0; obb[13] = 0; obb[14] = 1;
    return obb;
}

/// @func obb_apply_matrix4(obb, mat4)
/// @desc Transforms the OBB by a 4x4 matrix.
function obb_apply_matrix4(obb, mat4) {
    gml_pragma("forceinline");
    
    var cx = obb[0], cy = obb[1], cz = obb[2];
    obb[0] = mat4[0]*cx + mat4[4]*cy + mat4[8]*cz + mat4[12];
    obb[1] = mat4[1]*cx + mat4[5]*cy + mat4[9]*cz + mat4[13];
    obb[2] = mat4[2]*cx + mat4[6]*cy + mat4[10]*cz + mat4[14];
    
    var sx = sqrt(mat4[0]*mat4[0] + mat4[1]*mat4[1] + mat4[2]*mat4[2]);
    var sy = sqrt(mat4[4]*mat4[4] + mat4[5]*mat4[5] + mat4[6]*mat4[6]);
    var sz = sqrt(mat4[8]*mat4[8] + mat4[9]*mat4[9] + mat4[10]*mat4[10]);
    
    obb[3] *= sx;
    obb[4] *= sy;
    obb[5] *= sz;
    
    var r11 = mat4[0]/sx, r21 = mat4[1]/sx, r31 = mat4[2]/sx;
    var r12 = mat4[4]/sy, r22 = mat4[5]/sy, r32 = mat4[6]/sy;
    var r13 = mat4[8]/sz, r23 = mat4[9]/sz, r33 = mat4[10]/sz;
    
    var m0=obb[6], m1=obb[7], m2=obb[8], m3=obb[9], m4=obb[10], m5=obb[11], m6=obb[12], m7=obb[13], m8=obb[14];
    
    obb[6]  = r11*m0 + r12*m1 + r13*m2;
    obb[7]  = r21*m0 + r22*m1 + r23*m2;
    obb[8]  = r31*m0 + r32*m1 + r33*m2;
    
    obb[9]  = r11*m3 + r12*m4 + r13*m5;
    obb[10] = r21*m3 + r22*m4 + r23*m5;
    obb[11] = r31*m3 + r32*m4 + r33*m5;
    
    obb[12] = r11*m6 + r12*m7 + r13*m8;
    obb[13] = r21*m6 + r22*m7 + r23*m8;
    obb[14] = r31*m6 + r32*m7 + r33*m8;
    
    return obb;
}
