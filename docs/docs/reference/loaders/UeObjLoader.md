---
sidebar_position: 4
---

A `.obj` model loader. Supports vertex positions, normals, UVs, vertex colors, material groups, `usemtl` references, and `.mtl` material libraries.

---

## Constructor

```js
new UeObjLoader()
```

### Properties

| Name             | Type    | Description                                                       |
| ---------------- | ------- | ----------------------------------------------------------------- |
| `flipUV`         | Boolean | If `true`, UVs are flipped vertically (default `true`)            |
| `reverseWinding` | Boolean | If `true`, triangle winding is reversed (default `false`)         |
| `materials`      | Struct  | Dictionary of materials loaded from an `.mtl` file                |


## Methods

| Method Signature          | Description                                                            |
| ------------------------- | ---------------------------------------------------------------------- |
| `load(fname)`             | Loads and parses an `.obj` file from disk. Returns the root `UeMesh`.  |
| `setMaterials(materials)` | Assigns a struct of materials (from `UeMtlLoader`) to enable `usemtl`. |

## Example

```js
var mtlLoader = new UeMtlLoader();
var materials = mtlLoader.load("models/car.mtl");

var objLoader = new UeObjLoader();
objLoader.setMaterials(materials);

var mesh = objLoader.load("models/car.obj");
scene.add(mesh);
```

## Notes

- Faces are triangulated automatically if needed.

- The loader uses the `global.UE_VFORMAT_PNUTC` vertex format.

- Since OBJ files do not natively store tangent data, default tangents (`1, 0, 0, 1`) are generated for compatibility with PBR shaders.

- Materials are not loaded automatically; use `UeMtlLoader`.

- No vertex deduplication is performed (each face defines separate vertices).

- Supports color-per-vertex if .obj includes RGB values in v.
