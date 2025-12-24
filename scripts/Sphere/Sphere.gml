/// @desc Sphere functions using arrays [x, y, z, radius]

function sphere_create(x = 0, y = 0, z = 0, r = 0) {
    gml_pragma("forceinline");
    return [x, y, z, r];
}

function sphere_set(s, x, y, z, r) {
    gml_pragma("forceinline");
    s[0] = x;
    s[1] = y;
    s[2] = z;
    s[3] = r;
}

function sphere_copy(s, src) {
    gml_pragma("forceinline");
    s[0] = src[0];
    s[1] = src[1];
    s[2] = src[2];
    s[3] = src[3];
}

function sphere_clone(s) {
    gml_pragma("forceinline");
    return [s[0], s[1], s[2], s[3]];
}

/// @func sphere_apply_matrix4(s, m)
/// @desc Transforms the sphere by the given matrix 4.
function sphere_apply_matrix4(s, m) {
    gml_pragma("forceinline");
    var _x = s[0], _y = s[1], _z = s[2], r = s[3];
    var w = m[3] * _x + m[7] * _y + m[11] * _z + m[15];
    w = (w != 0) ? (1 / w) : 1;
    s[0] = (m[0] * _x + m[4] * _y + m[8] * _z + m[12]) * w;
    s[1] = (m[1] * _x + m[5] * _y + m[9] * _z + m[13]) * w;
    s[2] = (m[2] * _x + m[6] * _y + m[10] * _z + m[14]) * w;
    var sx = m[0]*m[0] + m[1]*m[1] + m[2]*m[2];
    var sy = m[4]*m[4] + m[5]*m[5] + m[6]*m[6];
    var sz = m[8]*m[8] + m[9]*m[9] + m[10]*m[10];
    var maxScale = sqrt(max(sx, sy, sz));
    
    s[3] = r * maxScale;
}

/// @func sphere_contains_point(s, px, py, pz)
function sphere_contains_point(s, px, py, pz) {
    gml_pragma("forceinline");
    var dx = px - s[0];
    var dy = py - s[1];
    var dz = pz - s[2];
    return (dx*dx + dy*dy + dz*dz) <= (s[3] * s[3]);
}

/// @func sphere_intersects_sphere(s1, s2)
function sphere_intersects_sphere(s1, s2) {
    gml_pragma("forceinline");
    var rSum = s1[3] + s2[3];
    var dx = s1[0] - s2[0];
    var dy = s1[1] - s2[1];
    var dz = s1[2] - s2[2];
    return (dx*dx + dy*dy + dz*dz) <= (rSum * rSum);
}

function sphere_equals(a, b) {
    gml_pragma("forceinline");
    return a[0]==b[0] && a[1]==b[1] && a[2]==b[2] && a[3]==b[3];
}

function sphere_distance_to_point(s, px, py, pz) {
    gml_pragma("forceinline");
    var dx = px - s[0];
    var dy = py - s[1];
    var dz = pz - s[2];
    return sqrt(dx*dx + dy*dy + dz*dz) - s[3];
}

function sphere_clamp_point(s, px, py, pz, out = undefined) {
    gml_pragma("forceinline");
    var dx = px - s[0];
    var dy = py - s[1];
    var dz = pz - s[2];
    var d2 = dx*dx + dy*dy + dz*dz;
    out ??= array_create(3);
    if (d2 > (s[3]*s[3])) {
        var d = sqrt(d2);
        var f = s[3] / d;
        out[0] = s[0] + dx * f;
        out[1] = s[1] + dy * f;
        out[2] = s[2] + dz * f;
    } else {
        out[0] = px; out[1] = py; out[2] = pz;
    }
    return out;
}

function sphere_expand_by_point(s, px, py, pz) {
    gml_pragma("forceinline");
    if (s[3] < 0) {
        s[0] = px; s[1] = py; s[2] = pz; s[3] = 0;
        return;
    }
    var dx = px - s[0];
    var dy = py - s[1];
    var dz = pz - s[2];
    var d = sqrt(dx*dx + dy*dy + dz*dz);
    if (d > s[3]) s[3] = d;
}

function sphere_is_empty(s) {
    gml_pragma("forceinline");
    return s[3] < 0;
}

function sphere_make_empty(s) {
    gml_pragma("forceinline");
    s[0] = 0; s[1] = 0; s[2] = 0; s[3] = -1;
}

function sphere_translate(s, ox, oy, oz) {
    gml_pragma("forceinline");
    s[0] += ox; s[1] += oy; s[2] += oz;
}

function sphere_get_bounding_box(s, out = undefined) {
    gml_pragma("forceinline");
    var r = s[3];
    out ??= box3_create();
    box3_set(out, s[0]-r, s[1]-r, s[2]-r, s[0]+r, s[1]+r, s[2]+r);
    return out;
}

function sphere_intersects_box(s, box) {
    gml_pragma("forceinline");
    var cx = s[0], cy = s[1], cz = s[2];
    var _x = clamp(cx, box[0], box[3]);
    var _y = clamp(cy, box[1], box[4]);
    var _z = clamp(cz, box[2], box[5]);
    var dx = _x - cx, dy = _y - cy, dz = _z - cz;
    return (dx*dx + dy*dy + dz*dz) <= (s[3]*s[3]);
}

function sphere_intersects_plane(s, plane) {
    gml_pragma("forceinline");
    var d = plane_distance_to_point(plane, s[0], s[1], s[2]);
    return abs(d) <= s[3];
}

function sphere_union(s, s2) {
    gml_pragma("forceinline");
    var x1 = s[0], y1 = s[1], z1 = s[2], r1 = s[3];
    var x2 = s2[0], y2 = s2[1], z2 = s2[2], r2 = s2[3];
    var dx = x2 - x1, dy = y2 - y1, dz = z2 - z1;
    var d = sqrt(dx*dx + dy*dy + dz*dz);
    if (r1 >= d + r2) return s;
    if (r2 >= d + r1) { s[0]=x2; s[1]=y2; s[2]=z2; s[3]=r2; return s; }
    var newR = (d + r1 + r2) * 0.5;
    var t = (newR - r1) / d;
    s[0] = x1 + dx * t;
    s[1] = y1 + dy * t;
    s[2] = z1 + dz * t;
    s[3] = newR;
    return s;
}

function sphere_set_from_points(s, points, optionalCenter = undefined) {
    gml_pragma("forceinline");
    var n = array_length(points);
    if (n == 0) return s;
    if (optionalCenter != undefined) {
        s[0] = optionalCenter[0]; s[1] = optionalCenter[1]; s[2] = optionalCenter[2];
    } else {
        var minX = infinity, minY = infinity, minZ = infinity;
        var maxX = -infinity, maxY = -infinity, maxZ = -infinity;
        for (var i=0; i<n; i++) {
            var p = points[i];
            var px = p[0], py = p[1], pz = p[2];
            if (px < minX) minX = px; if (py < minY) minY = py; if (pz < minZ) minZ = pz;
            if (px > maxX) maxX = px; if (py > maxY) maxY = py; if (pz > maxZ) maxZ = pz;
        }
        s[0] = (minX + maxX) * 0.5;
        s[1] = (minY + maxY) * 0.5;
        s[2] = (minZ + maxZ) * 0.5;
    }
    s[3] = 0;
    for (var j=0; j<n; j++) {
        var q = points[j];
        var dx = q[0] - s[0], dy = q[1] - s[1], dz = q[2] - s[2];
        var dist = sqrt(dx*dx + dy*dy + dz*dz);
        if (dist > s[3]) s[3] = dist;
    }
    return s;
}
