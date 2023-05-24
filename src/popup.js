enableDisableButton = document.querySelector("#enable")

enableDisableButton.addEventListener('click', () => {
    // Tell only the current tab to enable/disable itself via the chrome api.
    chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
        chrome.tabs.sendMessage(tabs[0].id, {
            type: "enable-disable",
        })
    })
})

volumeSlider = document.querySelector("#volume")

volumeSlider.addEventListener('input', () => {
    chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
        chrome.tabs.sendMessage(tabs[0].id, {
            type: 'set-volume',
            volume: Number(volumeSlider.value),
        })
    })
})

happinessSpan = document.querySelector("#happiness")

function popupUpdate(state) {
    happinessSpan.value = Number(state.happiness) / 10
    volumeSlider.value = state.volume

    for (let i = 0; i <= state.level; i++) {
        let levelEl = document.getElementById('level-' + i)
        if (levelEl != null) {
            levelEl.classList.remove("level-inactive")
            levelEl.href = chrome.runtime.getURL("resources/level-" + i + ".pdf")
        }
    }
}

loadState().then(popupUpdate)
onStateChanged(popupUpdate)

document.querySelector("#shaninatan").src = chrome.runtime.getURL("resources/shaninatan.png")

document.querySelector("#cheat-button").onclick = () => {
    chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
        chrome.tabs.sendMessage(tabs[0].id, {
            type: 'cheat',
        })
    })
}
