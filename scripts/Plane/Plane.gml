/// @desc Plane functions using arrays [nx, ny, nz, constant]

function plane_create(nx = 0, ny = 1, nz = 0, constant = 0) {
    gml_pragma("forceinline");
    return [nx, ny, nz, constant];
}

function plane_set(p, nx, ny, nz, constant) {
    gml_pragma("forceinline");
    p[0] = nx;
    p[1] = ny;
    p[2] = nz;
    p[3] = constant;
}

function plane_copy(p, src) {
    gml_pragma("forceinline");
    p[0] = src[0];
    p[1] = src[1];
    p[2] = src[2];
    p[3] = src[3];
}

function plane_clone(p) {
    gml_pragma("forceinline");
    return [p[0], p[1], p[2], p[3]];
}

/// @func plane_normalize(p)
/// @desc Normalizes the plane normal and adjusts constant.
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
}

/// @func plane_distance_to_point(p, px, py, pz)
/// @desc Returns signed distance from point to plane.
function plane_distance_to_point(p, px, py, pz) {
    gml_pragma("forceinline");
    return p[0] * px + p[1] * py + p[2] * pz + p[3];
}

/// @func plane_set_from_normal_and_coplanar_point(p, nx, ny, nz, px, py, pz)
/// @desc Sets plane from normal and a point on the plane.
function plane_set_from_normal_and_coplanar_point(p, nx, ny, nz, px, py, pz) {
    gml_pragma("forceinline");
    p[0] = nx;
    p[1] = ny;
    p[2] = nz;
    p[3] = -(nx * px + ny * py + nz * pz);
}

function plane_equals(p, p2) {
    gml_pragma("forceinline");
    return p[0]==p2[0] && p[1]==p2[1] && p[2]==p2[2] && p[3]==p2[3];
}

function plane_negate(p) {
    gml_pragma("forceinline");
    p[0] = -p[0];
    p[1] = -p[1];
    p[2] = -p[2];
    p[3] = -p[3];
}

function plane_translate(p, tx, ty, tz) {
    gml_pragma("forceinline");
    p[3] -= p[0]*tx + p[1]*ty + p[2]*tz;
}

function plane_coplanar_point(p, out = undefined) {
    gml_pragma("forceinline");
    out ??= array_create(3);
    var t = -p[3];
    out[0] = p[0] * t;
    out[1] = p[1] * t;
    out[2] = p[2] * t;
    return out;
}

function plane_project_point(p, px, py, pz, out = undefined) {
    gml_pragma("forceinline");
    var t = -(p[0]*px + p[1]*py + p[2]*pz + p[3]);
    out ??= array_create(3);
    out[0] = px + p[0]*t;
    out[1] = py + p[1]*t;
    out[2] = pz + p[2]*t;
    return out;
}

function plane_distance_to_sphere(p, sphere) {
    gml_pragma("forceinline");
    return (p[0]*sphere[0] + p[1]*sphere[1] + p[2]*sphere[2] + p[3]) - sphere[3];
}

function plane_intersects_sphere(p, sphere) {
    gml_pragma("forceinline");
    return abs(p[0]*sphere[0] + p[1]*sphere[1] + p[2]*sphere[2] + p[3]) <= sphere[3];
}

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

function plane_intersects_line(p, line) {
    gml_pragma("forceinline");
    var sd = p[0]*line[0] + p[1]*line[1] + p[2]*line[2] + p[3];
    var ed = p[0]*line[3] + p[1]*line[4] + p[2]*line[5] + p[3];
    return sd == 0 || ed == 0 || (sd < 0 && ed > 0) || (sd > 0 && ed < 0);
}

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
    plane_set_from_normal_and_coplanar_point(p, n[0], n[1], n[2], pt[0], pt[1], pt[2]);
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
    plane_set_from_normal_and_coplanar_point(p, nx, ny, nz, a[0], a[1], a[2]);
}
