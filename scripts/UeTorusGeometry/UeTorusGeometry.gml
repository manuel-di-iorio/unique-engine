/// @desc Creates a torus (donut) geometry
/// @param {real} radius Major radius of the torus (distance from center to tube center), default 40
/// @param {real} tubeRadius Minor radius (tube thickness), default 10
/// @param {struct} data Optional configuration: {radialSegments, tubularSegments, color, alpha}
function UeTorusGeometry(radius = 40, tubeRadius = 10, data = {}): UeBufferGeometry(data) constructor {
    var _radius = radius ?? 40;
    var _tubeRadius = tubeRadius ?? 10;
    var _radialSegments = data[$ "radialSegments"] ?? 16; // Segments around the tube
    var _tubularSegments = data[$ "tubularSegments"] ?? 32; // Segments around the main ring
    var _color = data[$ "color"] ?? c_white;
    var _alpha = data[$ "alpha"] ?? 1;
    
    // Generate torus geometry
    for (var i = 0; i < _tubularSegments; i++) {
        var u1 = (i / _tubularSegments) * 2 * pi;
        var u2 = ((i + 1) / _tubularSegments) * 2 * pi;
        
        for (var j = 0; j < _radialSegments; j++) {
            var v1 = (j / _radialSegments) * 2 * pi;
            var v2 = ((j + 1) / _radialSegments) * 2 * pi;
            
            // Calculate four corners of quad
            var p1 = calculateTorusVertex(u1, v1, _radius, _tubeRadius);
            var p2 = calculateTorusVertex(u2, v1, _radius, _tubeRadius);
            var p3 = calculateTorusVertex(u2, v2, _radius, _tubeRadius);
            var p4 = calculateTorusVertex(u1, v2, _radius, _tubeRadius);
            
            // Calculate normals for each vertex
            var n1 = calculateTorusNormal(u1, v1);
            var n2 = calculateTorusNormal(u2, v1);
            var n3 = calculateTorusNormal(u2, v2);
            var n4 = calculateTorusNormal(u1, v2);
            
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
            array_push(vertices, {
                x: p1.x, y: p1.y, z: p1.z,
                nx: n1.nx, ny: n1.ny, nz: n1.nz,
                u: uv1_u, v: uv1_v,
                color: _color, alpha: _alpha
            });
            array_push(vertices, {
                x: p2.x, y: p2.y, z: p2.z,
                nx: n2.nx, ny: n2.ny, nz: n2.nz,
                u: uv2_u, v: uv2_v,
                color: _color, alpha: _alpha
            });
            array_push(vertices, {
                x: p3.x, y: p3.y, z: p3.z,
                nx: n3.nx, ny: n3.ny, nz: n3.nz,
                u: uv3_u, v: uv3_v,
                color: _color, alpha: _alpha
            });
            
            // Second triangle (p1, p3, p4)
            array_push(vertices, {
                x: p1.x, y: p1.y, z: p1.z,
                nx: n1.nx, ny: n1.ny, nz: n1.nz,
                u: uv1_u, v: uv1_v,
                color: _color, alpha: _alpha
            });
            array_push(vertices, {
                x: p3.x, y: p3.y, z: p3.z,
                nx: n3.nx, ny: n3.ny, nz: n3.nz,
                u: uv3_u, v: uv3_v,
                color: _color, alpha: _alpha
            });
            array_push(vertices, {
                x: p4.x, y: p4.y, z: p4.z,
                nx: n4.nx, ny: n4.ny, nz: n4.nz,
                u: uv4_u, v: uv4_v,
                color: _color, alpha: _alpha
            });
        }
    }
    
    build();
    
    /// @desc Calculate vertex position on torus surface
    /// @param {real} u Tubular angle (around main ring)
    /// @param {real} v Radial angle (around tube)
    /// @param {real} majorRadius Major radius of torus
    /// @param {real} minorRadius Minor radius (tube radius)
    /// @return {struct} Struct with x, y, z coordinates
    function calculateTorusVertex(u, v, majorRadius, minorRadius) {
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
    /// @param {real} u Tubular angle (around main ring)
    /// @param {real} v Radial angle (around tube)
    /// @return {struct} Struct with nx, ny, nz normal components
    function calculateTorusNormal(u, v) {
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
}
