# Elm frontend

You may be wondering, "why Elm?", and the simple answer is
because I wanted to try it out.

The Elm frontend handles most of the game logic for net-go.

# Dev setup

A Node.js and NPM setup is required, since Elm transpiles into
JavaScript (and the package manager system is at least
partially reliant on NPM). More can be learned about setup
(and everything Elm in general) from [elmprogramming.com](https://elmprogramming.com/).

Once the elm ecosystem is installed, you can run `elm install`
to install the Elm deps for this app. (And `npm i` for some linting
and deployment tools.)

The app can be built using:
```
elm make src/Main.elm --output static/js/elm.js
```

To run the app, it must be served from the backend, so run
`npm start` from the project root.
