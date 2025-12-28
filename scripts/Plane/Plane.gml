/// @desc Plane functions using arrays [nx, ny, nz, constant]

function plane_create(normal, constant = 0) {
  gml_pragma("forceinline");
  normal ??= vec3_create(1, 0, 0);
  return [normal[0], normal[1], normal[2], constant];
}

/// @func plane_set(p, normal, constant)
/// @desc Sets the plane's normal and constant.
/// @param {Array<Real>} p The plane array to modify
/// @param {Array<Real>} normal Normal (Vector 3)
/// @param {Real} constant Plane constant
/// @returns {Array<Real>} The modified plane array
function plane_set(p, normal, constant) {
  gml_pragma("forceinline");
  p[0] = normal[0];
  p[1] = normal[1];
  p[2] = normal[2]
  p[3] = constant;
  return p;
}

/// @func plane_copy(p, src)
/// @desc Copies plane properties from one array to another.
/// @param {Array<Real>} p The target array (will be modified)
/// @param {Array<Real>} src The source array
/// @returns {Array<Real>} The modified plane array
function plane_copy(p, src) {
    gml_pragma("forceinline");
    p[0] = src[0];
    p[1] = src[1];
    p[2] = src[2];
    p[3] = src[3];
    return p;
}

/// @func plane_clone(p)
/// @desc Creates a new plane array with the same properties.
/// @param {Array<Real>} p The plane array to clone
/// @returns {Array<Real>} A new plane array
function plane_clone(p) {
    gml_pragma("forceinline");
    return [p[0], p[1], p[2], p[3]];
}

/// @func plane_normalize(p)
/// @desc Normalizes the plane normal and adjusts constant.
/// @param {Array<Real>} p The plane array to modify
/// @returns {Array<Real>} The modified plane array
function plane_normalize(p) {
    gml_pragma("forceinline");
    var nx = p[0], ny = p[1], nz = p[2];
    var len = sqrt(nx*nx + ny*ny + nz*nz);
    if (len > 0) {
        var invLen = 1 / len;
        p[0] *= invLen;
        p[1] *= invLen;
        p[2] *= invLen;
        p[3] *= invLen;
    }
    return p;
}

/// @func plane_distance_to_point(p, point)
/// @desc Returns signed distance from point to plane.
/// @param {Array<Real>} p The plane
/// @param {Array<Real>} point The point [x, y, z]
/// @returns {Real}
function plane_distance_to_point(p, point) {
    gml_pragma("forceinline");
    return p[0] * point[0] + p[1] * point[1] + p[2] * point[2] + p[3];
}

/// @func plane_set_from_normal_and_coplanar_point(p, normal, point)
/// @desc Sets plane from normal and a point on the plane.
/// @param {Array<Real>} p The plane array to modify
/// @param {Array<Real>} normal The normal vector
/// @param {Array<Real>} point A point on the plane
/// @returns {Array<Real>} The modified plane array
function plane_set_from_normal_and_coplanar_point(p, normal, point) {
    gml_pragma("forceinline");
    var nx = normal[0], ny = normal[1], nz = normal[2];
    var px = point[0], py = point[1], pz = point[2];
    p[0] = nx;
    p[1] = ny;
    p[2] = nz;
    p[3] = -(nx * px + ny * py + nz * pz);
    return p;
}

/// @func plane_equals(p, p2)
/// @desc Checks if two planes are equal.
/// @param {Array<Real>} p The first plane
/// @param {Array<Real>} p2 The second plane
/// @returns {Bool}
function plane_equals(p, p2) {
    gml_pragma("forceinline");
    return p[0]==p2[0] && p[1]==p2[1] && p[2]==p2[2] && p[3]==p2[3];
}

/// @func plane_negate(p)
/// @desc Negates the plane normal and constant.
/// @param {Array<Real>} p The plane array to modify
/// @returns {Array<Real>} The modified plane array
function plane_negate(p) {
    gml_pragma("forceinline");
    p[0] = -p[0];
    p[1] = -p[1];
    p[2] = -p[2];
    p[3] = -p[3];
    return p;
}

/// @func plane_translate(p, offset)
/// @desc Translates the plane by the given offset.
/// @param {Array<Real>} p The plane array to modify
/// @param {Array<Real>} offset The translation offset [tx, ty, tz]
/// @returns {Array<Real>} The modified plane array
function plane_translate(p, offset) {
    gml_pragma("forceinline");
    p[3] -= p[0]*offset[0] + p[1]*offset[1] + p[2]*offset[2];
    return p;
}

/// @func plane_coplanar_point(p, out = undefined)
/// @desc Returns a point on the plane.
/// @param {Array<Real>} p The plane
/// @param {Array<Real>} [out] Optional output vector
/// @returns {Array<Real>} The point on the plane
function plane_coplanar_point(p, out = undefined) {
    gml_pragma("forceinline");
    out ??= array_create(3);
    var t = -p[3];
    out[0] = p[0] * t;
    out[1] = p[1] * t;
    out[2] = p[2] * t;
    return out;
}

/// @func plane_project_point(p, point, out = array_create(3))
/// @desc Projects a point onto the plane.
/// @param {Array<Real>} p The plane
/// @param {Array<Real>} point The point to project
/// @param {Array<Real>} [out] Optional output vector
/// @returns {Array<Real>} The projected point
function plane_project_point(p, point, out = array_create(3)) {
    gml_pragma("forceinline");
    var px = point[0], py = point[1], pz = point[2];
    var t = -(p[0]*px + p[1]*py + p[2]*pz + p[3]);
    out[0] = px + p[0]*t;
    out[1] = py + p[1]*t;
    out[2] = pz + p[2]*t;
    return out;
}

/// @func plane_distance_to_sphere(p, sphere)
/// @desc Returns signed distance from sphere center to plane, minus radius.
/// @param {Array<Real>} p The plane
/// @param {Array<Real>} sphere The sphere [x, y, z, r]
/// @returns {Real}
function plane_distance_to_sphere(p, sphere) {
    gml_pragma("forceinline");
    return (p[0]*sphere[0] + p[1]*sphere[1] + p[2]*sphere[2] + p[3]) - sphere[3];
}

/// @func plane_intersects_sphere(p, sphere)
/// @desc Checks if the plane intersects a sphere.
/// @param {Array<Real>} p The plane
/// @param {Array<Real>} sphere The sphere
/// @returns {Bool}
function plane_intersects_sphere(p, sphere) {
    gml_pragma("forceinline");
    return abs(p[0]*sphere[0] + p[1]*sphere[1] + p[2]*sphere[2] + p[3]) <= sphere[3];
}

/// @func plane_intersect_line(p, line, out = undefined)
/// @desc Finds the intersection point between the plane and a line segment.
/// @param {Array<Real>} p The plane
/// @param {Array<Real>} line The line segment [x1, y1, z1, x2, y2, z2]
/// @param {Array<Real>} [out] Optional output vector
/// @returns {Array<Real>|undefined} The intersection point or undefined
function plane_intersect_line(p, line, out = undefined) {
    gml_pragma("forceinline");
    var sx = line[0], sy = line[1], sz = line[2];
    var ex = line[3], ey = line[4], ez = line[5];
    var sd = p[0]*sx + p[1]*sy + p[2]*sz + p[3];
    var ed = p[0]*ex + p[1]*ey + p[2]*ez + p[3];
    if (abs(sd) < 0.00000001 && abs(ed) < 0.00000001) {
        out ??= array_create(3);
        out[0] = sx; out[1] = sy; out[2] = sz;
        return out;
    }
    var denom = sd - ed;
    if (abs(denom) < 0.00000001) return undefined;
    var t = sd / denom;
    if (t < 0 || t > 1) return undefined;
    out ??= array_create(3);
    out[0] = sx + (ex - sx) * t;
    out[1] = sy + (ey - sy) * t;
    out[2] = sz + (ez - sz) * t;
    return out;
}

/// @func plane_intersects_line(p, line)
/// @desc Checks if the plane intersects a line segment.
/// @param {Array<Real>} p The plane
/// @param {Array<Real>} line The line segment
/// @returns {Bool}
function plane_intersects_line(p, line) {
    gml_pragma("forceinline");
    var sd = p[0]*line[0] + p[1]*line[1] + p[2]*line[2] + p[3];
    var ed = p[0]*line[3] + p[1]*line[4] + p[2]*line[5] + p[3];
    return sd == 0 || ed == 0 || (sd < 0 && ed > 0) || (sd > 0 && ed < 0);
}

/// @func plane_intersects_box(p, box)
/// @desc Checks if the plane intersects an AABB.
/// @param {Array<Real>} p The plane
/// @param {Array<Real>} box The AABB [minX, minY, minZ, maxX, maxY, maxZ]
/// @returns {Bool}
function plane_intersects_box(p, box) {
    gml_pragma("forceinline");
    var nx = p[0], ny = p[1], nz = p[2];
    var minX = box[0], minY = box[1], minZ = box[2];
    var maxX = box[3], maxY = box[4], maxZ = box[5];
    var vminx = (nx > 0) ? minX : maxX;
    var vminy = (ny > 0) ? minY : maxY;
    var vminz = (nz > 0) ? minZ : maxZ;
    var vmaxx = (nx > 0) ? maxX : minX;
    var vmaxy = (ny > 0) ? maxY : minY;
    var vmaxz = (nz > 0) ? maxZ : minZ;
    var dmin = nx*vminx + ny*vminy + nz*vminz + p[3];
    var dmax = nx*vmaxx + ny*vmaxy + nz*vmaxz + p[3];
    return dmin <= 0 && dmax >= 0;
}

function plane_apply_matrix4(p, m, normalMatrix = undefined) {
    gml_pragma("forceinline");
    var n = [p[0], p[1], p[2]];
    var pt = [0, 0, 0];
    plane_coplanar_point(p, pt);
    vec3_apply_matrix4(pt, m);
    if (is_array(normalMatrix)) {
        vec3_apply_normal_matrix(n, normalMatrix);
    } else {
        vec3_transform_direction(n, m);
    }
    plane_set_from_normal_and_coplanar_point(p, n, pt);
}

function plane_set_from_coplanar_points(p, a, b, c) {
    gml_pragma("forceinline");
    var e1x = b[0] - a[0], e1y = b[1] - a[1], e1z = b[2] - a[2];
    var e2x = c[0] - a[0], e2y = c[1] - a[1], e2z = c[2] - a[2];
    var nx = e1y*e2z - e1z*e2y;
    var ny = e1z*e2x - e1x*e2z;
    var nz = e1x*e2y - e1y*e2x;
    var len = sqrt(nx*nx + ny*ny + nz*nz);
    if (len > 0) { var inv = 1/len; nx*=inv; ny*=inv; nz*=inv; }
    plane_set_from_normal_and_coplanar_point(p, [nx, ny, nz], a);
}
