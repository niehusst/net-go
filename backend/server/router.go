package server

import (
	"github.com/gin-gonic/gin"
	"net-go/server/backend/server/provider"
	"net/http"
)

func GetRouter(p provider.Provider) *gin.Engine {
	router := gin.Default()
	handler := NewRouteHandler(p)

	router.RedirectTrailingSlash = true

	// load HTML files from glob pattern so gin can reference them
	router.LoadHTMLGlob("frontend/templates/*")
	// load the asset files
	router.Static("/static", "frontend/static")

	// API request routes

	// auth
	authGroup := router.Group("/api/accounts")
	authGroup.POST("/signup", handler.Signup)
	authGroup.POST("/signin", handler.Signin)
	authGroup.POST("/signout", handler.Signout)

	// serve the Elm app HTML for any other route; the
	// app will handle its own routing internally
	router.NoRoute(func(c *gin.Context) {
		c.HTML(http.StatusOK, "index.html", gin.H{})
	})

	return router
}
