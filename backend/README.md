# Go backend

Get it? Because it's written in Go but is for the game Go? 
Pretty funny, right??

The backend is mostly a simple CRUD API with a database and 
some basic HTML file serving/rendering (the actual HTML layout
files will all eventually be stored under the `frontend/`
directory, where they will be defined in Elm).
It may also end up being a WebSocket proxy between players
if I don't find a good P2P solution.

## Dev setup

Run `go get .` when located within this directory (`backend/`)
to download all the Go module deps.

You can run the server on localhost with `go run main.go`.
