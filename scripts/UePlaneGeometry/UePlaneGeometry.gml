function UePlaneGeometry(width = 1, height = 1, data = {}): UeGeometry(data) constructor {
    var color = data[$ "color"] ?? c_white;
    var alpha = data[$ "alpha"] ?? 1;
    var halfW = width * 0.5;
    var halfH = height * 0.5;

    self.position = [
        -halfW, -halfH, 0,
         halfW,  halfH, 0,
         halfW, -halfH, 0,
         halfW,  halfH, 0,
        -halfW, -halfH, 0,
        -halfW,  halfH, 0
    ];

    self.normal = [
        0, 0, 1,
        0, 0, 1,
        0, 0, 1,
        0, 0, 1,
        0, 0, 1,
        0, 0, 1
    ];

    self.uv = [
        0, 0,
        1, 1,
        1, 0,
        1, 1,
        0, 0,
        0, 1
    ];

    self.tangent = [
        1, 0, 0, 1,
        1, 0, 0, 1,
        1, 0, 0, 1,
        1, 0, 0, 1,
        1, 0, 0, 1,
        1, 0, 0, 1
    ];

    self.color = [
        color, alpha,
        color, alpha,
        color, alpha,
        color, alpha,
        color, alpha,
        color, alpha
    ];
    
    // Bone data (empty for static geometry)
    var vcount = array_length(self.position) / 3;
    self.boneIndices = array_create(vcount * 4, 0);
    self.boneWeights = array_create(vcount * 4, 0);
    
    build();
}
