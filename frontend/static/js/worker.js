importScripts("scoring-worker.js");

const app = Elm.ScoringWorker.init();

// when we receive a msg from main thread, send it to worker's `receiveSentGame` elm port
onmessage = function ({ data }) {
  const { type, value } = data;

  switch (type) {
    case "score":
      app.ports.receiveSentGame.send(value);
      break;
    default:
      console.error("Unhandled web worker message: " + type);
  }
};

// listen for calls to `returnScoreGame` port, and pass back to main thread
app.ports.returnScoreGame.subscribe(function (game) {
  postMessage(game);
});
