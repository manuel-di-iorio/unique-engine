function UeParticleCollision(planeY, bounce = 0.5) : UeParticleModule() constructor {
    self.planeY = planeY;
    self.bounce = bounce;

    function onUpdate(p, i, dt) {
        gml_pragma("forceinline");
        if (p.posY[i] < self.planeY) {
            p.posY[i] = self.planeY;
            p.velY[i] = -p.velY[i] * self.bounce;
        }
    }
}
