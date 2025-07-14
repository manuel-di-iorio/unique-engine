function UeLineBasicMaterial(data = {}): UeMaterial(data = {}) constructor {
    lights = 0;
    shader = sh_ue_line; 
    uniforms.ueColor = { type: UE_UNIFORM_TYPE.ARRAY };
    
    function setColor(color) {
        uniforms.ueColor.value = [color_get_red(color), color_get_green(color), color_get_blue(color)];
    };
    
    setColor(data[$ "color"] ?? c_white);
    build();
}