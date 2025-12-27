/**
 * UeOutlinePass
 * 
 * A post-processing pass that renders outlines around selected objects.
 * Inspired by Three.js OutlinePass.
 * 
 * How it works:
 * 
 * 1. MASK PASS: Render selected objects as white silhouettes on black background
 *    - Uses a simple solid color shader (sh_ue_outline)
 *    - Renders to a separate render target (maskTarget)
 *    - This creates a clean binary mask of the object shapes
 * 
 * 2. EDGE DETECTION: Apply Sobel filter on the mask
 *    - Detects edges only on the mask, not the scene
 *    - This finds ONLY the silhouette edges, ignoring internal shading
 * 
 * 3. COMPOSITION: Overlay detected edges onto the original scene
 *    - Blends edge color with scene color based on edge intensity
 *    - Optional glow effect for softer edges
 * 
 * @param {UeScene} scene - The scene containing the objects
 * @param {UeCamera} camera - The camera used for rendering
 * @param {Array} selectedObjects - Array of objects to outline
 */
function UeOutlinePass(scene, camera, selectedObjects = []): UePass() constructor {
    // ========================================
    // CONFIGURATION
    // ========================================
    
    self.renderScene = scene;
    self.renderCamera = camera;
    self.selectedObjects = selectedObjects;
    
    // Outline visual parameters
    self.visibleEdgeColor = [1, 1, 1];  // White outline by default
    self.edgeGlow = 1;                   // Glow/blur amount (0 = sharp)
    self.edgeStrength = 3;               // Intensity multiplier
    self.thickness = 1;                  // Edge thickness in pixels
    self.hiddenEdgeColor = [0.1, 0.04, 0.02]; // For future hidden edge support
    
    // ========================================
    // INTERNAL RESOURCES
    // ========================================
    
    // Render target for the mask (selected objects as white silhouettes)
    self.__maskTarget = undefined;
    
    // Material for rendering objects as solid white (mask pass)
    self.__maskMaterial = new UeMaterial({
        shader: sh_ue_outline_mask,
        lights: 0,         // No lighting needed
        blending: false,   // Solid color, no blending
        depthTest: true,   // Respect depth for proper occlusion
        depthWrite: true,
    });
    
    // Material for edge detection and composition pass
    self.__outlineMaterial = new UeMaterial({
        shader: sh_ue_outline_pass,
        lights: 0,
        blending: false,
    });
    
    // Texture reference for the mask (used by the outline shader)
    self.__maskTexture = new UeTexture();
    
    // Fullscreen quad for rendering the final composition
    self.__fullscreenQuad = undefined;

    /**
     * Build/initialize all resources.
     * Called automatically in constructor.
     */
    function build() {
        gml_pragma("forceinline");
        
        // Setup outline material uniforms
        var _uniforms = {};
        _uniforms[$ "visibleEdgeColor"] = { type: UE_UNIFORM_TYPE.ARRAY, value: self.visibleEdgeColor };
        _uniforms[$ "thickness"] = { type: UE_UNIFORM_TYPE.FLOAT, value: self.thickness };
        _uniforms[$ "edgeStrength"] = { type: UE_UNIFORM_TYPE.FLOAT, value: self.edgeStrength };
        _uniforms[$ "edgeGlow"] = { type: UE_UNIFORM_TYPE.FLOAT, value: self.edgeGlow };
        _uniforms[$ "texelSize"] = { type: UE_UNIFORM_TYPE.VEC2, value: [1, 1] };
        
        self.__outlineMaterial.uniforms = _uniforms;
        
        // Register the mask texture with the material
        // The shader will sample this as 's_mask'
        self.__outlineMaterial.textures[$ "mask"] = self.__maskTexture;
        
        // Build materials
        self.__maskMaterial.build();
        self.__outlineMaterial.build();
        
        // Create fullscreen quad for the composition pass
        self.__fullscreenQuad = new UeFullscreenQuad(self.__outlineMaterial);
        
        return self;
    }
    
    /**
     * Set the size of the mask render target.
     * Should be called when the composer size changes.
     */
    function setSize(width, height) {
        gml_pragma("forceinline");
        
        if (self.__maskTarget != undefined) {
            self.__maskTarget.setSize(width, height);
        } else {
            self.__maskTarget = new UeRenderTarget(width, height);
        }
        
        return self;
    }

    /**
     * Main render function.
     * 
     * @param {UeRenderer} renderer - The renderer instance
     * @param {UeRenderTarget} writeTarget - Target to write output to
     * @param {UeRenderTarget} readTarget - Contains the rendered scene from previous pass
     */
    function render(renderer, writeTarget, readTarget) {
        gml_pragma("forceinline");
        
        // Skip if no objects to outline
        if (array_length(self.selectedObjects) == 0) {
            return self;
        }
        
        // ========================================
        // STEP 1: MASK PASS
        // Render selected objects as white silhouettes
        // ========================================
        
        // Ensure mask target exists and matches the size
        if (self.__maskTarget == undefined) {
            self.__maskTarget = new UeRenderTarget(readTarget.width, readTarget.height);
        }
        
        // Set the mask as render target
        var _oldRT = renderer.getRenderTarget();
        renderer.setRenderTarget(self.__maskTarget);
        
        // Clear to black (background of the mask)
        renderer.setClearColor(c_black, 1);
        renderer.clear(true, true, false);
        
        // Apply the 3D camera for proper perspective
        camera_apply(self.renderCamera.camera);
        
        // Apply mask material (solid white shader)
        self.__maskMaterial.use();
        
        // Render each selected object
        for (var i = 0, len = array_length(self.selectedObjects); i < len; i++) {
            var obj = self.selectedObjects[i];
            if (obj != undefined && obj[$ "geometry"] != undefined && obj.geometry[$ "vb"] != undefined) {
                // Set world matrix for this object
                matrix_set(matrix_world, obj.matrixWorld);
                // Submit the geometry
                vertex_submit(obj.geometry.vb, obj.primitive ?? pr_trianglelist, -1);
            }
        }
        
        // ========================================
        // STEP 2: EDGE DETECTION & COMPOSITION
        // Apply Sobel filter on mask and overlay on scene
        // ========================================
        
        // Set output render target
        renderer.setRenderTarget(self.renderToScreen ? undefined : writeTarget);
        
        // Don't clear - we want to draw over the existing scene
        // (The scene is already in the target from previous passes)
        
        // Update uniforms
        var _texelSize = self.__outlineMaterial.uniforms[$ "texelSize"].value;
        _texelSize[@ 0] = 1 / readTarget.width;
        _texelSize[@ 1] = 1 / readTarget.height;
        
        // Render fullscreen quad with the scene texture
        // The shader will:
        // - Sample the scene from gm_BaseTexture
        // - Sample the mask from s_mask
        // - Apply edge detection on the mask
        // - Composite edges onto the scene
        var _sceneTexture = surface_get_texture(readTarget.surface);
        
        // Apply the outline material
        self.__outlineMaterial.use();
        
        // Manually set the mask texture (UeMaterial skips textures without sprites)
        var _maskSampler = shader_get_sampler_index(sh_ue_outline_pass, "s_mask");
        var _maskTexture = surface_get_texture(self.__maskTarget.surface);
        texture_set_stage(_maskSampler, _maskTexture);
        
        // Now render the fullscreen quad (skip material.use since we already called it)
        self.__fullscreenQuad.render(_sceneTexture, true);
        
        // Restore previous render target
        renderer.setRenderTarget(_oldRT);
        
        return self;
    }

    /**
     * Clean up all resources.
     */
    function dispose() {
        gml_pragma("forceinline");
        
        if (self.__fullscreenQuad != undefined) {
            self.__fullscreenQuad.dispose();
            self.__fullscreenQuad = undefined;
        }
        if (self.__maskTarget != undefined) {
            self.__maskTarget.dispose();
            self.__maskTarget = undefined;
        }
        if (self.__maskMaterial != undefined) {
            self.__maskMaterial.dispose();
            self.__maskMaterial = undefined;
        }
        if (self.__outlineMaterial != undefined) {
            self.__outlineMaterial.dispose();
            self.__outlineMaterial = undefined;
        }
        if (self.__maskTexture != undefined) {
            self.__maskTexture.dispose();
            self.__maskTexture = undefined;
        }
        
        return self;
    }

    // Build on construction
    self.build();
}
