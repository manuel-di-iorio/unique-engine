---
sidebar_position: 6
---

# Animations

Unique Engine supports a hierarchical animation and skinning system based on the **Assimp** model. This allows for importing complex models with skeletons and keyframe animations.

## Performance and Optimization

The animation system is designed for maximum performance while maintaining a low memory footprint.

### Global Timestamp Mapping
To prepare the animation for optimized playback, you must call the `update()` method:

## Supported Animation Types

### 1. Node Animation (Transform Animation)
This type of animation acts directly on the `position`, `rotation`, and `scale` properties of any `UeObject3D`. It is ideal for kinematic objects (e.g., a door opening, an elevator).

### 2. Skeletal Animation (Skinning)
Skeletal animation allows for deforming a mesh through a hierarchy of bones (`UeBone`). Each vertex of the mesh is influenced by one or more bones via weights.

## Main Classes

- **`UeAnimation`**: Contains animation data (duration, tracks).
- **`UeAnimationTrack`**: Contains keyframes for a single node.
- **`UeSkeleton`**: Manages a set of bones and calculates deformation matrices.
- **`UeBone`**: A special node representing a bone in the skeleton.

## Example: Playing an Animation

To play an animation on an imported model:

```js
// --- Create Event ---
// Load a model with animations
model = assimpLoader.load("character.fbx");
modelRoot = model.root;

// Get the desired animation
anim = model.animations[$ "Animation0"];

// Initialize optimized mapping (crucial for performance)
anim.update();

currentTime = 0;

// --- Step Event ---
// Update the animation time using delta_time (converted to seconds)
currentTime += delta_time / 1000000;

// Evaluate the animation and apply transforms to the model hierarchy
anim.evaluate(currentTime, modelRoot);
```

## Data Structure

### UeAnimationTrack
A track consists of three keyframe arrays and their optimized index maps:
- `positionKeys`: `[ time, x, y, z, ... ]`
- `rotationKeys`: `[ time, x, y, z, w, ... ]`
- `scaleKeys`: `[ time, x, y, z, ... ]`

#### Optimized Baking
When `anim.update()` is called, the system generates:
- `_baked.posIdx`, `_baked.rotIdx`, `_baked.sclIdx`: Arrays of indices mapping global timestamps to the closest preceding keyframe in this track.

## Blending Animations

Unique Engine supports blending between multiple animations. This is useful for creating smooth transitions (e.g., from Walking to Running) or layering animations (e.g., an Aim animation on top of a Walk cycle).

### 1. Manual Layering
The `evaluate()` function takes an optional `weight` parameter (default is `1.0`). If the weight is less than 1.0, the animation will blend with the current transformation of the objects.

```js
// Step Event
// 1. Apply base animation (e.g., Walk)
animWalk.evaluate(walkTime, modelRoot, 1.0);

// 2. Layer another animation on top with 50% influence (e.g., Wave)
animWave.evaluate(waveTime, modelRoot, 0.5);
```

### 2. Static Blend Helper
For simple transitions between two animations, you can use the static `blend` method:

```js
// Step Event
// Blends between animA and animB based on 'weight' (0.0 to 1.0)
UeAnimation.blend(animA, timeA, animB, timeB, weight, modelRoot);
```
