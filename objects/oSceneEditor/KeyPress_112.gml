/// @description Keypress F1 - Go to Test Room
if (projectManager.hasUnsavedChanges) {
    if (show_question("There are unsaved changes. Do you really want to go to the demos?")) {
        room_goto(rTest);
    }
} else {
    room_goto(rTest);
}