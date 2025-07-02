package router

import (
	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/contrib/instrumentation/github.com/gin-gonic/gin/otelgin"
	"net-go/server/backend/constants"
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
	apiGroup := router.Group("/api")

	// global middlware
	router.Use(gin.Recovery()) // handle panics gracefully 500 errors
	apiGroup.Use(otelgin.Middleware(constants.GetOtelServiceName()))
	apiGroup.Use(middleware.AttachLogTraceMetadata())

	// -- UNAUTHENTICATED ROUTES --

	// auth
	authGroup := apiGroup.Group("/accounts")
	authGroup.POST("/signup", handler.Signup)
	authGroup.POST("/signin", handler.Signin)
	authGroup.GET("/signout", handler.Signout)

	// -- AUTHENTICATED ROUTES --
	apiGroup.Use(middleware.AuthUser(handler))

	// game play
	gameGroup := apiGroup.Group("/games")
	gameGroup.GET("/:id", handler.GetGame)
	gameGroup.GET("/:id/long", handler.GetGameLongPoll)
	gameGroup.GET("/", handler.ListGamesByUser)
	gameGroup.POST("/:id", handler.UpdateGame)
	gameGroup.POST("/", handler.CreateGame)
	gameGroup.DELETE("/:id", handler.DeleteGame)

	// serve the Elm app HTML for any other route; the
	// Elm SPA will handle its own routing internally
	router.NoRoute(func(c *gin.Context) {
		c.HTML(http.StatusOK, "index.html", gin.H{})
	})
}
