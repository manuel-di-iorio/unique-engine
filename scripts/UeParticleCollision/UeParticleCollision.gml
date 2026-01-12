function UeParticleCollision(planeZ, bounce = 0.5) : UeParticleModule() constructor {
    self.planeZ = planeZ;
    self.bounce = bounce;

    onUpdate = function(p, i, dt) {
        gml_pragma("forceinline");
        if (p.posZ[i] < self.planeZ) {
            p.posZ[i] = self.planeZ;
            p.velZ[i] = -p.velZ[i] * self.bounce;
        }
    }
}
