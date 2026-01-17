/**
 * Icosahedron geometry.
 * @param {Real} [radius=1] Radius of the icosahedron.
 * @param {Real} [detail=0] Setting this to a value greater than 0 adds vertices making it no longer a icosahedron.
 * @param {Struct} [data] Additional settings.
 * @extends UeGeometry
 */
function UeIcosahedronGeometry(radius = 1, detail = 0, data = {}): UeGeometry(data) constructor {
    var _radius = radius ?? 1;
    var _detail = detail ?? 0;
    var _color  = data[$ "color"] ?? c_white;
    var _alpha  = data[$ "alpha"] ?? 1;

    var t = (1 + sqrt(5)) / 2;

    // Standard vertices, but we'll treat them as (x, z, y) for Z-up alignment if needed
    // However, an icosahedron is highly symmetrical, so we just need hard edges.
    var vertices = [
        -1,  t,  0,    1,  t,  0,   -1, -t,  0,    1, -t,  0,
         0, -1,  t,    0,  1,  t,    0, -1, -t,    0,  1, -t,
         t,  0, -1,    t,  0,  1,   -t,  0, -1,   -t,  0,  1
    ];

    var indices = [
         0, 11,  5,    0,  5,  1,    0,  1,  7,    0,  7, 10,    0, 10, 11,
         1,  5,  9,    5, 11,  4,   11, 10,  2,   10,  7,  6,    7,  1,  8,
         3,  9,  4,    3,  4,  2,    3,  2,  6,    3,  6,  8,    3,  8,  9,
         4,  9,  5,    2,  4, 11,    6,  2, 10,    8,  6,  7,    9,  8,  1
    ];

    // Helper to get midpoint for subdivision
    var midPointHelper = {
        cache: {},
        verts: vertices
    };
    
    var getMiddlePoint = method(midPointHelper, function(p1, p2) {
        var smallerIndex = min(p1, p2);
        var greaterIndex = max(p1, p2);
        var key = string(smallerIndex) + "_" + string(greaterIndex);

        if (variable_struct_exists(self.cache, key)) return self.cache[$ key];

        var i1 = p1 * 3, i2 = p2 * 3;
        var mx = (self.verts[i1] + self.verts[i2]) / 2;
        var my = (self.verts[i1+1] + self.verts[i2+1]) / 2;
        var mz = (self.verts[i1+2] + self.verts[i2+2]) / 2;

        var idx = array_length(self.verts) / 3;
        array_push(self.verts, mx, my, mz);
        self.cache[$ key] = idx;
        return idx;
    });

    // Subdivide
    for (var d = 0; d < _detail; d++) {
        var newIndices = [];
        for (var i = 0, il = array_length(indices); i < il; i += 3) {
            var a = indices[i], b = indices[i+1], c = indices[i+2];
            var ab = getMiddlePoint(a, b);
            var bc = getMiddlePoint(b, c);
            var ca = getMiddlePoint(c, a);
            array_push(newIndices, a, ab, ca);
            array_push(newIndices, b, bc, ab);
            array_push(newIndices, c, ca, bc);
            array_push(newIndices, ab, bc, ca);
        }
        indices = newIndices;
    }

    vertices = midPointHelper.verts;

    // Build Flat-Shaded Non-Indexed Geometry
    var pos = [];
    var norm = [];
    var tang = [];
    var uvs = [];
    var cols = [];

    for (var i = 0, il = array_length(indices); i < il; i += 3) {
        var i1 = indices[i] * 3, i2 = indices[i+1] * 3, i3 = indices[i+2] * 3;
        
        // Vertices of the triangle
        var v1x = vertices[i1], v1y = vertices[i1+1], v1z = vertices[i1+2];
        var v2x = vertices[i2], v2y = vertices[i2+1], v2z = vertices[i2+2];
        var v3x = vertices[i3], v3y = vertices[i3+1], v3z = vertices[i3+2];

        // Normalize points to sphere surface
        var l1 = sqrt(v1x*v1x + v1y*v1y + v1z*v1z);
        v1x /= l1; v1y /= l1; v1z /= l1;
        var l2 = sqrt(v2x*v2x + v2y*v2y + v2z*v2z);
        v2x /= l2; v2y /= l2; v2z /= l2;
        var l3 = sqrt(v3x*v3x + v3y*v3y + v3z*v3z);
        v3x /= l3; v3y /= l3; v3z /= l3;

        // Calculate face normal
        var ax = v2x - v1x, ay = v2y - v1y, az = v2z - v1z;
        var bx = v3x - v1x, by = v3y - v1y, bz = v3z - v1z;
        var nx = ay * bz - az * by;
        var ny = az * bx - ax * bz;
        var nz = ax * by - ay * bx;
        var nl = sqrt(nx*nx + ny*ny + nz*nz);
        if (nl > 0) { nx /= nl; ny /= nl; nz /= nl; }

        // Store 3 vertices for the triangle
        var tri = [[v1x, v1y, v1z], [v2x, v2y, v2z], [v3x, v3y, v3z]];
        for (var v = 0; v < 3; v++) {
            var curr = tri[v];
            var vx = curr[0], vy = curr[1], vz = curr[2];
            
            // Apply scale (radius)
            array_push(pos, vx * _radius, vy * _radius, vz * _radius);
            array_push(norm, nx, ny, nz);
            
            // Tangent: horizontal rotation around Z
            var tx = -vy;
            var ty = vx;
            var tz = 0;
            var tl = sqrt(tx*tx + ty*ty);
            if (tl > 0) { tx /= tl; ty /= tl; }
            else { tx = 1; ty = 0; }
            array_push(tang, tx, ty, tz, 1.0);

            // UVs based on spherical mapping
            var _u = 0.5 + (arctan2(vx, vy) / (2 * pi));
            var _v = 0.5 - (arcsin(vz) / pi);
            array_push(uvs, _u, _v);
            array_push(cols, _color, _alpha);
        }
    }

    self.position = pos;
    self.normal   = norm;
    self.tangent  = tang;
    self.uv       = uvs;
    self.color    = cols;
    self.index    = undefined; // Non-indexed for flat shading

    // Bone data (empty for static geometry)
    var vcount = array_length(pos) / 3;
    self.bone_indices = array_create(vcount * 4, 0);
    self.bone_weights = array_create(vcount * 4, 0);

    build();
}
