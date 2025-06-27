---
sidebar_position: 8
---

The `UeMaterial` class defines the visual appearance of a `UeMesh`, including color, transparency, shading, blending, lighting, and custom shader uniforms and textures.

It supports GPU-side configurations and automatic uniform population for lights and cameras.

### Constructor
```js
new UeMaterial(data = {})
```

### Properties

| Property               | Type      | Default                 | Description                                              |
| --------------------   | --------- | ----------------------- | -------------------------------------------------------- |
| `isMaterial`           | `boolean` | `true`                  | Identifies this object as a material                     |
| `color`                | `number`  | `c_white`               | Base color                                               |
| `transparent`          | `boolean` | `false`                 | Whether to enable transparency                           |
| `opacity`              | `number`  | `1`                     | Opacity (used in shaders)                                |
| `side`                 | `number`  | `cull_counterclockwise` | Which side to render (`cull_*`)                          |
| `depthTest`            | `boolean` | `true`                  | Enables depth testing                                    |
| `depthWrite`           | `boolean` | `true`                  | Enables writing to depth buffer                          |
| `depthFunc`            | `number`  | `cmpfunc_lessequal`     | Comparison function for depth testing                    |
| `forceSinglePass`      | `boolean` | `false`                 | Prevents double-pass rendering for transparent materials |
| `alphaTest`            | `number`  | `0`                     | Alpha test reference value                               |
| `colorWrite`           | `boolean` | `true`                  | Whether to write to the color buffer                     |
| `blending`             | `boolean` | `transparent`           | Whether to enable blending                               |
| `blendEquation`        | `number`  | `bm_eq_add`             | Blend equation for color                                 |
| `blendEquationAlpha`   | `number`  | `1`                     | Blend equation for alpha                                 |
| `blendSrc`             | `number`  | `bm_src_alpha`          | Blend source factor (RGB)                                |
| `blendDst`             | `number`  | `bm_inv_src_alpha`      | Blend destination factor (RGB)                           |
| `blendSrcAlpha`        | `number`  | `1`                     | Blend source factor (alpha)                              |
| `blendDstAlpha`        | `number`  | `1`                     | Blend destination factor (alpha)                         |
| `shader`               | `shader`  | `sh_ue_standard`        | The shader program to use                                |
| `uniforms`             | `object`  | `{}`                    | Custom uniforms to pass to the shader                    |
| `lights`               | `number`  | `2`                     | Number of supported lights (0 to disable lighting)       |
| `textures`             | `object`  | `{map, normalMap, ...}` | Maps for base color, normal, roughness, etc.             |

## Textures

Textures are assigned via the textures object:

- **map**: Base diffuse texture
- **normalMap**: Normal mapping
- **roughnessMap**: For roughness (PBR)
- **metalnessMap**: For metallic (PBR)
- **aoMap**: Ambient occlusion
- **emissiveMap**: Emissive light contribution

Each texture must be a UeTexture.

## Uniforms
Uniforms must be defined as objects like:

```js
uniforms: {
  myFloat: { type: "float", value: 1.0 },
  myVec3: { type: "vec3", value: [1, 0, 0] },
}
```
**Supported types:**

- "float" — single float

- "vec2" / "vec3" / "vec4"

- "mat4" — 4x4 matrix (set manually)

- "array" — float array

- "buffer" — raw GPU float buffer

**Automatically included uniforms:**

- ueModelPosition
- ueCameraPosition
- ueAmbient
- ueDirLight* / uePointLight* (if lights > 0)

🧩 Methods
```js
build()
```
Prepares internal caches of uniforms and samplers for GPU use.

```js
clone()
```
Returns a deep copy of the material.

### Example
```js
const mat = new UeMaterial({
  color: c_red,
  transparent: true,
  opacity: 0.5,
  map: myTexture,
  uniforms: {
    time: { type: "float", value: 0 }
  }
});
```

## 🔧 Internal Notes

- The `build()` method is automatically called in the constructor.

- Uniforms and textures must be named in the shader as u_ + name and s_ + name. This is an opinionated standard in Unique Engine's shaders, but you may want to change it if you prefer.

- If `forceSinglePass` is `false`, transparent objects may be rendered twice to help with depth artifacts.
