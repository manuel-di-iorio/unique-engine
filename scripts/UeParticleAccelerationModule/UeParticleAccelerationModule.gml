/**
 * @description Increases the particle's speed along its current direction of travel.
 * This is a scalar acceleration.
 */
function UeParticleAccelerationModule(amount) : UeParticleModule() constructor {
    self.amount = amount;

    onUpdate = function(p, i, dt) {
        gml_pragma("forceinline");
        if (self.amount == 0) return;
        
        var vx = p.velX[i], vy = p.velY[i], vz = p.velZ[i];
        var spd = sqrt(vx*vx + vy*vy + vz*vz);
        if (spd > 0) {
            var newSpd = spd + self.amount * dt;
            var f = (newSpd / spd);
            p.velX[i] *= f;
            p.velY[i] *= f;
            p.velZ[i] *= f;
        }
    }
}
