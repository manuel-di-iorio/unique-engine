/**
 * @description Handles particle motion (velocity integration and initial spawn velocity).
 */
function UeParticleMotionModule(type = undefined) : UeParticleModule() constructor {
    self.type = type;
    
    onRegister = function(pool) {
        pool.registerAttribute("velX", 0);
        pool.registerAttribute("velY", 0);
        pool.registerAttribute("velZ", 0);
    }

    onSpawn = function(p, i) {
        if (self.type != undefined) {
             var spd = self.type[$ "speed"] ?? 0;
             var dir = self.type[$ "direction"] ?? 0;
             var pitch = self.type[$ "pitch"] ?? 0;
             
             var _s = is_array(spd)   ? random_range(spd[0], spd[1]) : spd;
             var _d = is_array(dir)   ? random_range(dir[0], dir[1]) : dir;
             var _p = is_array(pitch) ? random_range(pitch[0], pitch[1]) : pitch;
             
             var radDir = degtorad(_d);
             var radPitch = degtorad(_p);
             
             p.velX[i] = _s * cos(radPitch) * cos(radDir);
             p.velY[i] = _s * cos(radPitch) * sin(radDir);
             p.velZ[i] = _s * sin(radPitch);
        }
    }

    onUpdate = function(p, i, dt) {
        gml_pragma("forceinline");
        p.posX[i] += p.velX[i] * dt;
        p.posY[i] += p.velY[i] * dt;
        p.posZ[i] += p.velZ[i] * dt;
        return false;
    }
}
