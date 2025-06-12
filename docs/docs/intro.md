---
sidebar_position: 1
---

import CubeDemo from '@site/static/img/cube.png';

# Getting Started

Welcome to **Unique Engine**, a modular 3D engine built for GameMaker and inspired by the power and design of Three.js.  
This guide will walk you through the first steps to get your 3D scene up and running in minutes.

---

## 🔧 Requirements

- GameMaker Studio 2 (latest LTS or IDE version recommended)

---

## 🧱 Project Structure

Your 3D scene will usually include:

- A `UeScene` object (holds all visible elements)
- A `UePerspectiveCamera` (defines the point of view)
- A `UeRenderer` (responsible for drawing)
- Meshes and materials
- Lights, etc..


## 📦 Installation

1. Clone or download the latest version of the Unique Engine from GitHub:  
   [https://github.com/manuel-di-iorio/unique-engine](https://github.com/manuel-di-iorio/unique-engine)

2. Import the `ue.yymps` file by dragging it into your GameMaker project.

3. Create an object and add it to your room.

4. Turn on "Enable viewports" in your room view settings

---

## 🚀 Your First Scene

Add this code in the create event of your object

```js
renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera();

cubeGeometry = new UeBoxGeometry({ color: c_blue });
cubeMesh = new UeMesh(cubeGeometry);

ambientLight = new UeAmbientLight();
dirLight = new UeDirectionalLight({ xt: -100, yt: -50, zt: -70 });

scene.add(cubeMesh, ambientLight, dirLight);
```
and this one in the draw Event, in order to render the scene:

```js
renderer.render(scene, camera);
```

Then run the game and you will see a nice cube!

<img src={CubeDemo} width="400" />
