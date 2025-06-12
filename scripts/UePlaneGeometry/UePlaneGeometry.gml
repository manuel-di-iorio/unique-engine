function UePlaneGeometry(width = 100, height = 100, data = {}): UeBufferGeometry(data) constructor {
    var color = data[$ "color"] ?? c_white;
    var alpha = data[$ "alpha"] ?? 1;
    var halfW = width * 0.5;
    var halfH = height * 0.5;

  array_push(
        // Triangle 1
        { x: -halfW, y: -halfH, z: 0, nx: 0, ny: 1, nz: 0, u: 0, v: 0, color, alpha },
        { x:  halfW, y:  halfH, z: 0, nx: 0, ny: 1, nz: 0, u: 1, v: 1, color, alpha },
        { x:  halfW, y: -halfH, z: 0, nx: 0, ny: 1, nz: 0, u: 1, v: 0, color, alpha },

        // Triangle 2
        { x:  halfW, y:  halfH, z: 0, nx: 0, ny: 1, nz: 0, u: 1, v: 1, color, alpha },
        { x: -halfW, y: -halfH, z: 0, nx: 0, ny: 1, nz: 0, u: 0, v: 0, color, alpha },
        { x: -halfW, y:  halfH, z: 0, nx: 0, ny: 1, nz: 0, u: 0, v: 1, color, alpha },
    );
    
    build();
}
