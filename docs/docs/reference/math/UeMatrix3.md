---
sidebar_position: 4
---

Represents a 3×3 matrix, mainly used for 2D/3D transformations like normal matrix calculations, scaling, or other matrix math in compact form.

---

## Constructor

```js
new UeMatrix3(data = undefined)
```

### Parameters

| Name   | Type       | Default         | Description                                        |
| ------ | ---------- | --------------- | -------------------------------------------------- |
| `data` | `number[]` | Identity matrix | Optional flat array of 9 numbers (row-major order) |

## Methods

| Method           | Returns     | Description                                                         |
| ---------------- | ----------- | ------------------------------------------------------------------- |
| `clone()`        | `UeMatrix3` | Returns a deep copy of the matrix                                   |
| `scaleByVec3(v)` | `self`      | Applies a non-uniform scale using a `UeVector3` to each matrix axis |

## Example
```js
var mat = new UeMatrix3();
var scale = new UeVector3(2, 3, 4);
mat.scaleByVec3(scale);
```
