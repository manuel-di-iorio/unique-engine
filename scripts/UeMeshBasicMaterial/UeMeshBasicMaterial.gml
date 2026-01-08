function UeMeshBasicMaterial(data = {}): UeMaterial(data) constructor {
    lights = 0;
    shader = data[$ "shader"] ?? sh_ue_basic;
    
    var emissive = data[$ "emissive"];
    if (emissive != undefined) {
        emissive = [ color_get_red(emissive)/255, color_get_green(emissive)/255, color_get_blue(emissive)/255 ];
    } else {
        emissive = [0, 0, 0];
    }
    uniforms.ueEmissive = { type: UE_UNIFORM_TYPE.ARRAY, value: emissive };
    uniforms.ueEmissiveIntensity = { type: UE_UNIFORM_TYPE.FLOAT, value: data[$ "emissiveIntensity"] ?? 0 };
    
    /** === Textures === */
    textures.emissiveMap = data[$ "emissiveMap"];
    
    build();
}
