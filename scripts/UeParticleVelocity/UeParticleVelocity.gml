function UeParticleVelocity(dir, spread) : UeParticleModule() constructor {
    onSpawn = function(p) {
        p.velocity = random_cone(dir, spread);
    };
}
