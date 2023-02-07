const modelKey = 'yippeeModel';

const node = document.createElement("div");
const body = document.querySelector("body");

body.append(node);

chrome.storage.local.get(modelKey)
  .then(res => res[modelKey])
  .catch(_ => null)
  .then(state => {
    const flags = {
      state,
      resources: {
        yippeeUrl: chrome.runtime.getURL("images/yippee.gif"),
        appleUrl: chrome.runtime.getURL("images/apple.png"),
      },
    }
    const elm = Elm.Main.init({
      flags,
      node,
    })

    var prevTime = new Date().getTime() * 0.001;
    function loop(time) {
      // Normalize to seconds.
      time *= 0.001;

      // Calculate delta time and cut off after half a second.
      const delta = clamp(time - prevTime, 0, 0.5);

      elm.ports.frame.send({ delta, time });

      prevTime = time;
      window.requestAnimationFrame(loop);
    }
    // Start the loop.
    window.requestAnimationFrame(loop);

    elm.ports.requestSave.subscribe(model => {
      chrome.storage.local.set({ [modelKey]: model })
        .then(_ => elm.ports.saveDone.send(null))
    })

    body.addEventListener('mousemove', event => {
      elm.ports.mouseMove.send(eventPos(event))
    })
  })

