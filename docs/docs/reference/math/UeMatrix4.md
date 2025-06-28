---
sidebar_position: 5
---

Represents a 4×4 transformation matrix. Useful for 3D object transformations including translation, rotation, and scaling. Internally stored as a column-major flat array.

---

## Constructor

```js
new UeMatrix4(data = undefined)
```

### Parameters

| Name   | Type       | Default                   | Description                                      |
| ------ | ---------- | ------------------------- | ------------------------------------------------ |
| `data` | `number[]` | `matrix_build_identity()` | Optional 4×4 matrix as a flat column-major array |

### Methods

| Method                  | Returns     | Description                                                               |
| ----------------------- | ----------- | ------------------------------------------------------------------------- |
| `clone()`               | `UeMatrix4` | Returns a deep copy of the matrix                                         |
| `multiply(m)`           | `self`      | Multiplies this matrix by another UeMatrix                                |
| `buildByTransform(obj)` | `self`      | Builds a 4×4 matrix from a Transform object (position, quaternion, scale) |

## Example

```js
var mat = new UeMatrix4();
var result = mat.multiply(anotherMatrix);

mat.buildByTransform(myTransform);
```
