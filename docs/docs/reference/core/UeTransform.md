---
sidebar_position: 1
---

# UeTransform

The base class for all objects that have a position, rotation, and scale in 3D space. It handles the hierarchical scene graph and matrix transformations.

### Constructor
```js
new UeTransform(data = {})
```

> Inherits from [UeEventDispatcher](./UeEventDispatcher.md)

### Data parameters

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `position` | `vec3` | `[0,0,0]` | Local position vector |
| `rotation` | `quat` | `[0,0,0,1]` | Local rotation quaternion |
| `scale` | `vec3` | `[1,1,1]` | Local scale vector |
| `up` | `vec3` | `[0,0,-1]` | Local up direction |
| `matrixAutoUpdate` | `boolean` | `true` | Automatically update local matrix |
| `matrixWorldAutoUpdate` | `boolean` | `true` | Automatically update world matrix |

### Properties

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `position` | `vec3` | `[0,0,0]` | Local position vector |
| `rotation` | `quat` | `[0,0,0,1]` | Local rotation quaternion |
| `scale` | `vec3` | `[1,1,1]` | Local scale vector |
| `up` | `vec3` | `global.UE_DEFAULT_UP` | Local up direction |
| `matrix` | `mat4` | | Local transformation matrix |
| `matrixWorld` | `mat4` | | World transformation matrix |
| `version` | `number` | `0` | Increments whenever the world matrix is updated. Used for performance tracking. |
| `parent` | `UeTransform` | `undefined` | Parent transform |
| `children` | `array` | `[]` | Child transforms |
| `matrixAutoUpdate` | `boolean` | `true` | If true, recomputes local matrix every frame if needed |
| `matrixWorldAutoUpdate` | `boolean` | `true` | If true, recomputes world matrix every frame if needed |
| `matrixWorldNeedsUpdate` | `boolean` | `false` | Flag indicating world matrix needs recomputation |

## 🧩 Methods

#### Matrix Updates

```js
updateMatrix()
```
Recomputes the local matrix from position, rotation, and scale.

```js
updateMatrixWorld(force = false)
```
Updates the world matrix of this object and its children.

```js
updateWorldMatrix(updateParents = false, updateChildren = false)
```
Updates world matrices with optional parent or child propagation.

```js
forceUpdate(startFromRoot = false)
```
Forces an update of the local and world matrices on this object and its children. Also static objects will be updated. If `startFromRoot` is true, the update starts from the absolute root object.

#### Translation

```js
setPosition(x, y, z)
```
Sets the local position.

```js
translateX(value)
translateY(value)
translateZ(value)
```
Translates along the local X, Y, or Z axis.

```js
translateOnAxis(axis, distance)
```
Translates the object by distance along a specific axis in local space.

```js
translate(x, y, z)
```
Translates the object in local space by the given amounts.

#### Rotation

```js
lookAt(x, y, z)
lookAtVec(target)
```
Rotates the object to face a target position or vector.

```js
setRotation(x, y, z)
```
Sets rotation from Euler angles (in degrees).

```js
setRotationFromMatrix(mat)
```
Sets rotation from a rotation matrix.

```js
setRotationFromQuaternion(quat)
```
Copies a quaternion into the rotation property.

```js
rotate(x, y, z)
```
Applies an Euler rotation increment.

```js
rotateX(angle)
rotateY(angle)
rotateZ(angle)
```
Rotates around the local X, Y, or Z axis by the given angle (in degrees).

```js
rotateOnAxis(axis, angle)
```
Rotates around a specific axis in local space.

```js
rotateOnWorldAxis(axis, angle)
```
Rotates around a specific axis in world space.

#### Scale

```js
setScale(x, y, z)
```
Sets the local scale.

```js
scaleX(value)
scaleY(value)
scaleZ(value)
```
Increments the scale on the X, Y, or Z axis.

#### Transformation

```js
applyMatrix4(mat4)
```
Applies a matrix transformation to the object.

```js
applyQuaternion(quat)
```
Applies a quaternion rotation to the object.

```js
getWorldPosition(target = undefined)
```
Returns the world position of the object. If `target` is provided, the result is stored in it; otherwise, a new array is returned.

```js
getWorldQuaternion(target = undefined)
```
Returns the world rotation quaternion. If `target` is provided, the result is stored in it; otherwise, a new array is returned.

```js
getWorldScale(target = undefined)
```
Returns the world scale. If `target` is provided, the result is stored in it; otherwise, a new array is returned.

```js
getWorldDirection(target = undefined)
```
Returns a vector representing the world direction the object is facing (based on the `up` property). If `target` is provided, the result is stored in it; otherwise, a new array is returned.

```js
localToWorld(vector)
```
Converts a vector from local space to world space.

```js
worldToLocal(vector)
```
Converts a vector from world space to local space.
