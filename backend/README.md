# Go backend

Get it? Because it's written in Golang and is for the game Go? 
Pretty funny, right??

The backend is mostly a simple Gin CRUD API with a database and 
some basic HTML file serving (the actual HTML layout
files are stored under the `frontend/` directory, and are
defined in Elm, along with SPA page routing).

## Dev setup

As per the Gin library setup instructions, Golang v1.13+
is required to run this app.

Run `go get .` when located within the repo root
to download all the Go module deps.

You can run the server on localhost by running in the terminal (also from project root):
```
go run main.go
```

## Testing

Entire test suite can be run via npm script:
```
npm run test-go
```

To run 1 test suite at a time, you can pass the `-run` flag to `go test` in the npm script:

``` sh
npm run test-go -- -run TestGetGameIntegration
# or just 1 test from a selected suite
npm run test-go -- -run TestGetGameIntegration/success
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

I switched from sqlite to mariadb because creating a docker volume for just the db file
when it what in the same container as the app code + binary was giving me a headache.
So the local and prod apps are configured to run with mariadb now.

Your first time running the app (or if you want to wipe your db), you can run an npm
script to create the dev db and a dummy user to connect with:

``` sh
npm run reset-db
```

Migrations are currently set to be run on server startup. We'll see how scalable of a solution that is.

## Server

The Gin server expects all requests to the /api routes to use Content-Type: application/json.
Any other content type will fail to bind. 

Since we are using ShouldBindJSON function, there is no need to explicitly specify the 
content-type header; the server will assume any request is in JSON format.
