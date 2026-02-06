# UeSSAOPass

`UeSSAOPass` implements **Screen Space Ambient Occlusion**, a technique used to approximate local ambient occlusion in real-time. It adds depth and realism to the scene by darkening crevices, corners, and areas where objects are close to each other.

This pass is designed to work efficiently in both **Forward** and **Deferred** rendering paths.

:::warning
This feature is experimental and does not works yet.
:::

## Constructor

```gml
new UeSSAOPass(data?)
```

- **data** (optional): A struct containing configuration properties.
    - `radius`: float (default: `0.5`) - The radius of the occlusion sampling.
    - `bias`: float (default: `0.025`) - The bias to prevent self-occlusion artifacts.
    - `power`: float (default: `1.0`) - The exponent applied to the occlusion factor.
    - `intensity`: float (default: `1.0`) - The overall strength of the effect.

## Properties

- **radius**: float - The sampling radius in view-space units. Larger values create broader shadows but may lose detail.
- **bias**: float - A small offset to avoid "acne" or self-occlusion on flat surfaces.
- **power**: float - Controls the falloff of the occlusion. Higher values make the shadows darker and more concentrated.
- **intensity**: float - Blending factor for the final composition. `0.0` means no AO, `1.0` means full AO.

## How it works

The SSAO pass performs several internal steps to generate the effect:

1.  **Normal Pre-pass**: If not already available (like in Forward Rendering), the pass renders the opaque objects of the scene to a separate buffer to extract **View-Space Normals**.
2.  **Occlusion Generation**: Using the **Depth Buffer** and the **Normal Map**, the shader reconstructs the view-space position of each pixel and samples a random kernel of 32 points within a hemisphere oriented along the surface normal.
3.  **Bilateral Blur**: The raw occlusion output is noisy due to the random sampling. A bilateral blur is applied to smooth the result while preserving sharp edges by comparing depth differences.
4.  **Composition**: The final smoothed occlusion map is multiplied with the original scene color.

### 🛠️ Integration with Forward Rendering

In Forward Rendering, `UeSSAOPass` automatically leverages `surface_get_texture_depth()` to avoid an extra depth pass. It only performs one additional geometry pass for normals, making it highly efficient.

---

## Example

```js
var composer = new UeEffectComposer(renderer);

// Standard render pass
composer.addPass(new UeRenderPass(scene, camera));

// Add SSAO
var ssao = new UeSSAOPass({
    radius: 0.8,
    intensity: 1.5,
    power: 2.0
});
composer.addPass(ssao);
```
