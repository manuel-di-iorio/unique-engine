/// @function throttle(id, callback, waitMs, leading)
/// @description Executes a callback with throttling based on a unique ID. Useful for inline calls in Step events without prior initialization.
/// @param {String} id A unique identifier for this throttled action
/// @param {Function} callback The function to execute
/// @param {Real} waitMs The number of milliseconds to wait between executions
/// @param {Bool} [leading=true] Whether to execute on the leading edge (immediately)
function throttle(id, callback, waitMs, leading = true) {
  static _throttles = {};

  var _data = _throttles[$ id];
  if (_data == undefined) {
    _data = {
      lastRunTime: leading ? -1 : current_time
    };
    _throttles[$ id] = _data;
  }

  var _now = current_time;
  if (_data.lastRunTime == -1 || _now - _data.lastRunTime >= waitMs) {
    _data.lastRunTime = _now;
    callback();
  }
}
