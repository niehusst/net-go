package server

import (
	"github.com/gin-gonic/gin"
	"net/http"
)

func GetRouter() *gin.Engine {
	router := gin.Default()

  router.RedirectTrailingSlash = true

	// load HTML files from glob pattern so gin can reference them
	router.LoadHTMLGlob("frontend/templates/*")
  // load the asset files
  router.Static("/static", "frontend/static")

	router.GET("/", func(c *gin.Context) {
		c.HTML(http.StatusOK, "index.html", gin.H{})
	})

  router.NoRoute(func(c *gin.Context) {
    c.String(404, "404 placeholder")
  })

  return router
	//router.Run("localhost:8080") // TODO: debug
}
