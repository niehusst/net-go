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

	// API request routes
	//  router.GET("/", func(c *gin.Context) {
	//    c.HTML(http.StatusOK, "index.html", gin.H{})
	//  })

	// serve the Elm app HTML for any other route; the
	// app will handle its own routing internally
	router.NoRoute(func(c *gin.Context) {
		c.HTML(http.StatusOK, "index.html", gin.H{})
	})

	return router
}
