function Mat4(_data = undefined) constructor {
    data = _data ?? matrix_build_identity();
    
    function multiply(m) {
        return matrix_multiply(self.data, m);
    }
    
    function clone() {
        return new Mat4(data);
    }
    
    function buildByTransform(transform) {
        var pos = transform.position;
        var rot = transform.rotation;
        var scl = transform.scale;
    
        // Assicuriamoci che il quaternion sia normalizzato
        rot.normalize();
    
        // === Matrice di scala S ===
        var sx = scl.x, sy = scl.y, sz = scl.z;
        var S = [
            sx, 0,  0,  0,
            0,  sy, 0,  0,
            0,  0,  sz, 0,
            0,  0,  0,  1
        ];
    
        // === Matrice di rotazione R (da quaternion) ===
        var r = rot.toMat3();
        var R = [
            r.data[0], r.data[1], r.data[2], 0,
            r.data[3], r.data[4], r.data[5], 0,
            r.data[6], r.data[7], r.data[8], 0,
            0,         0,         0,         1
        ];
    
        // === Matrice di traslazione T ===
        var T = [
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            pos.x, pos.y, pos.z, 1
        ];
    
        // === Composizione finale: T * R * S ===
        var RS = matrix_multiply(R, S);
        data = matrix_multiply(T, RS);
    
        return self;
    }

}