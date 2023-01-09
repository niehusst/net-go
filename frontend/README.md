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
to install the Elm deps for this app.

Individual pages can be built using:
```
elm make src/Main.elm --output static/js/elm.js
```

You can run the Elm frontend as a stand-alone file viewer on
localhost using the following command:
```
elm-live src/Main.elm --pushstate -- --output=static/js/elm.js
```

For the full experience (with access to backend), please
run the backend from project root with `go run .` instead.
