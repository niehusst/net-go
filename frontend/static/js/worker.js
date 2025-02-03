importScripts("scoring-worker.js");

const app = Elm.Worker.init();

// when we receive a msg from main thread, send it to worker's `sendScoreGame` port
onmessage = function ({ data }) {
  const { type, value } = data;

  switch (type) {
    case "score":
      app.ports.sendScoreGame.send(value);
      break;
    default:
      console.error("Unhandled web worker message: " + type);
  }
};

// listen for calls to `returnScoreGame` port, and pass back to main thread
app.ports.receiveReturnedGame.subscribe(function (game) {
  console.log(`returning ${game}`)
  postMessage(game);
});
