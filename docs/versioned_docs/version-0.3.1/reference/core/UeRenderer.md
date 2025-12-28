---
sidebar_position: 7
---

`UeRenderer` is responsible for rendering the scene, collecting visible objects, computing their sort order using a **52-bit packed integer key**, building the lighting state, and issuing the draw calls.

The renderer recursively traverses the scene graph, extracts lights and meshes, constructs a global render queue, sorts it, and renders all objects in the correct order.

### Constructor
```js
new UeRenderer(data = {})
```

### Data Properties

| Property              | Type      | Default | Description                                    |
| --------------------- | --------- | ------- | ---------------------------------------------- |
| `width`               | `number`  | `display_get_width()` | Default render width (viewport) |
| `height`              | `number`  | `display_get_height()` | Default render height (viewport) |
| `shadowMap.enabled`   | `boolean` | `false` | Enable shadow map rendering                    |
| `shadowMap.autoUpdate`| `boolean` | `true`  | Automatically update shadows every frame       |

### Properties

| Property      | Type      | Default     | Description                                 |
| ------------- | --------- | ----------- | ------------------------------------------- |
| `isRenderer`  | `boolean` | `true`      | Identifies the object as a renderer         |
| `type`        | `string`  | `Renderer`  | Object type                                 |
| `name`        | `string`  | `undefined` | Object name (optional)                      |
| `width`       | `number`  | `display`   | Current render width                        |
| `height`      | `number`  | `display`   | Current render height                       |
| `sortObjects` | `boolean` | `true`      | Whether to sort the objects on render phase |
| `shadowMap`   | `struct`  | `{enabled: false, autoUpdate: true, needsUpdate: false}` | Shadow rendering configuration |

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

**6️⃣ Shadow Map Rendering**

When `shadowMap.enabled` is true, the renderer performs shadow map rendering before the main scene pass:

1. **Shadow Pass (for each shadow-casting light):**
   - Sets shadow map surface as render target
   - Positions shadow camera at light position/direction
   - Updates light space transformation matrix
   - Clears shadow map to white (maximum depth)
   - Renders scene from light's perspective using `sh_ue_shadow_map` shader
   - Stores depth values in `r32float` surface

2. **Supported Shadow Types:**
   - **DirectionalLight:** Uses orthographic shadow camera, single shadow map
   - **PointLight:** Uses 6 perspective cameras (cube shadow map) - *planned*

3. **Shadow Map Configuration:**
   ```js
   const renderer = new UeRenderer({
       shadowMap: {
           enabled: true,       // Enable shadow rendering
           autoUpdate: true,    // Update every frame
           needsUpdate: false   // Manual update trigger
       }
   });
   ```

4. **Object Shadow Properties:**
   - `castShadow` - Object casts shadows (rendered in shadow pass)
   - `receiveShadow` - Object receives shadows (shader samples shadow map)

5. **Shadow Callbacks:**
   - `onBeforeShadow()` - Called before object renders to shadow map
   - `onAfterShadow()` - Called after object renders to shadow map

**7️⃣ Render Flow**

The `render(scene, camera)` method:

1. Validates the target view (skipped if rendering to surface).
2. Applies camera matrices (`camera_apply`).
3. Updates camera world matrix.
4. Clears internal queues.
5. Collects objects and lights from scene graph.
6. Sorts renderables by sort key.
7. **Renders shadow maps** (if `shadowMap.enabled`).
8. Builds the light state.
9. Renders all objects in sorted order.
10. Resets shader and world matrix.
11. Restores previous GPU state.

---

## 🌑 Shadow Mapping System

The renderer implements a complete shadow mapping pipeline for directional lights.

### Enabling Shadows

```js
const renderer = new UeRenderer({
    shadowMap: {
        enabled: true,       // Enable shadow rendering
        autoUpdate: true,    // Update shadows every frame
        needsUpdate: false   // Manual trigger (when autoUpdate = false)
    }
});
```

### Shadow Rendering Pipeline

**Phase 1: Shadow Map Generation**

For each light with `castShadow = true`:

1. Position shadow camera at light location
2. Orient camera toward light target (directional) or in 6 directions (point)
3. Calculate light space transformation matrix
4. Set shadow map surface as render target
5. Clear to white (max depth = 1.0)
6. Render objects with `castShadow = true` using depth shader
7. Store depth values in `r32float` surface

**Phase 2: Main Scene Rendering**

1. Shadow maps are bound as textures to material shaders
2. Light space matrices are passed as uniforms
3. Fragment shaders transform positions to light space
4. Shadow map is sampled to determine visibility
5. Lighting is modulated by shadow factor

### Shadow Map Format

- **Surface format:** `surface_r32float` (32-bit float, single channel)
- **Clear value:** White (1.0) represents maximum depth
- **Depth range:** 0.0 (near) to 1.0+ (far)
- **Precision:** High precision minimizes depth artifacts

### Object Shadow Configuration

```js
// Enable shadow casting and receiving
const mesh = new UeMesh(geometry, material);
mesh.castShadow = true;    // Rendered in shadow pass
mesh.receiveShadow = true; // Shader samples shadow map
scene.add(mesh);
```

### Light Shadow Configuration

```js
// Directional light shadows
const sun = new UeDirectionalLight(c_white, 1.5);
sun.castShadow = true;
sun.shadow.updateMapSize(2048, 2048);  // Higher resolution
sun.shadow.camera.left = -500;         // Shadow frustum bounds
sun.shadow.camera.right = 500;
scene.add(sun);
```

### Performance Optimization

**Static Scenes:**
```js
renderer.shadowMap.autoUpdate = false;  // Don't update every frame
renderer.shadowMap.needsUpdate = true;  // Trigger manual update
renderer.render(scene, camera);
renderer.shadowMap.needsUpdate = false; // Prevent further updates
```

**Selective Shadow Casting:**
```js
// Only important objects cast shadows
importantMesh.castShadow = true;
smallDetail.castShadow = false;  // Skip for performance
```

### Shadow Map Resolution Guidelines

| Resolution | Use Case              | Memory per Map |
| ---------- | --------------------- | -------------- |
| 512×512    | Mobile/low-end        | ~1 MB          |
| 1024×1024  | Default quality       | ~4 MB          |
| 2048×2048  | High quality          | ~16 MB         |
| 4096×4096  | Ultra quality/closeup | ~64 MB         |

---

## 📘 Example

### Basic Rendering

```js
const scene = new UeScene();
const camera = new UePerspectiveCamera();
const renderer = new UeRenderer();

renderer.render(scene, camera);
```

### With Shadow Mapping

```js
const scene = new UeScene();
const camera = new UePerspectiveCamera();

// Enable shadows in renderer
const renderer = new UeRenderer({
    shadowMap: {
        enabled: true,
        autoUpdate: true
    }
});

// Create shadow-casting light
const sun = new UeDirectionalLight(c_white, 1.5);
sun.castShadow = true;
sun.shadow.updateMapSize(2048, 2048);
sun.position.set(100, 200, 150);
scene.add(sun);

// Create mesh with shadows
const mesh = new UeMesh(geometry, material);
mesh.castShadow = true;
mesh.receiveShadow = true;
scene.add(mesh);

// Render with shadows
renderer.render(scene, camera);
```
