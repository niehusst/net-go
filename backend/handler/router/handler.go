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

// TODO: delete me
func (handler RouteHandler) Signout(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"dummy": "data",
	})
}
