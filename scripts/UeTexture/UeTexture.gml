function UeTexture(data = {}) constructor {
    // Flag indicating this object is a texture
    isTexture = true;

    // Type string
    type = "Texture";

    // Unique identifier for this texture instance
    uuid = ueUuid();

    // Optional texture name
    name = data[$ "name"] ?? "";

    // Base image sprite used for this texture
    image = data[$ "image"];

    // UV offset for texture coordinates (Vector2)
    offset = new UeVector2(0, 0);

    // Number of times the texture repeats on UV axes (Vector2)
    self[$ "repeat"] = data[$ "repeat"] ?? new UeVector2(1, 1);

    // Center point for rotation and transformations (Vector2)
    center = new UeVector2(0, 0);

    // Rotation angle in radians (around Z axis)
    rotation = 0;

    // Flip horizontally (boolean)
    flipX = false;

    // Flip vertically (boolean)
    flipY = false;

    // Horizontal wrapping mode (Repeat, ClampToEdge, MirroredRepeat)
    wrapS = UE_TEXTURE_WRAP.CLAMP_TO_EDGE;

    // Vertical wrapping mode
    wrapT = UE_TEXTURE_WRAP.CLAMP_TO_EDGE;

    // Texture filtering: true for bilinear, false for nearest neighbor
    filter = data[$ "filter"] ?? true;

    // Enable mipmaps generation
    generateMipmaps = data[$ "generateMipmaps"] ?? true;

    // 4x4 transformation matrix for UVs
    matrix = new UeMatrix4();

    // Whether to auto-update matrix before drawing
    matrixAutoUpdate = true;

    // Flag indicating if texture needs to be re-baked/updated
    needsUpdate = false;

    // Cached sprite created from baked surface with applied transforms
    __cachedSprite = image;

    // Cached texture handle from the cached sprite
    __cachedTexture = image != undefined ? sprite_get_texture(image, 0) : undefined;

    /**
     * Updates the UV transformation matrix combining offset, repeat,
     * rotation, center, and flips into a single matrix.
     * Uses matrix multiplication to concatenate transformations.
     */
    function updateMatrix() {
        gml_pragma("forceinline");

        var tx = -center.x;
        var ty = -center.y;

        var repeatVec = self[$ "repeat"];
        var sx = repeatVec.x * (flipX ? -1 : 1);
        var sy = repeatVec.y * (flipY ? -1 : 1);

        var ox = offset.x + center.x;
        var oy = offset.y + center.y;
        
        log(tx, ty, sx, sy, ox, oy)

        matrix.identity()
            .multiply(matrix.makeTranslation(tx, ty, 0))
            .multiply(matrix.makeRotationFromEuler(0, rotation, 0))
            .multiply(matrix.makeScale(sx, sy, 1))
            .multiply(matrix.makeTranslation(ox, oy, 0));

        return self;
    }

    /**
     * Internal method to bake the transformed texture into a surface,
     * then create a persistent sprite from that surface.
     * Handles wrapping modes and tiling by repeated drawing.
     */
    function __update() {
        gml_pragma("forceinline");
        dispose();    // Clear previous cached sprite
        updateMatrix();  // Build the transformation matrix
        
        var repeatVec = self[$ "repeat"];
        var tilesX = ceil(abs(repeatVec.x));
        var tilesY = ceil(abs(repeatVec.y));
        
        var spriteW = sprite_get_width(image);
        var spriteH = sprite_get_height(image);
        var surfW = spriteW * tilesX;
        var surfH = spriteH * tilesY; 
        var surf = surface_create(surfW, surfH);
        surface_set_target(surf);
        draw_clear_alpha(c_white, 0);
        
        matrix_set(matrix_world, matrix.data);
     
        for (var ix = 0; ix < tilesX; ix++) {
            for (var iy = 0; iy < tilesY; iy++) {
                // Determine mirroring based on wrap mode
                var mirrorX = (wrapS == UE_TEXTURE_WRAP.MIRRORED_REPEAT) && ((ix % 2) == 1);
                var mirrorY = (wrapT == UE_TEXTURE_WRAP.MIRRORED_REPEAT) && ((iy % 2) == 1);

                // ClampToEdge disables tiling beyond first tile
                if (wrapS == UE_TEXTURE_WRAP.CLAMP_TO_EDGE && ix > 0) continue;
                if (wrapT == UE_TEXTURE_WRAP.CLAMP_TO_EDGE && iy > 0) continue;

                var px = ix * spriteW;
                var py = iy * spriteH;
                var scaleX = mirrorX ? -1 : 1;
                var scaleY = mirrorY ? -1 : 1;

                draw_sprite_ext(image, 0, px, py, scaleX, scaleY, 0, c_white, 1);
            } 
        }
        
        surface_reset_target();

        // Create cached sprite from baked surface
        __cachedSprite = sprite_create_from_surface(surf, 0, 0, surfW, surfH, false, false, 0, 0);
        
        surface_free(surf);
        
        // Get texture handle from cached sprite
        __cachedTexture = sprite_get_texture(__cachedSprite, 0);

        needsUpdate = false;
        return self;
    }

    /**
     * Bind this texture to a given sampler stage.
     * Applies GPU parameters for wrapping, filtering, mipmaps.
     * Automatically updates cached texture if needed.
     */
    function __use(sampler) {
        gml_pragma("forceinline");

        if (matrixAutoUpdate && needsUpdate) __update();

        var repeatFlag = wrapS == UE_TEXTURE_WRAP.REPEAT || wrapT == UE_TEXTURE_WRAP.REPEAT;
        gpu_set_texrepeat_ext(sampler, repeatFlag);

        gpu_set_texfilter_ext(sampler, filter);
        gpu_set_tex_mip_enable_ext(sampler, generateMipmaps);
        texture_set_stage(sampler, __cachedTexture);

        return self;
    }

    /**
     * Dispose cached sprite and free GPU resources.
     */
    function dispose() {
        gml_pragma("forceinline");

        if (sprite_exists(__cachedSprite)) sprite_delete(__cachedSprite);
        __cachedSprite = undefined;
        __cachedTexture = undefined;

        return self;
    }

    /**
     * Serialize important texture properties to JSON for export.
     */
    function toJSON() {
        gml_pragma("forceinline");

        var repeatVec = self[$ "repeat"];

        var payload = {
            filter,
            generateMipmaps,
            spriteBuffSize: 0,
            
            // UV transform parameters
            offset: [offset.x, offset],
            center: [center.x, center.y],
            rotation,
            
             // Flip flags
            flipX,
            flipY,
            
            // Wrapping modes
            wrapS,
            wrapT
        };

        payload[$ "repeat"] = [repeatVec.x, repeatVec.y];
        return payload;
    }

    /**
     * Internal method to prepare export data, including sprite size and buffer size.
     */
    function _compileData(data) {
        gml_pragma("forceinline");

        var payload = toJSON();

        var compileSprites = data.compileSprites && __cachedSprite != undefined;
        var spriteWidth = undefined;
        var spriteHeight = undefined;
        var spriteBuffSize = 0;

        if (compileSprites) {
            spriteWidth = sprite_get_width(__cachedSprite);
            spriteHeight = sprite_get_height(__cachedSprite);
            spriteBuffSize = spriteWidth * spriteHeight * 4;
            payload.spriteWidth = spriteWidth;
            payload.spriteHeight = spriteHeight;
            payload.spriteBuffSize = spriteBuffSize;
        }

        data.size += spriteBuffSize;

        return {
            payload: payload,
            ctx: { spriteWidth, spriteHeight, spriteBuffSize }
        };
    }

    /**
     * Internal method to copy the sprite surface data into an export buffer.
     */
    function _compileBufferExtra(buffer, ctx) {
        gml_pragma("forceinline");

        if (!ctx.spriteBuffSize) return;

        var spriteSurf = surface_create(ctx.spriteWidth, ctx.spriteHeight);
        surface_set_target(spriteSurf);
        draw_clear_alpha(c_black, 0);
        draw_sprite(__cachedSprite, 0, 0, 0);
        surface_reset_target();
        buffer_get_surface(buffer, spriteSurf, buffer_tell(buffer));
        surface_free(spriteSurf);
    }
    
    /**
     * --- Helpers --- 
     */
    
     /**
     * Object-fit: contain (fit inside surface preserving aspect ratio)
     */
    function contain(aspect) {
        gml_pragma("forceinline");
        var imageW = sprite_get_width(image);
        var imageH = sprite_get_height(image);
        var imageAspect = imageW / imageH;
    
        var scaleX = 1;
        var scaleY = 1;
    
        if (imageAspect > aspect) {
            // Image is wider than container
            scaleY = imageAspect / aspect;
        } else {
            // Image is taller than container
            scaleX = aspect / imageAspect;
        }
    
        self[$ "repeat"].x = 1 / scaleX;
        self[$ "repeat"].y = 1 / scaleY;
        offset.x = (1 - self[$ "repeat"].x) * 0.5;
        offset.y = (1 - self[$ "repeat"].y) * 0.5;
    
        needsUpdate = true;
        return self;
    }
    
    /**
     * Object-fit: cover (cover entire surface preserving aspect ratio)
     */
    function cover(aspect) {
        gml_pragma("forceinline");
        var imageW = sprite_get_width(image);
        var imageH = sprite_get_height(image);
        var imageAspect = imageW / imageH;
    
        var scaleX = 1;
        var scaleY = 1;
    
        if (imageAspect > aspect) {
            // Image is wider, scale width more
            scaleX = imageAspect / aspect;
        } else {
            // Image is taller, scale height more
            scaleY = aspect / imageAspect;
        }
    
        self[$ "repeat"].x = scaleX;
        self[$ "repeat"].y = scaleY;
        offset.x = (1 - self[$ "repeat"].x) * 0.5;
        offset.y = (1 - self[$ "repeat"].y) * 0.5;
    
        needsUpdate = true;
        return self;
    }
    
    /**
     * Object-fit: fill (stretch to fill, ignore aspect ratio)
     */
    function fill() {
        gml_pragma("forceinline");
        self[$ "repeat"].x = 1;
        self[$ "repeat"].y = 1;
        offset.x = 0;
        offset.y = 0;
        rotation = 0;
        flipX = false;
        flipY = false;
        needsUpdate = true;
        return self;
    } 
}
