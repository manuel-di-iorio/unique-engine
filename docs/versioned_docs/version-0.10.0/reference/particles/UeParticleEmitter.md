# UeParticleEmitter

`UeParticleEmitter` is responsible for spawning particles based on a `UeParticleType` and an emission shape.

## Constructor

```gml
var emitter = new UeParticleEmitter(type, [data]);
```
* `data`: (Optional) Struct with initial parameters.

### Data Parameters
- `rate`: Particles per second.
- `burst`: Number of particles to spawn immediately (resets to 0 after spawning).
- `position`: `[x, y, z]`.
- `shape`: `"point"`, `"box"`, `"sphere"`.
- `shapeSize`: `[radius]` for sphere, `[w, h, d]` for box.
- `castShadow`: (Optional) Overrides or sets the default shadow casting for spawned particles.
- `receiveShadow`: (Optional) Overrides or sets the default shadow receiving for spawned particles.

## Methods

### update
Updates the emission accumulator and spawns necessary particles.
```gml
emitter.update(dt);
```

### spawn
Forces the spawn of a single particle.

## Example

```gml
var fireType = new UeParticleType()
    .setSprite(sprFire)
    .setLife(30, 60)
    .setSpeed(1, 2)
    .setSize(0.5, 1.2);

var emitter = new UeParticleEmitter(fireType, {
    rate: 20,
    shape: "box",
    shapeSize: [10, 2, 10],
    position: [0, 0, 0],
    castShadow: true
});

system.addEmitter(emitter);
```
