function UeParticleRotationModule(amount) : UeParticleModule() constructor {
    self.amount = amount;

    onRegister = function(pool) {
        pool.registerAttribute("rotation", 0);
    }

    onUpdate = function(p, i, dt) {
        gml_pragma("forceinline");
        p.rotation[i] += self.amount * dt;
    }
}
