---
sidebar_position: 2
---

A material with a flat color and a simple diffuse texture, that does not receive lights data.

> Inherits from [UeMaterial](/docs/reference/core/UeMaterial)

---

🧾 Emissive Material Properties

| Property                     | Type                    | Description                                                                                                                       | Default                                          |
| ---------------------------- | ----------------------- | --------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| `uniforms.emissive`          | `vec3` (ARRAY)          | Emissive (self-illuminated) color of the material. This color (0-1) is added to the final pixel color, independent of scene lighting.   | `[0, 0, 0]`                                |
| `uniforms.emissiveIntensity` | `float`                 | Multiplier applied to the emissive color. Useful for boosting or dimming the emissive effect.                                     | `1`                                            |
| `textures.emissiveMap`       | `UeTexture` (or `null`) | Optional texture used to modulate the emissive color per pixel. White pixels emit full emissive color, black pixels emit nothing. | `global.UE_TEXTURE_EMISSIVE` (1×1 black texture) |
