function UeParticleGravity(gx, gy, gz) : UeParticleModule() constructor {
    self.gx = gx;
    self.gy = gy;
    self.gz = gz;

    function onUpdate(p, i, dt) {
        gml_pragma("forceinline");
        p.velX[i] += self.gx * dt;
        p.velY[i] += self.gy * dt;
        p.velZ[i] += self.gz * dt;
    }
}
