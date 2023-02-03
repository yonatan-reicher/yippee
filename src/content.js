function clamp(x, a, b) {
    return x < a ? a : x > b ? b : x;
}

function setFlipped(el, flip) {
    el.css({
        transform: `scale(${flip ? -1 : 1}, 1)`,
    })
}

function yippeeImg() {
    const yippeeImg = document.createElement("img");
    yippeeImg.class = "yippee";
    yippeeImg.src = "https://media.tenor.com/dKfHDccWYT0AAAAi/tbh-creature-pixel-art.gif"
    yippeeImg.style.all = 'unset';
    yippeeImg.style.position = 'fixed';
    yippeeImg.style.bottom = '0';
    yippeeImg.style.left = '0px';
    yippeeImg.style.maxWidth = '15vw';
    yippeeImg.style.maxHeight = '25vh';
    yippeeImg.style.opacity = '0.9';
    return $(yippeeImg);   
}

const yippee = {
    img: yippeeImg(),
    x: 0,
    y: 0,
    targetX: 0,
    targetY: 0,
    width: 0,
    height: 0,
}

// Always
var prevTime = 0;
function loop(time) {
    // Normalize time to seconds.
    time *= 0.001;

    // Calculate delta time and cut off after half a second.
    const delta = clamp(time - prevTime, 0, 0.5);

    yippee.width = yippee.img.width();
    yippee.height = yippee.img.height();
        
    const diffX = yippee.targetX - yippee.x;
    const diffY = yippee.targetY - (yippee.y + 0.5 * yippee.height);
    const dist = Math.sqrt(diffX * diffX + diffY * diffY);
    const targetAngle = Math.atan2(diffY, diffX);
    
    // Movement physics.
    const maxSpeed = 100;
    const wantedDistPx = 200;
    const wantedMove = Math.cos(targetAngle) * (dist - wantedDistPx);
    yippee.x += clamp(wantedMove, -maxSpeed, maxSpeed) * delta;

    // DOM.
    yippee.img.css({ left: yippee.x - 0.5 * yippee.width + 'px' });
    setFlipped(yippee.img, diffX > 0);

    prevTime = time;
    window.requestAnimationFrame(loop);
};
window.requestAnimationFrame(loop);

// Set the target.
$('body')
.on('mousemove', (event) => {
    yippee.targetX = event.clientX;
    yippee.targetY = window.screenY - event.clientY;
})
.append(yippee.img);

console.log("done!");
