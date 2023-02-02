function clamp(x, a, b) {
    return x < a ? a : x > b ? b : x;
}

const yippeeImg = document.createElement("img");
yippeeImg.class = "yippee";
yippeeImg.src = "https://media.tenor.com/dKfHDccWYT0AAAAi/tbh-creature-pixel-art.gif"
yippeeImg.style.position = 'fixed';
yippeeImg.style.bottom = '0';
yippeeImg.style.left = '0vw';
yippeeImg.style.maxWidth = '20vw';
yippeeImg.style.maxHeight = '30vh';

const body = document.querySelector("body");

const yippee = {
    img: yippeeImg,
    x: 0,
    targetX: 0,
}

// Set the target.
body.addEventListener('mousemove', (event) => {
    yippee.targetX = event.clientX;
});

// Always
var prevTime = 0;
function loop(time) {
    // Normalize time to seconds.
    time *= 0.001;

    // Calculate delta time and cut off after half a second.
    const delta = clamp(time - prevTime, 0, 0.5);
    
    // Movement physics.
    const maxSpeed = 100;
    const diff = yippee.targetX - yippee.x;
    yippee.x += clamp(diff, -maxSpeed, maxSpeed) * delta;

    // DOM.
    yippee.img.style.left = yippee.x + "px";

    prevTime = time;
    window.requestAnimationFrame(loop);
};
window.requestAnimationFrame(loop);


body.appendChild(yippee.img);

console.log("done!");
