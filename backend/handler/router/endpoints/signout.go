package endpoints

import (
	"github.com/gin-gonic/gin"
	"net-go/server/backend/handler/cookies"
)

func (rhandler RouteHandler) Signout(c *gin.Context) {
	cookies.DeleteAuthCookiesInResponse(c)

	// redirect to root route
	c.Request.URL.Path = "/"
	rhandler.Provider.R.HandleContext(c)
}
