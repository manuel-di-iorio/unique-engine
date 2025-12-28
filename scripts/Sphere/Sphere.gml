/// @desc Sphere functions using arrays [x, y, z, radius]

enum SPHERE {
  x, y, z, r
}

function sphere_create(center, r = -1) {
  gml_pragma("forceinline");
  center ??= vec3_create();
  return [center[0], center[1], center[2], r];
}

/// @func sphere_set(s, x, y, z, r)
/// @desc Sets the sphere's position and radius.
/// @param {Array<Real>} s The sphere to modify
/// @param {Real} x The x coordinate
/// @param {Real} y The y coordinate
/// @param {Real} z The z coordinate
/// @param {Real} r The radius
/// @returns {Array<Real>} The modified sphere
function sphere_set(s, center, r = -1) {
  gml_pragma("forceinline");
  s[0] = center[0];
  s[1] = center[1];
  s[2] = center[2];
  s[3] = r;
  return s;
}

/// @func sphere_copy(s, src)
/// @desc Copies the properties of one sphere to another.
/// @param {Array<Real>} s The target sphere (will be modified)
/// @param {Array<Real>} src The source sphere
/// @returns {Array<Real>} The modified sphere
function sphere_copy(s, src) {
    gml_pragma("forceinline");
    s[0] = src[0];
    s[1] = src[1];
    s[2] = src[2];
    s[3] = src[3];
    return s;
}

/// @func sphere_clone(s)
/// @desc Creates a new sphere with the same properties.
/// @param {Array<Real>} s The sphere to clone
/// @returns {Array<Real>} A new sphere
function sphere_clone(s) {
    gml_pragma("forceinline");
    return [s[0], s[1], s[2], s[3]];
}

/// @func sphere_apply_matrix4(s, m)
/// @desc Transforms the sphere by the given matrix 4.
/// @param {Array<Real>} s The sphere to modify
/// @param {Array<Real>} m The matrix to apply
/// @returns {Array<Real>} The modified sphere
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
    return s;
}

/// @func sphere_contains_point(s, point)
/// @desc Checks if the sphere contains a point.
/// @param {Array<Real>} s The sphere
/// @param {Array<Real>} point The point to check
/// @returns {Bool} True if the point is inside the sphere
function sphere_contains_point(s, point) {
    gml_pragma("forceinline");
    var dx = point[0] - s[0];
    var dy = point[1] - s[1];
    var dz = point[2] - s[2];
    return (dx*dx + dy*dy + dz*dz) <= (s[3] * s[3]);
}

/// @func sphere_intersects_sphere(s1, s2)
/// @desc Checks if two spheres intersect.
/// @param {Array<Real>} s1 The first sphere
/// @param {Array<Real>} s2 The second sphere
/// @returns {Bool} True if the spheres intersect
function sphere_intersects_sphere(s1, s2) {
    gml_pragma("forceinline");
    var rSum = s1[3] + s2[3];
    var dx = s1[0] - s2[0];
    var dy = s1[1] - s2[1];
    var dz = s1[2] - s2[2];
    return (dx*dx + dy*dy + dz*dz) <= (rSum * rSum);
}

/// @func sphere_equals(a, b)
/// @desc Checks if two spheres are equal.
/// @param {Array<Real>} a The first sphere
/// @param {Array<Real>} b The second sphere
/// @returns {Bool} True if the spheres are equal
function sphere_equals(a, b) {
    gml_pragma("forceinline");
    return a[0]==b[0] && a[1]==b[1] && a[2]==b[2] && a[3]==b[3];
}

/// @func sphere_distance_to_point(s, point)
/// @desc Calculates the distance from the sphere to a point.
/// @param {Array<Real>} s The sphere
/// @param {Array<Real>} point The point to check
/// @returns {Real} The distance to the point
function sphere_distance_to_point(s, point) {
    gml_pragma("forceinline");
    var dx = point[0] - s[0];
    var dy = point[1] - s[1];
    var dz = point[2] - s[2];
    return sqrt(dx*dx + dy*dy + dz*dz) - s[3];
}

/// @func sphere_clamp_point(s, point, out)
/// @desc Clamps a point to the surface of the sphere.
/// @param {Array<Real>} s The sphere
/// @param {Real} px The x coordinate
/// @func sphere_clamp_point(s, point, out)
/// @desc Clamps a point to the surface of the sphere.
/// @param {Array<Real>} s The sphere
/// @param {Array<Real>} point The point to clamp
/// @param {Array<Real>} [out] Optional output array
/// @returns {Array<Real>} The clamped point
function sphere_clamp_point(s, point, out = undefined) {
    gml_pragma("forceinline");
    var dx = point[0] - s[0];
    var dy = point[1] - s[1];
    var dz = point[2] - s[2];
    var d2 = dx*dx + dy*dy + dz*dz;
    out ??= array_create(3);
    if (d2 > (s[3]*s[3])) {
        var d = sqrt(d2);
        var f = s[3] / d;
        out[0] = s[0] + dx * f;
        out[1] = s[1] + dy * f;
        out[2] = s[2] + dz * f;
    } else {
        out[0] = point[0]; out[1] = point[1]; out[2] = point[2];
    }
    return out;
}

/// @func sphere_expand_by_point(s, point)
/// @desc Expands the sphere to include a point.
/// @param {Array<Real>} s The sphere to modify
/// @param {Array<Real>} point The point to expand by
/// @returns {Array<Real>} The modified sphere
function sphere_expand_by_point(s, point) { 
    gml_pragma("forceinline");
    if (s[3] < 0) {
        s[0] = point[0]; s[1] = point[1]; s[2] = point[2]; s[3] = 0;
        return s;
    }
    var dx = point[0] - s[0];
    var dy = point[1] - s[1];
    var dz = point[2] - s[2];
    var d = sqrt(dx*dx + dy*dy + dz*dz);
    if (d > s[3]) s[3] = d;
    return s;
}

/// @func sphere_is_empty(s)
/// @desc Checks if the sphere is empty (negative radius).
/// @param {Array<Real>} s The sphere
/// @returns {Bool} True if the sphere is empty
function sphere_is_empty(s) {
    gml_pragma("forceinline");
    return s[3] < 0;
}

/// @func sphere_make_empty(s)
/// @desc Makes the sphere empty.
/// @param {Array<Real>} s The sphere to modify
/// @returns {Array<Real>} The modified sphere
function sphere_make_empty(s) {
    gml_pragma("forceinline");
    s[0] = 0; s[1] = 0; s[2] = 0; s[3] = -1;
    return s;
}

/// @func sphere_translate(s, offset)
/// @desc Translates the sphere by an offset.
/// @param {Array<Real>} s The sphere to modify
/// @param {Array<Real>} offset The translation offset [ox, oy, oz]
/// @returns {Array<Real>} The modified sphere
function sphere_translate(s, offset) {
    gml_pragma("forceinline");
    s[0] += offset[0]; s[1] += offset[1]; s[2] += offset[2];
    return s;
}

/// @func sphere_get_bounding_box(s, out)
/// @desc Gets the bounding box of the sphere.
/// @param {Array<Real>} s The sphere
/// @param {Array<Real>} [out] Optional output box
/// @returns {Array<Real>} The bounding box
function sphere_get_bounding_box(s, out = undefined) {
    gml_pragma("forceinline");
    var r = s[3];
    out ??= box3_create();
    box3_set(out, vec3_create(s[0]-r, s[1]-r, s[2]-r), vec3_create(s[0]+r, s[1]+r, s[2]+r));
    return out;
}

/// @func sphere_intersects_box(s, box)
/// @desc Checks if the sphere intersects a bounding box.
/// @param {Array<Real>} s The sphere
/// @param {Array<Real>} box The box
/// @returns {Bool} True if the sphere intersects the box
function sphere_intersects_box(s, box) {
    gml_pragma("forceinline");
    var cx = s[0], cy = s[1], cz = s[2];
    var _x = clamp(cx, box[0], box[3]);
    var _y = clamp(cy, box[1], box[4]);
    var _z = clamp(cz, box[2], box[5]);
    var dx = _x - cx, dy = _y - cy, dz = _z - cz;
    return (dx*dx + dy*dy + dz*dz) <= (s[3]*s[3]);
}

/// @func sphere_intersects_plane(s, plane)
/// @desc Checks if the sphere intersects a plane.
/// @param {Array<Real>} s The sphere
/// @param {Array<Real>} plane The plane
/// @returns {Bool} True if the sphere intersects the plane
function sphere_intersects_plane(s, plane) {
    gml_pragma("forceinline");
    var d = plane_distance_to_point(plane, s);
    return abs(d) <= s[3];
}

/// @func sphere_union(s, s2)
/// @desc Expands the sphere to include another sphere.
/// @param {Array<Real>} s The sphere to modify
/// @param {Array<Real>} s2 The other sphere
/// @returns {Array<Real>} The modified sphere
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

/// @func sphere_set_from_points(s, points, optionalCenter)
/// @desc Sets the sphere to enclose a set of points.
/// @param {Array<Real>} s The sphere to modify
/// @param {Array<Array<Real>>} points An array of point arrays
/// @param {Array<Real>} [optionalCenter] Optional pre-calculated center
/// @returns {Array<Real>} The modified sphere
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
