---
sidebar_position: 7
---

The `UeRenderer` is responsible for rendering a scene with proper sorting and handling of opaque and transparent objects.

It traverses the scene graph, builds lighting state, sorts renderables by distance to the camera, and performs the draw calls.

### Constructor
```js
new UeRenderer(data = {})
```

### Properties

| Property     | Type      | Default | Description                         |
| ------------ | --------- | ------- | ----------------------------------- |
| `isRenderer` | `boolean` | `true`  | Identifies the object as a renderer |

## 🔧 Internal Logic

**Object Classification**

Objects are split into two queues:

- Opaque queue → rendered first, front-to-back

- Transparent queue → rendered last, back-to-front, with zwrite disabled

- Each object's .material.transparent flag determines which queue it goes to.

**Sorting**

Objects are sorted by distance to the camera using quicksort:

- Opaque → front-to-back (to reduce overdraw)

- Transparent → back-to-front (to ensure correct alpha blending)

**Transparency Rendering**
- Transparent objects are rendered with:

- Depth write disabled (`gpu_set_zwriteenable(false)`)

- Double-pass rendering if the material does not have forceSinglePass = true

**Lighting Aggregation**

When the internal `render()` method is called, the renderer collects all active lights from scene.lights, and builds a lightState object:

```js
{
  ambient: [r, g, b], // Total ambient light
  directional: [...], // Array of directional lights
  point: [...]        // Array of point lights
}
```
Each light contributes only if enabled == true.

🧠 Notes

- The renderer expects all visible meshes to implement a .render(renderState) method.
- The renderState struct passed to each mesh includes:

  - scene, lightState, camera, and optionally side (for double-pass).

- World matrix is reset to identity after rendering to avoid side effects.

Example
```js
const scene = new UeScene();
const camera = new UePerspectiveCamera();
const renderer = new UeRenderer();

renderer.render(scene, camera);
```
