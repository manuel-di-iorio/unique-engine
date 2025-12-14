# UeOutlinePass

`UeOutlinePass` applies an outline effect to specific selected objects in the scene. It uses a post-processing technique to detect edges on a mask of the selected objects.

## Constructor

```gml
new UeOutlinePass(scene, camera, selectedObjects?)
```

- **scene**: `UeScene` - The scene context.
- **camera**: `UeCamera` - The camera used for rendering.
- **selectedObjects** (optional): `Array<UeObject3D>` - Initial list of objects to outline.

## Properties

- **visibleEdgeColor**: Array[r,g,b] - Color of the outline (normalized 0-1). Default: White `[1, 1, 1]`.
- **edgeStrength**: float - Intensity of the edge. Default: `3.0`.
- **edgeGlow**: float - Softness/Glow of the edge. Default: `1.0`.
- **thickness**: float - Thickness of the outline. Default: `1.0`.
- **selectedObjects**: Array - List of objects to outline. Can be updated at runtime.

## How it works

The pass operates in two internal steps:

1.  **Mask Pass**: Renders the `selectedObjects` into an internal buffer as solid white silhouettes on a black background. Since a custom solid-color shader is used, internal texture details or lighting are ignored.
2.  **Edge Detection**: Applies a Sobel filter to the generated mask to detect the silhouette edges. These edges are then composited on top of the original scene image.

This ensures that only the outer contours of the selected objects are highlighted, ignoring internal geometry edges.

## Example

```js
// Select an object
var outlinePass = new UeOutlinePass(scene, camera, [ cube ]);

// Configuring visual style
outlinePass.visibleEdgeColor = [1, 0, 0]; // Red
outlinePass.edgeStrength = 5;

composer.addPass(outlinePass);
```
