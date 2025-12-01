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

## 🎥 Cameras
Unique Engine provides two types of cameras to project your 3D scene to the 2D screen:

### Perspective Camera
The most common camera type, mimicking how human eyes perceive depth. Objects farther away appear smaller.

```js
camera = new UePerspectiveCamera();
camera.setPosition(0, 5, 10);
```

### Orthographic Camera
Objects maintain the same size regardless of distance. Perfect for 2D games, isometric views, or technical drawings.

```js
camera = new UeOrthographicCamera({
  left: -400, right: 400,
  top: 300, bottom: -300
});
camera.setPosition(0, 5, 10);
```

You don't need to manually handle GameMaker's view system - the engine integrates cameras automatically.

### Field of View & Clipping
By default, the perspective camera has:

- FOV: 60 degrees
- Near plane: 0.1
- Far plane: 2000

Cameras are `UeObject3D` instances, so you can move or rotate them like any other object.

## 🖌️ Renderer
The renderer is responsible for drawing the scene. It does:

- Recursively traverses the scene graph
- Sorts opaque and transparent objects independently
- Passing light data to shaders
- Updates world matrices only where necessary
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
light = new UeDirectionalLight(45, 45);
scene.add(light);
```
Lights automatically inject their data into shaders when the material support them, no manual uniform handling needed.
