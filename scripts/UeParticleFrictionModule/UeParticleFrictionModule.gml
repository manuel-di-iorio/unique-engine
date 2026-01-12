function UeParticleFrictionModule(amount) : UeParticleModule() constructor {
    self.amount = amount;

    onRegister = function(pool) {
        pool.registerAttribute("velX", 0);
        pool.registerAttribute("velY", 0);
        pool.registerAttribute("velZ", 0);
    }

    onUpdate = function(p, i, dt) {
        gml_pragma("forceinline");
        if (self.amount == 0) return;
        
        var vx = p.velX[i], vy = p.velY[i], vz = p.velZ[i];
        var spd = sqrt(vx*vx + vy*vy + vz*vz);
        if (spd > 0) {
            var newSpd = max(0, spd - self.amount * dt);
            var f = (newSpd / spd);
            p.velX[i] *= f;
            p.velY[i] *= f;
            p.velZ[i] *= f;
        }
    }
}
