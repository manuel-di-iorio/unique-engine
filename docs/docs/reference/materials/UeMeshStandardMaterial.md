---
sidebar_position: 3
---

A ready-to-use material with built-in lighting support (ambient, point, directional) and texture handling.

Currently handles up to 2 directional lights and 2 point lights, but you can easily modify the shader to add more uniforms. Remember to also modify the material 'shaderMaxLights' property

> Inherits from [UeMaterial](/docs/reference/core/UeMaterial)

---

> NOTE: emissive, emissiveIntensity, emissiveMap are the actual properties that are currently implemented. We are adding support for other ones in the future. So e.g. if you pass "metalness", nothing will change for now.

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
| `normalMapType` | `UE_NORMAL_MAP_TYPE` | The type of normal map. | `TANGENT_SPACE_NORMAL_MAP` |
| `normalMapScale` | `vec2` | How much the normal map affects the surface. | `[1, 1]` |
| `displacementScale` | `float` | How much the displacement map affects the mesh. | `0` |
| `displacementBias` | `float` | Offset of the displacement map values. | `0` |
| `lightMapIntensity` | `float` | Intensity of the light map. | `1` |
| `envMapIntensity` | `float` | Intensity of the environment map. | `1` |
| `envMapRotation` | `vec3` | Rotation of the environment map (Euler angles). | `[0, 0, 0]` |
| `flatShading` | `boolean` | Whether the material is rendered with flat shading. | `false` |
| `fog` | `boolean` | Whether the material is affected by fog. | `true` |

---

🧾 Textures

| Property | Type | Description | Default |
| --- | --- | --- | --- |
| `textures.map` | `UeTexture` | The main diffuse/albedo texture. | `global.UE_TEXTURE_DEFAULT_WHITE` |
| `textures.emissiveMap` | `UeTexture` | Texture used to modulate the emissive color. | `global.UE_TEXTURE_DEFAULT_BLACK` |
| `textures.alphaMap` | `UeTexture` | Texture used to control the alpha (transparency) per pixel. | `global.UE_TEXTURE_DEFAULT_WHITE` |
| `textures.roughnessMap` | `UeTexture` | Texture used to modulate the roughness. | `global.UE_TEXTURE_DEFAULT_WHITE` |
| `textures.metalnessMap` | `UeTexture` | Texture used to modulate the metalness. | `global.UE_TEXTURE_DEFAULT_BLACK` |
| `textures.aoMap` | `UeTexture` | Ambient occlusion map. | `global.UE_TEXTURE_DEFAULT_WHITE` |
| `textures.normalMap` | `UeTexture` | Normal map for adding surface detail. | `global.UE_TEXTURE_DEFAULT_NORMAL` |
| `textures.bumpMap` | `UeTexture` | Bump map for adding surface detail. | `global.UE_TEXTURE_DEFAULT_BLACK` |
| `textures.lightMap` | `UeTexture` | Pre-baked light map. | `global.UE_TEXTURE_DEFAULT_BLACK` |
| `textures.displacementMap` | `UeTexture` | Displacement map for deforming the mesh. | `global.UE_TEXTURE_DEFAULT_BLACK` |
| `textures.envMap` | `UeTexture` | Environment map for reflections. | `global.UE_TEXTURE_DEFAULT_BLACK` |
