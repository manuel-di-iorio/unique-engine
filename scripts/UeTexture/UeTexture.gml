function UeTexture(data = {}) constructor {
    isTexture = true;
    uuid = ueUuid();
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
        return self;
    }
    
    function use(sampler) {
        gpu_set_texrepeat_ext(sampler, self[$ "repeat"]);
        gpu_set_texfilter_ext(sampler, filter);
        gpu_set_tex_mip_enable_ext(sampler, generateMipmaps);
        texture_set_stage(sampler, texture);
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
        var compileSprites = data.compileSprites && image;
        var spriteBuffSize = 0;
        var spriteWidth = undefined;
        var spriteHeight = undefined;
        
        if (compileSprites) {
            spriteWidth = sprite_get_width(image);
            spriteHeight = sprite_get_height(image);
            spriteBuffSize = spriteWidth * spriteHeight * 4;
        }
        
        var payload = {
            type: UE_BUFFER_TYPE.TEXTURE,
            uuid,
            name,
            filter,
            generateMipmaps,
            spriteWidth,
            spriteHeight,
            spriteBuffSize
        };
        obj[$ "repeat"] = self[$ "repeat"];
        
        data.size += spriteBuffSize;
        
        var spriteSurf = surface_create(spriteWidth, spriteHeight);
        surface_set_target(spriteSurf);
        draw_sprite(image, 0, 0, 0);
        surface_reset_target();
        
        return {
            obj: _self, 
            payload,
            ctx: { spriteSurf, spriteBuffSize }
        };
    }
    
    function _compileBufferExtra(buffer, ctx) {
        buffer_get_surface(buffer, ctx.spriteSurf, buffer_tell(buffer));
        buffer_seek(buffer, buffer_seek_relative, ctx.spriteBuffSize);
        surface_free(ctx.spriteSurf);
    }
}