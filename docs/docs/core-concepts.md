---
sidebar_position: 2
---

# Core Concepts

Unique Engine is built around a clear and modular architecture. Before diving deeper, it's important to understand the main building blocks of the engine.

---

## 🧩 Object3D

`UeObject3D` is the base class for all 3D elements in the scene, meshes, lights, and even the camera.  
It supports hierarchical parenting, transformation, and visibility.



> Tip: All transforms are automatically updated only when needed, improving performance.

---

## 🖼️ Scene

The scene acts as the root container for your 3D world. You add all objects, meshes, lights, etc. to the scene.

```js
scene = new UeScene();
scene.add(myMesh);
scene.add(myLight);
```

## 🎥 PerspectiveCamera
The camera defines how your 3D scene is projected to the 2D screen.
Unique Engine includes a default perspective camera.

You place the camera in 3D space like any other object:

```js
camera = new UePerspectiveCamera();
camera.move(0, 5, 10);
```
You don't need to manually handle GameMaker’s built-in view system, the engine integrates the camera automatically.

### Field of View & Clipping
By default, the camera has:

- FOV: 60 degrees
- Near plane: 0.1
- Far plane: 32000

The camera is a Object3D, so you can move or rotate it like any other object.

## 🖌️ Renderer
The renderer is responsible for drawing the scene. It does:

- Recursively traverses the scene graph
- Sorts opaque and transparent objects independently
- Passing light data to shaders
- Updates world matrices only when necessary
- Calls the render function for each visible mesh

```js
renderer = new UeRenderer();

// Per-frame rendering:
renderer.render(scene, camera);
```

## 💡 Light
Lights bring depth and realism to the scene. Currently supported types:

- Ambient (default): global illumination

- Point: light with position

- Directional: light with direction (e.g. sun)

Example:

```js
light = new UeDirectionalLight();
light.move(5, 10, 5);
scene.add(light);
```
Lights automatically inject their data into shaders when the material support them, no manual uniform handling needed.
