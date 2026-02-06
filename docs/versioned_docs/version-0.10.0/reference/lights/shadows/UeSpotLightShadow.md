---
sidebar_position: 4
---

# UeSpotLightShadow

`UeSpotLightShadow` manages shadows for `UeSpotLight` using a single perspective camera approach. Since spot lights emit light in a cone, a single perspective camera is sufficient to cover the illuminated area.

## Overview

- Uses a single `UePerspectiveCamera` to render the shadow map.
- The camera's Field of View (FOV) is automatically synchronized with the `UeSpotLight` angle.
- Generates a depth texture used by shaders for shadow calculation.
- Computes a `lightSpaceMatrix` (projection * view) used for vertex transformation in the shadow pass.
- Automatically updates its matrices when the light moves or changes its target/angle.

## Shader usage

The standard shader `sh_ue_standard` automatically handles spot shadows if enabled. It uses the `u_ueSpotShadowEnabled` uniform, the `u_ueSpotShadowMatrix` uniform, and the `s_spotShadowMap` sampler.

## API

- `UeSpotLightShadow(data = {})` - Constructor.
  - `data.shadowNear` - Near plane distance for the camera (default 0.5).
  - `data.shadowFar` - Far plane distance for the camera (default 500).
  - `data.mapSize` - Struct with `width` and `height` for the shadow map (default 512x512).

Key methods:

- `updateMatrices(light)` - Updates the internal camera and shadow matrix based on the provided light's properties.
- `dispose()` - Release resources.

## Example

```gml
spotLight = new UeSpotLight(c_white, 1, 600, degtorad(45));
spotLight.castShadow = true;
spotLight.position.set(0, 200, 0);
spotLight.target.position.set(0, 0, 0);
scene.add(spotLight);
```
