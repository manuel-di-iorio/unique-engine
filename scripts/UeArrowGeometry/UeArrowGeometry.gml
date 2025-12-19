function UeArrowGeometry(radius = 1, height = 1, radialSegments = 32, arrowSize = undefined, data = {}): UeGeometry(data) constructor {
    var _radius = radius ?? 1;
    var _height = height ?? 1;
    var _radialSegments = radialSegments ?? 32;
    var _color = data[$ "color"] ?? c_white;
    var _alpha = data[$ "alpha"] ?? 1;
    var _arrowSize = arrowSize ?? 0.15;

    var arrowHeight = _height * _arrowSize;
    var cylinderHeight = _height - arrowHeight;
    var cylinderHalfHeight = cylinderHeight * 0.5;

    var coneBaseX = cylinderHalfHeight;
    var coneTipX = cylinderHalfHeight + arrowHeight;
    var offsetX = (coneTipX + (-cylinderHalfHeight)) * 0.5;
    var coneRadius = _radius * 3;

    var _pos = [];
    var _norm = [];
    var _uvs = [];
    var _col = [];

    // Precalculate cylinder vertices for sides
    var rightV = [];
    var leftV = [];
    for (var i = 0; i <= _radialSegments; i++) {
        var angle = (i / _radialSegments) * 2 * pi;
        var cosAngle = cos(angle);
        var sinAngle = sin(angle);
        array_push(rightV, { x: cylinderHalfHeight - offsetX, y: _radius * cosAngle, z: _radius * sinAngle, u: (cosAngle + 1) * 0.5, v: (sinAngle + 1) * 0.5 });
        array_push(leftV, { x: -cylinderHalfHeight - offsetX, y: _radius * cosAngle, z: _radius * sinAngle, u: (cosAngle + 1) * 0.5, v: (sinAngle + 1) * 0.5 });
    }

    // Cylinder sides
    for (var i = 0; i < _radialSegments; i++) {
        var r1 = rightV[i], r2 = rightV[i + 1], l1 = leftV[i], l2 = leftV[i + 1];
        var centerY = (r1.y + l1.y) * 0.5, centerZ = (r1.z + l1.z) * 0.5;
        var nLen = sqrt(centerY * centerY + centerZ * centerZ);
        var ny = nLen > 0 ? centerY / nLen : 1, nz = nLen > 0 ? centerZ / nLen : 0;
        var u1 = i / _radialSegments, u2 = (i + 1) / _radialSegments;

        // Tri 1
        array_push(_pos, r1.x, r1.y, r1.z,  l1.x, l1.y, l1.z,  l2.x, l2.y, l2.z);
        array_push(_norm, 0, ny, nz,  0, ny, nz,  0, ny, nz);
        array_push(_uvs, u1, 0,  u1, 1,  u2, 1);
        array_push(_col, _color, _alpha, _color, _alpha, _color, _alpha);
        // Tri 2
        array_push(_pos, r1.x, r1.y, r1.z,  l2.x, l2.y, l2.z,  r2.x, r2.y, r2.z);
        array_push(_norm, 0, ny, nz,  0, ny, nz,  0, ny, nz);
        array_push(_uvs, u1, 0,  u2, 1,  u2, 0);
        array_push(_col, _color, _alpha, _color, _alpha, _color, _alpha);
    }

    // Cylinder base
    var lx = -cylinderHalfHeight - offsetX;
    for (var i = 0; i < _radialSegments; i++) {
        var l1 = leftV[i], l2 = leftV[i+1];
        array_push(_pos, lx, 0, 0,  l2.x, l2.y, l2.z,  l1.x, l1.y, l1.z);
        array_push(_norm, -1, 0, 0,  -1, 0, 0,  -1, 0, 0);
        array_push(_uvs, 0.5, 0.5,  l2.u, l2.v,  l1.u, l1.v);
        array_push(_col, _color, _alpha, _color, _alpha, _color, _alpha);
    }

    // Cone sides
    var coneBaseV = [];
    for (var i = 0; i <= _radialSegments; i++) {
        var angle = (i / _radialSegments) * 2 * pi;
        var cosAngle = cos(angle), sinAngle = sin(angle);
        array_push(coneBaseV, { x: coneBaseX - offsetX, y: coneRadius * cosAngle, z: coneRadius * sinAngle, u: (cosAngle + 1) * 0.5, v: (sinAngle + 1) * 0.5 });
    }
    var ctx = coneTipX - offsetX, cty = 0, ctz = 0;
    var nX = coneRadius / sqrt(coneRadius * coneRadius + arrowHeight * arrowHeight);
    for (var i = 0; i < _radialSegments; i++) {
        var b1 = coneBaseV[i], b2 = coneBaseV[i+1];
        var eLen = sqrt(b1.y * b1.y + b1.z * b1.z);
        var nY = eLen > 0 ? b1.y / eLen : 0, nZ = eLen > 0 ? b1.z / eLen : 0;
        var u1 = i / _radialSegments, u2 = (i + 1) / _radialSegments;
        array_push(_pos, b1.x, b1.y, b1.z,  ctx, cty, ctz,  b2.x, b2.y, b2.z);
        array_push(_norm, nX, nY, nZ,  nX, nY, nZ,  nX, nY, nZ);
        array_push(_uvs, u1, 0,  (u1+u2)*0.5, 1,  u2, 0);
        array_push(_col, _color, _alpha, _color, _alpha, _color, _alpha);
    }

    // Cone base
    var cbx = coneBaseX - offsetX;
    for (var i = 0; i < _radialSegments; i++) {
        var b1 = coneBaseV[i], b2 = coneBaseV[i+1];
        array_push(_pos, cbx, 0, 0,  b1.x, b1.y, b1.z,  b2.x, b2.y, b2.z);
        array_push(_norm, -1, 0, 0,  -1, 0, 0,  -1, 0, 0);
        array_push(_uvs, 0.5, 0.5,  b1.u, b1.v,  b2.u, b2.v);
        array_push(_col, _color, _alpha, _color, _alpha, _color, _alpha);
    }

    self.position = _pos;
    self.normal = _norm;
    self.uv = _uvs;
    self.color = _col;
    build();
}
