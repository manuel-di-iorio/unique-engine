function UeArrowHelper(
    dir, origin, length = 1, color = c_yellow, headLength = undefined, headWidth = undefined
): UeMesh() constructor {

    var _dir = dir.clone().normalize();
    var _origin = origin.clone();

    self._length = length;
    self.headLength = headLength ?? length * 0.1;
    self.headWidth = headWidth ?? self.headLength * 0.2;

    // Compute the length of the shaft (line) excluding the arrowhead
    var lineLen = length - self.headLength;

    // --- Create the shaft line geometry ---
    var lineGeom = new UeLineGeometry();
    // Set positions of the line from origin (0,0,0) to (lineLen,0,0) along X axis
    lineGeom.setPositions([
        0, 0, 0,
        lineLen, 0, 0
    ]);
    // Set color of the line vertices (same color at both ends)
    lineGeom.setColors([
        color_get_red(color), color_get_green(color), color_get_blue(color),
        color_get_red(color), color_get_green(color), color_get_blue(color)
    ]);
    // Create the line mesh from geometry
    self.line = new UeLine(lineGeom);
    self.line.matrixAutoUpdate = false;

    // --- Create the cone geometry for the arrowhead ---
    var coneGeom = new UeConeGeometry(self.headWidth * 0.5, self.headLength, 32, { color });
    // Create the mesh for the cone with basic material
    self.cone = new UeMesh(coneGeom, new UeMeshBasicMaterial());
    self.cone.setPosition(lineLen, 0, 0);

    // Add line and cone as children of this arrow mesh
    self.add(self.line, self.cone);

    // --- Method to set the direction of the arrow ---
    function setDirection(dir) {
        // Normalize the new direction vector
        var _dir = dir.clone().normalize();
        
        // Compute quaternion rotation from default direction (X+) to new direction
        self.rotation.copy(global.UE_DUMMY_QUATERNION.setFromUnitVectors(new UeVector3(1, 0, 0), _dir));
        forceUpdate();
        
        // Calculate new position for the cone along the rotated direction
        var pos = _dir.scale(self._length - self.headLength);
        // Update the cone’s position to stay at the tip of the arrow
        self.cone.setPosition(pos.x, pos.y, pos.z);
        self.cone.forceUpdate();
    }

    // --- Method to update the length and dimensions of the arrow (untested) ---
    function setLength(_length, _headLength = undefined, _headWidth = undefined) {
        self._length = _length;
        
        // Update head length and width based on parameters or defaults
        self.headLength = _headLength ?? _length * 0.2;
        self.headWidth = _headWidth ?? self.headLength * 0.2;
    
        var lineLen = _length - self.headLength;
    
        // Dispose old line geometry before updating (good practice)
        self.line.geometry.dispose();
        // Update line geometry positions along X axis
        self.line.geometry.setPositions([
            0, 0, 0,
            lineLen, 0, 0
        ]);
    
        // Dispose old cone geometry before recreating
        self.cone.geometry.dispose();
        // Create new cone geometry with updated size
        self.cone.geometry = new UeConeGeometry(self.headWidth * 0.5, self.headLength, 32, { color });
    
        // Position the cone at the new tip of the line along X axis
        self.cone.setPosition(lineLen, 0, 0);
        self.cone.forceUpdate();
    }

    // --- Method to update the color of the arrow (untested) ---
    function setColor(_color) {
        // Update line vertex colors
        self.line.geometry.setColors([
            color_get_red(_color), color_get_green(_color), color_get_blue(_color),
            color_get_red(_color), color_get_green(_color), color_get_blue(_color)
        ]);
        // Update the cone’s material color
        self.cone.material.setColor(_color);
    }

    // Initialize arrow direction and position
    setDirection(_dir);
    self.position.copy(_origin);
}
