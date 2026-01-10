---
sidebar_position: 4
---

# Materials & Shaders

Materials define how your 3D objects look — their color, texture, lighting, and more. In Unique Engine, materials are tightly integrated with the rendering pipeline and automatically pass data to the appropriate shaders.

---

## 🎨 UeRenderer & Sorting

The `UeRenderer` is responsible for drawing the scene. To maximize performance, it sorts objects before rendering to minimize GPU state changes (like switching shaders or textures).

The sorting logic works as follows:
1. **Opaque Objects**: Sorted front-to-back (to take advantage of early Z-culling).
2. **Transparent Objects**: Sorted back-to-front (painter's algorithm) to ensure correct blending.
3. **Material Batching**: Objects sharing the same material ID are grouped together to reduce draw calls overhead.

---

## 🎨 UeMaterial (base class)

All materials inherit from `UeMaterial`, which provides the basic structure for working with shaders and uniforms.

### Properties

Each material exposes several properties to control the GPU render state:

- **`visible`**: (bool) Whether the material is visible.
- **`transparent`**: (bool) Enables transparency handling.
- **`opacity`**: (float) Global opacity factor (0.0 to 1.0).
- **`side`**: (const) Culling mode. Defaults to `cull_counterclockwise`. Can be `cull_clockwise`, `cull_counterclockwise`, or `cull_noculling`.
- **`wireframe`**: (bool) If true, renders the object as a wireframe (using `pr_linelist`).
- **`lights`**: (int) Number of lights this material supports (default: 2).

**Depth & Stencil:**
- **`depthTest`**: (bool) Enables depth testing (Z-buffer). Default `true`.
- **`depthWrite`**: (bool) Enables writing to the depth buffer. Default `true` (automatically `false` if transparent).
- **`depthFunc`**: (const) The depth comparison function (e.g., `cmpfunc_lessequal`).
- **`alphaTest`**: (float) Threshold for discarding pixels based on alpha (alpha testing).
- **`colorWrite`**: (bool) Enables writing to color channels.

**Blending:**
- **`blending`**: (bool) Enables blending.
- **`blendSrc`**, **`blendDst`**: Source and destination blend factors.
- **`blendEquation`**: The blending equation to use.

### Methods

- **`build()`**: Caches uniform and texture locations. **Must be called** after changing the shader or adding new uniforms/textures.
- **`use()`**: Applies the material's state and uniforms to the GPU.
- **`clone()`**: Creates a copy of the material.

---

### 🧱 UeMeshBasicMaterial

A material with a flat color and a simple diffuse texture, that does not receive lights data.

### 🧱 UeMeshStandardMaterial

A ready-to-use material with built-in lighting support (ambient, point, directional), shadows and texture handling.

**Example:**
```js
material = new UeMeshStandardMaterial();
material.opacity = .8;
material.setTexture("map", new UeTexture("my_texture.png"));
material.build();
// or pass these data into the first argument of UeMeshStandardMaterial({ <data> }) with automatic building.
```

### 🖼️ UeSpriteMaterial

A simplified material for 2D-like rendering of flat meshes or billboards.
It uses the shader `sh_ue_sprite` under the hood and does not support lighting.

### 🧪 Custom Materials

You can assign the `shader` property or extend `UeMaterial` to create a full custom material.

### 🧵 Working with Textures

Textures are assigned to materials via the `textures` object. Unique Engine uses an optimized texture system:

- **Undefined by Default**: Most texture slots are `undefined` by default. 
- **GPU Optimization**: When a texture is `undefined`, the engine skips binding it and tells the shader (via `u_ueHas*Map` uniforms) to skip the sampling process.
- **Performance**: This reduces texture swaps and memory bandwidth usage on the GPU.

To set a texture:
```js
material.setTexture("map", new UeTexture("my_texture.png"));
material.build(); // Always call build() after updating textures or uniforms
```

---

## 🧵 Working with Uniforms

Materials support custom uniforms, which are automatically passed to the shader when the material is applied.

Uniforms are defined as a struct inside the material constructor via the `uniforms` field:

```js
uniforms: {
  myColor: { type: "vec3", value: [1, 0.5, 0.2] },
  time: { type: "float", value: 0.0 }
}
```

**Supported uniform types:**

- `UE_UNIFORM_TYPE.FLOAT` ("float")
- `UE_UNIFORM_TYPE.VEC2` ("vec2")
- `UE_UNIFORM_TYPE.VEC3` ("vec3")
- `UE_UNIFORM_TYPE.VEC4` ("vec4")
- `UE_UNIFORM_TYPE.MAT4` ("mat4")
- `UE_UNIFORM_TYPE.ARRAY` ("array")
- `UE_UNIFORM_TYPE.BUFFER` ("buffer")

All uniforms are automatically sent to the GPU, using the correct `shader_set_uniform_*` function depending on their type. 

Uniform locations are cached on material creation using `build()`.

**Example of setting a custom value at runtime:**

```js
myMaterial.setUniform("time", current_time / 1000);
```
