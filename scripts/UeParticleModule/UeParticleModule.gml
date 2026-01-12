/**
 * @description Base class for particle behaviors.
 */
function UeParticleModule() constructor {
    /**
     * Called when the module is added to a system.
     * Use this to register required attributes in the pool.
     * @param {Struct} pool The particle pool.
     */
    onRegister = function(pool) {};

    /**
     * Called when a particle is spawned.
     * @param {Struct} pool The particle pool container.
     * @param {Real} index The index of the new particle.
     */
    onSpawn = function(pool, index) {};

    /**
     * Called every frame for each alive particle.
     * @param {Struct} pool The particle pool container.
     * @param {Real} index The index of the particle to update.
     * @param {Real} dt Delta time.
     * @returns {Bool} True if the particle was killed and should stop processing other modules.
     */
    onUpdate = function(pool, index, dt) { return false; };
}
