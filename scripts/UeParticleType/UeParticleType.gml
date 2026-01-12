/**
 * @description Defines the properties and behavior of a particle.
 */
function UeParticleType() constructor {
    // --- Appearance ---
    self.sprite = undefined;
    self.frame = 0;
    self.color = [1, 1, 1]; // RGB [0-1]
    self.alpha = 1;
    self.size = [1, 1]; // [min, max] or just [size]
    self.scale = [1, 1]; // XY scale
    
    // --- Life ---
    self.life = [60, 60]; // [min, max] frames/ticks
    
    // --- Movement ---
    self.speed = [0, 0];
    self.direction = [0, 360];
    self.gravity = 0;
    self.gravityDir = 270;
    self.friction = 0;
    
    // --- Variation & Over Lifetime ---
    self.sizeIncr = 0;
    self.alphaIncr = 0;
    self.speedIncr = 0;
    
    self.colorStart = [1, 1, 1];
    self.colorMiddle = [1, 1, 1];
    self.colorEnd = [1, 1, 1];
    self.useColorMix = false;

    self.alphaStart = 1;
    self.alphaMiddle = 1;
    self.alphaEnd = 1;
    self.useAlphaMix = false;

    self.rotation = [0, 360];
    self.rotationIncr = 0;

    // --- Methods (Fluent API) ---
    
    self.setSprite = function(_sprite, _frame = 0) {
        self.sprite = _sprite;
        self.frame = _frame;
        return self;
    };

    self.setLife = function(_min, _max) {
        self.life = [_min, _max];
        return self;
    };

    self.setSpeed = function(_min, _max, _incr = 0) {
        self.speed = [_min, _max];
        self.speedIncr = _incr;
        return self;
    };

    self.setDirection = function(_min, _max) {
        self.direction = [_min, _max];
        return self;
    };

    self.setSize = function(_min, _max, _incr = 0) {
        self.size = [_min, _max];
        self.sizeIncr = _incr;
        return self;
    };

    self.setAlpha = function(_start, _middle = undefined, _end = undefined) {
        if (_middle == undefined) {
            self.alphaStart = _start;
            self.alphaMiddle = _start;
            self.alphaEnd = _start;
            self.useAlphaMix = false;
        } else {
            self.alphaStart = _start;
            self.alphaMiddle = _middle;
            self.alphaEnd = _end ?? _middle;
            self.useAlphaMix = true;
        }
        return self;
    };

    self.setColor = function(_start, _middle = undefined, _end = undefined) {
        var _toVec = function(c) {
            if (is_array(c)) return c;
            return [color_get_red(c)/255, color_get_green(c)/255, color_get_blue(c)/255];
        };

        if (_middle == undefined) {
            self.colorStart = _toVec(_start);
            self.colorMiddle = self.colorStart;
            self.colorEnd = self.colorStart;
            self.useColorMix = false;
        } else {
            self.colorStart = _toVec(_start);
            self.colorMiddle = _toVec(_middle);
            self.colorEnd = _toVec(_end ?? _middle);
            self.useColorMix = true;
        }
        return self;
    };

    self.setGravity = function(_amount, _dir = 270) {
        self.gravity = _amount;
        self.gravityDir = _dir;
        return self;
    };

    self.setRotation = function(_min, _max, _incr = 0) {
        self.rotation = [_min, _max];
        self.rotationIncr = _incr;
        return self;
    };
}
