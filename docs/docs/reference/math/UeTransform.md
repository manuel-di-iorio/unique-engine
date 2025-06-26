---
sidebar_position: 1
---

A `UeTransform` represents an object's position, rotation, and scale in 3D space. It handles local and world transformation matrices, and offers methods to manipulate transforms programmatically.

---

## Constructor

```js
new UeTransform(data = {})
```

### Parameters

| Name       | Type           | Default        | Description                  |
| ---------- | -------------- | -------------- | ---------------------------- |
| `position` | `UeVector3`    | `(x, y, z)`    | Local position of the object |
| `rotation` | `UeQuaternion` | `(rx, ry, rz)` | Local rotation as quaternion |
| `scale`    | `UeVector3`    | `(1, 1, 1)`    | Local scale vector           |
| `parent`   | `UeObject3D`   | `undefined`    | Optional parent object       |

### Properties

| Property                 | Type           | Default     | Description                                  |
| ------------------------ | -------------- | ----------- | -------------------------------------------- |
| `position`               | `UeVector3`    | `(0, 0, 0)` | Local position vector                        |
| `rotation`               | `UeQuaternion` | `(0, 0, 0)` | Local rotation as quaternion                 |
| `scale`                  | `UeVector3`    | `(1, 1, 1)` | Local scale vector                           |
| `up`                     | `UeVector3`    | `(0, 1, 0)` | World up direction used in `lookAt()`        |
| `matrix`                 | `UeMatrix4`    | —           | Local transformation matrix                  |
| `matrixWorld`            | `UeMatrix4`    | —           | World transformation matrix                  |
| `parent`                 | `UeObject3D`   | `undefined` | Parent in transform hierarchy                |
| `matrixAutoUpdate`       | `boolean`      | `true`      | Whether to automatically update local matrix |
| `matrixWorldAutoUpdate`  | `boolean`      | `true`      | Whether to auto-update world matrix          |
| `matrixNeedsUpdate`      | `boolean`      | `false`     | Forces local matrix update                   |
| `matrixWorldNeedsUpdate` | `boolean`      | `false`     | Forces world matrix update                   |

## Methods

**Matrix Updates**

| Method                                 | Description                                       |
| -------------------------------------- | ------------------------------------------------- |
| `update()`                             | Updates both local and world matrices recursively |
| `updateMatrix()`                       | Rebuilds the local transform matrix               |
| `updateMatrixWorld()`                  | Computes world matrix from parent                 |
| `updateWorldMatrix(parents, children)` | Updates matrices optionally recursively           |

**Translation**

| Method                 | Description                       |
| ---------------------- | --------------------------------- |
| `setPosition(x, y, z)` | Set absolute position             |
| `translate(x, y, z)`   | Translate relative to current pos |
| `translateX(v)`        | Translate along X axis            |
| `translateY(v)`        | Translate along Y axis            |
| `translateZ(v)`        | Translate along Z axis            |

**Rotation**

| Method                 | Description                                |
| ---------------------- | ------------------------------------------ |
| `setRotation(x, y, z)` | Sets rotation using Euler angles           |
| `rotate(x, y, z)`      | Rotates using a delta quaternion           |
| `rotateX(v)`           | Rotates around local X axis                |
| `rotateY(v)`           | Rotates around local Y axis                |
| `rotateZ(v)`           | Rotates around local Z axis                |
| `lookAt(x, y, z)`      | Rotates to face a world position           |
| `lookAtVec(vec3)`      | Same as `lookAt()` but takes a `UeVector3` |


**Scaling**

| Method              | Description               |
| ------------------- | ------------------------- |
| `setScale(x, y, z)` | Set absolute scale        |
| `scaleX(v)`         | Modify scale along X axis |
| `scaleY(v)`         | Modify scale along Y axis |
| `scaleZ(v)`         | Modify scale along Z axis |

## 💡 Example
```js
const obj = new UeObject3D();
obj.setPosition(10, 0, 0);
obj.rotateY(45);
obj.scaleZ(2);
```
