function CubeMesh(data = {}): Mesh(data) constructor {
    var _width = data[$ "width"] ?? 50;
    var _height = data[$ "height"] ?? 50;
    var _depth = data[$ "depth"] ?? 50;
    var _color  = data[$ "color"] ?? c_white;
    
    var hw = _width / 2;
    var hh = _height / 2;
    var hd = _depth / 2;

    var vertices = [
    // Front face (z positivo)
    -hw, -hh,  hd,
    -hw,  hh,  hd,
     hw,  hh,  hd,

     hw,  hh,  hd,
     hw, -hh,  hd,
    -hw, -hh,  hd,

    // Back face (z negativo)
    -hw, -hh, -hd,
     hw, -hh, -hd,
     hw,  hh, -hd,

     hw,  hh, -hd,
    -hw,  hh, -hd,
    -hw, -hh, -hd,

    // Top face (y positivo)
    -hw,  hh, -hd,
     hw,  hh, -hd,
     hw,  hh,  hd,

     hw,  hh,  hd,
    -hw,  hh,  hd,
    -hw,  hh, -hd,

    // Bottom face (y negativo)
    -hw, -hh, -hd,
    -hw, -hh,  hd,
     hw, -hh,  hd,

     hw, -hh,  hd,
     hw, -hh, -hd,
    -hw, -hh, -hd,

    // Right face (x positivo)
     hw, -hh, -hd,
     hw, -hh,  hd,
     hw,  hh,  hd,

     hw,  hh,  hd,
     hw,  hh, -hd,
     hw, -hh, -hd,

    // Left face (x negativo)
    -hw, -hh, -hd,
    -hw,  hh, -hd,
    -hw,  hh,  hd,

    -hw,  hh,  hd,
    -hw, -hh,  hd,
    -hw, -hh, -hd,
];
    
    var normals = [
        // Front face (all 0,0,1)
        0, 0, 1,  0, 0, 1,  0, 0, 1,
        0, 0, 1,  0, 0, 1,  0, 0, 1,
        
        // Back face (all 0,0,-1)
        0, 0, -1, 0, 0, -1, 0, 0, -1,
        0, 0, -1, 0, 0, -1, 0, 0, -1,
    
        // Top face (0,1,0)
        0, 1, 0,  0, 1, 0,  0, 1, 0,
        0, 1, 0,  0, 1, 0,  0, 1, 0,
    
        // Bottom face (0,-1,0)
        0, -1, 0, 0, -1, 0, 0, -1, 0,
        0, -1, 0, 0, -1, 0, 0, -1, 0,
    
        // Right face (1,0,0)
        1, 0, 0,  1, 0, 0,  1, 0, 0,
        1, 0, 0,  1, 0, 0,  1, 0, 0,
    
        // Left face (-1,0,0)
        -1, 0, 0, -1, 0, 0, -1, 0, 0,
        -1, 0, 0, -1, 0, 0, -1, 0, 0,
    ];
    
    geometry = new Geometry({ vertices, normals, color: _color }).freeze();
}