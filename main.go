package main

import (
  "net-go/server/backend/server"
)

func main() {
  router := server.GetRouter()

  router.Run(":4000")
}
