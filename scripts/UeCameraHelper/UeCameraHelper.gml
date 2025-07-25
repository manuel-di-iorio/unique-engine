// @MissingDoc
function UeCameraHelper(camera, color = c_yellow): UeLineSegments() constructor {
    self.camera = camera;
    self.color = color;

    material.transparent = true;
    material.depthTest = false;
    material.forceSinglePass = true;
    material.side = cull_noculling;
    frustumCulled = false;

    self.ndcCorners = [
        new UeVector3(-1,  1, -1), new UeVector3( 1,  1, -1),
        new UeVector3( 1,  1,  1), new UeVector3(-1,  1,  1),
        new UeVector3(-1, -1, -1), new UeVector3( 1, -1, -1),
        new UeVector3( 1, -1,  1), new UeVector3(-1, -1,  1)
    ];

    // Ogni plane definito da 4 indici in worldPts
    self.planeQuads = [
        [0,1,2,3], // near
        [4,5,6,7], // far
        [0,3,7,4], // left
        [1,2,6,5], // right
        [0,1,5,4], // top
        [3,2,6,7]  // bottom
    ];

    // Ogni quad -> 4 linee = 8 vertici
    var totalEdges = array_length(self.planeQuads) * 4;
    self._positions = array_create(totalEdges * 3 * 2);
    self._colors    = array_create(totalEdges * 3 * 2);

    var geom = new UeLineSegmentsGeometry();
    geom.setPositions(self._positions);
    geom.setColors(self._colors);
    self.geometry = geom;

    function build() {
        var projView = global.UE_DUMMY_MATRIX4;
        projView.multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse).invert();

        var worldPts = array_create(8);
        for (var i = 0; i < 8; i++) {
            worldPts[i] = ndcCorners[i].clone().applyMatrix4(projView);
        }

        var ip = 0;
        for (var qi = 0; qi < array_length(self.planeQuads); qi++) {
            var qq = self.planeQuads[qi];
            for (var ei = 0; ei < 4; ei++) {
                var idxA = qq[ei];
                var idxB = qq[(ei + 1) mod 4];
                var a = worldPts[idxA], b = worldPts[idxB];
                self._positions[ip++] = a.x; self._positions[ip++] = a.z; self._positions[ip++] = a.y;
                self._positions[ip++] = b.x; self._positions[ip++] = b.z; self._positions[ip++] = b.y;
            }
        }

        var r = color_get_red(self.color),
            g = color_get_green(self.color),
            b = color_get_blue(self.color);

        for (var i = 0; i < array_length(self._colors); i += 3) {
            self._colors[i] = r;
            self._colors[i + 1] = g;
            self._colors[i + 2] = b;
        }

        self.geometry.setPositions(self._positions);
        self.geometry.setColors(self._colors);
        self.geometry.build();
    }

    function update() {
        //self.position.copy(camera.position);
        
        var rotMatrix = camera.matrixWorld.clone().setPositionXYZ(0, 0, 0).multiply(new UeMatrix4().makeRotationX(90));
        rotation.setFromRotationMatrix(rotMatrix);
        //inv.multiply(new UeMatrix4().makeRotationX(-PI / 2));
        //rotation.rotateX(90);
        
    }

    function setColor(newColor) {
        self.color = newColor;
        update();
        return self;
    }

    function dispose() {
        geometry.dispose();
        return self;
    }

    build();
    update();
}
