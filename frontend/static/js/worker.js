importScripts("scoring-worker.js");

const app = Elm.Worker.init();

onmessage = function ({ data }) {
  const { type, value } = data;

  switch (type) {
    case "score":
      app.ports.scoreGame.send(value);
      break;
    default:
      console.error("Unhandled web worker message: " + type);
  }
};

app.ports.sendScoredGame.subscribe(function (game) {
  postMessage(game);
});
