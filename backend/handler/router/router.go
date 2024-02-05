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
	rhandler := endpoints.NewRouteHandler(p)

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
	authGroup.POST("/signup", rhandler.Signup)
	authGroup.POST("/signin", rhandler.Signin)
	authGroup.GET("/signout", rhandler.Signout)

	// game play
	gameGroup := router.Group("/api/games")
	gameGroup.Use(middleware.AuthUser(rhandler))
	gameGroup.GET("/:id", rhandler.GetGame)
	//gameGroup.POST("/:id", rhandler.UpdateGame)
	gameGroup.POST("/", rhandler.CreateGame)

	// serve the Elm app HTML for any other route; the
	// Elm SPA will handle its own routing internally
	router.NoRoute(func(c *gin.Context) {
		c.HTML(http.StatusOK, "index.html", gin.H{})
	})
}
