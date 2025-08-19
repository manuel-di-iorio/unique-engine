---
sidebar_position: 5
---

A 4x4 matrix class used for 3D transformations such as translation, rotation, scaling, and projection. Operates in column-major order, compatible with GameMaker's internal matrix format.

---

## Constructor

```js
new UeMatrix4(data)
```

### Data parameters

| Name   | Type       | Default                       | Description                       |
| ------ | ---------- | ----------------------------- | --------------------------------- |
| `data` | `number[]` | `matrix_build_identity()`     | Optional column-major matrix data |

## Methods

| Method                               | Returns     | Description                                                   |
| ------------------------------------ | ----------- | ------------------------------------------------------------- |
| `clone()`                            | `UeMatrix4` | Returns a deep copy of this matrix                            |
| `multiply(m)`                        | `self`      | Multiplies this matrix by `m`                                 |
| `multiplyMatrices(a, b)`             | `self`      | Multiplies matrices `a * b`                                   |
| `premultiply(m)`                     | `self`      | Pre-multiplies this matrix by `m`                             |
| `multiplyScalar(s)`                  | `self`      | Multiplies every component by a scalar                        |
| `compose(pos, rot, scl)`             | `self`      | Composes a matrix from position, quaternion and scale         |
| `decompose(p, q, s)`                 | `self`      | Decomposes matrix into position, quaternion, and scale        |
| `copy(m)`                            | `self`      | Copies all elements from `m`                                  |
| `copyPosition(m)`                    | `self`      | Copies only the translation part from `m`                     |
| `determinant()`                      | `number`    | Returns the matrix determinant                                |
| `invert()`                           | `self`      | Inverts the matrix                                            |
| `equals(m)`                          | `boolean`   | Compares matrices for equality                                |
| `extractBasis(x, y, z)`              | `self`      | Extracts basis vectors from matrix                            |
| `extractRotation(m)`                 | `self`      | Extracts rotation removing scale                              |
| `identity()`                         | `self`      | Resets to identity matrix                                     |
| `lookAt(eye, tgt, up)`               | `self`      | Builds a lookAt view matrix                                   |
| `makeRotationAxis(a, θ)`             | `self`      | Builds rotation matrix from axis-angle                        |
| `makeRotationFromQuaternion(q)`      | `self`      | Builds rotation matrix from quaternion                        |
| `makeScale(x, y, z)`                 | `self`      | Builds a scaling matrix                                       |
| `makeTranslation(x, y, z)`           | `self`      | Builds a translation matrix                                   |
| `makePerspective(left, right, top, bottom, near, far)`  | `self`      | Builds a perspective projection matrix                        |
| `makeOrthographic(left, right, top, bottom, near, far)` | `self`      | Builds an orthographic projection matrix                      |
| `fromArray(arr, offset)`             | `self`      | Loads data from an array                                      |
| `toArray(arr, offset)`               | `number[]`  | Exports data to array                                         |
| `transpose()`                        | `self`      | Transposes the matrix                                         |
| `getMaxScaleOnAxis()`                | `number`    | Returns the largest scale among all axes                      |
| `applyToVector3(vec)`                | `UeVector3` | Applies matrix to a vector (as a position, w=1)               |
| `scale(vec)`                         | `self`      | Scales matrix per vector component                            |
| `scaleXYZ(x, y, z)`                  | `self`      | Scales matrix per XYZ components                              |
| `set(...values)`                     | `self`      | Sets all 16 values (row-major input, internally converted)    |
| `setPosition(vec)`                   | `self`      | Sets position component (x, y, z) from a vector               |
| `setPositionXYZ(x, y, z)`            | `self`      | Sets position from individual components                      |
| `makeBasis(x, y, z)`                 | `self`      | Builds a matrix from 3 orthogonal vectors                     |
| `makeRotationFromEuler(x, y, z)`     | `self`      | Builds rotation matrix from Euler angles (XYZ order, degrees) |
| `makeRotationX(theta)`               | `self`      | Builds a matrix for rotation around X axis                    |
| `makeRotationY(theta)`               | `self`      | Builds a matrix for rotation around Y axis                    |
| `makeRotationZ(theta)`               | `self`      | Builds a matrix for rotation around Z axis                    |
| `makeShear(xy, xz, yx, yz, zx, zy)`  | `self`      | Builds a shear matrix                                         |
