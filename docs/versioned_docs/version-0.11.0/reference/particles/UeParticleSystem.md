# UeParticleSystem

`UeParticleSystem` manages a group of particles, their emitters, and behavior modules. It uses a **Data-Oriented (SoA)** architecture to maximize performance in GML.

As of version 0.7.0, `UeParticleSystem` inherits from `UeObject3D`, allowing it to be integrated into the scene graph and participate in the shadow mapping pipeline.

## Constructor

```gml
var pool = new UeParticlePool(maxCount);
var system = new UeParticleSystem(pool, [data]);
```

## Properties

| Property | Type | Description |
| --- | --- | --- |
| `timeScale` | Float | Multiplier for the system's update speed. |
| `sorted` | Bool | If `true`, particles are sorted by depth (back-to-front). Required for correct transparent blending. |
| `softFactor` | Float | Controls soft particle fading. `0.0` disables the effect. Recommended: `5.0`. |
| `castShadow` | Bool | Whether the particle system casts shadows. |
| `receiveShadow` | Bool | Whether particles receive shadows from directional lights. |

## Methods

### addEmitter
Adds an emitter to the system.
```gml
system.addEmitter(emitter);
```

### update
Updates all emitters and particles in the system.
```gml
system.update(dt, [camera]);
```
* `dt`: Delta time.
* `camera`: (Optional) The camera used for depth calculation if `sorted` is `true`.

### kill
Removes a specific particle (used internally).
```gml
system.kill(index);
```

### depthSort
Performs manual sorting of particles (used internally if `sorted` is `true`).

## SoA Architecture
The system does not store "Particle" objects. Instead, it stores properties in separate arrays within `UeParticlePool`. This reduces object overhead and improves cache locality.

```gml
// Example of accessing data in the pool
var px = system.pool.posX[i];
var py = system.pool.posY[i];
```
