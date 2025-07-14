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
| `multiply(m)`                        | `this`      | Multiplies this matrix by `m`                                 |
| `multiplyMatrices(a, b)`             | `this`      | Multiplies matrices `a * b`                                   |
| `premultiply(m)`                     | `this`      | Pre-multiplies this matrix by `m`                             |
| `multiplyScalar(s)`                  | `this`      | Multiplies every component by a scalar                        |
| `compose(pos, rot, scl)`             | `this`      | Composes a matrix from position, quaternion and scale         |
| `decompose(p, q, s)`                 | `this`      | Decomposes matrix into position, quaternion, and scale        |
| `copy(m)`                            | `this`      | Copies all elements from `m`                                  |
| `copyPosition(m)`                    | `this`      | Copies only the translation part from `m`                     |
| `determinant()`                      | `number`    | Returns the matrix determinant                                |
| `invert()`                           | `this`      | Inverts the matrix                                            |
| `equals(m)`                          | `boolean`   | Compares matrices for equality                                |
| `extractBasis(x, y, z)`              | `this`      | Extracts basis vectors from matrix                            |
| `extractRotation(m)`                 | `this`      | Extracts rotation removing scale                              |
| `identity()`                         | `this`      | Resets to identity matrix                                     |
| `lookAt(eye, tgt, up)`               | `this`      | Builds a lookAt view matrix                                   |
| `makeRotationAxis(a, θ)`             | `this`      | Builds rotation matrix from axis-angle                        |
| `makeRotationFromQuaternion(q)`      | `this`      | Builds rotation matrix from quaternion                        |
| `makeScale(x, y, z)`                 | `this`      | Builds a scaling matrix                                       |
| `makeTranslation(x, y, z)`           | `this`      | Builds a translation matrix                                   |
| `makePerspective(l, r, t, b, n, f)`  | `this`      | Builds a perspective projection matrix                        |
| `makeOrthographic(l, r, t, b, n, f)` | `this`      | Builds an orthographic projection matrix                      |
| `fromArray(arr, offset)`             | `this`      | Loads data from an array                                      |
| `toArray(arr?, offset)`              | `number[]`  | Exports data to array                                         |
| `transpose()`                        | `this`      | Transposes the matrix                                         |
| `getMaxScaleOnAxis()`                | `number`    | Returns the largest scale among all axes                      |
| `applyToVector3(vec)`                | `UeVector3` | Applies matrix to a vector (as a position, w=1)               |
| `scale(vec)`                         | `this`      | Scales matrix per vector component                            |
| `set(...values)`                     | `this`      | Sets all 16 values (row-major input, internally converted)    |
| `setPosition(vec)`                   | `this`      | Sets position component (x, y, z) from a vector               |
| `setPositionXYZ(x, y, z)`            | `this`      | Sets position from individual components                      |
| `makeBasis(x, y, z)`                 | `this`      | Builds a matrix from 3 orthogonal vectors                     |
| `makeRotationFromEuler(x, y, z)`     | `this`      | Builds rotation matrix from Euler angles (XYZ order, degrees) |
| `makeRotationX(theta)`               | `this`      | Builds a matrix for rotation around X axis                    |
| `makeRotationY(theta)`               | `this`      | Builds a matrix for rotation around Y axis                    |
| `makeRotationZ(theta)`               | `this`      | Builds a matrix for rotation around Z axis                    |
| `makeShear(xy, xz, yx, yz, zx, zy)`  | `this`      | Builds a shear matrix                                         |
