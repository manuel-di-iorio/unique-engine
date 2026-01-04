function UeTexture(sprite = undefined, data = {}) constructor {
    id = global.UE_OBJECT_ID++;
    
    // Flag indicating this object is a texture
    isTexture = true;

    // Type string
    type = "Texture";

    // Unique identifier for this texture instance
    uuid = ueUuid();

    // Optional texture name
    name = data[$ "name"] ?? "";

    // Base image sprite used for this texture
    self.sprite = sprite;

    // UV offset for texture coordinates (Vector2)
    offset = vec2_create();

    // Number of times the texture repeats on UV axes (Vector2)
    self[$ "repeat"] = data[$ "repeat"] ?? vec2_create(1, 1);

    // Center point for rotation and transformations (Vector2)
    center = vec2_create();

    // Rotation angle in degrees (around Z axis)
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
    // @todo doc to align
    generateMipmaps = data[$ "generateMipmaps"] ?? mip_on;

    // 4x4 transformation matrix for UVs
    matrix = mat4_create()

    // Whether to auto-update matrix before drawing
    matrixAutoUpdate = true;

    // Flag indicating if texture needs to be re-baked/updated
    needsUpdate = false;

    // Cached sprite created from baked surface with applied transforms
    __cachedSprite = sprite;

    // Cached texture handle from the cached sprite
    __cachedTexture = sprite != undefined ? sprite_get_texture(sprite, 0) : undefined;
    
    // A struct that can be used to store custom data about the texture(also exported on the buffer)
    userData = {};

    /**
     * Updates the UV transformation matrix combining offset, repeat,
     * rotation, center, and flips into a single matrix.
     * Uses matrix multiplication to concatenate transformations.
     */
    function updateMatrix() {
      gml_pragma("forceinline");
  
      var tx = -center[VEC2.x];
      var ty = -center[VEC2.y];

      var repeatVec = self[$ "repeat"];
      var sx = repeatVec[VEC2.x] * (flipX ? -1 : 1);
      var sy = repeatVec[VEC2.y] * (flipY ? -1 : 1);

      var ox = offset[VEC2.x] + center[VEC2.x];
      var oy = offset[VEC2.y] + center[VEC2.y];
      
      var cx = sprite_get_width(sprite) * 0.5;
      var cy = sprite_get_height(sprite) * 0.5;

      var tempMat = global.UE_MAT4_TEMP0;
      mat4_identity(matrix);
      // Move the offset
      mat4_make_translation(tempMat, ox, oy, 0); mat4_multiply(matrix, tempMat);
      // Move the pivot to the sprite center
      mat4_make_translation(tempMat, cx, cy, 0); mat4_multiply(matrix, tempMat);
      // Rotate around the pivot
      mat4_make_rotation_from_euler(tempMat, 0, 0, rotation); mat4_multiply(matrix, tempMat);
      // Flip if requested
      mat4_make_scale(tempMat, sx, sy, 1); mat4_multiply(matrix, tempMat);
      // Move back the pivot
      mat4_make_translation(tempMat, -cx, -cy, 0); mat4_multiply(matrix, tempMat);
      // Move to the specified center
      mat4_make_translation(tempMat, tx, ty, 0); mat4_multiply(matrix, tempMat);
      
      return self;
    }

    /**
     * Internal method to bake the transformed texture into a surface,
     * then create a persistent sprite from that surface.
     * Handles wrapping modes and tiling by repeated drawing.
     */
    function update() {
        gml_pragma("forceinline");
        dispose();    // Clear previous cached sprite
        if (!sprite_exists(sprite)) return;
        
        var repeatVec = self[$ "repeat"];
        var tilesX = ceil(abs(repeatVec[VEC2.x]));
        var tilesY = ceil(abs(repeatVec[VEC2.y]));
        
        var spriteW = sprite_get_width(sprite);
        var spriteH = sprite_get_height(sprite);
        var surfW = spriteW * tilesX;
        var surfH = spriteH * tilesY; 
        var surf = surface_create(surfW, surfH);

        surface_set_target(surf);
        draw_clear_alpha(c_black, 0);
        
        var currentBlendEnable = gpu_get_blendenable();
        gpu_set_blendenable(false);
        
        updateMatrix();  // Build the transformation matrix
        matrix_set(matrix_world, matrix);
     
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

                draw_sprite_ext(sprite, 0, px, py, scaleX, scaleY, 0, c_white, 1);
           
            } 
        }
        
        gpu_set_blendenable(currentBlendEnable);

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
     * Set the texture properties globally (internally used for base textures)
     */
    function __useGlobal() {
      gml_pragma("forceinline");
        if (__cachedTexture == undefined) return;

        // if (matrixAutoUpdate && needsUpdate) update();

        var repeatFlag = wrapS == UE_TEXTURE_WRAP.REPEAT || wrapT == UE_TEXTURE_WRAP.REPEAT;
        gpu_set_texrepeat(repeatFlag);

        gpu_set_texfilter(filter);
        gpu_set_tex_mip_enable(generateMipmaps);

        return self;
    }

    /**
     * Bind this texture to a given sampler stage.
     * Applies GPU parameters for wrapping, filtering, mipmaps.
     * Automatically updates cached texture if needed.
     */
    function __use(sampler) {
        gml_pragma("forceinline");
        if (__cachedTexture == undefined) return;

        if (matrixAutoUpdate && needsUpdate) update();

        var repeatFlag = wrapS == UE_TEXTURE_WRAP.REPEAT || wrapT == UE_TEXTURE_WRAP.REPEAT;
        gpu_set_texrepeat_ext(sampler, repeatFlag);

        gpu_set_texfilter_ext(sampler, filter);
        gpu_set_tex_mip_enable_ext(sampler, generateMipmaps);
        texture_set_stage(sampler, __cachedTexture);

        return self;
    }

    /**
     * Dispose cached sprite (if modified) to free memory resources.
     */
    function dispose() {
        gml_pragma("forceinline");

        if (sprite != __cachedSprite && sprite_exists(__cachedSprite)) {
            sprite_delete(__cachedSprite);
        }
        
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
            uuid,
            type,
            name,
            filter,
            generateMipmaps,
            spriteBuffSize: 0,
            
            // UV transform parameters
            offset,
            center,
            rotation,
            
             // Flip flags
            flipX,
            flipY,
            
            // Wrapping modes
            wrapS,
            wrapT,
            
            // Custom user data
            userData
        };

        payload[$ "repeat"] = [repeatVec[0], repeatVec[1]];
        return payload;
    }

    function fromJSON(data) {
        gml_pragma("forceinline");

        uuid = data.uuid;
        name = data.name;
        filter = data.filter;
        generateMipmaps = data.generateMipmaps;

        var repeatArr = data[$ "repeat"] ?? [1, 1];
        vec2_set(self[$ "repeat"], repeatArr[0], repeatArr[1]);

        var offsetArr = data[$ "offset"] ?? [0, 0];
        vec2_set(offset, offsetArr[0], offsetArr[1]);

        var centerArr = data[$ "center"] ?? [0, 0];
        vec2_set(center, centerArr[0], centerArr[1]);

        rotation = data.rotation ?? 0;
        flipX = data.flipX ?? false;
        flipY = data.flipY ?? false;
        wrapS = data.wrapS ?? UE_TEXTURE_WRAP.CLAMP_TO_EDGE;
        wrapT = data.wrapT ?? UE_TEXTURE_WRAP.CLAMP_TO_EDGE;

        userData = data.userData ?? {};

        // needsUpdate = true;
        return self;
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
            payload,
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

    function export(fname) {
        if (__cachedSprite == undefined) return self;
        sprite_save(__cachedSprite, 0, fname);
        return self;
    }
    
    function import(fname) {
        if (!file_exists(fname)) return self;
        
        // Delete old sprite if it exists
        if (sprite_exists(sprite)) {
            sprite_delete(sprite);
        }
        
        // Load the sprite from file
        sprite = sprite_add(fname, 0, false, false, 0, 0);
        __cachedSprite = sprite;
        __cachedTexture = sprite_exists(sprite) ? sprite_get_texture(sprite, 0) : undefined;
        
        return self;
    }
    
    /**
     * --- Helpers --- 
     */
    
     /**
     * Object-fit: contain (fit inside surface preserving aspect ratio)
     */
    function contain(aspect) {
        gml_pragma("forceinline");
        var imageW = sprite_get_width(sprite);
        var imageH = sprite_get_height(sprite);
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
    
        self[$ "repeat"][0] = 1 / scaleX;
        self[$ "repeat"][1] = 1 / scaleY;
        offset[0] = (1 - self[$ "repeat"][0]) * 0.5;
        offset[1] = (1 - self[$ "repeat"][1]) * 0.5;
    
        needsUpdate = true;
        return self;
    }
    
    /**
     * Object-fit: cover (cover entire surface preserving aspect ratio)
     */
    function cover(aspect) {
        gml_pragma("forceinline");
        var imageW = sprite_get_width(sprite);
        var imageH = sprite_get_height(sprite);
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
    
        self[$ "repeat"][0] = scaleX;
        self[$ "repeat"][1] = scaleY;
        offset[0] = (1 - self[$ "repeat"][0]) * 0.5;
        offset[1] = (1 - self[$ "repeat"][1]) * 0.5;
    
        needsUpdate = true;
        return self;
    }
    
    /**
     * Object-fit: fill (stretch to fill, ignore aspect ratio)
     */
    function fill() {
        gml_pragma("forceinline");
        self[$ "repeat"][0] = 1;
        self[$ "repeat"][1] = 1;
        offset.x = 0;
        offset.y = 0;
        rotation = 0;
        flipX = false;
        flipY = false;
        needsUpdate = true;
        return self;
    } 

    /**
     * Clone this texture instance
     */
    function clone() {
        return variable_clone(self);
    }
}
