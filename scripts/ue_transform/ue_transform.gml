function Transform(_data = {}) constructor {
    position = _data[$ "position"] ?? new Vec3(_data[$ "x"] ?? 0, _data[$ "y"] ?? 0, _data[$ "z"] ?? 0);
    rotation = _data[$ "rotation"] ?? new Quat(_data[$ "rx"] ?? 0, _data[$ "ry"] ?? 0, _data[$ "rz"] ?? 0);
    scale    = _data[$ "scale"]    ?? new Vec3(_data[$ "sx"] ?? 1, _data[$ "sy"] ?? 1, _data[$ "sz"] ?? 1);
    
    /// Rebuilds the matrix from pos/rot/scale
    function transform() {
        matrix = new Mat4().buildByTransform(self);
        return self;
    }
    
    function rotateX(value) {
        rotation.rotateX(value);
        return self;
    }
    
    function rotateY(value) {
        rotation.rotateY(value);
        return self;
    }
    
    function rotateZ(value) {
        rotation.rotateZ(value);
        return self;
    }
    
    transform();
}