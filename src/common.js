function clamp(x, a, b) {
  return x < a ? a : x > b ? b : x;
}

function eventPos(event) {
  return {
    x: event.clientX,
    y: window.screenY - event.clientY,
  }
}

