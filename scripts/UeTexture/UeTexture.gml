function Texture(data = {}) constructor {
    isTexture = true;
    image = data[$ "image"];
    subimg = data[$ "subimg"] ?? 0;
    texture = sprite_get_texture(image, subimg);
    self[$ "repeat"] = data[$ "repeat"] ?? true;
    filter = data[$ "filter"] ?? true;
    generateMipmaps = data[$ "generateMipmaps"] ?? true;
    
    function setTexture(image, subimg = 0) {
        self.image = image;
        self.subimg = subimg;
        texture = sprite_get_texture(image, subimg);
    }
    
    function use(sampler) {
        gpu_set_texrepeat_ext(sampler, self[$ "repeat"]);
        gpu_set_texfilter_ext(sampler, filter);
        gpu_set_tex_mip_enable_ext(sampler, generateMipmaps);
        texture_set_stage(sampler, texture);
    }
}