---
sidebar_position: 6
---

# Animations

:::warning
Animations module is under costruction and do not works yet.
:::

Unique Engine supports a hierarchical animation and skinning system based on the **Assimp** model. This allows for importing complex models with skeletons and keyframe animations.

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

To play an animation on an imported model in GameMaker:

```gml
// --- Create Event ---
// Load a model with animations
model = loader.load("character.fbx");

// Get the desired animation
anim = model.animations[0];
currentTime = 0;

// --- Step Event ---
// Update the animation time using delta_time (converted to seconds)
var deltaTime = delta_time / 1000000;
currentTime += deltaTime;

// Evaluate the animation and apply transforms to the model hierarchy
anim.evaluate(currentTime, model);
```

## Data Structure

### UeAnimationTrack
A track consists of three keyframe arrays:
- `positionKeys`: `[ time, value: Vector3 ]`
- `rotationKeys`: `[ time, value: Quaternion ]`
- `scaleKeys`: `[ time, value: Vector3 ]`

Interpolation occurs automatically between the nearest keyframes during the `evaluate()` call.

## Skinning and Matrices
When a `UeMesh` has an associated `UeSkeleton`, the bone matrices are sent to the shader. The final calculation for each bone is:
`FinalMatrix = BoneWorldMatrix * BoneOffsetMatrix`

Where `BoneOffsetMatrix` (Inverse Bind Pose) transforms vertices from mesh space to the bone's local space at the moment the mesh was bound to the skeleton.
