if (!window_mouse_get_locked()) {
  game_end();
} else {
  window_mouse_set_locked(false);
}