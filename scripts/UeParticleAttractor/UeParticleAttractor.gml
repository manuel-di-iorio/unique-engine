function UeParticleAttractor(pos, strength) : UeParticleModule() constructor {
    self.pos = pos;
    self.strength = strength;

    function onUpdate(p, i, dt) {
        gml_pragma("forceinline");
        var dx = self.pos[0] - p.posX[i];
        var dy = self.pos[1] - p.posY[i];
        var dz = self.pos[2] - p.posZ[i];
        
        var distSq = dx*dx + dy*dy + dz*dz;
        var dist = sqrt(max(distSq, 0.0001));
        
        var f = (self.strength / distSq) * dt;
        p.velX[i] += (dx / dist) * f;
        p.velY[i] += (dy / dist) * f;
        p.velZ[i] += (dz / dist) * f;
    }
}
