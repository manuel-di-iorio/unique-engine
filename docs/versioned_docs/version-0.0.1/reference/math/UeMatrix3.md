---
sidebar_position: 4
---

Represents a 3×3 matrix, mainly used for 2D/3D transformations like normal matrix calculations, scaling, or other matrix math in compact form.

---

## Constructor

```js
new UeMatrix3(data = undefined)
```

### Data parameters

| Name   | Type       | Default         | Description                                        |
| ------ | ---------- | --------------- | -------------------------------------------------- |
| `data` | `number[]` | Identity matrix | Optional flat array of 9 numbers (row-major order) |

## Methods

| Method                    | Returns     | Description                                                                                   |
| ------------------------- | ----------- | --------------------------------------------------------------------------------------------- |
| `clone()`                 | `UeMatrix3` | Creates and returns a new copy of this matrix                                                |
| `copy(m)`                 | `UeMatrix3` | Copies values from matrix `m` into this matrix                                              |
| `determinant()`           | `number`    | Calculates and returns the determinant of the matrix                                        |
| `equals(m)`               | `boolean`   | Checks if this matrix is equal to another matrix `m` element-wise                            |
| `extractBasis(x, y, z)`   | `UeMatrix3` | Extracts the basis vectors (columns) into given vectors `x`, `y`, and `z`                    |
| `fromArray(arr, offset)`  | `UeMatrix3` | Sets matrix elements from an array starting at `offset`                                     |
| `invert()`                | `UeMatrix3` | Inverts the matrix or sets to zero matrix if not invertible                                 |
| `getNormalMatrix(m4)`     | `UeMatrix3` | Sets this matrix as the normal matrix derived from a 4x4 matrix `m4`                        |
| `identity()`              | `UeMatrix3` | Resets this matrix to the identity matrix                                                   |
| `makeRotation(theta)`     | `UeMatrix3` | Sets this matrix as a 2D rotation matrix with angle `theta` (in radians)                     |
| `makeScale(x, y)`         | `UeMatrix3` | Sets this matrix as a 2D scale matrix                                                      |
| `makeTranslation(x, y)`   | `UeMatrix3` | Sets this matrix as a 2D translation matrix                                                |
| `multiply(m)`             | `UeMatrix3` | Multiplies this matrix by matrix `m` (this = this * m)                                     |
| `multiplyMatrices(a, b)`  | `UeMatrix3` | Sets this matrix as the product of matrices `a` and `b`                                    |
| `multiplyScalar(s)`       | `UeMatrix3` | Multiplies every element by scalar `s`                                                     |
| `rotate(theta)`           | `UeMatrix3` | Applies a rotation by `theta` radians to this matrix                                       |
| `scale(sx, sy)`           | `UeMatrix3` | Applies scaling factors `sx` and `sy` to this matrix                                       |
| `set(n11, n12, ..., n33)` | `UeMatrix3` | Sets all matrix elements explicitly                                                        |
| `premultiply(m)`          | `UeMatrix3` | Premultiplies this matrix by `m` (this = m * this)                                        |
| `setFromMatrix4(m4)`      | `UeMatrix3` | Sets this matrix from upper-left 3x3 part of 4x4 matrix `m4`                               |
| `setUvTransform(...)`     | `UeMatrix3` | Sets matrix to transform UV coordinates for textures                                      |
| `toArray(arr, offset)`    | `Array`     | Copies matrix elements into array starting at offset                                       |
| `translate(tx, ty)`       | `UeMatrix3` | Applies translation by `tx` and `ty`                                                      |
| `transpose()`             | `UeMatrix3` | Transposes the matrix                                                                     |
| `transposeIntoArray(arr)` | `UeMatrix3` | Writes the transposed matrix into given array                                             |


## Example
```js
var mat = new UeMatrix3();
var scale = new UeVector3(2, 3, 4);
mat.scaleByVec3(scale);
```
