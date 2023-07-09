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

## Database

I've decided to use a sqlite database since it's easy and open-source (creative commons, but whatever).
I've gitignored the database file, since committing the user passwords table would be a bad idea.

Migrations are currently set to be run on server startup. We'll see how scalable of a solution that is.

## Server

The Gin server expects all requests to the /api routes to use Content-Type: application/json.
Any other content type will fail to bind. 

Since we are using ShouldBindJSON function, there is no need to explicitly specify the 
content-type header; the server will assume any request is in JSON format.
