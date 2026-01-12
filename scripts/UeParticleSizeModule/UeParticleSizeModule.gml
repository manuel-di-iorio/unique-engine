function UeParticleSizeModule(amount) : UeParticleModule() constructor {
    self.amount = amount;

    onRegister = function(pool) {
        pool.registerAttribute("size", 1);
    }

    onUpdate = function(p, i, dt) {
        gml_pragma("forceinline");
        p.size[i] += self.amount * dt;
    }
}
