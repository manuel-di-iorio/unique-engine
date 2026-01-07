function UeCapsuleGeometry(radius = 1, height = 1, capSegments = 4, radialSegments = 8, heightSegments = 1, data = {}): UeGeometry(data) constructor {
    var _radius = radius ?? 1;
    var _height = height ?? 1;
    var _capSegments = capSegments ?? 4;
    var _radialSegments = radialSegments ?? 8;
    var _heightSegments = heightSegments ?? 1;
    var _color = data[$ "color"] ?? c_white;
    var _alpha = data[$ "alpha"] ?? 1;

    // Helper arrays
    var pos = [];
    var norm = [];
    var uvs = [];
    var cols = [];
    var idx = [];

    // Calculate total points
    // Profile points: 
    // Bottom Cap: capSegments + 1 points (including equator)
    // Body: heightSegments points (excluding start, including end)
    // Top Cap: capSegments points (excluding equator)
    // Total profile points = (capSegments + 1) + heightSegments + capSegments 
    // Body shares start with bottom cap, and end with top cap.
    
    // Profile generation
    var profileXY = []; // x, y, normalX, normalY
    var halfHeight = _height * 0.5;
    
    // 1. Bottom Cap ( -PI/2 to 0 )
    for (var i = 0; i <= _capSegments; i++) {
        var theta = (i / _capSegments) * (pi * 0.5) - (pi * 0.5);
        var ct = cos(theta);
        var st = sin(theta);
        array_push(profileXY, _radius * ct, -halfHeight + _radius * st, ct, st); 
    }
    
    // 2. Body ( 0 to height )
    for (var i = 1; i <= _heightSegments; i++) {
        var alpha = i / _heightSegments;
        var py = lerp(-halfHeight, halfHeight, alpha);
        array_push(profileXY, _radius, py, 1, 0);
    }
    
    // 3. Top Cap ( 0 to PI/2 )
    for (var i = 1; i <= _capSegments; i++) {
        var theta = (i / _capSegments) * (pi * 0.5);
        var ct = cos(theta);
        var st = sin(theta);
        array_push(profileXY, _radius * ct, halfHeight + _radius * st, ct, st);
    }
    
    var profileCount = array_length(profileXY) / 4;
    
    // Generate Mesh
    // Loop around Y axis
    // j goes 0..radialSegments (inclusive to create seam vertices for UVs)
    for (var j = 0; j <= _radialSegments; j++) {
        var phi = (j / _radialSegments) * 2 * pi;
        var cp = -cos(phi); // aligning so texture usually wraps naturally
        var sp = -sin(phi); // standard -sin, -cos or whatever matches system
        // Let's use x = r*sin, z = r*cos to start at Z axis?
        // Let's adhere to x = r*cos(phi), z = r*sin(phi) -> Start at X axis.
        cp = cos(phi);
        sp = sin(phi);

        for (var i = 0; i < profileCount; i++) {
            var px = profileXY[i*4];
            var py = profileXY[i*4 + 1];
            var nx2 = profileXY[i*4 + 2];
            var ny2 = profileXY[i*4 + 3];

            // Position
            // x = profileX * cos(phi)
            // z = profileX * sin(phi)
            // y = profileY
            var _x = px * cp;
            var _z = px * sp;
            var _y = py;
            
            // Normal
            var nx = nx2 * cp;
            var nz = nx2 * sp;
            var ny = ny2;
            
            // UV
            var u = j / _radialSegments;
            var v = i / (profileCount - 1);
            
            array_push(pos, _x, _y, _z);
            array_push(norm, nx, ny, nz);
            array_push(uvs, u, 1 - v); // 1-v to match standard bottom-up GL coords usually
            array_push(cols, _color, _alpha);
        }
    }
    
    // Indices
    var stride = profileCount;
    for (var j = 0; j < _radialSegments; j++) {
        for (var i = 0; i < profileCount - 1; i++) {
            var p1 = j * stride + i;
            var p2 = (j + 1) * stride + i;
            var p3 = (j + 1) * stride + (i + 1);
            var p4 = j * stride + (i + 1);
            
            // Counter-clockwise
            array_push(idx, p1, p2, p4);
            array_push(idx, p2, p3, p4);
        }
    }

    self.position = pos;
    self.normal = norm;
    self.uv = uvs;
    self.color = cols;
    self.index = idx;
    
    build();
}
