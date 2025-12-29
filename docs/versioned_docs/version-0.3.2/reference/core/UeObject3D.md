---
sidebar_position: 0
---

The base class for all 3D entities in Unique Engine. Inherits from `UeTransform`, and acts as a hierarchical scene graph node.

### Constructor
```js
new UeObject3D(data = {})
```

> Inherits from [UeTransform](./UeTransform.md)

### Data parameters

| Key               | Type                      | Default     | Description                     |
| ----------------- | ------------------------- | ----------- | ------------------------------- |
| `name`            | `string`                  | `""`        | Optional object name            |
| `visible`         | `boolean`                 | `true`      | Visibility flag                 |
| `parent`          | `UeObject3D`              | `undefined` | Parent object in the hierarchy  |
| `renderOrder`     | `number`                  | `0`         | Custom sort order for rendering |
| `castShadow`      | `boolean`                 | `false`     | Whether this object casts shadows |
| `receiveShadow`   | `boolean`                 | `false`     | Whether this object receives shadows |

### Properties

| Property      | Type         | Default          |  Description                                     |
| ------------- | ------------ | ---------        | ---------------------------                      |
| `isObject3D`  | `boolean`    | true             | Indicates that this is an Object3D               |
| `type`        | `string`     | `"Object3D"`     | Object type                                      |
| `id`          | `number`     | (auto-generated) | Incremental object ID                            |
| `uuid`        | `string`     | (auto-generated) | Randomly generated unique identifier             |
| `name`        | `string`     | ""               | Optional object name                             |
| `visible`     | `boolean`    | true             | Visibility flag                                  |
| `parent`      | `UeObject3D` | undefined        | Parent object in the scene graph                 |
| `children`    | `array`      | []               | Array of child objects                           |
| `renderOrder` | `number`     | 0                | Overrides render sort when rendering             |
| `layers`      | `UeLayers`   |                  | Layers with membership set to layer 0 by default |
| `userData`    | `struct`     | {}               | A struct where to safely place custom related data for this entity |
| `onBeforeRender` | `method`  | void method      | Function called before rendering this object |
| `onAfterRender`  | `method`  | void method      | Function called after rendering this object  |
| `onBeforeShadow` | `method`  | void method      | Function called before rendering this object to shadow map |
| `onAfterShadow`  | `method`  | void method      | Function called after rendering this object to shadow map |
| `frustumCulled`  | `boolean` | `true`           | If true, only renders this object if within the camera frustum. Geometry needs to have a bounding sphere, otherwise the test will be skipped and the object will always be rendered |
| `castShadow`     | `boolean` | `false`          | If true, this object will cast shadows when shadow mapping is enabled |
| `receiveShadow`  | `boolean` | `false`          | If true, this object will receive shadows from shadow-casting lights |
| `object`         | `UeObject3D` | `undefined`     | Reference to the original object (if this is an instance). |
| `instances`      | `UeInstanceList` |        | List of instances created from this object. |
| `isInstance`     | `boolean`    | `false`         | Flag indicating if this object is an instance of another object. |


### 🔁 Inherited from `UeTransform`

This class inherits all transformation logic, including:

- .position, .rotation, .scale
- .setPosition(), .rotate(), .lookAt() etc.
- .matrix, .matrixWorld and update flags

## 🧩 Methods
```js
add(...objects)
```
Adds one or more child objects. Accepts individual objects as arguments or an array of objects.

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
clone()
```
Returns a deep clone of this object.

```js
traverse(callback)
```
Executes a function on this object and all children (recursively).

```js
traverseVisible(callback)
```
Same as .traverse(), but skips invisible objects.

```js
traverseAncestors(callback)
```
Executes a callback function on this object’s ancestors, from immediate parent up to the root. Useful for parent hierarchy inspection.

```js
attach(child)
```
Adds child to this object while preserving the child’s world transform. Does not support non-uniformly scaled parents.

```js
copy(source, recursive = true)
```
Copies properties from another UeObject3D. If recursive is true, also clones and adds the source’s children.

```js
getObjectById(targetId)
```
Searches for and returns the first object with a matching .id in the entire hierarchy.

```js
getObjectByName(name)
```
Searches for and returns the first object with a matching .name. Names are empty by default unless set manually.

```js
getObjectByProperty(name, value)
```
Searches for and returns the first object in the hierarchy where object[name] === value.

```js
getObjectsByProperty(name, value, optionalTarget = [])`
```
Same as getObjectByProperty, but collects all matching objects in the hierarchy. Optional array target can be passed for reuse.

```js
traverseChildren(callback)
```
Executes the callback on all children of this object (not on the object itself).

```js
traverseInstances(callback)
```
Executes the callback on all instances of this object.

---

## Events
The following events are automatically dispatched by `UeObject3D`:
- `added` – emitted on a child when it is added to a parent via `.add(), .attach()`.
- `childAdded` – emitted on the parent when a child is added via `.add()`, `.attach()`.
- `removed` – emitted on a child when it is removed from its parent via `.clear(), .remove(), .removeFromParent()`.
- `childRemoved` – emitted on the parent when a child is removed via `.clear(), .remove(), .removeFromParent()`.

## 🧠 Notes

All 3D objects in the scene (meshes, groups, lights, etc.) extend `UeObject3D`

When building a scene graph, you can nest children arbitrarily using .add() and traverse them for rendering or updates.

## Globals

`UE_OBJECT3D_DEFAULT_UP = new UeVector3(0, 0, -1)`   Default up vector for objects (applied on the `up` property)

`UE_OBJECT3D_DEFAULT_MATRIX_AUTO_UPDATE = true`   Default value for all new created objects

`UE_OBJECT3D_DEFAULT_MATRIX_WORLD_AUTO_UPDATE = true`   Default value for all new created objects
