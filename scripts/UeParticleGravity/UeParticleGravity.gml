function UeParticleGravity(gx, gy, gz) : UeParticleModule() constructor {
    self.gx = gx;
    self.gy = gy;
    self.gz = gz;

    onRegister = function(pool) {
        pool.registerAttribute("velX", 0);
        pool.registerAttribute("velY", 0);
        pool.registerAttribute("velZ", 0);
    }

    onUpdate = function(p, i, dt) {
        gml_pragma("forceinline");
        p.velX[i] += self.gx * dt;
        p.velY[i] += self.gy * dt;
        p.velZ[i] += self.gz * dt;
    }
}
