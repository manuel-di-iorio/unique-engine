# UeParticleRenderer

`UeParticleRenderer` is an optimized renderer that uses vertex batching and dedicated shaders to draw thousands of particles with billboarding in a single draw call.

## Constructor

```gml
var renderer = new UeParticleRenderer();
```

## Methods

### render
Draws the specified particle system.
```gml
renderer.render(system, camera, [texture], [isShadowPass]);
```
* `system`: The particle system to render.
* `camera`: The camera for billboarding (needed to get Right and Up vectors).
* `texture`: (Optional) Texture to use. Default: `sprUiPointLight`.
* `isShadowPass`: (Optional) Whether this is a depth-only pass for shadow casting.

### dispose
Frees the resources (vertex buffer) used by the renderer.
```gml
renderer.dispose();
```

## Shaders

### sh_ue_particle
The main shader handles:
1.  **Billboarding**: Calculated on the GPU using camera vectors.
2.  **Soft Particles**: Fades particles when they intersect scene geometry using the depth buffer.
3.  **Shadow Receiving**: Samples the directional shadow map to apply shadows to particles.
4.  **Alpha Testing**: Discards transparent pixels for depth-buffer optimization.

### sh_ue_particle_shadow
A specialized depth-only shader used for shadow casting. It maintains billboarding and alpha testing to ensure shadows match the particle's shape.

## Integration Example

```gml
// In Draw Event
gpu_set_zwriteenable(false); // Disable z-write for transparent particles
gpu_set_blendmode(bm_add);    // Optional: additive blending

particleRenderer.render(particleSystem, mainCamera);

gpu_set_blendmode(bm_normal);
gpu_set_zwriteenable(true);
```
