enableCheckbox = document.querySelector("#enable")

enableCheckbox.addEventListener('change', () => {
    // Tell the content scripts on all tabs to enable/disable themselves via the chrome api.
    chrome.tabs.query({}, function(tabs) {
        for (var i = 0; i < tabs.length; ++i) {
            chrome.tabs.sendMessage(tabs[i].id, {
                type: "enable-disable",
                enable: enableCheckbox.checked
            })
        }
    })
})
