# UeRenderPass

`UeRenderPass` is usually the first pass in an `UeEffectComposer` chain. It renders the 3D scene into the first render target (or screen), providing the base image for subsequent post-processing effects.

## Constructor

```js
new UeRenderPass(scene, camera, overrideMaterial?, clearColor?, clearAlpha?)
```

- **scene**: `UeScene` - The scene to render.
- **camera**: `UeCamera` - The camera to use.
- **overrideMaterial** (optional): `UeMaterial` - If provided, renders all objects with this material (e.g., for depth passes).
- **clearColor** (optional): Color (c_white). Background clear color.
- **clearAlpha** (optional): Alpha (0-1). Background alpha.

## Properties

- **enabled**: boolean - If false, the pass is skipped.
- **clear**: boolean - Whether to clear the buffer before rendering.
- **renderToScreen**: boolean - Whether to render directly to screen (automatically managed by Composer).

## Example

```js
var renderPass = new UeRenderPass(scene, camera);
composer.addPass(renderPass);
```
