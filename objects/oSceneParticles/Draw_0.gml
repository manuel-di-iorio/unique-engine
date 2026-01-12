//renderer.render(scene, camera);
//
//// Bridge Unique Engine state to Agnostic Particle Renderer
//var _depthTex = global[$ "UE_RENDERER_DEPTH_TEXTURE"]; 
//
//// Find main directional light shadow for particle self-shadowing
//var _shadowConfig = undefined;
//if (variable_global_exists("UE_RENDERER_LIGHT_STATE")) {
   //// Access global light state directly (Integration layer)
   //var _dirLights = global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.DIRECTIONAL];
   //var _dirCount = global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.DIRECTIONAL_COUNT];
   //
   //if (_dirCount > 0) {
      //var _light = _dirLights[0];
      //// Verify light has shadow map
      //if (_light != undefined && _light.castShadow && variable_struct_exists(_light, "shadow")) {
          //if (surface_exists(_light.shadow.map.surface)) {
              //_shadowConfig = {
                  //texture: _light.shadow.map.getTexture(),
                  //matrix: _light.shadow.lightSpaceMatrix
              //};
          //}
      //}
   //}
//}
//
//// Render Particles
//fireSystem.render(particleRenderer, camera, -1, _depthTex, _shadowConfig);
//smokeSystem.render(particleRenderer, camera, -1, _depthTex, _shadowConfig);
