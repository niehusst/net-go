# Go backend

Get it? Because it's written in Go but is for the game Go? 
Pretty funny, right??

The backend is mostly a simple Gin CRUD API with a database and 
some basic HTML file serving/rendering (the actual HTML layout
files will all eventually be stored under the `frontend/`
directory, where they will be defined in Elm).
It may also end up being a WebSocket proxy between players
if I don't find a good P2P solution.

## Dev setup

As per the Gin library setup instructions, Golang v1.13+
is required to run this app.

Run `go get .` when located within the project root
to download all the Go module deps.

You can run the server on localhost by running in the terminal(also from project root):
```
go run .
```
