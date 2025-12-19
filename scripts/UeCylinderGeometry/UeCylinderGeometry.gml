function UeCylinderGeometry(radius = 1, height = 1, radialSegments = 32, data = {}): UeGeometry(data) constructor {
    var _radius = radius ?? 1;
    var _height = height ?? 1;
    var _radialSegments = radialSegments ?? 32;
    var _color = data[$ "color"] ?? c_white;
    var _alpha = data[$ "alpha"] ?? 1;
    var halfHeight = _height * 0.5;
    
    var pos = [], norm = [], uvs = [], cols = [];
    
    // We'll use flat arrays to store the ring vertices temporarily to avoid struct overhead
    // ringPosition: [x, y, z, u, v] per segment
    var rightRing = array_create((_radialSegments + 1) * 5);
    var leftRing = array_create((_radialSegments + 1) * 5);
    
    for (var i = 0; i <= _radialSegments; i++) {
        var a = (i / _radialSegments) * 2 * pi;
        var ca = cos(a), sa = sin(a);
        var u = (ca + 1) * 0.5;
        var v = (sa + 1) * 0.5;
        
        var idx = i * 5;
        // Right ring (x = halfHeight)
        rightRing[idx]     = halfHeight;
        rightRing[idx + 1] = _radius * ca;
        rightRing[idx + 2] = _radius * sa;
        rightRing[idx + 3] = u;
        rightRing[idx + 4] = v;
        
        // Left ring (x = -halfHeight)
        leftRing[idx]      = -halfHeight;
        leftRing[idx + 1]  = _radius * ca;
        leftRing[idx + 2]  = _radius * sa;
        leftRing[idx + 3]  = u;
        leftRing[idx + 4] = v;
    }
    
    // Sides
    for (var i = 0; i < _radialSegments; i++) {
        var idx1 = i * 5;
        var idx2 = (i + 1) * 5;
        
        var r1x = rightRing[idx1], r1y = rightRing[idx1+1], r1z = rightRing[idx1+2];
        var r2x = rightRing[idx2], r2y = rightRing[idx2+1], r2z = rightRing[idx2+2];
        var l1x = leftRing[idx1],  l1y = leftRing[idx1+1],  l1z = leftRing[idx1+2];
        var l2x = leftRing[idx2],  l2y = leftRing[idx2+1],  l2z = leftRing[idx2+2];
        
        var ny = r1y, nz = r1z; // Normal for side at this segment (approx)
        var nLen = sqrt(ny * ny + nz * nz);
        if (nLen > 0) { ny /= nLen; nz /= nLen; }
        
        var u1 = i / _radialSegments, u2 = (i + 1) / _radialSegments;
        
        // Face 1
        array_push(pos, r1x, r1y, r1z,  l1x, l1y, l1z,  l2x, l2y, l2z);
        array_push(norm, 0, ny, nz,  0, ny, nz,  0, ny, nz);
        array_push(uvs, u1, 0,  u1, 1,  u2, 1);
        array_push(cols, _color, _alpha, _color, _alpha, _color, _alpha);
        
        // Face 2
        array_push(pos, r1x, r1y, r1z,  l2x, l2y, l2z,  r2x, r2y, r2z);
        array_push(norm, 0, ny, nz,  0, ny, nz,  0, ny, nz);
        array_push(uvs, u1, 0,  u2, 1,  u2, 0);
        array_push(cols, _color, _alpha, _color, _alpha, _color, _alpha);
    }
    
    // Right cap
    for (var i = 0; i < _radialSegments; i++) {
        var idx1 = i * 5;
        var idx2 = (i + 1) * 5;
        array_push(pos, halfHeight, 0, 0,  rightRing[idx1], rightRing[idx1+1], rightRing[idx1+2],  rightRing[idx2], rightRing[idx2+1], rightRing[idx2+2]);
        array_push(norm, 1, 0, 0,  1, 0, 0,  1, 0, 0);
        array_push(uvs, 0.5, 0.5,  rightRing[idx1+3], rightRing[idx1+4],  rightRing[idx2+3], rightRing[idx2+4]);
        array_push(cols, _color, _alpha, _color, _alpha, _color, _alpha);
    }
    
    // Left cap
    for (var i = 0; i < _radialSegments; i++) {
        var idx1 = i * 5;
        var idx2 = (i + 1) * 5;
        array_push(pos, -halfHeight, 0, 0,  leftRing[idx2], leftRing[idx2+1], leftRing[idx2+2],  leftRing[idx1], leftRing[idx1+1], leftRing[idx1+2]);
        array_push(norm, -1, 0, 0,  -1, 0, 0,  -1, 0, 0);
        array_push(uvs, 0.5, 0.5,  leftRing[idx2+3], leftRing[idx2+4],  leftRing[idx1+3], leftRing[idx1+4]);
        array_push(cols, _color, _alpha, _color, _alpha, _color, _alpha);
    }
    
    self.position = pos;
    self.normal = norm;
    self.uv = uvs;
    self.color = cols;
    build();
}
