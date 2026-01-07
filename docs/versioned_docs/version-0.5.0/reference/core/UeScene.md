---
sidebar_position: 5
title: UeScene
---

The `UeScene` class represents the root node of a 3D scene in Unique Engine. It inherits from `UeObject3D` and manages fog settings, material overrides, and the hierarchy of objects to be rendered.

### Constructor
```js
new UeScene(data = {})
```

> Inherits from [UeObject3D](./UeObject3D.md)

### Data parameters

| Key                | Type             | Default     | Description                                         |
| ------------------ | ---------------- | ----------- | --------------------------------------------------- |
| `fog`              | `struct`         | (see below) | Fog configuration struct                            |
| `overrideMaterial` | `UeMaterial`     | `undefined` | Forces all objects in the scene to use this material |

### Properties

| Property           | Type             | Default     | Description                                         |
| ------------------ | ---------------- | ----------- | --------------------------------------------------- |
| `isScene`          | `boolean`        | `true`      | Indicates that this is a scene                      |
| `type`             | `string`         | `"Scene"`   | Object type identifier                              |
| `fog`              | `struct`         | `{...}`     | Fog settings for the scene                          |
| `overrideMaterial` | `UeMaterial`     | `undefined` | If set, overrides materials of all children          |

#### Fog Configuration Struct
The `fog` property is a struct with the following fields:

| Field     | Type      | Default           | Description                               |
| --------- | --------- | ----------------- | ----------------------------------------- |
| `enabled` | `boolean` | `false`           | Whether fog is active                     |
| `color`   | `array`   | `[0.5, 0.5, 0.5]` | RGB fog color                             |
| `density` | `number`  | `0`               | Exponential fog density                   |
| `near`    | `number`  | `1`               | Linear fog start distance                 |
| `far`     | `number`  | `1000`            | Linear fog end distance                   |

## 🧩 Methods

```js
toJSON()
```
Returns a JSON-compatible representation of the scene, including recursive serialization of model instances.

```js
fromJSON(data, objectsByUUID)
```
Loads scene data from a JSON object. `objectsByUUID` is an optional lookup table to link existing objects.

```js
clone(recursive = true)
```
Returns a clone of the scene. If `recursive` is true, it also clones all children.

## 🧠 Notes

- You can build your scene tree using `.add()` to nest meshes, lights, or other objects.
- `overrideMaterial` is useful for effects like depth-prepass or selecting all objects with a single material.

## Example

```js
const scene = new UeScene();

// Setup Fog
scene.fog.enabled = true;
scene.fog.color = [0.1, 0.1, 0.1];
scene.fog.near = 100;
scene.fog.far = 2000;

const light = new UeDirectionalLight(c_white, { x: 100 });
const material = new UeMeshStandardMaterial();
const mesh = new UeMesh(new UeBoxGeometry(), material);

scene.add(light, mesh);
```
