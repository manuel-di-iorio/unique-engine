function Texture(data = {}) constructor {
    isTexture = true;
    image = data[$ "image"];
    subimg = data[$ "subimg"] ?? 0;
    texture = sprite_get_texture(image, subimg);
    canRepeat = data[$ "repeat"] ?? true;
    filter = data[$ "filter"] ?? true;
    
    function setTexture(image, subimg = 0) {
        self.image = image;
        self.subimg = subimg;
        texture = sprite_get_texture(image, subimg);
    }
    
    //offset: options.offset ?? [0, 0],
    //rotation: options.rotation ?? 0,
    //wrapS: options.wrapS ?? tex_wrap_repeat,
    //wrapT: options.wrapT ?? tex_wrap_repeat,
    //flipY: options.flipY ?? true,
    //generateMipmaps: options.generateMipmaps ?? true,
    //magFilter: options.magFilter ?? tex_filter_linear,
    //minFilter: options.minFilter ?? tex_filter_linear,
}