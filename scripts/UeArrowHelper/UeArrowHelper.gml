function UeArrowHelper(dir, origin, length = 1, color = c_yellow, headLength = undefined, headWidth = undefined) : UeMesh() constructor {
    self.dir = dir.clone().normalize();
    self.origin = origin.clone();

    self.headLength = headLength ?? length * 0.2;
    self.headWidth = headWidth ?? self.headLength * 0.2;

    var lineGeom = new UeLineGeometry();
    lineGeom.setPositions([
        0, 0, 0,
        0, 0, -length
    ]);
    lineGeom.setColors([
        color_get_red(color), color_get_green(color), color_get_blue(color),
        color_get_red(color), color_get_green(color), color_get_blue(color)
    ]);
    self.line = new UeLine(lineGeom);

    var coneGeom = new UeConeGeometry(self.headWidth * 0.5, self.headLength, 32, { color });
    self.cone = new UeMesh(coneGeom, new UeMeshBasicMaterial());
    self.cone.setPosition(0, 0, -length);

    self.add(self.line, self.cone);

    // setDirection con up +Y
    function setDirection(_dir) {
        self.dir = _dir.clone().normalize();
        self.rotation.copy(new UeQuaternion().setFromUnitVectors(up, self.dir));
        self.matrixNeedsUpdate = true;
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
        self.cone.setPosition(0, 0, _length);
    }

    function setColor(_color) {
        self.line.geometry.setColors([
            color_get_red(_color)/255, color_get_green(_color)/255, color_get_blue(_color)/255,
            color_get_red(_color)/255, color_get_green(_color)/255, color_get_blue(_color)/255
        ]);
        self.cone.material.setColor(_color);
    }

    // Applica la direzione iniziale
    setDirection(self.dir); 
    self.position.copy(origin);
}
