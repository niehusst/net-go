package router

import (
	"github.com/gin-gonic/gin"
	"net-go/server/backend/handler/provider"
	"net/http"
)

// given a gin.Engine pointer in Provider, set all the
// route handling on that pointer.
func SetRouter(p provider.Provider) {
	router := p.R
	handler := NewRouteHandler(p)

	router.RedirectTrailingSlash = true

	if gin.Mode() != gin.TestMode {
		// load HTML files from glob pattern so gin can reference them
		router.LoadHTMLGlob("frontend/templates/*")
		// load the asset files
		router.Static("/static", "frontend/static")
	}

	// API request routes

	// auth
	authGroup := router.Group("/api/accounts")
	authGroup.POST("/signup", handler.Signup)
	authGroup.POST("/signin", handler.Signin)
	authGroup.GET("/signout", handler.Signout)

	// serve the Elm app HTML for any other route; the
	// app will handle its own routing internally
	router.NoRoute(func(c *gin.Context) {
		c.HTML(http.StatusOK, "index.html", gin.H{})
	})
}
