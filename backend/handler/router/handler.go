package router

import (
	"github.com/gin-gonic/gin"
	"net-go/server/backend/handler/provider"
	"net/http"
)

type RouteHandler struct {
	p provider.Provider
}

func NewRouteHandler(p provider.Provider) RouteHandler {
	return RouteHandler{
		p: p,
	}
}

/* routing definitions used by router.go */

func (handler RouteHandler) Signin(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"dummy": "data",
	})
}

func (handler RouteHandler) Signout(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"dummy": "data",
	})
}
