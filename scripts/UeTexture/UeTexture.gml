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
    }
    
    function use(sampler) {
        gpu_set_texrepeat_ext(sampler, self[$ "repeat"]);
        gpu_set_texfilter_ext(sampler, filter);
        gpu_set_tex_mip_enable_ext(sampler, generateMipmaps);
        texture_set_stage(sampler, texture);
    }
    
    function dispose() {
        texture_flush(texture);
        texture = undefined;
        return self;
    }
    
    /**
     * Export the texture properties to a buffer
     * The actual sprite may be saved to disk by using the UUID as name
     * 
     * Structure:
     *   1 byte = buffer type
     *   37 bytes = UUID
     *   1 byte = texture repeat
     *   1 byte = texture filtering
     *   1 byte = generate mipmaps
     *   4 bytes = sprite size in bytes
     *   variable bytes = sprite buffer
     */
    function export() {
        // Get the sprite buffer size
        var spriteWidth = sprite_get_width(image);
        var spriteHeight = sprite_get_height(image);
        var spriteBuffSize = spriteWidth * spriteHeight * 4;
        
        // Create the final buffer
        var buffer = buffer_create(45 + spriteBuffSize, buffer_fast, 1);
        
        // Write the buffer type
        buffer_write(buffer, buffer_u8, UE_BUFFER_TYPE.TEXTURE);
        
        // Write the UUID
        buffer_write(buffer, buffer_string, uuid);
        
        // Write the texture props
        buffer_write(buffer, buffer_u8, self[$ "repeat"]);
        buffer_write(buffer, buffer_u8, filter);
        buffer_write(buffer, buffer_u8, generateMipmaps);
        
        // Draw the sprite to a temporary surface, in order to extract its buffer
        var spriteSurf = surface_create(sprite_get_width(image), sprite_get_height(image));
        surface_set_target(spriteSurf);
        draw_sprite(image, 0, 0, 0);
        surface_reset_target();
        
        // Write the sprite size and buffer
        buffer_write(buffer, buffer_u32, spriteBuffSize); 
        buffer_get_surface(buffer, spriteSurf, 45);
        surface_free(spriteSurf);
        
        return buffer;
    }
}