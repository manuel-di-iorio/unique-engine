---
sidebar_position: 4
---

# Materials & Shaders

Materials define how your 3D objects look — their color, texture, lighting, and more. In Unique Engine, materials are tightly integrated with the rendering pipeline and automatically pass data to the appropriate shaders.

---

## 🎨 UeMaterial (base class)

All materials inherit from `UeMaterial`, which provides the basic structure for working with shaders and uniforms.

Each material:
- References a shader
- Manages its own uniforms
- Automatically integrates lighting data when required

In addition, each material applies GPU render state settings before drawing, including:

- Backface culling: controlled via side, to render front, back, or both faces.
- Depth testing: toggled with depthTest, to discard hidden fragments.
- Depth writing: via depthWrite, to enable or disable writing to the depth buffer.
- Alpha testing: using transparent and alphaTest, to discard transparent pixels below a threshold.
- Color writing: you can control whether to write the color channels.
- Blending: enabled via blending, with fine-grained control over blend equations and blend factors

These settings are applied using GameMaker's built-in gpu_* functions. This means that materials fully encapsulate how objects are rendered, not just how they look.

---

### 🧱 UeMeshBasicMaterial

A material with a flat color and a simple diffuse texture, that does not receive lights data.

### 🧱 UeMeshStandardMaterial

A ready-to-use material with built-in lighting support (ambient, point, directional) and texture handling.

**Example:**
```js
material = new UeMeshStandardMaterial();
material.color = #229094;
material.textures.map = new UeTexture("my_texture.png");
material.build();
// or pass these data into the first argument of UeMeshStandardMaterial({ <data> }) with automatic building.
```

### 🖼️ UeSpriteMaterial

A simplified material for 2D-like rendering of flat meshes or billboards.
It uses sh_ue_sprite under the hood and does not support lighting.

### 🧪 Custom Materials

You can assign the `shader` property or extend UeMaterial to create a full custom material.

---

## 🧵 Working with Uniforms

Materials support custom uniforms, which are automatically passed to the shader when the material is applied.

Uniforms are defined as a struct inside the material constructor via the uniforms field:

```js
uniforms: {
  myColor: { type: "vec3", value: [1, 0.5, 0.2] },
  time: { type: "float", value: 0.0 }
}
```

**Supported uniform types:**

- "float" — single number
- "vec2", "vec3", "vec4" — arrays of 2/3/4 numbers
- "mat4" — matrix
- "array" — float arrays (e.g. for positions, colors)
- "buffer" — partial data from a float buffer with offset and count

All uniforms are automatically sent to the GPU, using the correct shader_set_uniform_* function depending on their type. 

Uniform locations are cached on material creation using build().

**Example of setting a custom value at runtime:**

```js
myMaterial.uniforms.time.value = current_time / 1000;
```

🔧 Internal use: the engine also injects default uniforms like ueModelPosition and ueCameraPosition, and light-related uniforms when lighting is enabled.
