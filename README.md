# Unique Engine

Unique Engine is a modular and flexible 3D library, inspired by Three.js, designed to make it easy to create 3D games and interactive applications.
The goal is to offer a simple, accessible and powerful API, while maintaining a clear and easily extensible structure.

---

## Current Features ✅

- **Camera**
Manages 3D projection and automatically connects to the view.

- **Renderer**
Draws meshes with independent ordering of opaque and transparent materials. Manages passing light data to shaders.

- **Mesh**
Recursive rendering of children, updating matrices only if necessary. Rotations in degrees, with internal conversion to quaternions.

- **Lights**
Basic support for Ambient, Point and Directional lights via custom shaders.

- **Materials & Textures**
Automatic management of uniforms and samplers, including integration with lights.

- **VertexFormat**
Easy and flexible creation of vertex formats, e.g.:
`new VertexFormat().position().normal().uv().color().build()`

- **Geometry**
Separated from the mesh, with vertex buffer and index automatically created based on the format.

- **Math Utilities**
Vectors, matrices, quaternions, planes and raycasting: `Vec2`, `Vec3`, `Mat3`, `Mat4`, `Quaternion`, `Plane`, `Raycast`.

- **OrbitControls**
Addon for interactive drag, pan, rotate and zoom of the camera.

- **Import models (demo)**
Support via AssimpDLL by Jak (not included in the library for licensing reasons).

---

## Basic example:

```gml
renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera();

cubeGeometry = new UeBoxGeometry({ color: c_blue });
cubeMesh = new UeMesh(cubeGeometry);

ambientLight = new UeAmbientLight();
dirLight = new UeDirectionalLight({ xt: -100, yt: -50, zt: -70 });

scene.add(cubeMesh, ambientLight, dirLight);
```

---

## Trello board:

https://trello.com/b/NYfgFbd8/unique-engine

---

### Contribute

The project is open source and open to contributions!
Report bugs, feature requests or open a pull request on [GitHub](https://github.com/manuel-di-iorio/unique-engine/issues).

### License

[MIT License](LICENSE.md)

Other bundled software, such as Assimp or the included 3d models, are copyrighted by their respective creators and may come with additional usage restrictions. The included extension "GMAssimp.dll", which the engine uses internally to import external models, has been created by Giacomo "Jak" Marton and it is MIT-licensed.
These components are not required to use the engine — if you prefer to avoid any third-party licensing terms, simply remove the AssimpLoader and the included 3d models from the project's datafiles.

Links to the free 3D models used in the examples:
- https://free3d.com/3d-model/airplane-v2--659376.html
- https://free3d.com/3d-model/cat-v1--522281.html

### Useful Links

- [Documentation](https://manuel-diiorio.github.io/unique-engine/docs)
- [Game Maker Official Website](https://gamemaker.io)
- [Game Maker Italia Community](https://gamemakeritalia.it)
