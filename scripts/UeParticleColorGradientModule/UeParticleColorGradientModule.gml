/**
 * @description Applies a color and alpha gradient over the lifetime of a particle.
 */
function UeParticleColorGradientModule(data = {}) : UeParticleModule() constructor {
    var _toVec = function(c) {
        if (is_array(c)) return c;
        return [color_get_red(c)/255, color_get_green(c)/255, color_get_blue(c)/255];
    };

    self.colorStart  = _toVec(data[$ "colorStart"]  ?? [1, 1, 1]);
    self.colorMiddle = _toVec(data[$ "colorMiddle"] ?? self.colorStart);
    self.colorEnd    = _toVec(data[$ "colorEnd"]    ?? self.colorMiddle);
    
    self.alphaStart  = data[$ "alphaStart"]  ?? 1;
    self.alphaMiddle = data[$ "alphaMiddle"] ?? self.alphaStart;
    self.alphaEnd    = data[$ "alphaEnd"]    ?? self.alphaMiddle;

    onRegister = function(pool) {
        pool.registerAttribute("colorR", 1);
        pool.registerAttribute("colorG", 1);
        pool.registerAttribute("colorB", 1);
        pool.registerAttribute("alpha", 1);
        pool.registerAttribute("age", 0);
        pool.registerAttribute("life", 1);
    }

    onUpdate = function(p, i, dt) {
        gml_pragma("forceinline");
        var progress = p.age[i] / p.life[i];
        
        var w;
        if (progress < 0.5) {
            w = progress * 2;
            p.colorR[i] = lerp(self.colorStart[0], self.colorMiddle[0], w);
            p.colorG[i] = lerp(self.colorStart[1], self.colorMiddle[1], w);
            p.colorB[i] = lerp(self.colorStart[2], self.colorMiddle[2], w);
            p.alpha[i]  = lerp(self.alphaStart, self.alphaMiddle, w);
        } else {
            w = (progress - 0.5) * 2;
            p.colorR[i] = lerp(self.colorMiddle[0], self.colorEnd[0], w);
            p.colorG[i] = lerp(self.colorMiddle[1], self.colorEnd[1], w);
            p.colorB[i] = lerp(self.colorMiddle[2], self.colorEnd[2], w);
            p.alpha[i]  = lerp(self.alphaMiddle, self.alphaEnd, w);
        }
    }
}
