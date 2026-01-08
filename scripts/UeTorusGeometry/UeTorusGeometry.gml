/// @desc Creates a torus (donut) geometry
/// @param {real} radius Major radius of the torus (distance from center to tube center), default 40
/// @param {real} tubeRadius Minor radius (tube thickness), default 10
/// @param {struct} data Optional configuration: {radialSegments, tubularSegments, color, alpha}
function UeTorusGeometry(radius = 40, tubeRadius = 10, data = {}): UeGeometry(data) constructor {
    var _radius = radius ?? 40;
    var _tubeRadius = tubeRadius ?? 10;
    var _radialSegments = data[$ "radialSegments"] ?? 16; // Segments around the tube
    var _tubularSegments = data[$ "tubularSegments"] ?? 32; // Segments around the main ring
    var _color = data[$ "color"] ?? c_white;
    var _alpha = data[$ "alpha"] ?? 1;
    var _arc = data[$ "arc"] ?? (2 * pi); // Total arc length in radians (default full circle)
    var _arcOffset = data[$ "arcOffset"] ?? 0; // Starting angle offset in radians
    
    var _pos = [];
    var _norm = [];
    var _tang = [];
    var _uvs = [];
    var _col = [];

    // Generate torus geometry
    for (var i = 0; i < _tubularSegments; i++) {
        var u1 = _arcOffset + (i / _tubularSegments) * _arc;
        var u2 = _arcOffset + ((i + 1) / _tubularSegments) * _arc;
        
        for (var j = 0; j < _radialSegments; j++) {
            var v1 = (j / _radialSegments) * 2 * pi;
            var v2 = ((j + 1) / _radialSegments) * 2 * pi;
            
            // Calculate four corners of quad
            var p1 = __calculateTorusVertex(u1, v1, _radius, _tubeRadius);
            var p2 = __calculateTorusVertex(u2, v1, _radius, _tubeRadius);
            var p3 = __calculateTorusVertex(u2, v2, _radius, _tubeRadius);
            var p4 = __calculateTorusVertex(u1, v2, _radius, _tubeRadius);
            
            // Calculate normals for each vertex
            var n1 = __calculateTorusNormal(u1, v1);
            var n2 = __calculateTorusNormal(u2, v1);
            var n3 = __calculateTorusNormal(u2, v2);
            var n4 = __calculateTorusNormal(u1, v2);
            
            // Calculate tangents for each vertex
            var t1 = __calculateTorusTangent(u1, v1);
            var t2 = __calculateTorusTangent(u2, v1);
            var t3 = __calculateTorusTangent(u2, v2);
            var t4 = __calculateTorusTangent(u1, v2);
            
            // UV coordinates
            var uv1_u = i / _tubularSegments;
            var uv1_v = j / _radialSegments;
            var uv2_u = (i + 1) / _tubularSegments;
            var uv2_v = j / _radialSegments;
            var uv3_u = (i + 1) / _tubularSegments;
            var uv3_v = (j + 1) / _radialSegments;
            var uv4_u = i / _tubularSegments;
            var uv4_v = (j + 1) / _radialSegments;
            
            // First triangle (p1, p2, p3)
            array_push(_pos, p1.x, p1.y, p1.z, p2.x, p2.y, p2.z, p3.x, p3.y, p3.z);
            array_push(_norm, n1.nx, n1.ny, n1.nz,  n2.nx, n2.ny, n2.nz,  n3.nx, n3.ny, n3.nz);
            array_push(_tang, t1.tx, t1.ty, t1.tz, 1,  t2.tx, t2.ty, t2.tz, 1,  t3.tx, t3.ty, t3.tz, 1);
            array_push(_uvs, uv1_u, uv1_v, uv2_u, uv2_v, uv3_u, uv3_v);
            array_push(_col, _color, _alpha, _color, _alpha, _color, _alpha);
            
            // Second triangle (p1, p3, p4)
            array_push(_pos, p1.x, p1.y, p1.z, p3.x, p3.y, p3.z, p4.x, p4.y, p4.z);
            array_push(_norm, n1.nx, n1.ny, n1.nz,  n3.nx, n3.ny, n3.nz,  n4.nx, n4.ny, n4.nz);
            array_push(_tang, t1.tx, t1.ty, t1.tz, 1,  t3.tx, t3.ty, t3.tz, 1,  t4.tx, t4.ty, t4.tz, 1);
            array_push(_uvs, uv1_u, uv1_v, uv3_u, uv3_v, uv4_u, uv4_v);
            array_push(_col, _color, _alpha, _color, _alpha, _color, _alpha);
        }
    }
    
    self.position = _pos;
    self.normal = _norm;
    self.tangent = _tang;
    self.uv = _uvs;
    self.color = _col;

    build();
    
    /// @desc Calculate vertex position on torus surface
    function __calculateTorusVertex(u, v, majorRadius, minorRadius) {
        var cosu = cos(u);
        var sinu = sin(u);
        var cosv = cos(v);
        var sinv = sin(v);
        
        return {
            x: (majorRadius + minorRadius * cosv) * cosu,
            y: (majorRadius + minorRadius * cosv) * sinu,
            z: minorRadius * sinv
        };
    }
    
    /// @desc Calculate normal vector at torus surface point
    function __calculateTorusNormal(u, v) {
        var cosu = cos(u);
        var sinu = sin(u);
        var cosv = cos(v);
        var sinv = sin(v);
        
        return {
            nx: cosv * cosu,
            ny: cosv * sinu,
            nz: sinv
        };
    }

    /// @desc Calculate tangent vector at torus surface point
    function __calculateTorusTangent(u, v) {
        return {
            tx: -sin(u),
            ty: cos(u),
            tz: 0
        };
    }
}
