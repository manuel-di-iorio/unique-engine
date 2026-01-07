---
sidebar_position: 10
---

# UeInstanceList

A helper class to manage instances of a `UeObject3D`. It allows for efficient rendering and management of multiple objects that share the same geometry and material.

### Constructor
```js
new UeInstanceList(owner)
```
- `owner`: The `UeObject3D` that owns this list of instances.

### Properties

| Property | Type | Description |
| --- | --- | --- |
| `owner` | `UeObject3D` | The object that owns this list. |
| `list` | `array` | The array containing all instance objects. |

### Methods

```js
add(instance)
```
Adds an instance to the list.

```js
remove(instance)
```
Removes an instance from the list.

```js
clear()
```
Removes all instances from the list.

```js
traverseInstances(callback)
```
Executes the callback function for each instance in the list.
