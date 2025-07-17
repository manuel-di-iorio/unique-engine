function UeArrowHelper(
    dir, origin, length = 1, color = c_yellow, headLength = undefined, headWidth = undefined
): UeMesh() constructor {

    var _dir = dir.clone().normalize();
    var _origin = origin.clone();

    self.headLength = headLength ?? length * 0.2;
    self.headWidth = headWidth ?? self.headLength * 0.2;

    var lineLen = length - self.headLength;

    // Line
    var lineGeom = new UeLineGeometry();
    lineGeom.setPositions([
        0, 0, 0,
        0, 0, lineLen
    ]);
    lineGeom.setColors([
        color_get_red(color), color_get_green(color), color_get_blue(color),
        color_get_red(color), color_get_green(color), color_get_blue(color)
    ]);
    self.line = new UeLine(lineGeom);

    // Cone
    var coneGeom = new UeConeGeometry(self.headWidth * 0.5, self.headLength, 32, { color });
    self.cone = new UeMesh(coneGeom, new UeMeshBasicMaterial());
    self.cone.position.setZ(lineLen);
    self.cone.matrixNeedsUpdate = true;

    self.add(self.line, self.cone);

    function setDirection(dir) {
        var _dir = dir.clone().normalize();
        var q = new UeQuaternion().setFromUnitVectors(new UeVector3(0, 0, 1), _dir);
        self.rotation.copy(q);
        self.matrixNeedsUpdate = true;
        
        //// Posiziona il cono alla fine della freccia, direzione finale
        //var coneOffset = dir.clone().scale(30-headLength);
        //self.cone.setPosition(coneOffset.x, coneOffset.y, coneOffset.z);
    }

    function setLength(_length, _headLength = undefined, _headWidth = undefined) {
        self.headLength = _headLength ?? _length * 0.2;
        self.headWidth = _headWidth ?? self.headLength * 0.2;

        var lineLen = _length - self.headLength;
        self.line.geometry.setPositions([
            0, 0, 0,
            0, lineLen, 0
        ]);

        self.cone.geometry = new UeConeGeometry(self.headWidth * 0.5, self.headLength, 32, { color });
        self.cone.setPosition(0, _length, 0);
    }

    function setColor(_color) {
        self.line.geometry.setColors([
            color_get_red(_color), color_get_green(_color), color_get_blue(_color),
            color_get_red(_color), color_get_green(_color), color_get_blue(_color)
        ]);
        self.cone.material.setColor(_color);
    }

    // Move and rotate the entire mesh to the specified origin/direction
    self.position.copy(_origin);
    setDirection(_dir);
    self.matrixNeedsUpdate = true;
}
