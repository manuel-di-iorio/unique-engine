// @MissingDoc
function UeVector3(_x = 0, _y = 0, _z = 0) constructor {
    self.x = _x;
    self.y = _y;
    self.z = _z;
    
    function set(_x, _y, _z) {
        self.x = _x;
        self.y = _y;
        self.z = _z;
    }
    
    function clone() {
        return variable_clone(self);
    }

    function copy(vec) {
        self.x = vec.x;
        self.y = vec.y;
        self.z = vec.z;
        return self;
    }

    function add(vec) {
        self.x += vec.x;
        self.y += vec.y;
        self.z += vec.z;
        return self;
    }

    function sub(vec) {
        self.x -= vec.x;
        self.y -= vec.y;
        self.z -= vec.z;
        return self;
    }

    function multiply(vec) {
        self.x *= vec.x;
        self.y *= vec.y;
        self.z *= vec.z;
        return self;
    }

    function scale(s) {
        self.x *= s;
        self.y *= s;
        self.z *= s;
        return self;
    }

    function dot(vec) {
        return self.x * vec.x + self.y * vec.y + self.z * vec.z;
    }

    function cross(vec) {
        var cx = self.y * vec.z - self.z * vec.y;
        var cy = self.z * vec.x - self.x * vec.z;
        var cz = self.x * vec.y - self.y * vec.x;
        return new UeVector3(cx, cy, cz);
    }

    function length() {
        return sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
    }

    function normalize() {
        var len = length();
        if (len > 0) {
            var inv = 1 / len;
            self.x *= inv;
            self.y *= inv;
            self.z *= inv;
        }
        return self;
    }

    function equals(vec) {
        return self.x == vec.x && self.y == vec.y && self.z == vec.z;
    }

    function lerp(vec, t) {
        self.x += (vec.x - self.x) * t;
        self.y += (vec.y - self.y) * t;
        self.z += (vec.z - self.z) * t;
        return self;
    }
    
    function angleTo(vec) {
        var dot = dot(vec);
        var len1 = length();
        var len2 = vec.length();
        var denom = len1 * len2;
        if (denom == 0) return 0;
    
        var cos_theta = clamp(dot / denom, -1, 1);
        return darccos(cos_theta);
    }
    
    function distanceTo(vec) {
        var dx = self.x - vec.x;
        var dy = self.y - vec.y;
        var dz = self.z - vec.z;
        return sqrt(dx * dx + dy * dy + dz * dz);
    }
    
    /// Like distanceTo() but squared. Faster since it avoids the sqrt, useful for render sorting
    function distanceToSquared(vec) {
        var dx = self.x - vec.x;
        var dy = self.y - vec.y;
        var dz = self.z - vec.z;
        return dx * dx + dy * dy + dz * dz;
    }
    
    // @MissingDoc:    
    function addScalar(s) {
        self.x += s;
        self.y += s;
        self.z += s;
        return self;
    }
    
    function addScaledVector(vec, scale) {
        self.x += vec.x * scale;
        self.y += vec.y * scale;
        self.z += vec.z * scale;
        return self;
    }
    
    function addVectors(a, b) {
        self.x = a.x + b.x;
        self.y = a.y + b.y;
        self.z = a.z + b.z;
        return self;
    }
    
    function clamp(minVec, maxVec) {
        self.x = clamp(self.x, minVec.x, maxVec.x);
        self.y = clamp(self.y, minVec.y, maxVec.y);
        self.z = clamp(self.z, minVec.z, maxVec.z);
        return self;
    }
    
    function clampScalar(minVal, maxVal) {
        self.x = clamp(self.x, minVal, maxVal);
        self.y = clamp(self.y, minVal, maxVal);
        self.z = clamp(self.z, minVal, maxVal);
        return self;
    }
    
    function clampLength(minLen, maxLen) {
        var len = length();
        return setLength(clamp(len, minLen, maxLen));
    }
    
    function divide(vec) {
        self.x /= vec.x;
        self.y /= vec.y;
        self.z /= vec.z;
        return self;
    }
    
    function divideScalar(scalar) {
        return self.scale(1 / scalar);
    }
    
    function floor() {
        self.x = floor(self.x);
        self.y = floor(self.y);
        self.z = floor(self.z);
        return self;
    }
    
    function ceil() {
        self.x = ceil(self.x);
        self.y = ceil(self.y);
        self.z = ceil(self.z);
        return self;
    }
    
    function round() {
        self.x = round(self.x);
        self.y = round(self.y);
        self.z = round(self.z);
        return self;
    }
    
    function roundToZero() {
        self.x = (self.x < 0) ? ceil(self.x) : floor(self.x);
        self.y = (self.y < 0) ? ceil(self.y) : floor(self.y);
        self.z = (self.z < 0) ? ceil(self.z) : floor(self.z);
        return self;
    }
    
    function lengthSq() {
        return self.x * self.x + self.y * self.y + self.z * self.z;
    }
    
    function manhattanLength() {
        return abs(self.x) + abs(self.y) + abs(self.z);
    }
    
    function manhattanDistanceTo(vec) {
        return abs(self.x - vec.x) + abs(self.y - vec.y) + abs(self.z - vec.z);
    }
    
    function multiplyScalar(s) {
        return scale(s);
    }
    
    function multiplyVectors(a, b) {
        self.x = a.x * b.x;
        self.y = a.y * b.y;
        self.z = a.z * b.z;
        return self;
    }
    
    function negate() {
        self.x = -self.x;
        self.y = -self.y;
        self.z = -self.z;
        return self;
    }
    
    function setScalar(scalar) {
        self.x = self.y = self.z = scalar;
        return self;
    }
    
    function setX(x) {
        self.x = x;
        return self;
    }
    
    function setY(y) {
        self.y = y;
        return self;
    }
    
    function setZ(z) {
        self.z = z;
        return self;
    }
    
    function subScalar(s) {
        self.x -= s;
        self.y -= s;
        self.z -= s;
        return self;
    }
    
    function subVectors(a, b) {
        self.x = a.x - b.x;
        self.y = a.y - b.y;
        self.z = a.z - b.z;
        return self;
    }

    // Trasforma il vettore con una matrice 3x3
    function applyMatrix3(m) {
        var xx = self.x, yy = self.y, zz = self.z;
        var e = m.data;
        self.x = e[0]*xx + e[3]*yy + e[6]*zz;
        self.y = e[1]*xx + e[4]*yy + e[7]*zz;
        self.z = e[2]*xx + e[5]*yy + e[8]*zz;
        return self;
    }
    
    /// Projects this vector from world space into camera NDC space (-1 to 1).
    /// The vector is transformed by the view and projection matrices.
    function project(camera) {
        return applyMatrix4(camera.matrixWorldInverse)
                .applyMatrix4(camera.projectionMatrix);
    }
    
    /// Unprojects this vector from NDC space (-1 to 1) into world space.
    /// Applies the inverse projection followed by the inverse view matrix.
    function unproject(camera) {
        return applyMatrix4(camera.projectionMatrixInverse)
                .applyMatrix4(camera.matrixWorld);
    }
    
    // Trasforma solo la direzione (no traslazione), poi normalizza
    function transformDirection(m) {
        var xx = self.x, yy = self.y, zz = self.z;
        var e = m.data;
        self.x = e[0]*xx + e[4]*yy + e[8]*zz;
        self.y = e[1]*xx + e[5]*yy + e[9]*zz;
        self.z = e[2]*xx + e[6]*yy + e[10]*zz;
        return self.normalize();
    }
    
    // Trasforma come punto 3D con matrice 4x4
    function applyMatrix4(m) {
        var xx = self.x, yy = self.y, zz = self.z;
        var e = m.data;
        var w = e[3]*xx + e[7]*yy + e[11]*zz + e[15];
        w = w != 0 ? 1 / w : 1;
        self.x = (e[0]*xx + e[4]*yy + e[8]*zz + e[12]) * w;
        self.y = (e[1]*xx + e[5]*yy + e[9]*zz + e[13]) * w;
        self.z = (e[2]*xx + e[6]*yy + e[10]*zz + e[14]) * w;
        return self;
    }
    
    // Usa matrice 3x3 per normal, poi normalizza
    function applyNormalMatrix(m) {
        applyMatrix3(m);
        return self.normalize();
    }
    
    // Proietta su un piano definito dalla normale
    function projectOnPlane(normal) {
        var v = normal.clone().scale(self.dot(normal));
        return self.sub(v);
    }
    
    // Proietta sul vettore diretto v
    function projectOnVector(v) {
        var scalar = self.dot(v) / v.dot(v);
        return self.copy(v).scale(scalar);
    }
    
    // Riflette questo vettore rispetto alla normale
    function reflect(normal) {
        return self.sub(normal.clone().scale(2 * self.dot(normal)));
    }
    
    // Imposta la lunghezza del vettore
    function setLength(l) {
        var old = length();
        return old != 0 ? self.scale(l / old) : self.scale(0);
    }
    
    // Legge da array semplici
    function fromArray(arr, offset = 0) {
        self.x = arr[offset];
        self.y = arr[offset + 1];
        self.z = arr[offset + 2];
        return self;
    }
    
    // Estrae componenti della matrice o array
    function getComponent(index) {
        if (index == 0) return self.x;
        if (index == 1) return self.y;
        if (index == 2) return self.z; 
    }
    
    // Copia in array o ne crea uno nuovo
    function toArray(arr = undefined, offset = 0) {
        arr ??= []; 
        arr[offset]     = self.x;
        arr[offset + 1] = self.y;
        arr[offset + 2] = self.z;
        return arr;
    }
    
    // Imposta lunghezze random uniformi [0,1)
    function random() {
        self.x = random_range(0, 1);
        self.y = random_range(0, 1);
        self.z = random_range(0, 1);
        return self;
    }
    
    // Vettore casuale sulla superficie della sfera unitaria
    function randomDirection() {
        var theta = random_range(0, 2 * pi);
        var phi = arccos(random_range( -1, 1 ));
        var sinPhi = sin(phi);
        self.x = sinPhi * cos(theta);
        self.y = sinPhi * sin(theta);
        self.z = cos(phi);
        return self;
    }
    
}