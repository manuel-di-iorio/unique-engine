device_mouse_dbclick_enable(false);

// Anti-aliasing
if (display_aa >= 8) {
    display_reset(8, false);
} else if (display_aa >= 4) {
    display_reset(4, false);
}

// Maximize the window
call_later(3, time_source_units_frames, function() {
    window_command_run(window_command_maximize);
});