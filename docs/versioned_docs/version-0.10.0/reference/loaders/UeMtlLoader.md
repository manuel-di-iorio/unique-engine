---
sidebar_position: 3
---

A `.mtl` material file loader, designed to work with `UeObjLoader`.

Parses standard MTL directives and builds `UeMeshStandardMaterial` instances, loading any associated textures.

### Constructor
```js
new UeMtlLoader()
```

## Methods

| Method Signature | Description                                                                |
| ---------------- | -------------------------------------------------------------------------- |
| `load(fname)`    | Loads and parses the specified `.mtl` file. Returns a struct of materials. |

---

### Supported .mtl Directives

| Directive  | Description                                             |
| ---------- | ------------------------------------------------------- |
| `newmtl`   | Starts a new material definition                        |
| `Ka`       | Ambient color (R G B)                                   |
| `Kd`       | Diffuse color (R G B)                                   |
| `Ks`       | Specular color (R G B)                                  |
| `Ke`       | Emissive color (R G B)                                  |
| `Tf`       | Transmission filter color (R G B)                       |
| `d`        | Dissolve (alpha), 1 = opaque, 0 = fully transparent     |
| `Tr`       | Transparency (inverted alpha), `alpha = 1 - Tr`         |
| `Ns`       | Specular exponent (shininess)                           |
| `Ni`       | Index of refraction (ior)                               |
| `illum`    | Illumination model (stored as-is)                       |
| `map_Ka`   | Ambient texture → `material.textures.map`               |
| `map_Kd`   | Diffuse texture → `material.textures.map`               |
| `map_bump` | Bump map → `material.textures.bump`                     |
| `bump`     | Alternate bump map directive → `material.textures.bump` |
