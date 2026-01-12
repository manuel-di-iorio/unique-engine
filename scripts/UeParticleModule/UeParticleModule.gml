/**
 * @description Base class for particle behaviors.
 */
function UeParticleModule() constructor {
    /**
     * Called when a particle is spawned.
     * @param {Struct} pool The particle pool container.
     * @param {Real} index The index of the spawned particle.
     */
    function onSpawn(pool, index) {};

    /**
     * Called every frame for each alive particle.
     * @param {Struct} pool The particle pool container.
     * @param {Real} index The index of the particle to update.
     * @param {Real} dt Delta time.
     */
    function onUpdate(pool, index, dt) {};
}
