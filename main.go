package main

import (
	"net-go/server/backend/server"
)

func main() {
	// TODO: refactor this code into server.go, only call Start from here (and pass in env settings?)
	router := server.GetRouter()

	router.Run(":4000")
}
