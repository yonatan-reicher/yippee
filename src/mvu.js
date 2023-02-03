// I want to create a model-view-update architechture to this code.

const modelKey = 'yippeeModel';

chrome.storage.local.get(null).then(x => console.log(x))

var model = {};
chrome.storage.local.get(modelKey).then(json => {
    const obj = json[modelKey];
    if (obj && typeof(obj) === 'object') model = obj;
}).finally(_ => {
    init(model);
  
    var prevTime = new Date().getTime() * 0.001;
    function loop(time) {
        // Normalize to seconds.
        time *= 0.001;

        // Calculate delta time and cut off after half a second.
        const delta = clamp(time - prevTime, 0, 0.5);

        update(model, { delta, time });
        view(model);

        chrome.storage.local.set({ [modelKey]: model }).then(_ => {
      
            prevTime = time;
            window.requestAnimationFrame(loop);
        })
    }

    // Start the loop.
    window.requestAnimationFrame(loop);
})


