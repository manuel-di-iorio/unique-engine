function fswatcher_onchange(cb) {
  var event = fswatcher_poll();
  if (event == "") return;
    
  var eventSplit = string_split(event, "|");
  if (eventSplit[0] == "RENAMED") {
    cb(eventSplit[0], eventSplit[1], eventSplit[2]);
  } else {
    cb(eventSplit[0], eventSplit[1]);
  }
}