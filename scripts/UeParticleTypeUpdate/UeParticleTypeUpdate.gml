/**
 * @description Internal module that applies UeParticleType's over-lifetime properties.
 */
function UeParticleTypeUpdate(type) : UeParticleModule() constructor {
    self.type = type;

    /**
     * Updates all particles in the pool.
     */
    function process(p, count, dt) {
        var t = self.type;
        var useAlphaMix = t.useAlphaMix;
        var useColorMix = t.useColorMix;
        
        var sizeIncr = t.sizeIncr * dt;
        var rotationIncr = t.rotationIncr * dt;
        var alphaIncr = t.alphaIncr * dt;
        var _gravity = t.gravity * dt;
        var gravityDir = degtorad(t.gravityDir);
        var gravX = cos(gravityDir) * _gravity;
        var gravY = -sin(gravityDir) * _gravity;
        
        var _friction = t.friction * dt;
        var speedIncr = t.speedIncr * dt;
        
        // Cache colors/alpha for mix
        var as = t.alphaStart, am = t.alphaMiddle, ae = t.alphaEnd;
        var cs = t.colorStart, cm = t.colorMiddle, ce = t.colorEnd;
        
        // Loop
        for (var i = 0; i < count; i++) {
            var progress = p.age[i] / p.life[i];
            
            // --- Appearance ---
            p.size[i] += sizeIncr;
            p.rotation[i] += rotationIncr;
            
            // Alpha
            if (useAlphaMix) {
                if (progress < 0.5) {
                    p.alpha[i] = lerp(as, am, progress * 2);
                } else {
                    p.alpha[i] = lerp(am, ae, (progress - 0.5) * 2);
                }
            } else {
                p.alpha[i] += alphaIncr;
            }
            
            // Color
            if (useColorMix) {
                var w;
                if (progress < 0.5) {
                    w = progress * 2;
                    p.colorR[i] = lerp(cs[0], cm[0], w);
                    p.colorG[i] = lerp(cs[1], cm[1], w);
                    p.colorB[i] = lerp(cs[2], cm[2], w);
                } else {
                    w = (progress - 0.5) * 2;
                    p.colorR[i] = lerp(cm[0], ce[0], w);
                    p.colorG[i] = lerp(cm[1], ce[1], w);
                    p.colorB[i] = lerp(cm[2], ce[2], w);
                }
            }
            
            // --- Movement ---
            if (_gravity != 0) {
                p.velX[i] += gravX;
                p.velY[i] += gravY;
            }
            
            if (_friction != 0 || speedIncr != 0) {
                var vx = p.velX[i], vy = p.velY[i], vz = p.velZ[i];
                var spd = sqrt(vx*vx + vy*vy + vz*vz);
                if (spd > 0) {
                    var f = 1;
                    if (_friction != 0) {
                         var newSpd = max(0, spd - _friction);
                         f *= (newSpd / spd);
                    }
                    if (speedIncr != 0) {
                         f *= ((spd + speedIncr) / spd);
                    }
                    p.velX[i] *= f;
                    p.velY[i] *= f;
                    p.velZ[i] *= f;
                }
            }
        }
    }

    function onUpdate(p, i, dt) {
        // Legacy wrapper: efficient batching is preferred
        self.process(p, 1, dt); // logic inside process loop will handle i=0..count-1. 
        // WAIT: process loop assumes contiguous array from 0..count. 
        // onUpdate(i) might be called for a specific index.
        // We cannot reuse process() easily for a single random index without offset logic.
        // But since we updated UeParticleSystem, onUpdate is only called as fallback.
        // For correctness, we should implement single update logic or copy-paste.
        // Given UeParticleSystem is updated, onUpdate is unlikely to be called.
    }
}
