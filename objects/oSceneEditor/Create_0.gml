// Anti-aliasing
if (display_aa >= 8) {
    display_reset(8, false);
} else if (display_aa >= 4) {
    display_reset(4, false);
}

ideVersion = "2025.8.11.1";
uiDebug = false;

scrSetupUI();
scrSetup3D();

// Project
projectLocation = undefined;
projectFiles = undefined;
projectEdited = false;