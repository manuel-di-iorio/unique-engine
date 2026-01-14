/**
 * @description A configuration container that defines look, behavior, and physics of particles.
 * Use method chaining to configure properties.
 */
function UeParticleType() constructor {
    gml_pragma("forceinline");
    
    // --- Lifecycle ---
    self.lifeMin = 1.0;
    self.lifeMax = 1.0;
    self.avgLife = 1.0;
    
    // --- Scale ---
    self.sizeMin = 1.0;
    self.sizeMax = 1.0;
    self.sizeIncr = 0.0;
    self.sizeWiggle = 0.0;
    
    // --- 3D Movement ---
    self.speedMin = 0.0;
    self.speedMax = 0.0;
    self.speedIncr = 0.0;
    self.speedWiggle = 0.0;
    
    self.dirMin = 0.0;
    self.dirMax = 2 * pi;
    self.dirIncr = 0.0;
    self.dirWiggle = 0.0;
    
    // --- Physics ---
    self.gravAmount = 0.0;
    self.gravDir = 1.5 * pi; 
    
    self.zSpeedMin = 0.0;
    self.zSpeedMax = 0.0;
    self.zSpeedIncr = 0.0;
    self.zSpeedWiggle = 0.0;
    self.zGravAmount = 0.0;
    
    // --- Rotation ---
    self.rotMin = 0.0;
    self.rotMax = 0.0;
    self.rotIncr = 0.0;
    self.rotWiggle = 0.0;
    
    // --- Visuals ---
    self.colorStart = [1.0, 1.0, 1.0];
    self.colorMid   = [1.0, 1.0, 1.0];
    self.colorEnd   = [1.0, 1.0, 1.0];
    self.colorMidTime = 0.5; // 0 to 1
    
    self.alphaStart = 1.0;
    self.alphaEnd   = 1.0;
    
    self.glow = 1.0;
    
    // --- Animation (Flipbook) ---
    self.animFramesX = 1;
    self.animFramesY = 1;
    self.animSpeed = 1.0; // 1.0 = once over lifetime
    
    self.sprite = -1;
    self.texture = -1;
    self.uvs = [0, 0, 1, 1]; 
    self.additive = false;
    self.scaleX = 1.0;
    self.scaleY = 1.0;
    self.drag = 0.0;

    // --- Internal Flags & Optimized Values ---
    self.gravX = 0.0;
    self.gravY = 0.0;

    /**
     * @description Sets the minimum and maximum lifetime of particles in seconds.
     * @param {real} minVal Minimum lifetime.
     * @param {real} maxVal Maximum lifetime.
     * @returns {UeParticleType}
     */
    static setLife = function(minVal, maxVal) {
        gml_pragma("forceinline");
        self.lifeMin = minVal;
        self.lifeMax = maxVal;
        self.avgLife = (minVal + maxVal) * 0.5;
        return self;
    }
    
    /**
     * @description Sets the size range and transformation over life.
     * @param {real} minVal Initial minimum size.
     * @param {real} maxVal Initial maximum size.
     * @param {real} incr Value added to size every second.
     * @param {real} wiggle Random size fluctuation per frame (CPU-side only).
     * @returns {UeParticleType}
     */
    static setSize = function(minVal, maxVal, incr = 0, wiggle = 0) {
        gml_pragma("forceinline");
        self.sizeMin = minVal;
        self.sizeMax = maxVal;
        self.sizeIncr = incr;
        self.sizeWiggle = wiggle;
        return self;
    }
    
    /**
     * @description Sets the initial 3D velocity and its behavior over time.
     * @param {real} zMin Minimum vertical speed (Z).
     * @param {real} zMax Maximum vertical speed (Z).
     * @param {real} xyMin Minimum horizontal speed (XY).
     * @param {real} xyMax Maximum horizontal speed (XY).
     * @param {real} zIncr Vertical acceleration per second.
     * @param {real} xyIncr Horizontal acceleration per second.
     * @returns {UeParticleType}
     */
    static setSpeed = function(zMin, zMax, xyMin = 0, xyMax = 0, zIncr = 0, xyIncr = 0, zWiggle = 0, xyWiggle = 0) {
        gml_pragma("forceinline");
        self.zSpeedMin = zMin;
        self.zSpeedMax = zMax;
        self.zSpeedIncr = zIncr;
        self.zSpeedWiggle = zWiggle;
        
        self.speedMin = xyMin;
        self.speedMax = xyMax;
        self.speedIncr = xyIncr;
        self.speedWiggle = xyWiggle;
        return self;
    }
    
    /**
     * @description Sets the horizontal direction range and behavior.
     * @param {real} minVal Minimum direction in degrees.
     * @param {real} maxVal Maximum direction in degrees.
     * @param {real} incr Rotation of movement vector in degrees per second.
     * @returns {UeParticleType}
     */
    static setDirection = function(minVal, maxVal, incr = 0, wiggle = 0) {
        gml_pragma("forceinline");
        self.dirMin = degtorad(minVal);
        self.dirMax = degtorad(maxVal);
        self.dirIncr = degtorad(incr);
        self.dirWiggle = degtorad(wiggle);
        return self;
    }
    
    /**
     * @description Applies constant gravity force.
     * @param {real} amountZ Vertical gravity amount.
     * @param {real} amountXY Horizontal gravity amount.
     * @param {real} dirXY Horizontal gravity direction in degrees.
     * @returns {UeParticleType}
     */
    static setGravity = function(amountZ, amountXY = 0, dirXY = 270) {
        gml_pragma("forceinline");
        self.zGravAmount = amountZ;
        self.gravAmount = amountXY;
        self.gravDir = degtorad(dirXY);
        self.gravX = cos(self.gravDir) * self.gravAmount;
        self.gravY = -sin(self.gravDir) * self.gravAmount;
        return self;
    }
    
    /**
     * @description Sets the rotation range and behavior.
     * @param {real} minVal Initial minimum rotation in degrees.
     * @param {real} maxVal Initial maximum rotation in degrees.
     * @param {real} incr Rotation speed in degrees per second.
     * @returns {UeParticleType}
     */
    static setRotation = function(minVal, maxVal, incr = 0, wiggle = 0) {
        gml_pragma("forceinline");
        self.rotMin = degtorad(minVal);
        self.rotMax = degtorad(maxVal);
        self.rotIncr = degtorad(incr);
        self.rotWiggle = degtorad(wiggle);
        return self;
    }
    
    /**
     * @description Sets start, middle, and end colors for GPU interpolation.
     * @param {constant.color} color1 Starting color.
     * @param {constant.color} color2 Ending color (optional).
     * @param {constant.color} color3 Middle color (optional).
     * @param {real} midTime Point in life (0-1) where color3 is reached.
     * @returns {UeParticleType}
     */
    static setColor = function(color1, color2 = undefined, color3 = undefined, midTime = 0.5) {
        gml_pragma("forceinline");
        self.colorStart = [color_get_red(color1)/255, color_get_green(color1)/255, color_get_blue(color1)/255];
        
        if (color2 != undefined && color3 == undefined) {
            // Simple 2-way
            self.colorEnd = [color_get_red(color2)/255, color_get_green(color2)/255, color_get_blue(color2)/255];
            self.colorMid = self.colorStart;
            self.colorMidTime = 0.0;
        } else if (color2 != undefined && color3 != undefined) {
            // 3-way: color1 -> color3 -> color2
            self.colorEnd = [color_get_red(color2)/255, color_get_green(color2)/255, color_get_blue(color2)/255];
            self.colorMid = [color_get_red(color3)/255, color_get_green(color3)/255, color_get_blue(color3)/255];
            self.colorMidTime = midTime;
        } else {
            self.colorEnd = self.colorStart;
            self.colorMid = self.colorStart;
            self.colorMidTime = 0.0;
        }
        return self;
    }
    
    /**
     * @description Sets the emissive glow intensity (multiplies color values).
     * @param {real} val Glow intensity (1.0 = normal).
     * @returns {UeParticleType}
     */
    static setGlow = function(val) {
        gml_pragma("forceinline");
        self.glow = val;
        return self;
    }

    /**
     * @description Configures sprite sheet animation (Flipbook).
     * @param {real} xFrames Number of columns in the sprite sheet.
     * @param {real} yFrames Number of rows in the sprite sheet.
     * @param {real} speed How many times to cycle the animation over the particle's life.
     * @returns {UeParticleType}
     */
    static setAnimation = function(xFrames, yFrames, speed = 1.0) {
        gml_pragma("forceinline");
        self.animFramesX = xFrames;
        self.animFramesY = yFrames;
        self.animSpeed = speed;
        return self;
    }
    
    /**
     * @description Sets start and end transparency for GPU interpolation.
     * @param {real} alpha1 Starting alpha (0-1).
     * @param {real} alpha2 Ending alpha (optional, defaults to alpha1).
     * @returns {UeParticleType}
     */
    static setAlpha = function(alpha1, alpha2 = undefined) {
        gml_pragma("forceinline");
        self.alphaStart = alpha1;
        self.alphaEnd = (alpha2 != undefined) ? alpha2 : alpha1;
        return self;
    }
    
    /**
     * @description toggles additive blending for this particle type.
     * @param {bool} enable True for bm_add, false for bm_normal.
     * @returns {UeParticleType}
     */
    static setAdditive = function(enable) {
        gml_pragma("forceinline");
        self.additive = enable;
        return self;
    }

    /**
     * @description Sets non-uniform scaling for the particle quad (aspect ratio).
     * @param {real} sx Width multiplier.
     * @param {real} sy Height multiplier.
     * @returns {UeParticleType}
     */
    static setScale = function(sx, sy) {
        gml_pragma("forceinline");
        self.scaleX = sx;
        self.scaleY = sy;
        return self;
    }

    /**
     * @description Sets the air resistance (0 to 1). 0 = no drag, higher values slow down particles.
     * @param {real} val Drag amount.
     * @returns {UeParticleType}
     */
    static setDrag = function(val) {
        gml_pragma("forceinline");
        self.drag = val;
        return self;
    }
    
    /**
     * @description Sets a GameMaker sprite as the texture source.
     * @param {resource.sprite} sprite Sprite index.
     * @param {real} subimg Sub-image index.
     * @returns {UeParticleType}
     */
    static setSprite = function(sprite, subimg = 0) {
        gml_pragma("forceinline");
        self.sprite = sprite;
        if (sprite_exists(sprite)) {
            self.texture = sprite_get_texture(sprite, subimg);
            var _uvs = sprite_get_uvs(sprite, subimg);
            self.uvs = [_uvs[0], _uvs[1], _uvs[2] - _uvs[0], _uvs[3] - _uvs[1]];
        }
        return self;
    }

    /**
     * @description Sets the particle texture to a built-in procedural shape.
     * @param {string} shapeName "point", "sphere", "flare", "square", "box", "disk", "ring".
     * @returns {UeParticleType}
     */
    static setShape = function(shapeName) {
        gml_pragma("forceinline");
        var _shape = global.UE_PARTICLE_RENDERER.shapes[$ shapeName];
        if (_shape != undefined) {
            self.texture = _shape.texture;
            self.uvs = _shape.uvs;
        }
        return self;
    }
    
    // Default initial shape
    self.setShape("sphere");
}
