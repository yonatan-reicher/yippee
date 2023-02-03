function setFlipped(el, flip) {
    el.css({
        transform: `scale(${flip ? -1 : 1}, 1)`,
    })
}

function init(model) {
    model.yippee ??= {};
    model.yippee.pos ??= { x: -20, y: 0 };
    model.yippee.targetPos ??= { x: 0, y: 0 };
    model.yippee.flipped ??= true;
}

const maxSpeed = 100;
const wantedDistPx = 200;

function update(model, { delta }) {
    // const width = yippeeImg.width();
    const height = yippeeImg.height();
    
    const diffX = model.yippee.targetPos.x - model.yippee.pos.x;
    const diffY = model.yippee.targetPos.y - (model.yippee.pos.y + 0.5 * height);
    const dist = Math.sqrt(diffX * diffX + diffY * diffY);
    const targetAngle = Math.atan2(diffY, diffX);
    
    // Movement physics.
    const wantedMove = Math.cos(targetAngle) * (dist - wantedDistPx);

    // Update.
    model.yippee.pos.x += clamp(wantedMove, -maxSpeed, maxSpeed) * delta;
    model.yippee.flipped = diffX > 0;
}

const yippeeImg = (function () {
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
    return $(yippeeImg).appendTo('body');
})();   

function view(model) {
    const width = yippeeImg.width();
    // const height = yippeeImg.height();
    
    yippeeImg.css({ left: model.yippee.pos.x - 0.5 * width + 'px' });
    setFlipped(yippeeImg, model.yippee.flipped);
}

// Set the target.
$('body')
.on('mousemove', (event) => {
    model.yippee.targetPos.x = event.clientX;
    model.yippee.targetPos.y = window.screenY - event.clientY;
})
