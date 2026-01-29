---
sidebar_position: 15
---

# UeRendererDeferred

`UeRendererDeferred` is an alternative renderer that implements a **Deferred Shading** pipeline. Unlike the standard `UeRenderer` (which uses Forward Shading), it separates the geometry processing from the lighting calculations.

> ⚠️ **EXPERIMENTAL**: This renderer is currently in beta. Features like light volumes and advanced transparent sorting are still being refined.

## Advantages of Deferred Rendering

- **Large Number of Lights**: You can have dozens or even hundreds of dynamic lights with minimal performance impact compared to Forward Shading.
- **Simplified Shaders**: Geometry shaders don't need to handle lighting complexity, and lighting shaders don't need to handle complex geometry.
- **Screen-Space Effects**: Easier integration of effects like [SSAO](/docs/reference/post-processing/UeSSAOPass), SSR, or screen-space reflections since depth and normals are already available in the G-Buffer.

## Constructor

```js
new UeRendererDeferred(data = {})
```

### Parameters
Inherits all parameters from [UeRenderer](/docs/reference/core/UeRenderer).

## Methods

| Method | Returns | Description |
| :--- | :--- | :--- |
| `setSize(width, height)` | `void` | Resizes the renderer and its internal G-Buffer surfaces. |
| `render(scene, camera)` | `self` | Performs the two-pass deferred rendering process. |

## 🧠 Technical Notes

- **G-Buffer**: This renderer uses multiple render targets (MRTs) to store:
    - **Buffer 0**: Albedo (RGB) and Alpha (A).
    - **Buffer 1**: Normals (RGB, 16-bit float) and Metalness (A).
    - **Buffer 2**: Roughness (R), AO (G).
    - **Buffer 3**: Emissive (RGB).
- **Forward Pass**: Transparent objects are still rendered using a Forward pass after the lighting pass is completed, using the depth buffer from the G-Buffer pass for correct occlusion.
- **Hardware Support**: Requires GPU support for Multiple Render Targets (MRT), which is standard on most modern desktop and mobile hardware.
- **Lighting Shader**: Lighting is currently calculated in a single full-screen pass using `sh_ue_deferred_lighting`.
