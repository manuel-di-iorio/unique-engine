---
sidebar_position: 3
---

A ready-to-use material with built-in lighting support (ambient, point, directional, spot) and texture handling.

Currently handles up to **1 directional light**, **8 point lights** and **8 spot lights**. Only 1 directional, 1 point light and 1 spot light can cast shadows simultaneously.

> Inherits from [UeMaterial](/docs/reference/core/UeMaterial)

---

> NOTE: Most properties listed below are fully implemented in `sh_ue_standard`. Some advanced maps like `bumpMap`, `envMap` or `lightMap` are still in development.

🧾 Material Properties

| Property | Type | Description | Default |
| --- | --- | --- | --- |
| `color` | `color` | Base color of the material. | `c_white` |
| `emissive` | `color` | Emissive (self-illuminated) color of the material. This color is added to the final pixel color, independent of scene lighting. | `c_black` |
| `emissiveIntensity` | `float` | Multiplier applied to the emissive color. | `0` |
| `metalness` | `float` | How much the material looks like a metal. Non-metallic materials such as wood or stone use 0.0, metallic use 1.0. | `0` |
| `roughness` | `float` | How rough the material appears. 0.0 means a smooth mirror reflection, 1.0 means fully diffuse. | `1` |
| `aoMapIntensity` | `float` | Intensity of the ambient occlusion effect. | `1` |
| `bumpScale` | `float` | How much the bump map affects the surface. | `1` |
| `normalMapScale` | `vec2` | How much the normal map affects the surface. | `[1, 1]` |
| `displacementScale` | `float` | How much the displacement map affects the mesh. | `0` |
| `displacementBias` | `float` | Offset of the displacement map values. | `0` |
| `lightMapIntensity` | `float` | Intensity of the light map. | `1` |
| `envMapIntensity` | `float` | Intensity of the environment map. | `1` |
| `envMapRotation` | `vec3` | Rotation of the environment map (Euler angles). | `[0, 0, 0]` |
| `flatShading` | `boolean` | Whether the material is rendered with flat shading. | `false` |
| `fog` | `boolean` | Whether the material is affected by fog (Linear and Exponential are supported). | `true` |

---

🧾 Textures

| Property | Type | Description | Default |
| --- | --- | --- | --- |
| `textures.map` | `UeTexture` | The main diffuse/albedo texture. | `undefined` |
| `textures.emissiveMap` | `UeTexture` | Texture used to modulate the emissive color. | `undefined` |
| `textures.alphaMap` | `UeTexture` | Texture used to control the alpha (transparency) per pixel. | `undefined` |
| `textures.ormMap` | `UeTexture` | Packed texture for **O**cclusion, **R**oughness, and **M**etalness. Color channel mapping: R = Ambient Occlusion, G = Roughness, B = Metalness. | `undefined` |
| `textures.normalMap` | `UeTexture` | Normal map for adding surface detail. | `undefined` |
| `textures.displacementMap` | `UeTexture` | Displacement map for deforming the mesh. | `undefined` |

<!-- | `textures.bumpMap` | `UeTexture` | Bump map for adding surface detail. | `global.UE_TEXTURE_DEFAULT_BLACK` | -->
<!-- | `textures.lightMap` | `UeTexture` | Pre-baked light map. | `global.UE_TEXTURE_DEFAULT_BLACK` | -->
<!-- | `textures.envMap` | `UeTexture` | Environment map for reflections. | `global.UE_TEXTURE_DEFAULT_BLACK` | -->

---

## 🧾 Methods

| Method | Description |
| --- | --- |
| `setColor(color)` | Sets the base color of the material (e.g. `c_red`, `c_white`). |
| `setEmissiveColor(color)` | Sets the emissive color of the material. |

