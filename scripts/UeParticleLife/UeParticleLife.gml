function UeParticleLife(min, max) : UeParticleModule() constructor {
    self.minLife = min;
    self.maxLife = max;

    function onSpawn(pool, index) {
        gml_pragma("forceinline");
        pool.life[index] = random_range(self.minLife, self.maxLife);
        pool.age[index] = 0;
    }
}
