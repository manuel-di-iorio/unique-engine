/**
 * @description Internal module that applies UeParticleType's over-lifetime properties.
 */
function UeParticleTypeUpdate(type) : UeParticleModule() constructor {
    self.type = type;

    function onUpdate(p, i, dt) {
        var t = self.type;
        var progress = p.age[i] / p.life[i];
        
        // --- Appearance Over Lifetime ---
        
        // Increments
        p.size[i] += t.sizeIncr * dt;
        p.rotation[i] += t.rotationIncr * dt;
        
        // Alpha Mix
        if (t.useAlphaMix) {
            if (progress < 0.5) {
                p.alpha[i] = lerp(t.alphaStart, t.alphaMiddle, progress * 2);
            } else {
                p.alpha[i] = lerp(t.alphaMiddle, t.alphaEnd, (progress - 0.5) * 2);
            }
        } else {
            p.alpha[i] += t.alphaIncr * dt;
        }

        // Color Mix
        if (t.useColorMix) {
            var c1, c2, w;
            if (progress < 0.5) {
                c1 = t.colorStart;
                c2 = t.colorMiddle;
                w = progress * 2;
            } else {
                c1 = t.colorMiddle;
                c2 = t.colorEnd;
                w = (progress - 0.5) * 2;
            }
            p.colorR[i] = lerp(c1[0], c2[0], w);
            p.colorG[i] = lerp(c1[1], c2[1], w);
            p.colorB[i] = lerp(c1[2], c2[2], w);
        }

        // --- Movement Over Lifetime ---
        
        // Gravity
        if (t.gravity != 0) {
            var gDir = degtorad(t.gravityDir);
            p.velX[i] += cos(gDir) * t.gravity * dt;
            p.velY[i] += -sin(gDir) * t.gravity * dt; // In GM Y is usually down, but in 3D we might need to adjust
        }
        
        // Friction
        if (t.friction != 0) {
            var spd = sqrt(p.velX[i]*p.velX[i] + p.velY[i]*p.velY[i] + p.velZ[i]*p.velZ[i]);
            if (spd > 0) {
                var newSpd = max(0, spd - t.friction * dt);
                var f = newSpd / spd;
                p.velX[i] *= f;
                p.velY[i] *= f;
                p.velZ[i] *= f;
            }
        }
        
        // Speed Increment
        if (t.speedIncr != 0) {
             var spd = sqrt(p.velX[i]*p.velX[i] + p.velY[i]*p.velY[i] + p.velZ[i]*p.velZ[i]);
             if (spd > 0) {
                 var f = (spd + t.speedIncr * dt) / spd;
                 p.velX[i] *= f;
                 p.velY[i] *= f;
                 p.velZ[i] *= f;
             }
        }
    }
}
