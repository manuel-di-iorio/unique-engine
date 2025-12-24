/// @desc Ray functions using arrays [ox, oy, oz, dx, dy, dz]

function ray_create(ox = 0, oy = 0, oz = 0, dx = 0, dy = 0, dz = -1) {
    gml_pragma("forceinline");
    return [ox, oy, oz, dx, dy, dz];
}

function ray_set(r, ox, oy, oz, dx, dy, dz) {
    gml_pragma("forceinline");
    r[0] = ox; r[1] = oy; r[2] = oz;
    r[3] = dx; r[4] = dy; r[5] = dz;
}

function ray_copy(r, src) {
    gml_pragma("forceinline");
    array_copy(r, 0, src, 0, 6);
}

function ray_clone(r) {
    gml_pragma("forceinline");
    return [r[0], r[1], r[2], r[3], r[4], r[5]];
}

/// @func ray_equals(r, other)
/// @desc Returns true if both origin and direction are equal.
function ray_equals(r, other) {
    gml_pragma("forceinline");
    return r[0]==other[0] && r[1]==other[1] && r[2]==other[2] && r[3]==other[3] && r[4]==other[4] && r[5]==other[5];
}

/// @func ray_at(r, t, out)
/// @desc Returns vector at distance t along ray.
function ray_at(r, t, out = undefined) {
    gml_pragma("forceinline");
    out ??= array_create(3);
    out[0] = r[0] + r[3] * t;
    out[1] = r[1] + r[4] * t;
    out[2] = r[2] + r[5] * t;
    return out;
}

/// @func ray_recenter(r, ox, oy, oz)
function ray_recenter(r, ox, oy, oz) {
    gml_pragma("forceinline");
    r[0] = ox; r[1] = oy; r[2] = oz;
}

/// @func ray_recast(r, t)
/// @desc Shifts the origin along the direction by distance t.
function ray_recast(r, t) {
    gml_pragma("forceinline");
    r[0] += r[3] * t;
    r[1] += r[4] * t;
    r[2] += r[5] * t;
}

/// @func ray_look_at(r, tx, ty, tz)
/// @desc Adjusts direction to look at target.
function ray_look_at(r, tx, ty, tz) {
    gml_pragma("forceinline");
    var dx = tx - r[0];
    var dy = ty - r[1];
    var dz = tz - r[2];
    var len = sqrt(dx*dx + dy*dy + dz*dz);
    if (len > 0) {
        var invLen = 1 / len;
        r[3] = dx * invLen;
        r[4] = dy * invLen;
        r[5] = dz * invLen;
    }
}

/// @func ray_apply_matrix4(r, m)
/// @desc Transforms origin and direction by 4x4 matrix.
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
}

/// @func ray_intersect_sphere(r, sphere)
/// @desc Returns the distance to intersection or -1 if none.
function ray_intersect_sphere(r, sphere) {
    gml_pragma("forceinline");
    var sx = sphere[0], sy = sphere[1], sz = sphere[2], radius = sphere[3];
    
    var vx = sx - r[0];
    var vy = sy - r[1];
    var vz = sz - r[2];
    
    var tca = vx * r[3] + vy * r[4] + vz * r[5];
    if (tca < 0) return -1; // Behind origin
    
    var d2 = (vx*vx + vy*vy + vz*vz) - tca*tca;
    var radius2 = radius*radius;
    
    if (d2 > radius2) return -1; // Outside radius
    
    var thc = sqrt(radius2 - d2);
    
    // t0 = first intersection
    var t0 = tca - thc;
    
    // t1 = second intersection
    // var t1 = tca + thc; 
    
    if (t0 < 0) {
        // origin inside?
        t0 = tca + thc;
        if (t0 < 0) return -1;
    }
    
    return t0;
}

/// @func ray_intersects_sphere(r, sphere)
/// @desc Returns true if ray intersects sphere.
function ray_intersects_sphere(r, sphere) {
    gml_pragma("forceinline");
    return ray_intersect_sphere(r, sphere) != -1;
}

/// @func ray_intersect_plane(r, plane, out)
/// @desc Intersects ray with plane, returns point or undefined if none.
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
function ray_distance_to_plane(r, plane) {
    gml_pragma("forceinline");
    var denom = plane[0]*r[3] + plane[1]*r[4] + plane[2]*r[5];
    if (abs(denom) < 0.00000001) return undefined;
    var t = -(plane[0]*r[0] + plane[1]*r[1] + plane[2]*r[2] + plane[3]) / denom;
    return (t >= 0) ? t : undefined;
}

function ray_intersects_plane(r, plane) {
    gml_pragma("forceinline");
    return ray_distance_to_plane(r, plane) != undefined;
}

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
function ray_intersects_box(r, box) {
    gml_pragma("forceinline");
    return ray_intersect_box(r, box) != -1;
}

/// @func ray_distance_sq_to_point(r, px, py, pz)
/// @desc Squared distance from ray to point.
function ray_distance_sq_to_point(r, px, py, pz) {
    gml_pragma("forceinline");
    var vx = px - r[0], vy = py - r[1], vz = pz - r[2];
    var dlen2 = r[3]*r[3] + r[4]*r[4] + r[5]*r[5];
    if (dlen2 == 0) return vx*vx + vy*vy + vz*vz;
    var t = (vx*r[3] + vy*r[4] + vz*r[5]) / dlen2;
    if (t < 0) t = 0;
    var cx = r[0] + r[3]*t;
    var cy = r[1] + r[4]*t;
    var cz = r[2] + r[5]*t;
    var dx = px - cx, dy = py - cy, dz = pz - cz;
    return dx*dx + dy*dy + dz*dz;
}

/// @func ray_distance_to_point(r, px, py, pz)
/// @desc Distance from ray to point.
function ray_distance_to_point(r, px, py, pz) {
    gml_pragma("forceinline");
    return sqrt(ray_distance_sq_to_point(r, px, py, pz));
}

/// @func ray_closest_point_to_point(r, px, py, pz, out)
/// @desc Closest point on ray to given point.
function ray_closest_point_to_point(r, px, py, pz, out = undefined) {
    gml_pragma("forceinline");
    var vx = px - r[0], vy = py - r[1], vz = pz - r[2];
    var dlen2 = r[3]*r[3] + r[4]*r[4] + r[5]*r[5];
    var t = (dlen2 == 0) ? 0 : (vx*r[3] + vy*r[4] + vz*r[5]) / dlen2;
    if (t < 0) t = 0;
    return ray_at(r, t, out);
}

/// @func ray_distance_sq_to_segment(r, v0, v1, outRay, outSeg)
/// @desc Squared distance between ray and segment [v0,v1]; optionally outputs closest points.
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
    var dxo = rx - qcx, dyo = ry - qcy, dzo = rz - qcz;
    return dxo*dxo + dyo*dyo + dzo*dzo;
}

/// @func ray_intersect_sphere_point(r, sphere, out)
/// @desc Returns intersection point with sphere or undefined.
function ray_intersect_sphere_point(r, sphere, out = undefined) {
    gml_pragma("forceinline");
    var t = ray_intersect_sphere(r, sphere);
    if (t < 0) return undefined;
    return ray_at(r, t, out);
}

/// @func ray_intersect_triangle(r, a, b, c, backfaceCulling, out)
/// @desc Intersects ray with triangle; returns point or undefined.
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
