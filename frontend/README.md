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

Individual pages can be built using: (TODO update once proper setup is complete)
```
elm make src/<Target elm file> --output <output file name>.js
```

You can run the Elm frontend as a stand-alone file viewer on
localhost using the following command:
```
elm reactor
```
Note that if you select an HTML file, it likely won't render
due to being unable to find the corresponding JS file it needs
to render via Elm. You can select the corresponding Elm source
file, but it will render w/o CSS (since it's generating HTML
for you on the fly).

For the full experience (fully rendered HTML with CSS), please
run the backend from project root with `go run .`.
