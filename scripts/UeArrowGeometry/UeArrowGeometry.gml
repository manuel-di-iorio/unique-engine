function UeArrowGeometry(radius = 1, height = 1, radialSegments = 32, arrowSize = undefined, data = {}): UeBufferGeometry(data) constructor {
    var _radius = radius ?? 1;
    var _height = height ?? 1;
    var _radialSegments = radialSegments ?? 32;
    var _color = data[$ "color"] ?? c_white;
    var _alpha = data[$ "alpha"] ?? 1;
    var _arrowSize = arrowSize ?? 0.15;

    var arrowHeight = _height * _arrowSize;
    var cylinderHeight = _height - arrowHeight;
    var cylinderHalfHeight = cylinderHeight * 0.5;

    // Posizioni corrette per la base e la punta del cono
    var coneBaseX = cylinderHalfHeight;
    var coneTipX = cylinderHalfHeight + arrowHeight;

    // Offset per centrare l'intera mesh sull'origine
    var offsetX = (coneTipX + (-cylinderHalfHeight)) * 0.5;

    var coneRadius = _radius * 3;

    var rightVertices = [];
    var leftVertices = [];

    for (var i = 0; i <= _radialSegments; i++) {
        var angle = (i / _radialSegments) * 2 * pi;
        var cosAngle = cos(angle);
        var sinAngle = sin(angle);

        array_push(rightVertices, {
            x: cylinderHalfHeight - offsetX,
            y: _radius * cosAngle,
            z: _radius * sinAngle,
            u: (cosAngle + 1) * 0.5,
            v: (sinAngle + 1) * 0.5
        });

        array_push(leftVertices, {
            x: -cylinderHalfHeight - offsetX,
            y: _radius * cosAngle,
            z: _radius * sinAngle,
            u: (cosAngle + 1) * 0.5,
            v: (sinAngle + 1) * 0.5
        });
    }

    // Lati cilindro
    for (var i = 0; i < _radialSegments; i++) {
        var i1 = i;
        var i2 = (i + 1) % (_radialSegments + 1);

        var rightV1 = rightVertices[i1];
        var rightV2 = rightVertices[i2];
        var leftV1 = leftVertices[i1];
        var leftV2 = leftVertices[i2];

        var centerY = (rightV1.y + leftV1.y) * 0.5;
        var centerZ = (rightV1.z + leftV1.z) * 0.5;
        var normalLength = sqrt(centerY * centerY + centerZ * centerZ);
        var ny = normalLength > 0 ? centerY / normalLength : 1;
        var nz = normalLength > 0 ? centerZ / normalLength : 0;

        var u1 = i / _radialSegments;
        var u2 = (i + 1) / _radialSegments;

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

    // Fondo cilindro
    var leftCenter = {x: -cylinderHalfHeight - offsetX, y: 0, z: 0, u: 0.5, v: 0.5};
    for (var i = 0; i < _radialSegments; i++) {
        var i1 = i;
        var i2 = (i + 1) % (_radialSegments + 1);

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

    // ===== CONE =====
    var coneBaseVertices = [];
    for (var i = 0; i <= _radialSegments; i++) {
        var angle = (i / _radialSegments) * 2 * pi;
        var cosAngle = cos(angle);
        var sinAngle = sin(angle);

        array_push(coneBaseVertices, {
            x: coneBaseX - offsetX,
            y: coneRadius * cosAngle,
            z: coneRadius * sinAngle,
            u: (cosAngle + 1) * 0.5,
            v: (sinAngle + 1) * 0.5
        });
    }

    var coneTip = {
        x: coneTipX - offsetX,
        y: 0,
        z: 0,
        u: 0.5,
        v: 0.5
    };

    for (var i = 0; i < _radialSegments; i++) {
        var i1 = i;
        var i2 = (i + 1) % (_radialSegments + 1);

        var baseV1 = coneBaseVertices[i1];
        var baseV2 = coneBaseVertices[i2];

        var edge1Y = baseV1.y;
        var edge1Z = baseV1.z;
        var edgeLength = sqrt(edge1Y * edge1Y + edge1Z * edge1Z);

        var normalY = edgeLength > 0 ? edge1Y / edgeLength : 0;
        var normalZ = edgeLength > 0 ? edge1Z / edgeLength : 0;
        var normalX = coneRadius / sqrt(coneRadius * coneRadius + arrowHeight * arrowHeight);

        var u1 = i / _radialSegments;
        var u2 = (i + 1) / _radialSegments;

        array_push(vertices, {
            x: baseV1.x, y: baseV1.y, z: baseV1.z,
            nx: normalX, ny: normalY, nz: normalZ,
            u: u1, v: 0,
            color: _color, alpha: _alpha
        });
        array_push(vertices, {
            x: coneTip.x, y: coneTip.y, z: coneTip.z,
            nx: normalX, ny: normalY, nz: normalZ,
            u: (u1 + u2) * 0.5, v: 1,
            color: _color, alpha: _alpha
        });
        array_push(vertices, {
            x: baseV2.x, y: baseV2.y, z: baseV2.z,
            nx: normalX, ny: normalY, nz: normalZ,
            u: u2, v: 0,
            color: _color, alpha: _alpha
        });
    }

    var coneBaseCenter = {x: coneBaseX - offsetX, y: 0, z: 0, u: 0.5, v: 0.5};
    for (var i = 0; i < _radialSegments; i++) {
        var i1 = i;
        var i2 = (i + 1) % (_radialSegments + 1);

        array_push(vertices, {
            x: coneBaseCenter.x, y: coneBaseCenter.y, z: coneBaseCenter.z,
            nx: -1, ny: 0, nz: 0,
            u: coneBaseCenter.u, v: coneBaseCenter.v,
            color: _color, alpha: _alpha
        });
        array_push(vertices, {
            x: coneBaseVertices[i1].x, y: coneBaseVertices[i1].y, z: coneBaseVertices[i1].z,
            nx: -1, ny: 0, nz: 0,
            u: coneBaseVertices[i1].u, v: coneBaseVertices[i1].v,
            color: _color, alpha: _alpha
        });
        array_push(vertices, {
            x: coneBaseVertices[i2].x, y: coneBaseVertices[i2].y, z: coneBaseVertices[i2].z,
            nx: -1, ny: 0, nz: 0,
            u: coneBaseVertices[i2].u, v: coneBaseVertices[i2].v,
            color: _color, alpha: _alpha
        });
    }

    build();
}
