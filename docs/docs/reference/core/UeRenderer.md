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
| `renderPath`          | `number`  | `UE_RENDER_PATH.FORWARD` | The rendering path to use (`FORWARD` or `DEFERRED`) |
| `toneMapping`         | `number`  | `UE_TONE_MAPPING.NONE` | HDR to LDR mapping algorithm |
| `toneMappingExposure` | `number`  | `1.0`   | Global exposure for tone mapping |

### Properties

| Property      | Type      | Default     | Description                                 |
| ------------- | --------- | ----------- | ------------------------------------------- |
| `isRenderer`  | `boolean` | `true`      | Identifies the object as a renderer         |
| `type`        | `string`  | `Renderer`  | Object type                                 |
| `name`        | `string`  | `undefined` | Object name (optional)                      |
| `width`       | `number`  | `display`   | Current render width                        |
| `height`      | `number`  | `display`   | Current render height                       |
| `sortObjects` | `boolean` | `true`      | Whether to sort the objects on render phase |
| `renderPath`  | `number`  | `UE_RENDER_PATH.FORWARD` | Active rendering path (`FORWARD` or `DEFERRED`) |
| `shadowMap`   | `struct`  | `{enabled: false, autoUpdate: true, needsUpdate: false}` | Shadow rendering configuration |
| `toneMapping` | `number`  | `UE_TONE_MAPPING.NONE` | Active tone mapping algorithm |
| `toneMappingExposure` | `number` | `1.0` | Active exposure level |

## 💡 Optimized Lighting System

The renderer uses a high-performance lighting system designed to minimize state changes and redundant work:

- **Numeric Hashing**: Instead of string-based hashing, the renderer uses a 32-bit FNV-1a numeric hash to detect light state changes (position, color, intensity, etc.).
- **Leveled Versioning**: Lights track their own `version` (from [UeTransform](./UeTransform.md)) and `paramsVersion` (from [UeLight](../lights/UeLight.md)). The renderer only repacks light data into GPU buffers when these versions change.
- **Unified Light Pass**: Hashing and light classification are performed in a single loop traversal.
- **Direct Memory Access**: The renderer accesses world matrices directly, avoiding high-level function calls during the hot rendering loop.
- **Shadow Index Caching**: The renderer caches the index of the primary shadow caster to avoid rescanning the light list every frame.

---

## 🏗️ Rendering Paths

Unique Engine supports two main rendering paths, each with its own strengths and use cases.

### 1️⃣ Forward Rendering (`UE_RENDER_PATH.FORWARD`)

The default rendering path. Each object is rendered in a single pass, calculating all lighting and shadows directly in its fragment shader.

- **Pros**: Low memory overhead, supports any number of transparent objects, easy to understand.
- **Cons**: Lighting cost increases linearly with the number of lights per object (`lights` property in material).

### 2️⃣ Deferred Rendering (`UE_RENDER_PATH.DEFERRED`)

:::caution
Deferred Rendering is **experimental** and not working correctly yet.
:::

A more advanced path that decouples geometry rendering from lighting calculations. It uses a **G-Buffer** (Geometry Buffer) to store surface properties.

**How it works:**
1. **G-Buffer Pass**: All opaque objects are rendered once to multiple targets (Albedo, Normals, Positions, Emissive/AO).
2. **Lighting Pass**: A single fullscreen quad is rendered, sampling the G-Buffer to calculate lighting for the entire screen at once.
3. **Transparent Pass**: Transparent objects are rendered using Forward rendering on top of the deferred result.

**G-Buffer Layout:**
- **Target 0 (Albedo/Alpha)**: `surface_rgba8unorm` - RGB Albedo and Alpha mask.
- **Target 1 (Normal/Metal)**: `surface_rgba16float` - RGB World Normals (mapped -1 to 1) and Metalness.
- **Target 2 (Position/Rough)**: `surface_rgba32float` - RGB World Position and Roughness.
- **Target 3 (Emissive/AO)**: `surface_rgba16float` - RGB Emissive color and Ambient Occlusion.

**Pros**: Lighting cost is independent of geometry complexity, supports a very high number of lights, enables advanced post-processing effects (like Screen Space Reflections or better Outlines).
**Cons**: Higher memory usage (VRAM), requires hardware support for multiple render targets (MRT) and floating-point surfaces.

---

## 🔧 Internal Logic

**1️⃣ Object Collection**

Rendering starts by recursively walking the scene graph to extract lights and meshes. Since the same scene graph is used for both shadow passes and the main camera pass, the collection is decoupled into two phases:

- **Recursive Traversal**: Lights are stored into an internal array (`__lights`), and all visible meshes are added to a main queue (`__queue`) regardless of their visibility to the camera frustum (to ensure they can cast shadows even if the caster is off-camera).
- **Visibility Filtering**: To prevent shadow popping, all objects are initially collected for the shadow pass. After sorting the main render queue, a visibility check is performed against the camera's frustum. Objects marked with `frustumCulled == true` that are not visible to the camera are removed before the main rendering phase.

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
   - Sets shadow map surface as render target.
   - Positions shadow camera and updates light space transformation matrix.
   - Frustum Culling: Shadow maps implement their own culling pass using the shadow camera's frustum. This ensures only objects within the light's reach are rendered, optimizing performance without causing shadows to "pop" when the proejcting object is outside the main camera's view.
   - Clears shadow map to white (maximum depth).
   - Renders scene from light's perspective using `sh_ue_shadow_map` shader.
   - Stores depth values in `r32float` surface.

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
7. Renders shadow maps (if `shadowMap.enabled`).
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

---

## 🎨 Tone Mapping System

The engine implements various tone mapping algorithms to convert HDR (High Dynamic Range) lighting into LDR (Low Dynamic Range) values suitable for display.

### Available Algorithms

| Algorithm | Constant | Description |
| --- | --- | --- |
| **None** | `UE_TONE_MAPPING.NONE` | No transformation, values are clamped. |
| **Linear** | `UE_TONE_MAPPING.LINEAR` | Linear tone mapping. |
| **Reinhard** | `UE_TONE_MAPPING.REINHARD` | Classic Reinhard operator: `L / (1 + L)`. Good for most scenes. |
| **Cineon** | `UE_TONE_MAPPING.CINEON` | Mimics modern film response with a softer plateau. |
| **ACES** | `UE_TONE_MAPPING.ACES` | High-contrast, cinematic look based on the Academy standards. |
| **AgX** | `UE_TONE_MAPPING.AGX` | Modern cinematic look with superior handling of bright colors and highlights. |
| **Neutral** | `UE_TONE_MAPPING.NEUTRAL` | Balanced color response based on the PBR Neutral standard. |

### Configuration

You can set the tone mapping globally in the renderer:

```js
const renderer = new UeRenderer({
    toneMapping: UE_TONE_MAPPING.ACES,
    toneMappingExposure: 1.2 // Adjust brightness before mapping
});
```

### Material Participation

By default, all materials using standard shaders participate in tone mapping. You can toggle this on a per-material basis:

```js
const material = new UeMeshStandardMaterial({
    color: c_white,
    toneMapped: false // Skip tone mapping for this material
});
```
