---
sidebar_position: 1
---

The base class for all 3D entities in Unique Engine. Inherits from `UeTransform`, and acts as a hierarchical scene graph node.

### Constructor
```js
new UeObject3D(data = {})
```

### Parameters

| Key               | Type                      | Default     | Description                     |
| ----------------- | ------------------------- | ----------- | ------------------------------- |
| `name`            | `string`                  | `undefined` | Optional object name            |
| `visible`         | `boolean`                 | `true`      | Visibility flag                 |
| `parent`          | `UeObject3D`              | `undefined` | Parent object in the hierarchy  |
| `renderOrder`     | `number`                  | `0`         | Custom sort order for rendering |
| `position` / `x`  | `UeVector3` / `number`    | `0`         | Initial position                |
| `rotation` / `rx` | `UeQuaternion` / `number` | `0`         | Initial rotation                |
| `scale` / `sx`    | `UeVector3` / `number`    | `1`         | Initial scale                   |


### Properties
| Property      | Type         | Description                          |
| ------------- | ------------ | ------------------------------------ |
| `id`          | `number`     | Unique numeric ID                    |
| `uuid`        | `string`     | Randomly generated unique identifier |
| `name`        | `string`     | Optional human-readable name         |
| `visible`     | `boolean`    | Visibility flag                      |
| `parent`      | `UeObject3D` | Parent object in the scene graph     |
| `children`    | `array`      | Array of child objects               |
| `renderOrder` | `number`     | Overrides render sort when rendering |


### 🔁 Inherited from `UeTransform`

This class inherits all transformation logic, including:

- .position, .rotation, .scale
- .update(), .move(), .rotate(), .lookAt() etc.
- .matrix, .matrixWorld and update flags

## 🧩 Methods
```js
add(...objects)
```
Adds one or more child objects.

```js
remove(child)
```
Removes a specific child from this object.

```js
removeFromParent()
```
Removes this object from its parent.

```js
clear()
```
Recursively removes all children from this object.

```js
traverse(callback)
```
Executes a function on this object and all children (recursively).

```js
traverseVisible(callback)
```
Same as .traverse(), but skips invisible objects.

---

## 🧠 Notes

All 3D objects in the scene (meshes, groups, lights, etc.) extend `UeObject3D`

When building a scene graph, you can nest children arbitrarily using .add() and traverse them for rendering or updates.
