function UeRenderer(data = {}): UeObject3D(data) constructor {
    isRenderer = true;
    type = "Renderer";
    sortObjects = data[$ "sortObjects"] ?? true;
    width = data[$ "width"] ?? display_get_width(); // Default to display size
    height = data[$ "height"] ?? display_get_height();
    autoClear = data[$ "autoClear"] ?? false;
    autoClearColor = data[$ "autoClearColor"] ?? true;
    autoClearDepth = data[$ "autoClearDepth"] ?? true;
    autoClearStencil = data[$ "autoClearStencil"] ?? true;
    __clearColor = c_white;
    __clearAlpha = 1;
    __renderTarget = undefined;

    // Shadow map configuration for the renderer
    shadowMap = data[$ "shadowMap"] ?? {};
    shadowMap.enabled = shadowMap[$ "enabled"] ?? false;
    shadowMap.autoUpdate = shadowMap[$ "autoUpdate"] ?? true;
    shadowMap.needsUpdate = shadowMap[$ "needsUpdate"] ?? false;
    
    function setSize(width, height) {
        gml_pragma("forceinline");
        self.width = width;
        self.height = height;
    }

    function getSize(target = undefined) {
        gml_pragma("forceinline");
        if (target == undefined) target = {};
        target.width = self.width;
        target.height = self.height;
        return target;
    }
    
    __boundMaterial = undefined; // Material that is currently bound
    __lightIdx = 0;
    __queueIdx = 0;
    __lights = array_create(2);
    __queue = array_create(512);
    __shadowIdx = 0;
    
    function clear(color = true, depth = true, stencil = true) {
        if (color) draw_clear_alpha(self.__clearColor, self.__clearAlpha);
        if (depth) draw_clear_depth(1);
        if (stencil) draw_clear_stencil(0);
    }
    
    function clearColor() {
        draw_clear_alpha(self.__clearColor, self.__clearAlpha);
    }
    
    function clearDepth() {
        draw_clear_depth(1);
    }
    
    function clearStencil() {
        draw_clear_stencil(0);
    }
    
    function getClearColor() {
        return self.__clearColor;
    }
    
    function getClearAlpha() {
        return self.__clearAlpha;
    }
    
    function setClearAlpha(alpha) {
        self.__clearAlpha = alpha;
    }

    function setClearColor(color, alpha) {
        self.__clearColor = color;
        self.__clearAlpha = alpha;
    }

    function setRenderTarget(target) {
        if (target != undefined) {
            if (!surface_exists(target.surface)) target.create();
            surface_set_target(target.surface);
        } else if (self.__renderTarget != undefined) {
            surface_reset_target();
        }

        self.__renderTarget = target;
    }

    function getRenderTarget() {
        return self.__renderTarget;
    }
    
    // Recursively collect renderable objects and precompute their sort key
    function __collectObjectQueues(objects, camera) {
        gml_pragma("forceinline");
        var cameraPos = camera.position;
        var cameraLayers = camera.layers;
        
        for (var i = 0, len = array_length(objects); i < len; i++) {
            var object = objects[i];
            if (!object.layers.test(cameraLayers)) continue;
            
            if (object[$ "isLight"]) {
                __lights[__lightIdx++] = object;
                continue;
            }
                
            // Update matrices for dynamic objects
            if (object.matrixAutoUpdate && object.matrixWorldAutoUpdate) object.updateMatrixWorld();
            
            /* Frustum intersection && sort key calculation */
            if (object.visible) {
               if (object[$ "geometry"] != undefined && object.geometry[$ "vb"] != undefined) {
                   // Test the frustum intersection
                   if (object[$ "isMesh"] && object.frustumCulled) {
                       var _boundingSphere = object[$ "__intersectionSphere"];
   
                       if (!_boundingSphere.isEmpty() &&
                           !sphere_is_visible(_boundingSphere.center.x, _boundingSphere.center.y, 
                            _boundingSphere.center.z, _boundingSphere.radius)) {
                        continue;
                      }
                   }
                   
                   // ** Precompute the sort hash **
   
                   // --- MATERIAL & TRANSPARENCY -------------------------------------------------
                   // Determine whether the material is transparent.
                   // Transparent objects must be rendered *after* opaque ones,
                   // and sorted back-to-front inside their own group.
                   var _material = object[$ "material"];
                   var _transparent = _material.transparent;
   
                   // Material ID (12-bit)
                   var _materialId = _material.id;
   
                   // --- DEPTH QUANTIZATION (31 bits) -------------------------------------------
                   // We convert the object distance into a normalized value (0..1),
                   // then map it into a 31-bit integer range (0..2^31-1).
                   //
                   // Why quantize instead of using the raw float distance?
                   // - Floating-point precision becomes poor for large distances.
                   // - Sorting with floats introduces instability and z-fighting-like errors.
                   // - By converting to a 31-bit integer, we guarantee a stable and uniform
                   //   precision distribution across the whole range.
                   var _nd = clamp(object.position.distanceToSquared(cameraPos) / 32000, 0, 1);
                   var _quantDepth = floor(_nd * 0x7FFFFFFF);  // 31-bit integer depth value
   
                   // --- DEPTH INVERSION FOR TRANSPARENT OBJECTS --------------------------------
                   // Transparent objects must be sorted *back-to-front*, while opaque objects
                   // are sorted *front-to-back*.
                   //
                   // Instead of using two different sort passes, we invert the depth integer
                   // when the object is transparent.
                   //
                   // Bitwise trick:
                   //     _quantDepth ^= mask
                   //
                   // The mask is (0x7FFFFFFF) when the object is transparent,
                   // and (0) when opaque. This works because:
                   //
                   //     -_transparent  →  0xFFFFFFFF when true, 0x00000000 when false
                   //     & 0x7FFFFFFF   →  either full-mask or zero-mask
                   //
                   // Result: all 31 bits of depth are flipped only when needed.
                   _quantDepth ^= (-_transparent & 0x7FFFFFFF);
   
                   // --- SORT KEY COMPOSITION (52 bits) ------------------------------------------
                   // We pack all sorting criteria into a single integer key.
                   // Higher-order bits have higher sorting priority.
                   //
                   // Bit layout (from MSB → LSB):
                   //
                   //  [51]        : 1 bit   → transparency flag (opaque first, transparent later)
                   //  [50..43]    : 8 bits  → renderOrder (explicit user sorting)
                   //  [42..31]    : 12 bits → material ID (minimizes shader/material switches)
                   //  [30..0]     : 31 bits → quantized depth (front-to-back or inverted)
                   //
                   // The final 52-bit key ensures a single fast integer comparison for sorting.
                   var _sortKey = 0;
                   _sortKey |= (_transparent ? 1 : 0) << 51;      // 1 bit  transparency flag
                   _sortKey |= (object.renderOrder & 0xFF) << 43; // 8 bits renderOrder
                   _sortKey |= (_materialId & 0xFFF) << 31;       // 12 bits material ID
                   _sortKey |= _quantDepth;                       // 31 bits depth
                   object.__sortKey = _sortKey;
   
                   __queue[__queueIdx++] = object;
               }
            
              // Traverse child objects
              __collectObjectQueues(object.children, camera);
            }
        } 
    }    
   
    function __quickSortObjects(left, right) {
        gml_pragma("forceinline");
        if (left >= right) return;
        
        var array = __queue;
        var pivot = array[right].__sortKey;
        var i = left - 1;
        var tmp;
        
        for (var j = left; j < right; j++) {
            if (array[j].__sortKey < pivot) {
                i++;
                tmp = array[i];
                array[i] = array[j];
                array[j] = tmp;
            }
        }
        
        tmp = array[i + 1];
        array[i + 1] = array[right];
        array[right] = tmp;
        
        var pivotIndex = i + 1;
        
        __quickSortObjects(left, pivotIndex - 1);
        __quickSortObjects(pivotIndex + 1, right);
    } 

    /**
     * Renders shadow maps for all shadow-casting lights.
     * This must be called before the main render pass.
     * @param {Struct} scene - The scene to render
     */
    function __renderShadowMaps(scene, camera) {
        gml_pragma("forceinline");
        
        // Configure GPU state for shadow depth pass
        var _prevCull = gpu_get_cullmode();
        var _prevZTest = gpu_get_ztestenable();
        var _prevZWrite = gpu_get_zwriteenable();
        var _prevBlend = gpu_get_blendenable();
        gpu_set_cullmode(cull_counterclockwise);
        gpu_set_ztestenable(true);
        gpu_set_zwriteenable(true);
        gpu_set_blendenable(false);
        var _resetSurf = false;
        
        for (var i = 0; i < __lightIdx; i++) {
            var light = __lights[i];
            if (!light.castShadow) continue;
            
            switch (light.lightType) {
                case "DirectionalLight":
                    light.shadow.map.render(light, scene, camera, __queue, __shadowIdx);
                    _resetSurf = true;
                    break;
            }
        }
        
        // Restore previous GPU state
        if (_resetSurf) surface_reset_target();
        shader_reset(); 
        gpu_set_cullmode(_prevCull);
        gpu_set_ztestenable(_prevZTest);
        gpu_set_zwriteenable(_prevZWrite);
        gpu_set_blendenable(_prevBlend);
        camera_apply(camera.camera);
    }

    // Aggregate light data from scene lights
    function __buildLightState() {
        gml_pragma("forceinline");

        var lights = __lights;
        var ambientState = global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.AMBIENT];
        ambientState[0] = 0;
        ambientState[1] = 0;
        ambientState[2] = 0;
        
        var directionalState = global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.DIRECTIONAL];
        var pointLightState = global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.POINT_LIGHT];
        
        var dIdx = 0;
        var pIdx = 0;
        
        for (var i = 0; i < __lightIdx; i++) {
            var l = lights[i];
            if (!l.enabled) continue;
                
            switch (l.lightType) {
                case "AmbientLight":
                    // Accumulate ambient light contributions
                    ambientState[0] += l.color[0] * l.intensity;
                    ambientState[1] += l.color[1] * l.intensity;
                    ambientState[2] += l.color[2] * l.intensity;
                    break;

                case "DirectionalLight":
                    directionalState[dIdx++] = l;
                    break;
                    
                case "PointLight":
                    pointLightState[pIdx++] = l;
                    break;
            }
        }
        
        global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.DIRECTIONAL_COUNT] = dIdx;
        global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.POINT_LIGHT_COUNT] = pIdx;
        
        // Clamp ambient light to prevent over-exposure
        ambientState[0] = clamp(ambientState[0], 0, 1);
        ambientState[1] = clamp(ambientState[1], 0, 1);
        ambientState[2] = clamp(ambientState[2], 0, 1);
    }

    /**
     * Render the main scene
     */
    function __renderObjects(scene) {
        gml_pragma("forceinline");
        var overrideMaterial = scene[$ "overrideMaterial"];
        
        for (var i = 0; i < __queueIdx; i++) {
            var _object = __queue[i];
            var _onBeforeRender = _object[$ "onBeforeRender"];
            var _onAfterRender = _object[$ "onAfterRender"];
            var _material = _object[$ "material"];
            
            // Override material
            if (overrideMaterial != undefined && _material[$ "allowOverride"]) {
                _material = overrideMaterial;
            }

            // Wireframes material applies the default material
            var _wireframe = _material.wireframe;
            if (_wireframe) {
                _material = global.UE_DEFAULT_MATERIAL_WIREFRAME;
            }

            // Use the material
            if (_material.visible) {
                if (_material != __boundMaterial) {
                    __boundMaterial = _material;
                    _material.use();
                }

                _material.useByMesh(_object, _material.transparent && !_material.forceSinglePass);
            }

            if (_onBeforeRender != undefined) _onBeforeRender();
            _object.render(_wireframe);
            if (_onAfterRender != undefined) _onAfterRender(); 
        }
    }
    
    /// Render the scene
    function render(scene, camera) {
        gml_pragma("forceinline");
        
        // When rendering to a surface (render target), skip the view check since
        // there's no active view. Otherwise, ensure we're on the correct view.
        if (self.__renderTarget == undefined && view_current != camera.view) return;
        
        // Apply camera to set view/projection matrices (essential for rendering to surfaces)
        camera_apply(camera.camera);
        
        var _gpuState = gpu_get_state();
        
        // Auto clear
        if (self.autoClear) {
            self.clear(self.autoClearColor, self.autoClearDepth, self.autoClearStencil); 
        }
        
        // Collect and classify all renderable objects
        if (camera.matrixAutoUpdate) camera.updateMatrixWorld();
    
        __lightIdx = 0;
        __queueIdx = 0;
        __collectObjectQueues(scene.children, camera);
        __shadowIdx = __queueIdx;

        // **PASS 1: Render shadow maps for shadow-casting lights**
        if (shadowMap.enabled && (shadowMap.autoUpdate || shadowMap.needsUpdate)) {
            __renderShadowMaps(scene, camera);
            shadowMap.needsUpdate = false;
        }

        // Build the light state after shadow maps so matrices and textures are current
        __buildLightState();

        // Sort both queues before rendering
        if (sortObjects) __quickSortObjects(0, __queueIdx - 1);
    
        // **PASS 2: Render the main scene**
        __renderObjects(scene);
        
        // Reset the world after rendering
        __boundMaterial = undefined;
        shader_reset();  
        matrix_set(matrix_world, global.UE_MATRIX_IDENTITY);
        gpu_set_state(_gpuState);

        return self;
    }
}
