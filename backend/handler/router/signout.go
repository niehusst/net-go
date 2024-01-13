package router

import (
	"github.com/gin-gonic/gin"
)

func (handler RouteHandler) Signout(c *gin.Context) {
	DeleteAuthCookiesInResponse(c)

	// redirect to root route
	c.Request.URL.Path = "/"
	handler.p.R.HandleContext(c)
}
