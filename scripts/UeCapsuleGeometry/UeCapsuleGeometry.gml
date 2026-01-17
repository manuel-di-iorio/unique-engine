function UeCapsuleGeometry(radius = 1, height = 1, capSegments = 4, radialSegments = 8, heightSegments = 1, data = {}): UeGeometry(data) constructor {
    var _radius = radius ?? 1;
    var _height = height ?? 1;
    var _capSegments = capSegments ?? 4;
    var _radialSegments = radialSegments ?? 8;
    var _heightSegments = heightSegments ?? 1;
    var _color = data[$ "color"] ?? c_white;
    var _alpha = data[$ "alpha"] ?? 1;

    var pos = [];
    var norm = [];
    var tang = [];
    var uvs = [];
    var cols = [];
    var idx = [];

    // =========================
    // PROFILE (X, Z) — Z is UP
    // =========================
    var profileXZ = []; // x, z, nx, nz
    var halfHeight = _height * 0.5;

    // Bottom cap (-PI/2 -> 0)
    for (var i = 0; i <= _capSegments; i++) {
        var t = (i / _capSegments) * (pi * 0.5) - (pi * 0.5);
        var ct = cos(t);
        var st = sin(t);
        array_push(profileXZ,
            _radius * ct,
            -halfHeight + _radius * st,
            ct,
            st
        );
    }

    // Body
    for (var i = 1; i <= _heightSegments; i++) {
        var a = i / _heightSegments;
        var pz = lerp(-halfHeight, halfHeight, a);
        array_push(profileXZ,
            _radius,
            pz,
            1,
            0
        );
    }

    // Top cap (0 -> PI/2)
    for (var i = 1; i <= _capSegments; i++) {
        var t = (i / _capSegments) * (pi * 0.5);
        var ct = cos(t);
        var st = sin(t);
        array_push(profileXZ,
            _radius * ct,
            halfHeight + _radius * st,
            ct,
            st
        );
    }

    var profileCount = array_length(profileXZ) / 4;

    // =========================
    // ROTATION AROUND Z (UP)
    // =========================
    for (var j = 0; j <= _radialSegments; j++) {
        var phi = (j / _radialSegments) * 2 * pi;
        var cp = cos(phi);
        var sp = sin(phi);

        for (var i = 0; i < profileCount; i++) {
            var px  = profileXZ[i*4];
            var pz  = profileXZ[i*4 + 1];
            var nx2 = profileXZ[i*4 + 2];
            var nz2 = profileXZ[i*4 + 3];

            // Position
            var _x = px * cp;
            var _y = px * sp; // depth
            var _z = pz;      // up

            // Normal
            var nx = nx2 * cp;
            var ny = nx2 * sp;
            var nz = nz2;

            // Tangent
            var tx = -sp;
            var ty = cp;
            var tz = 0;

            // UV
            var u = j / _radialSegments;
            var v = i / (profileCount - 1);

            array_push(pos, _x, _y, _z);
            array_push(norm, nx, ny, nz);
            array_push(tang, tx, ty, tz, -1.0);
            array_push(uvs, u, 1 - v);
            array_push(cols, _color, _alpha);
        }
    }

    // =========================
    // INDICES
    // =========================
    var stride = profileCount;
    for (var j = 0; j < _radialSegments; j++) {
        for (var i = 0; i < profileCount - 1; i++) {
            var p1 = j * stride + i;
            var p2 = (j + 1) * stride + i;
            var p3 = (j + 1) * stride + (i + 1);
            var p4 = j * stride + (i + 1);

            array_push(idx, p1, p4, p2);
            array_push(idx, p2, p4, p3);
        }
    }

    self.position = pos;
    self.normal   = norm;
    self.tangent  = tang;
    self.uv       = uvs;
    self.color    = cols;
    self.index    = idx;

    // Bone data (empty for static geometry)
    var vcount = array_length(pos) / 3;
    self.bone_indices = array_create(vcount * 4, 0);
    self.bone_weights = array_create(vcount * 4, 0);

    build();
}
