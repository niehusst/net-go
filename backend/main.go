package main

import (
	"github.com/gin-gonic/gin"
	"net/http"
)

func main() {
	router := gin.Default()

	// load HTML files from glob pattern so gin can reference them
	router.LoadHTMLGlob("testdata/*")

	router.GET("/", func(c *gin.Context) {
		c.HTML(http.StatusOK, "index.html", gin.H{})
	})

	router.Run("localhost:8080") // TODO: debug
}
