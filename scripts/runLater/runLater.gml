/**
 * Run a callback later
 */
function runLater(callback, units = 1) {
    var ts = time_source_create(time_source_global, units, time_source_units_frames, callback);
    time_source_start(ts);
    return ts;
}
