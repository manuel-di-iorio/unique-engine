/**
 * UeQuadGeometry
 * 
 * A simple quad geometry in Normalized Device Coordinates (NDC).
 * NDC ranges from -1 to +1 on both X and Y axes.
 * 
 * When rendered with identity matrices, this quad covers the entire screen,
 * making it perfect for fullscreen post-processing effects.
 */
function UeQuadGeometry(data = {}): UeGeometry(data) constructor {
    type = "QuadGeometry";
    
    // This is lighter than the default format (no normals/color needed for fullscreen quad)
    self.format = global.UE_POSITION_UV_VFORMAT;
    
    // Optimization: Single large triangle covering the entire NDC space
    // This avoids the diagonal seam issue sometimes visible with two triangles.
    // The triangle vertices are:
    // 1. Bottom-Left (-1, -1)
    // 2. Far-Right   ( 3, -1)
    // 3. Far-Top     (-1,  3)
    //
    // UV Mapping:
    // (-1, -1) -> (0, 1)  (Bottom-Left of screen)
    // ( 3, -1) -> (2, 1)  (Extrapolated Right)
    // (-1,  3) -> (0, -1) (Extrapolated Top)
    //
    // This results in the screen area [-1, 1] having UVs [0, 1].
    var vertices = [
        { x: -1, y: -1, z: 0, u: 0, v:  1 },
        { x:  3, y: -1, z: 0, u: 2, v:  1 },
        { x: -1, y:  3, z: 0, u: 0, v: -1 }
    ];
    
    self.vertices = vertices;
  
    self.build();
}


/**
 * UeFullscreenQuad
 * 
 * A utility class for rendering fullscreen post-processing effects.
 * It renders a quad that covers the entire screen with a specified material/shader.
 * 
 * How it works:
 * 1. The quad uses NDC coordinates (-1 to +1) which map directly to clip space
 * 2. When all transformation matrices are identity, the quad fills the screen
 * 3. The material's shader is applied to the quad, receiving the texture via gm_BaseTexture
 * 4. This allows post-processing shaders to sample and modify the input texture
 * 
 * Usage:
 *   var quad = new UeFullscreenQuad(myMaterial);
 *   quad.render(inputTexture); // Draws fullscreen with the shader applied
 * 
 * The quad does NOT own the material - caller is responsible for material lifecycle.
 */
function UeFullscreenQuad(material) constructor {
    self.material = material;
    
    // Create the NDC quad geometry once
    self.geometry = new UeQuadGeometry();

    /**
     * Clean up resources owned by this quad.
     * Note: Does NOT dispose the material (caller owns it).
     */
    function dispose() {
        gml_pragma("forceinline");
        if (self.geometry != undefined) {
            self.geometry.dispose();
            self.geometry = undefined;
        }
        self.material = undefined;
        return self;
    }

    /**
     * Render the fullscreen quad with the given texture.
     * 
     * @param {texture} texture - The texture to use as gm_BaseTexture in the shader.
     *                           This is typically a surface texture from a previous render pass.
     * @param {bool} skipMaterial - If true, skip calling material.use(). Useful when the caller
     *                              has already applied the material and set custom texture stages.
     * 
     * The method:
     * 1. Applies the material (activates shader, sets uniforms) - unless skipMaterial is true
     * 2. Configures GPU for 2D rendering (no depth test, no culling)
     * 3. Sets identity matrices so NDC coordinates map directly to screen
     * 4. Submits the quad geometry with the texture
     */
    function render(texture, skipMaterial = false) {
        gml_pragma("forceinline");
        
        // Step 1: Apply material (shader + uniforms)
        // This activates the post-processing shader
        if (!skipMaterial) self.material.use();
        
        // Step 2: Configure GPU for 2D/post-processing
        // - No depth testing (we're drawing a flat 2D overlay)
        // - No depth writing (don't affect the depth buffer)
        // - No backface culling (quad should always be visible)
        gpu_set_ztestenable(false);
        gpu_set_zwriteenable(false);
        gpu_set_cullmode(cull_noculling);
        
        // Step 3: Set identity matrices for NDC rendering
        // In NDC, (-1,-1) is bottom-left and (+1,+1) is top-right of the screen.
        // With identity matrices, the GPU doesn't transform our vertices,
        // so our NDC quad directly maps to the full viewport.
        matrix_set(matrix_projection, global.UE_MATRIX_IDENTITY);
        matrix_set(matrix_view, global.UE_MATRIX_IDENTITY);
        matrix_set(matrix_world, global.UE_MATRIX_IDENTITY);
        
        // Step 4: Submit the quad with the input texture
        // vertex_submit's third parameter sets gm_BaseTexture in the shader
        vertex_submit(self.geometry.vb, pr_trianglelist, texture);
        
        return self;
    }
}
