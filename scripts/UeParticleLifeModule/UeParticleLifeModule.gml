/**
 * @description Handles particle life cycle (age update and killing).
 */
function UeParticleLifeModule(type = undefined) : UeParticleModule() constructor {
    self.type = type;
    
    onRegister = function(pool) {
        pool.registerAttribute("age", 0);
        pool.registerAttribute("life", 1);
    }

    onSpawn = function(p, i) {
        if (self.type != undefined) {
            var l = self.type[$ "life"];
            if (is_array(l)) {
                p.life[i] = random_range(l[0], l[1]);
            } else {
                p.life[i] = l ?? 1;
            }
        }
        p.age[i] = 0;
    }

    onUpdate = function(p, i, dt) {
        gml_pragma("forceinline");
        p.age[i] += dt;
        if (p.age[i] >= p.life[i]) {
            p.aliveCount--;
            if (i < p.aliveCount) {
                p.swap(i, p.aliveCount);
            }
            return true; 
        }
        return false;
    }
}
