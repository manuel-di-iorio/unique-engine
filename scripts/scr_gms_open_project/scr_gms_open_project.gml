/**
* Load project
*/
function scr_gms_open_project() {
	var yyp = scr_load_json_from_file(projectYypPath, true);
	projectYyp = yyp.json;
	projectHash = yyp.hash; // This is used to check if the project has been modified
	var pos = string_last_pos("\\", projectYypPath);
	var projectPath = string_copy(projectYypPath, 1, pos); // Includes the latest slash
	var projectName = string_copy(projectYypPath, pos+1, string_length(projectYypPath)-pos+1);
		
	// Unload the current resources
	for (var i=0, l=array_length(projectModels); i<l; i++) {
		var model = projectModels[@ i];
		
		for (var a=0, al=array_length(model.meshes); a<al; a++) {
			var mesh = model.meshes[@ a];
			vertex_delete_buffer(mesh.vbuff);
			if (mesh.sprite != -1) sprite_delete(mesh.sprite);
		}
	}
	
	// Decode the new resources
	projectChanges = [];
	projectModels = [];
	projectCameras = [];
	projectAudioSources = [];
	projectLights = [];
	projectRooms = [];

	var resources = projectYyp.resources;
	for (var i=0, l=array_length(resources); i<l; i++) {
		var resource = resources[@ i].id;
		var resourceName = resource.name;
		var resourceType = string_copy(resource.path, 1, string_pos("/",  resource.path)-1);
		var resourcePath = projectPath + resource.path;		

		if (!file_exists(resourcePath)) {
			show_message("Resource file '" + resource.path + "' not found. The project may be corrupted");
			exit;
		}
		
		// Decode the resource file
		var resourceContent = scr_load_json_from_file(resourcePath).json;		
	
		switch (resourceType) {
			case "objects":
				// Load the object variable definitions
				var modelsPath = "ue_models\\" + resourceName + "\\";
				var properties = resourceContent.properties;
				var object = {
					name: resourceContent.name,
					json_file: resourceContent
				};
				for (var a=0, al=array_length(properties); a<al; a++) {
					var property = properties[@ a];
					variable_struct_set(object, property.name, property.value);
				}
				if (!variable_struct_exists(object, "ueObjectType")) continue;
				var objectType = variable_struct_get(object, "ueObjectType");
				
				// Prebuild the transform matrix
				scr_model_prebuild_matrix(object);
				
				switch (objectType) {
					case "model":
						// Load the model meshes
						object.meshesCount = 0;
						var meshes = [];
						object.meshes = meshes;
						var meshPath = modelsPath + "mesh" + string(object.meshesCount) + ".buff";

						while (file_exists(meshPath)) {
							// Load the buffer
							var buffer = buffer_load(meshPath);
							var vbuff = vertex_create_buffer_from_buffer(buffer, uniqueEngine_vformat);
							vertex_freeze(vbuff);
							var mesh = { vbuff: vbuff, sprite: -1, texture: -1 };
														
							// Load the texture
							if (variable_struct_exists(object, "ueTextures")) {
								var textures = variable_struct_get(object, "ueTextures");
								for (var b=0, bl=array_length(textures); b<bl; b++) {
									var spriteName = textures[@ b];
									var spritePath = file_find_first(projectPath + "sprites\\" + spriteName + "\\*.png", 0);
									if (spritePath == "") {
										show_message("Texture '" + spriteName + "' not found." + chr(13) + chr(10) + "This texture will be skipped.");
									}
									mesh.sprite = sprite_add(spritePath, 1, false, false, 0, 0);
									mesh.texture = sprite_get_texture(mesh.sprite, 1);
								}
							}

							array_push(object.meshes, mesh);
							object.meshesCount++;
							 meshPath = modelsPath + "mesh" + string(object.meshesCount) + ".buff";
						}
						
						array_push(projectModels, object);
					break;
					
					case "cameras": 
						array_push(projectCameras, object); 
						break;
						
					default: 
						show_message("Object '" + resourceName + "' has an unsupported object type '" + objectType + "'" + chr(13) + chr(10) + "This object will be skipped.");
				}
			break;
		
			//case "rooms":
			//	array_push(projectRooms, {
			//		name: resourceContent.name,
			//		item: resourceContent
			//	});
			break;	
		}
	}
	
	window_set_caption(projectName + " - Unique Engine");
	
	// Create the first camera for the first time (if specified)
	if (!array_length(projectCameras) ){//&& projectSettings.__internal_firstCompilation) {
		var camera = scr_model_add_game_camera();
		camera.name = "oUniqueEngineMainCamera";
		array_push(projectCameras, camera);
		scr_on_object_change(camera);
	}
}