/// @description Check if the project has been externally modified
alarm[2] = 2 * room_speed;
if (projectYypPath == "") exit;
if (sha1_file(projectYypPath) == projectHash) exit;
show_message("The project will now be reloaded since it has been externally modified");
scr_gms_open_project();