function UeMatrix3(_data = undefined) constructor {
    data = _data ?? [ 
        1, 0, 0,
        0, 1, 0,
        0, 0, 1
    ];
    
    function clone() {
        return variable_clone(self);
    }
    
    function scaleByVec3(scale) {
        data[0] *= scale.x; data[1] *= scale.x; data[2] *= scale.x;
        data[3] *= scale.y; data[4] *= scale.y; data[5] *= scale.y;
        data[6] *= scale.z; data[7] *= scale.z; data[8] *= scale.z;
        
        return self;
    };
}