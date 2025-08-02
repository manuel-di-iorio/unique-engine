function UeCylinderGeometry(radius = 1, height = 1, radialSegments = 32, data = {}): UeBufferGeometry(data) constructor {
    var _radius = radius ?? 1;
    var _height = height ?? 1;
    var _radialSegments = radialSegments ?? 32;
    var _color = data[$ "color"] ?? c_white;
    var _alpha = data[$ "alpha"] ?? 1;
    
    var halfHeight = _height * 0.5;
    
    // Generate vertices for the cylinder
    var rightVertices = [];
    var leftVertices = [];
    
    // Create vertices for right and left circles (oriented along X axis)
    for (var i = 0; i <= _radialSegments; i++) {
        var angle = (i / _radialSegments) * 2 * pi;
        var cosAngle = cos(angle);
        var sinAngle = sin(angle);
        
        // Right circle vertices (X+)
        array_push(rightVertices, {
            x: halfHeight,
            y: _radius * cosAngle,
            z: _radius * sinAngle,
            u: (cosAngle + 1) * 0.5,
            v: (sinAngle + 1) * 0.5
        });
        
        // Left circle vertices (X-)
        array_push(leftVertices, {
            x: -halfHeight,
            y: _radius * cosAngle,
            z: _radius * sinAngle,
            u: (cosAngle + 1) * 0.5,
            v: (sinAngle + 1) * 0.5
        });
    }
    
    // Generate side faces
    for (var i = 0; i < _radialSegments; i++) {
        var i1 = i;
        var i2 = (i + 1) % (_radialSegments + 1);
        
        var rightV1 = rightVertices[i1];
        var rightV2 = rightVertices[i2];
        var leftV1 = leftVertices[i1];
        var leftV2 = leftVertices[i2];
        
        // Calculate normal for side face (oriented for X-axis cylinder)
        var centerY = (rightV1.y + leftV1.y) * 0.5;
        var centerZ = (rightV1.z + leftV1.z) * 0.5;
        var normalLength = sqrt(centerY * centerY + centerZ * centerZ);
        var ny = normalLength > 0 ? centerY / normalLength : 1;
        var nz = normalLength > 0 ? centerZ / normalLength : 0;
        
        // UV coordinates for side faces
        var u1 = i / _radialSegments;
        var u2 = (i + 1) / _radialSegments;
        
        // First triangle (right-top, left-top, left-bottom)
        array_push(vertices, {
            x: rightV1.x, y: rightV1.y, z: rightV1.z,
            nx: 0, ny: ny, nz: nz,
            u: u1, v: 0,
            color: _color, alpha: _alpha
        });
        array_push(vertices, {
            x: leftV1.x, y: leftV1.y, z: leftV1.z,
            nx: 0, ny: ny, nz: nz,
            u: u1, v: 1,
            color: _color, alpha: _alpha
        });
        array_push(vertices, {
            x: leftV2.x, y: leftV2.y, z: leftV2.z,
            nx: 0, ny: ny, nz: nz,
            u: u2, v: 1,
            color: _color, alpha: _alpha
        });
        
        // Second triangle (right-top, left-bottom, right-bottom)
        array_push(vertices, {
            x: rightV1.x, y: rightV1.y, z: rightV1.z,
            nx: 0, ny: ny, nz: nz,
            u: u1, v: 0,
            color: _color, alpha: _alpha
        });
        array_push(vertices, {
            x: leftV2.x, y: leftV2.y, z: leftV2.z,
            nx: 0, ny: ny, nz: nz,
            u: u2, v: 1,
            color: _color, alpha: _alpha
        });
        array_push(vertices, {
            x: rightV2.x, y: rightV2.y, z: rightV2.z,
            nx: 0, ny: ny, nz: nz,
            u: u2, v: 0,
            color: _color, alpha: _alpha
        });
    }
    
    // Generate right cap (X+)
    var rightCenter = {x: halfHeight, y: 0, z: 0, u: 0.5, v: 0.5};
    
    for (var i = 0; i < _radialSegments; i++) {
        var i1 = i;
        var i2 = (i + 1) % (_radialSegments + 1);
        
        // Right cap triangle (center, v1, v2)
        array_push(vertices, {
            x: rightCenter.x, y: rightCenter.y, z: rightCenter.z,
            nx: 1, ny: 0, nz: 0,
            u: rightCenter.u, v: rightCenter.v,
            color: _color, alpha: _alpha
        });
        array_push(vertices, {
            x: rightVertices[i1].x, y: rightVertices[i1].y, z: rightVertices[i1].z,
            nx: 1, ny: 0, nz: 0,
            u: rightVertices[i1].u, v: rightVertices[i1].v,
            color: _color, alpha: _alpha
        });
        array_push(vertices, {
            x: rightVertices[i2].x, y: rightVertices[i2].y, z: rightVertices[i2].z,
            nx: 1, ny: 0, nz: 0,
            u: rightVertices[i2].u, v: rightVertices[i2].v,
            color: _color, alpha: _alpha
        });
    }
    
    // Generate left cap (X-)
    var leftCenter = {x: -halfHeight, y: 0, z: 0, u: 0.5, v: 0.5};
    
    for (var i = 0; i < _radialSegments; i++) {
        var i1 = i;
        var i2 = (i + 1) % (_radialSegments + 1);
        
        // Left cap triangle (center, v2, v1) - reversed winding
        array_push(vertices, {
            x: leftCenter.x, y: leftCenter.y, z: leftCenter.z,
            nx: -1, ny: 0, nz: 0,
            u: leftCenter.u, v: leftCenter.v,
            color: _color, alpha: _alpha
        });
        array_push(vertices, {
            x: leftVertices[i2].x, y: leftVertices[i2].y, z: leftVertices[i2].z,
            nx: -1, ny: 0, nz: 0,
            u: leftVertices[i2].u, v: leftVertices[i2].v,
            color: _color, alpha: _alpha
        });
        array_push(vertices, {
            x: leftVertices[i1].x, y: leftVertices[i1].y, z: leftVertices[i1].z,
            nx: -1, ny: 0, nz: 0,
            u: leftVertices[i1].u, v: leftVertices[i1].v,
            color: _color, alpha: _alpha
        });
    }
    
    build();
}