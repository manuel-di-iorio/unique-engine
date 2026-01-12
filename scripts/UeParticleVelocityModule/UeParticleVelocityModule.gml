/**
 * @description Forces a specific velocity or adds a spread to the initial velocity at spawn.
 * Note: Initial spawn velocity is usually handled by UeParticleEmitter settings.
 */
function UeParticleVelocityModule(dir, pitch, speed) : UeParticleModule() constructor {
    self.dir = dir;
    self.pitch = pitch;
    self.speed = speed;

    onRegister = function(pool) {
        pool.registerAttribute("velX", 0);
        pool.registerAttribute("velY", 0);
        pool.registerAttribute("velZ", 0);
    }

    function onSpawn(p, i) {
        gml_pragma("forceinline");
        var radDir = degtorad(self.dir);
        var radPitch = degtorad(self.pitch);
        
        p.velX[i] = self.speed * cos(radPitch) * cos(radDir);
        p.velY[i] = self.speed * cos(radPitch) * sin(radDir);
        p.velZ[i] = self.speed * sin(radPitch);
    }
}
