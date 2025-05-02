package router

import (
	"github.com/gin-gonic/gin"
	"net-go/server/backend/handler/provider"
	"net-go/server/backend/handler/router/endpoints"
	"net-go/server/backend/handler/router/middleware"
	"net/http"
)

// given a gin.Engine pointer in Provider, set all the
// route handling on that pointer.
func SetRouter(p provider.Provider) {
	router := p.R
	handler := endpoints.NewRouteHandler(p)

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

	// game play
	gameGroup := router.Group("/api/games")
	gameGroup.Use(middleware.AuthUser(handler))
	gameGroup.GET("/:id", handler.GetGame)
	gameGroup.GET("/", handler.ListGamesByUser)
	gameGroup.POST("/:id", handler.UpdateGame)
	gameGroup.POST("/", handler.CreateGame)
	gameGroup.DELETE("/:id", handler.DeleteGame)

	// serve the Elm app HTML for any other route; the
	// Elm SPA will handle its own routing internally
	router.NoRoute(func(c *gin.Context) {
		c.HTML(http.StatusOK, "index.html", gin.H{})
	})

	// handle 500 errors gracefully
	router.Use(gin.Recovery())
}
