// @MissingDoc
function UeMatrix3(_data = undefined) constructor {
    // dati in column-major (9 elementi)
    data = _data ?? [
        1, 0, 0,
        0, 1, 0,
        0, 0, 1
    ];

    function clone() {
        return variable_clone(self);
    }

    function copy(m) {
        for (var i = 0; i < 9; i++) data[i] = m.data[i];
        return self;
    }

    function determinant() {
        var a = data[0], d = data[3], g = data[6];
        var b = data[1], e = data[4], h = data[7];
        var c = data[2], f = data[5], i = data[8];

        return a*(e*i - f*h) - b*(d*i - f*g) + c*(d*h - e*g);
    }

    function equals(m) {
        for (var i = 0; i < 9; i++)
            if (data[i] != m.data[i]) return false;
        return true;
    }

    function extractBasis(xAxis, yAxis, zAxis) {
        // column-major
        xAxis.set(data[0], data[1], data[2]);
        yAxis.set(data[3], data[4], data[5]);
        zAxis.set(data[6], data[7], data[8]);
        return self;
    }

    function fromArray(arr, offset = 0) {
        for (var i = 0; i < 9; i++) data[i] = arr[offset + i];
        return self;
    }

    function invert() {
        var det = self.determinant();
        if (det == 0) {
            // zero matrix
            for (var i = 0; i < 9; i++) data[i] = 0;
            return self;
        }

        var invDet = 1 / det;

        var a = data[0], d = data[3], g = data[6];
        var b = data[1], e = data[4], h = data[7];
        var c = data[2], f = data[5], i = data[8];

        // Inverse using formula for 3x3
        data[0] =  (e*i - f*h) * invDet;
        data[1] = -(b*i - c*h) * invDet;
        data[2] =  (b*f - c*e) * invDet;

        data[3] = -(d*i - f*g) * invDet;
        data[4] =  (a*i - c*g) * invDet;
        data[5] = -(a*f - c*d) * invDet;

        data[6] =  (d*h - e*g) * invDet;
        data[7] = -(a*h - b*g) * invDet;
        data[8] =  (a*e - b*d) * invDet;

        return self;
    }

    function getNormalMatrix(m4) {
        // m4 is UeMatrix4
        self.setFromMatrix4(m4);
        self.invert();
        self.transpose();
        return self;
    }

    function identity() {
        data = [
            1,0,0,
            0,1,0,
            0,0,1
        ];
        return self;
    }

    function makeRotation(theta_rad) {
        var c = cos(theta_rad);
        var s = sin(theta_rad);
        data = [
            c, s, 0,
           -s, c, 0,
            0, 0, 1
        ];
        return self;
    }

    function makeScale(x, y) {
        data = [
            x, 0, 0,
            0, y, 0,
            0, 0, 1
        ];
        return self;
    }

    function makeTranslation(x, y) {
        data = [
            1, 0, 0,
            0, 1, 0,
            x, y, 1
        ];
        return self;
    }

    function multiply(m) {
        var a = data;
        var b = m.data;
        var r = [];

        for (var row = 0; row < 3; row++) {
            for (var col = 0; col < 3; col++) {
                var val = 0;
                for (var k = 0; k < 3; k++) {
                    val += a[k*3 + row] * b[col*3 + k];
                }
                r[col*3 + row] = val;
            }
        }
        data = r;
        return self;
    }

    function multiplyMatrices(a, b) {
        data = a.clone().multiply(b).data;
        return self;
    }

    function multiplyScalar(s) {
        for (var i = 0; i < 9; i++) data[i] *= s;
        return self;
    }

    function rotate(theta_rad) {
        var rot = new UeMatrix3().makeRotation(theta_rad);
        return self.multiply(rot);
    }

    function scale(sx, sy) {
        data[0] *= sx; data[3] *= sx; data[6] *= sx;
        data[1] *= sy; data[4] *= sy; data[7] *= sy;
        // last row unchanged (2D affine)
        return self;
    }

    function set(n11, n12, n13, n21, n22, n23, n31, n32, n33) {
        data = [
            n11, n12, n13,
            n21, n22, n23,
            n31, n32, n33
        ];
        return self;
    }

    function premultiply(m) {
        var result = m.clone().multiply(self);
        self.copy(result);
        return self;
    }

    function setFromMatrix4(m4) {
        var me = m4.data;
        data = [
            me[0], me[1], me[2],
            me[4], me[5], me[6],
            me[8], me[9], me[10]
        ];
        return self;
    }

    function setUvTransform(tx, ty, sx, sy, rotation, cx, cy) {
        var c = cos(rotation);
        var s = sin(rotation);

        data = [
            sx * c, sx * s, 0,
           -sy * s, sy * c, 0,
            tx + cx - cx * data[0] - cy * data[3],
            ty + cy - cx * data[1] - cy * data[4],
            1
        ];
        return self;
    }

    function toArray(arr = undefined, offset = 0) {
        arr ??= [];
        for (var i = 0; i < 9; i++) arr[offset + i] = data[i];
        return arr;
    }

    function translate(tx, ty) {
        data[6] += tx;
        data[7] += ty;
        return self;
    }

    function transpose() {
        var d = data;
        data = [
            d[0], d[3], d[6],
            d[1], d[4], d[7],
            d[2], d[5], d[8]
        ];
        return self;
    }

    function transposeIntoArray(arr) {
        arr[0] = data[0];
        arr[1] = data[3];
        arr[2] = data[6];

        arr[3] = data[1];
        arr[4] = data[4];
        arr[5] = data[7];

        arr[6] = data[2];
        arr[7] = data[5];
        arr[8] = data[8];
        return self;
    }
}
