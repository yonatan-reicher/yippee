enableDisableButton = document.querySelector("#enable")

enableDisableButton.addEventListener('click', () => {
    // Tell only the current tab to enable/disable itself via the chrome api.
    chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
        chrome.tabs.sendMessage(tabs[0].id, {
            type: "enable-disable",
        })
    })
    /*
    // Tell the content scripts on all tabs to enable/disable themselves via the chrome api.
    chrome.tabs.query({}, function(tabs) {
        for (var i = 0; i < tabs.length; ++i) {
            chrome.tabs.sendMessage(tabs[i].id, {
                type: "enable-disable",
                enable: enableCheckbox.checked
            })
        }
    })
    */
})

happinessSpan = document.querySelector("#happiness")

function updateHappiness(state) {
    happinessSpan.value = Number(state.happiness) / 7
}

loadState().then(updateHappiness)
onStateChanged(updateHappiness)
