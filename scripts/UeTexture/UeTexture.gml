function UeTexture(data = {}) constructor {
    isTexture = true;
    type = "Texture";
    uuid = ueUuid();
    name = data[$ "name"] ?? undefined;
    image = data[$ "image"];
    subimg = data[$ "subimg"] ?? 0;
    self[$ "repeat"] = data[$ "repeat"] ?? true;
    filter = data[$ "filter"] ?? true;
    generateMipmaps = data[$ "generateMipmaps"] ?? true;
    texture = undefined;
    
    function setTexture(image, subimg = 0) {
        self.image = image;
        self.subimg = subimg;
        texture = sprite_get_texture(image, subimg);
        return self;
    }
    
    // @MissingDoc wireframe arg
    function use(sampler, wireframe = false) {
        gpu_set_texrepeat_ext(sampler, self[$ "repeat"]);
        gpu_set_texfilter_ext(sampler, filter);
        gpu_set_tex_mip_enable_ext(sampler, generateMipmaps);
        texture_set_stage(sampler, wireframe ? global.UE_DEFAULT_TEXTURE.texture : texture);
        return self;
    }
    
    function dispose() {
        texture_flush(texture);
        texture = undefined;
        return self;
    }
    
    /** Internal export methods */
    function _compileData(data) {
        var _self = self;
        
        // Get the sprite buffer size
        var compileSprites = data.compileSprites && image != undefined;
        var spriteWidth = undefined;
        var spriteHeight = undefined;
        var spriteBuffSize = 0;
        
        var payload = {
            filter,
            generateMipmaps,
        };
        payload[$ "repeat"] = self[$ "repeat"];
        
        if (compileSprites) {
            spriteWidth = sprite_get_width(image);
            spriteHeight = sprite_get_height(image);
            spriteBuffSize = spriteWidth * spriteHeight * 4;
            payload.spriteWidth = spriteWidth;
            payload.spriteHeight = spriteHeight;
            payload.spriteBuffSize = spriteBuffSize;
        }
        
        data.size += spriteBuffSize;
        
        return {
            obj: _self, 
            payload,
            ctx: { spriteWidth, spriteHeight, spriteBuffSize }
        };
    }
    
    function _compileBufferExtra(buffer, ctx) {
        if (!ctx.spriteBuffSize) return;
            
        var spriteSurf = surface_create(ctx.spriteWidth, ctx.spriteHeight);
        surface_set_target(spriteSurf);
        draw_clear_alpha(c_black, 0);
        draw_sprite(image, 0, 0, 0);
        surface_reset_target();
        buffer_get_surface(buffer, spriteSurf, buffer_tell(buffer));
        surface_free(spriteSurf);
    }
    
    if (image != undefined) setTexture(image, subimg);
}