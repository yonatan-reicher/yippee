const node = document.createElement("div");
const body = document.querySelector("body");

body.append(node);

loadState()
    .catch(_ => null)
    .then(maybeState => {
        const resources = {
            yippeeUrl: chrome.runtime.getURL("resources/yippee.gif"),
            appleUrl: chrome.runtime.getURL("resources/apple.png"),
            yippeeSoundUrl: chrome.runtime.getURL("resources/yippee.mp4"),
        }
        const windowSize = {x: window.innerWidth, y: window.innerHeight}
        const flags = {
            maybeState,
            resources,
            windowSize,
            url: window.location.href,
        }

        var elm;
        try {
            elm = Elm.Main.init({
                flags,
                node,
            })
        } catch {
            flags.maybeState = null;
            elm = Elm.Main.init({
                flags,
                node,
            })
        }

        var prevTime = new Date().getTime() * 0.001;
        function loop(time) {
            // Normalize to seconds.
            time *= 0.001;

            // Calculate delta time and cut off after half a second.
            const delta = clamp(time - prevTime, 0, 0.5);

            elm.ports.frame.send({delta, time});

            prevTime = time;
            window.requestAnimationFrame(loop);
        }
        // Start the loop.
        window.requestAnimationFrame(loop);

        elm.ports.requestSave1.subscribe(model => {
            chrome.storage.local.set({[modelKey]: model})
                .then(_ => elm.ports.saveDone.send(null))
        })

        body.addEventListener('mousemove', event => {
            elm.ports.mouseMove.send(eventPos(event))
        })

        document.addEventListener('fullscreenchange', _ => {
            elm.ports.onFullscreenChange.send(document.fullscreenElement ? true : false)
        })

        chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
            if (message.type === 'enable-disable') {
                elm.ports.enableDisable.send(null)
            }
        })

        window.addEventListener('focus', _ => {
            loadState().then(state => elm.ports.loadState.send(state))
        })
    })

