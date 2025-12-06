function UePlaneGeometry(width = 1, height = 1, data = {}): UeBufferGeometry(data) constructor {
    var color = data[$ "color"] ?? c_white;
    var alpha = data[$ "alpha"] ?? 1;
    var halfW = width * 0.5;
    var halfH = height * 0.5;

  array_push(vertices,
        // Triangle 1
        { x: -halfW, y: -halfH, z: 0, nx: 0, ny: 0, nz: 1, u: 0, v: 0, color, alpha },
        { x:  halfW, y:  halfH, z: 0, nx: 0, ny: 0, nz: 1, u: 1, v: 1, color, alpha },
        { x:  halfW, y: -halfH, z: 0, nx: 0, ny: 0, nz: 1, u: 1, v: 0, color, alpha },

        // Triangle 2
        { x:  halfW, y:  halfH, z: 0, nx: 0, ny: 0, nz: 1, u: 1, v: 1, color, alpha },
        { x: -halfW, y: -halfH, z: 0, nx: 0, ny: 0, nz: 1, u: 0, v: 0, color, alpha },
        { x: -halfW, y:  halfH, z: 0, nx: 0, ny: 0, nz: 1, u: 0, v: 1, color, alpha },
    );
    
    build();
}
