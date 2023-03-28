function clamp(x, a, b) {
    return x < a ? a : x > b ? b : x;
}

function eventPos(event) {
    return {
        x: event.clientX,
        y: window.innerHeight - event.clientY,
    }
}

const modelKey = 'yippeeModel'

loadState = () =>
    chrome.storage.local.get(modelKey)
        .then(res => res[modelKey])

function onStateChanged(callback) {
    chrome.storage.onChanged.addListener((changes, namespace) => {
        if (namespace === 'local' && changes[modelKey]) {
            callback(changes[modelKey].newValue)
        }
    })
}
