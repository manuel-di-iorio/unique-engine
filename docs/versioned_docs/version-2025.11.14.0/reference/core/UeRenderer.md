---
sidebar_position: 7
---

`UeRenderer` is responsible for rendering the scene, collecting visible objects, computing their sort order using a **52-bit packed integer key**, building the lighting state, and issuing the draw calls.

The renderer recursively traverses the scene graph, extracts lights and meshes, constructs a global render queue, sorts it, and renders all objects in the correct order.

### Constructor
```js
new UeRenderer(data = {})
```

### Properties

| Property     | Type      | Default    | Description                                 |
| ------------ | --------- | -------    | -----------------------------------         |
| `isRenderer` | `boolean` | `true`     | Identifies the object as a renderer         |
| `type`       | `string`  | `Renderer` | Object type                                 |
| `name`       | `string`  | `undefined`| Object name (optional)                      |
| `sortObjects`| `boolean` | `true`     | Whether to sort the objects on render phase |

## 🔧 Internal Logic

**1️⃣ Object Collection**

Rendering starts by recursively walking the scene graph:

- Lights are stored into an internal array (__lights).
- Meshes (objects with geometry) are added to the main __queue.
- Frustum culling is applied when frustumCulled == true.
- For each mesh, a sort key is computed (see below).
- Collected objects are then rendered in a single unified pass.

**2️⃣ Sort Key (52-bit Packed Integer)**

Each object receives a packed integer used for sorting all renderables with a single fast comparison.

```
Bit Layout (MSB → LSB)
[51]        1 bit   → transparency flag (opaque first, transparent last)
[50..43]    8 bits  → renderOrder (user override)
[42..31]   12 bits  → material ID (minimizes state changes)
[30..0]    31 bits  → quantized depth (front-to-back or inverted)
```

**🔍 Depth Quantization (31 bits)**

The squared distance to the camera is normalized and mapped into a 31-bit integer:

```js
var nd = clamp(distSquared / MAX_SORT_DIST, 0, 1);
var quantDepth = floor(nd * 0x7FFFFFFF); // max 31-bit integer
```

Why quantize?

- Float comparisons are unstable at high distance.
- Quantization guarantees uniform precision.
- Integer sorting is faster and deterministic.

**🔁 Transparent Depth Inversion**

Transparent objects must be sorted back-to-front.

Instead of separate algorithms or reverse sorts, depth is bitwise inverted:

```js
quantDepth ^= (-transparent & 0x7FFFFFFF);
```

Opaque → normal depth

Transparent → inverted depth

**🧮 Final Sort Key Assembly**

```js
_sortKey = 0;
_sortKey |= (transparent ? 1 : 0) << 51;      // 1 bit
_sortKey |= (renderOrder & 0xFF) << 43;       // 8 bits
_sortKey |= (materialId & 0xFFF) << 31;       // 12 bits
_sortKey |= quantDepth;                       // 31 bits
```

The final 52-bit key is stored in:

```
object.__sortKey
```

**3️⃣ Sorting (Quicksort)**

The renderer uses an optimized quicksort:

```js
if (array[j].__sortKey < pivot)
```

Only one integer comparison is performed per element → very fast.

Opaque/transparent ordering, material sorting, and depth sorting all happen automatically via the key.

**4️⃣ Rendering Objects**

Rendering obeys the sorted order.

Transparent materials:

- disable culling (cull_noculling)
- may render in double-pass unless forceSinglePass == true

Opaque materials render normally.

`onBeforeRender` and `onAfterRender` callbacks are supported.

**5️⃣ Lighting Aggregation**

Before rendering, the renderer collects all lights into a global light state:

- Ambient light is accumulated.
- Directional lights are stored in order.
- Point lights are stored in order.
- Counts are updated in the global shared arrays.
- Mesh shaders access this state via UE_RENDERER_LIGHT_STATE.

**6️⃣ Render Flow**

The `render(scene, camera)` method:

- Validates the target view.
- Updates camera world matrix.
- Clears internal queues.
- Collects objects and lights.
- Sorts renderables.
- Builds the light state.
- Renders all objects in order.
- Resets shader and world matrix.
- Restores previous GPU state.

## 📘 Example
```js
const scene = new UeScene();
const camera = new UePerspectiveCamera();
const renderer = new UeRenderer();

renderer.render(scene, camera);
```
