---
sidebar_position: 3
---

# UePointLightShadow

`UePointLightShadow` manages shadows for `UePointLight` using a cube shadow map approach (6 faces). This implementation enables point lights to cast shadows in all directions.

## Overview

- Creates 6 `UePerspectiveCamera` instances with a 90° FOV (one per cube face).
- Generates a temporary surface atlas of 3x2 to render all faces in a single texture.
- Provides a unified `s_pointShadowMap` sampler for shaders to sample the atlas.
- Computes 6 `lightSpaceMatrix` (projection * view) matrices—one for each face.
- Provides methods to update cameras based on the light position and to change shadow map resolution.

## Implementation details (GameMaker)

Unique Engine uses a custom approach to handle point shadows in GameMaker. Instead of multiple render target switches, the engine renders all 6 faces into a single 3x2 atlas using temporary surfaces and then copies them to the final shadow map. This ensures compatibility and performance.

## Shader usage

The standard shader `sh_ue_standard` automatically handles point shadows if enabled. It uses the `u_uePointShadowEnabled` uniform and the `s_pointShadowMap` sampler. The distance-based shadow is calculated using the light position and the far/near planes.

## API

- `UePointLightShadow(data = {})` - Constructor.
  - `data.shadowNear` - Near plane distance for cameras (default 0.5).
  - `data.shadowFar` - Far plane distance for cameras (default 500).
  - `data.bias` - Bias to prevent shadow acne (default 0.05).
  - `data.normalBias` - Normal bias (default 0.02).

Key methods:

- `updateMapSize(width, height)` - Update resolution of all shadow maps.
- `updateCameras(lightPosition)` - Position all 6 cameras at the light's position and update matrices.
- `setRange(near, far)` - Set near/far for all cameras.
- `getTextures()` - Returns an array with the 6 shadow map textures.
- `dispose()` - Release resources.

## Best practices

- Use even resolutions (e.g. 512, 1024) for all faces to keep quality balanced.
- Keep `shadowFar` as small as possible to improve depth precision.
- Increase `bias` or `normalBias` if you experience shadow acne.

## Example

```gml
pointLight = new UePointLight(c_white, 1, 400);
pointLight.castShadow = true;
pointLight.position.set(0, 0, 50);
pointLight.shadow.updateMapSize(512, 512);
scene.add(pointLight);
```
