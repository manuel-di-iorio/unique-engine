---
sidebar_position: 3
---

# Creating and Using Meshes

Meshes are built from geometry classes (primitives), which define their vertex data. Each geometry can be reused across multiple meshes, and passed directly when creating a new mesh.

🔹 Example: Creating a circular terrain
```js
terrainGeometry = new UeCircleGeometry(500);
terrain = new UeMesh(terrainGeometry, new UeMeshStandardMaterial(), { z: 50 });
// The third argument is an optional struct of properties to apply to the mesh (such as position, rotation, etc.).
```

## 🧱 Available Geometry Primitives

**These are the built-in geometry types available:**

- UeBoxGeometry
- UeLineGeometry
- UeLineSegmentsGeometry
- UePlaneGeometry
- UeCircleGeometry
- UeSphereGeometry
- UePyramidGeometry
- UeConeGeometry
- UeCylinderGeometry
- UeArrowGeometry
- UeTorusGeometry

You can instantiate them with relevant parameters (e.g., radius, width, height), and they automatically generate the vertex buffers needed for rendering.

## 🛠️ Creating Custom Geometry

If you want full control, create a `UeGeometry` with a custom `UeVertexFormat`. In this example, we are going to create a triangle geometry:

**Step 1: Define Vertex Format (optional)**
```js
var format = new UeVertexFormat().position().normal().uv().color().build();
```

**Step 2: Create Geometry**
```js
var position = [
    -0.5, -0.5, 0,
     0.5, -0.5, 0,
     0.0,  0.5, 0
];

var normal = [
    0, 0, 1,
    0, 0, 1,
    0, 0, 1
];

var uv = [
    0, 0,
    1, 0,
    0.5, 1
];

var color = [
    c_white, 1,
    c_white, 1,
    c_white, 1
];

var geometry = new UeGeometry({ position, normal, uv, color, format });
```
🧠 The geometries also support custom attributes defined in the format by passing them as flat arrays.

## 🎨 Adding a Material

**You can assign a material to the mesh by including it in the creation properties:**

```js
var material = new UeMaterial({
  color: make_color_rgb(200, 200, 255),
  transparent: true
});

var sphere = new UeMesh(new UeSphereGeometry(), material, { 
  position: vec3_create(0, 0, 0) 
});
```

✅ Note: You can still modify the mesh's transform, material, or geometry after creation if needed.

<!-- ## 💾 Exporting and Importing Meshes

Importing a model from a buffer is extremely fast, compared to load it with an OBJLoader or AssimpLoader.

Usually you will import all meshes from buffers that you will place in the "Included files" of your game, at the start of your game, or eg. before of a level, in order to reduce loading times.

**This is useful for:**

- Reduce load times when loading large external models (.obj, .3ds, etc..)
- Saving procedural geometries
- Caching expensive computations
- Sharing custom assets between scenes or sessions 

```js
buffer = myMesh.export();   // Serializes data
new UeMesh().import(buffer);  // Loads mesh from buffer
```
📌 Tip: You can use buffer_save() and buffer_load() in combination to persist data between sessions.

The exported buffer will contain data about the geometry, mesh's children, local and world matrix, used material, etc.. -->
