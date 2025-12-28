/// @desc Ray functions using arrays [ox, oy, oz, dx, dy, dz]

global.UE_RAY_TEMP0 = ray_create();

enum RAY {
  origX,
  origY,
  origZ,
  dirX,
  dirY,
  dirZ
}

/// @func ray_create(origin, direction)
/// @desc Creates a new ray array [ox, oy, oz, dx, dy, dz].
/// @param {Real} [origin] Origin
/// @param {Real} [dir] Direction
/// @returns {Array<Real>} The new ray array
function ray_create(origin, dir) {
  gml_pragma("forceinline");
  origin ??= vec3_create(0,0,0);
  dir ??= vec3_create(0,0,-1);
  return [origin[0], origin[1], origin[2], dir[0], dir[1], dir[2]];
}

/// @func ray_set(r, origin, direction)
/// @desc Sets origin and direction of a ray.
/// @param {Array<Real>} r The ray array to modify
/// @param {Real} origin Origin
/// @param {Real} dir Direction
/// @returns {Array<Real>} The modified ray array
function ray_set(r, origin, dir) {
    gml_pragma("forceinline");
    r[0] = origin[0]; r[1] = origin[1]; r[2] = origin[2];
    r[3] = dir[0]; r[4] = dir[1]; r[5] = dir[2];
    return r;
}

/// @func ray_copy(r, src)
/// @desc Copies one ray to another.
/// @param {Array<Real>} r The target ray array to modify
/// @param {Array<Real>} src The source ray array
/// @returns {Array<Real>} The modified ray array
function ray_copy(r, src) {
    gml_pragma("forceinline");
    array_copy(r, 0, src, 0, 6);
    return r;
}

/// @func ray_clone(r)
/// @desc Clones a ray.
/// @param {Array<Real>} r The ray to clone
/// @returns {Array<Real>} A new ray array
function ray_clone(r) {
    gml_pragma("forceinline");
    return [r[0], r[1], r[2], r[3], r[4], r[5]];
}

/// @func ray_equals(r, r2)
/// @desc Returns true if both origin and direction are equal.
/// @param {Array<Real>} r The first ray
/// @param {Array<Real>} r2 The second ray
/// @returns {Bool} True if the rays are equal
function ray_equals(r, r2) {
    gml_pragma("forceinline");
    return r[0]==r2[0] && r[1]==r2[1] && r[2]==r2[2] && r[3]==r2[3] && r[4]==r2[4] && r[5]==r2[5];
}

/// @func ray_at(r, t, out)
/// @desc Returns vector at distance t along ray.
/// @param {Array<Real>} r The ray
/// @param {Real} t The distance
/// @param {Array<Real>} [out] Optional output vector [x, y, z]
/// @returns {Array<Real>} The point at distance t
function ray_at(r, t, out = undefined) {
    gml_pragma("forceinline");
    out ??= array_create(3);
    out[0] = r[0] + r[3] * t;
    out[1] = r[1] + r[4] * t;
    out[2] = r[2] + r[5] * t;
    return out;
}

/// @func ray_recenter(r, ox, oy, oz)
/// @desc Changes the origin of the ray.
/// @param {Array<Real>} r The ray array to modify
/// @param {Real} ox New origin X
/// @param {Real} oy New origin Y
/// @param {Real} oz New origin Z
/// @returns {Array<Real>} The modified ray array
function ray_recenter(r, origin) {
    gml_pragma("forceinline");
    r[0] = origin[0]; r[1] = origin[1]; r[2] = origin[2];
    return r;
}

/// @func ray_recast(r, t)
/// @desc Shifts the origin along the direction by distance t.
/// @param {Array<Real>} r The ray array to modify
/// @param {Real} t The distance to shift
/// @returns {Array<Real>} The modified ray array
function ray_recast(r, t) {
    gml_pragma("forceinline");
    r[0] += r[3] * t;
    r[1] += r[4] * t;
    r[2] += r[5] * t;
    return r;
}

/// @func ray_look_at(r, tx, ty, tz)
/// @desc Adjusts direction to look at target.
/// @param {Array<Real>} r The ray array to modify
/// @param {Real} tx Target X
/// @param {Real} ty Target Y
/// @param {Real} tz Target Z
/// @returns {Array<Real>} The modified ray array
function ray_look_at(r, target) {
    gml_pragma("forceinline");
    var dx = target[0] - r[0];
    var dy = target[1] - r[1];
    var dz = target[2] - r[2];
    var len = sqrt(dx*dx + dy*dy + dz*dz);
    if (len > 0) {
        var invLen = 1 / len;
        r[3] = dx * invLen;
        r[4] = dy * invLen;
        r[5] = dz * invLen;
    }
    return r;
}

/// @func ray_apply_matrix4(r, m)
/// @desc Transforms origin and direction by 4x4 matrix.
/// @param {Array<Real>} r The ray array to modify
/// @param {Array<Real>} m The matrix array
/// @returns {Array<Real>} The modified ray array
function ray_apply_matrix4(r, m) {
    gml_pragma("forceinline");
    var o = [r[0], r[1], r[2]];
    var e = [r[0] + r[3], r[1] + r[4], r[2] + r[5]];
    vec3_apply_matrix4(o, m);
    vec3_apply_matrix4(e, m);
    r[0] = o[0]; r[1] = o[1]; r[2] = o[2];
    r[3] = e[0] - o[0];
    r[4] = e[1] - o[1];
    r[5] = e[2] - o[2];
    var len = sqrt(r[3]*r[3] + r[4]*r[4] + r[5]*r[5]);
    if (len > 0) { var inv = 1/len; r[3]*=inv; r[4]*=inv; r[5]*=inv; }
    return r;
}

/// @func ray_intersect_sphere(r, sphere)
/// @desc Returns the distance to intersection or -1 if none.
/// @param {Array<Real>} r The ray
/// @param {Array<Real>} sphere The sphere [x, y, z, r]
/// @returns {Real} The distance to intersection or -1
function ray_intersect_sphere(r, sphere) {
    gml_pragma("forceinline");
    var sx = sphere[0], sy = sphere[1], sz = sphere[2], radius = sphere[3];
    
    var vx = sx - r[0];
    var vy = sy - r[1];
    var vz = sz - r[2];
    
    var tca = vx * r[3] + vy * r[4] + vz * r[5];
    var d2 = (vx*vx + vy*vy + vz*vz) - tca*tca;
    var radius2 = radius*radius;
    
    if (d2 > radius2) return -1; // Outside radius
    
    var thc = sqrt(radius2 - d2);
    var t0 = tca - thc;
    var t1 = tca + thc;
    
    if (t0 < 0) t0 = t1;
    if (t0 < 0) return -1;
    
    return t0;
}

/// @func ray_intersects_sphere(r, sphere)
/// @desc Returns true if ray intersects sphere.
/// @param {Array<Real>} r The ray
/// @param {Array<Real>} sphere The sphere [x, y, z, r]
/// @returns {Bool} True if the ray intersects the sphere
function ray_intersects_sphere(r, sphere) {
    gml_pragma("forceinline");
    return ray_intersect_sphere(r, sphere) != -1;
}

/// @func ray_intersect_plane(r, plane, out)
/// @desc Intersects ray with plane, returns point or undefined if none.
/// @param {Array<Real>} r The ray
/// @param {Array<Real>} plane The plane [nx, ny, nz, d]
/// @param {Array<Real>} [out] Optional output vector [x, y, z]
/// @returns {Array<Real>|Undefined} The intersection point or undefined
function ray_intersect_plane(r, plane, out = undefined) {
    gml_pragma("forceinline");
    var denom = plane[0]*r[3] + plane[1]*r[4] + plane[2]*r[5];
    if (abs(denom) < 0.00000001) return undefined;
    var t = -(plane[0]*r[0] + plane[1]*r[1] + plane[2]*r[2] + plane[3]) / denom;
    if (t < 0) return undefined;
    return ray_at(r, t, out);
}

/// @func ray_distance_to_plane(r, plane)
/// @desc Distance from origin to plane along ray; undefined if no intersection.
/// @param {Array<Real>} r The ray
/// @param {Array<Real>} plane The plane [nx, ny, nz, d]
/// @returns {Real|Undefined} The distance or undefined
function ray_distance_to_plane(r, plane) {
    gml_pragma("forceinline");
    var denom = plane[0]*r[3] + plane[1]*r[4] + plane[2]*r[5];
    if (abs(denom) < 0.00000001) return undefined;
    var t = -(plane[0]*r[0] + plane[1]*r[1] + plane[2]*r[2] + plane[3]) / denom;
    return (t >= 0) ? t : undefined;
}

/// @func ray_intersects_plane(r, plane)
/// @desc Returns true if ray intersects plane.
/// @param {Array<Real>} r The ray
/// @param {Array<Real>} plane The plane
/// @returns {Bool} True if the ray intersects the plane
function ray_intersects_plane(r, plane) {
    gml_pragma("forceinline");
    return ray_distance_to_plane(r, plane) != undefined;
}

/// @func ray_intersect_box(r, box)
/// @desc Returns the distance to intersection with a box or -1 if none.
/// @param {Array<Real>} r The ray
/// @param {Array<Real>} box The box [minX, minY, minZ, maxX, maxY, maxZ]
/// @returns {Real} The distance to intersection or -1
function ray_intersect_box(r, box) {
    var ox = r[0], oy = r[1], oz = r[2];
    var dx = r[3], dy = r[4], dz = r[5];

    var tmin = -1000000;
    var tmax = 1000000;

    // X slab
    if (dx != 0) {
        var tx1 = (box[0] - ox) / dx;
        var tx2 = (box[3] - ox) / dx;
        tmin = max(tmin, min(tx1, tx2));
        tmax = min(tmax, max(tx1, tx2));
    } else if (ox < box[0] || ox > box[3]) {
        return -1; // parallel and outside
    }

    // Y slab
    if (dy != 0) {
        var ty1 = (box[1] - oy) / dy;
        var ty2 = (box[4] - oy) / dy;
        tmin = max(tmin, min(ty1, ty2));
        tmax = min(tmax, max(ty1, ty2));
    } else if (oy < box[1] || oy > box[4]) {
        return -1;
    }

    // Z slab
    if (dz != 0) {
        var tz1 = (box[2] - oz) / dz;
        var tz2 = (box[5] - oz) / dz;
        tmin = max(tmin, min(tz1, tz2));
        tmax = min(tmax, max(tz1, tz2));
    } else if (oz < box[2] || oz > box[5]) {
        return -1;
    }

    if (tmax < 0 || tmin > tmax) return -1;

    return (tmin >= 0) ? tmin : tmax;
}

/// @func ray_intersects_box(r, box)
/// @desc Returns true if ray intersects box.
/// @param {Array<Real>} r The ray
/// @param {Array<Real>} box The box
/// @returns {Bool} True if the ray intersects the box
function ray_intersects_box(r, box) {
    gml_pragma("forceinline");
    return ray_intersect_box(r, box) != -1;
}

/// @func ray_distance_sq_to_point(r, point)
/// @desc Squared distance from ray to point.
/// @param {Array<Real>} r The ray
/// @param {Array<Real>} point The point [x, y, z]
/// @returns {Real} The squared distance
function ray_distance_sq_to_point(r, point) {
    gml_pragma("forceinline");
    var vx = point[0] - r[0], vy = point[1] - r[1], vz = point[2] - r[2];
    var dlen2 = r[3]*r[3] + r[4]*r[4] + r[5]*r[5];
    if (dlen2 == 0) return vx*vx + vy*vy + vz*vz;
    var t = (vx*r[3] + vy*r[4] + vz*r[5]) / dlen2;
    if (t < 0) t = 0;
    var cx = r[0] + r[3]*t;
    var cy = r[1] + r[4]*t;
    var cz = r[2] + r[5]*t;
    var dx = point[0] - cx, dy = point[1] - cy, dz = point[2] - cz;
    return dx*dx + dy*dy + dz*dz;
}

/// @func ray_distance_to_point(r, point)
/// @desc Distance from ray to point.
/// @param {Array<Real>} r The ray
/// @param {Array<Real>} point The point [x, y, z]
/// @returns {Real} The distance
function ray_distance_to_point(r, point) {
    gml_pragma("forceinline");
    return sqrt(ray_distance_sq_to_point(r, point));
}

/// @func ray_closest_point_to_point(r, point, out)
/// @desc Closest point on ray to given point.
/// @param {Array<Real>} r The ray
/// @param {Array<Real>} point The point [x, y, z]
/// @param {Array<Real>} [out] Optional output vector [x, y, z]
/// @returns {Array<Real>} The closest point on the ray
function ray_closest_point_to_point(r, point, out = undefined) {
    gml_pragma("forceinline");
    var vx = point[0] - r[0], vy = point[1] - r[1], vz = point[2] - r[2];
    var dlen2 = r[3]*r[3] + r[4]*r[4] + r[5]*r[5];
    var t = (dlen2 == 0) ? 0 : (vx*r[3] + vy*r[4] + vz*r[5]) / dlen2;
    if (t < 0) t = 0;
    return ray_at(r, t, out);
}

/// @func ray_distance_sq_to_segment(r, v0, v1, outRay, outSeg)
/// @desc Squared distance between ray and segment [v0,v1]; optionally outputs closest points.
/// @param {Array<Real>} r The ray
/// @param {Array<Real>} v0 Segment start [x, y, z]
/// @param {Array<Real>} v1 Segment end [x, y, z]
/// @param {Array<Real>} [outRay] Optional output for closest point on ray
/// @param {Array<Real>} [outSeg] Optional output for closest point on segment
/// @returns {Real} The squared distance
function ray_distance_sq_to_segment(r, v0, v1, outRay = undefined, outSeg = undefined) {
    gml_pragma("forceinline");
    var rx = r[0], ry = r[1], rz = r[2];
    var dx = r[3], dy = r[4], dz = r[5];
    var sx = v0[0], sy = v0[1], sz = v0[2];
    var ex = v1[0], ey = v1[1], ez = v1[2];
    var ux = dx, uy = dy, uz = dz;
    var vx = ex - sx, vy = ey - sy, vz = ez - sz;
    var wx = rx - sx, wy = ry - sy, wz = rz - sz;
    var a = ux*ux + uy*uy + uz*uz;
    var b = ux*vx + uy*vy + uz*vz;
    var c = vx*vx + vy*vy + vz*vz;
    var d = ux*wx + uy*wy + uz*wz;
    var e = vx*wx + vy*wy + vz*wz;
    var D = a*c - b*b;
    var sc, sN, sD = D;
    var tc, tN, tD = D;
    if (D < 0.00000001) {
        sN = 0; sD = 1; tN = e; tD = c;
    } else {
        sN = (b*e - c*d);
        tN = (a*e - b*d);
        if (sN < 0) { sN = 0; tN = e; tD = c; }
    }
    if (tN < 0) {
        tN = 0;
        sN = -d;
        sD = a;
    } else if (tN > tD) {
        tN = tD;
        sN = b - d;
        sD = a;
    }
    sc = (abs(sN) < 0.00000001) ? 0 : (sN / sD);
    tc = (abs(tN) < 0.00000001) ? 0 : (tN / tD);
    if (sc < 0) sc = 0; // ray only forward
    var pcx = rx + sc*ux, pcy = ry + sc*uy, pcz = rz + sc*uz;
    var qcx = sx + tc*vx, qcy = sy + tc*vy, qcz = sz + tc*vz;
    if (outRay != undefined) { outRay[0]=pcx; outRay[1]=pcy; outRay[2]=pcz; }
    if (outSeg != undefined) { outSeg[0]=qcx; outSeg[1]=qcy; outSeg[2]=qcz; }
    var dxo = pcx - qcx, dyo = pcy - qcy, dzo = pcz - qcz;
    return dxo*dxo + dyo*dyo + dzo*dzo;
}

/// @func ray_intersect_sphere_point(r, sphere, out)
/// @desc Returns intersection point with sphere or undefined.
/// @param {Array<Real>} r The ray
/// @param {Array<Real>} sphere The sphere
/// @param {Array<Real>} [out] Optional output vector [x, y, z]
/// @returns {Array<Real>|Undefined} The intersection point or undefined
function ray_intersect_sphere_point(r, sphere, out = undefined) {
    gml_pragma("forceinline");
    var t = ray_intersect_sphere(r, sphere);
    if (t < 0) return undefined;
    return ray_at(r, t, out);
}

/// @func ray_intersect_triangle(r, a, b, c, backfaceCulling, out)
/// @desc Intersects ray with triangle; returns point or undefined.
/// @param {Array<Real>} r The ray
/// @param {Array<Real>} a Triangle vertex A [x, y, z]
/// @param {Array<Real>} b Triangle vertex B [x, y, z]
/// @param {Array<Real>} c Triangle vertex C [x, y, z]
/// @param {Bool} [backfaceCulling] Whether to cull back-facing triangles
/// @param {Array<Real>} [out] Optional output vector [x, y, z]
/// @returns {Array<Real>|Undefined} The intersection point or undefined
function ray_intersect_triangle(r, a, b, c, backfaceCulling = false, out = undefined) {
    gml_pragma("forceinline");
    var edge1x = b[0] - a[0], edge1y = b[1] - a[1], edge1z = b[2] - a[2];
    var edge2x = c[0] - a[0], edge2y = c[1] - a[1], edge2z = c[2] - a[2];
    var px = r[4]*edge2z - r[5]*edge2y;
    var py = r[5]*edge2x - r[3]*edge2z;
    var pz = r[3]*edge2y - r[4]*edge2x;
    var det = edge1x*px + edge1y*py + edge1z*pz;
    if (backfaceCulling) { if (det < 0.00000001) return undefined; }
    else { if (abs(det) < 0.00000001) return undefined; }
    var invDet = 1 / det;
    var tx = r[0] - a[0], ty = r[1] - a[1], tz = r[2] - a[2];
    var u = (tx*px + ty*py + tz*pz) * invDet;
    if (u < 0 || u > 1) return undefined;
    var qx = ty*edge1z - tz*edge1y;
    var qy = tz*edge1x - tx*edge1z;
    var qz = tx*edge1y - ty*edge1x;
    var v = (r[3]*qx + r[4]*qy + r[5]*qz) * invDet;
    if (v < 0 || (u + v) > 1) return undefined;
    var t = (edge2x*qx + edge2y*qy + edge2z*qz) * invDet;
    if (t < 0) return undefined;
    return ray_at(r, t, out);
}
