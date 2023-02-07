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

  model.apples ??= []
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

  for (let i = 0; i < model.apples.length; i++) {
    const apple = model.apples[i]
    apple.pos.y = clamp(0, apple.pos.y - delta * 1000, window.innerHeight)
  }
}

function addApple(model, pos) {
  model.apples.push({
    pos,
    rol: 2 * Math.random() - 1,
    rotation: 0,
  })
}


// ===== VIEW =====

const yippeeImg = $('<img>')
  .addClass('yippee')
  .attr({
    src: "https://media.tenor.com/dKfHDccWYT0AAAAi/tbh-creature-pixel-art.gif",
  })
  .css({
    all: 'unset',
    position: 'fixed',
    bottom: 0,
    left: '0px',
    'max-width': '15vw',
    'max-height': '25vh',
    opacity: 0.9,
    visibility: 'hidden',
  })
  .appendTo('body')

const appleButton = $('<div>')
  .css({
    border: '2px solid black',
    position: 'fixed',
    right: 0,
    bottom: 0,
    padding: 8,
    margin: 0,
    background: 'white',
    opacity: 0.9,
  })
  .append(
    $('<img>')
      .attr({
        src: chrome.runtime.getURL('images/apple.png'),
        draggable: true,
      })
      .css({
        width: 40,
      })
      .on('dragstart', event => {
      })
      .on('dragend', event => {
        // TODO: Cant use model here! need message passing.
        addApple(model, eventPos(event))
      })
  )
  .appendTo('body')

const appleImgs = [];

function view(model) {
  const width = yippeeImg.width();
  // const height = yippeeImg.height();

  // TODO: Use appleImages pool.
  for (img of appleImgs) {
    img.remove()
  }
  for (apple of model.apples) {
    appleImgs.push(
      $('<img>')
        .attr({
          src: chrome.runtime.getURL('images/apple.png'),
        })
        .css({
          position: 'fixed',
          width: 40,
          bottom: apple.pos.y,
          left: apple.pos.x,
          transform: `rotate(${apple.rotation})`,
        })
        .appendTo('body')
    )
  }

  yippeeImg.css({ left: model.yippee.pos.x - 0.5 * width + 'px' });
  setFlipped(yippeeImg, model.yippee.flipped);
  yippeeImg.css({ visibility: 'visible' })
}

// Set the target.
$('body')
  .on('mousemove', event => {
    model.yippee.targetPos = eventPos(event)
  })
