console.log("starting web worker")
importScripts("scoring-worker.js");

console.log("imported scorere script")
const app = Elm.ScoringWorker.init();

// when we receive a msg from main thread, send it to worker's `sendScoreGame` port
onmessage = function ({ data }) {
  const { type, value } = data;

  switch (type) {
    case "score":
      console.log("recieving sent game", JSON.stringify(value))
      app.ports.receiveSentGame.send(value);
      break;
    default:
      console.error("Unhandled web worker message: " + type);
  }
};

console.log("worker:", app)

// listen for calls to `returnScoreGame` port, and pass back to main thread
app.ports.returnScoreGame.subscribe(function (game) {
  console.log(`returning ${game}`)
  postMessage(game);
});

console.log('web worker setup')
