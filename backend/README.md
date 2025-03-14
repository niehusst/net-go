# Go backend

Get it? Because it's written in Golang and is for the game Go? 
Pretty funny, right??

The backend is mostly a simple Gin CRUD API with a database and 
some basic HTML file serving (the actual HTML layout
files are stored under the `frontend/` directory, and are
defined in Elm, along with SPA page routing).
It may also end up being a WebSocket proxy between players
if I don't find a good P2P solution.

## Dev setup

As per the Gin library setup instructions, Golang v1.13+
is required to run this app.

Run `go get .` when located within the repo root
to download all the Go module deps.

You can run the server on localhost by running in the terminal (also from project root):
```
go run main.go
```

## Debugging

I've been using [delve](https://github.com/go-delve/delve) for debugging in go.
Once it's installed, you can debug a test if you know the package name of the test;
as far as I know, you can't debug all tests at once. e.g.

``` sh
dlv test net-go/server/backend/handler/router/endpoints
```

Once using delve, you can do `help [cmd]` to get more info on debugger tools.

## Database

I've decided to use a sqlite database since it's easy and open-source (creative commons, but whatever).
I've gitignored the database file, since committing the user passwords table would be a bad idea.

Migrations are currently set to be run on server startup. We'll see how scalable of a solution that is.

## Server

The Gin server expects all requests to the /api routes to use Content-Type: application/json.
Any other content type will fail to bind. 

Since we are using ShouldBindJSON function, there is no need to explicitly specify the 
content-type header; the server will assume any request is in JSON format.
