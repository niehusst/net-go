package endpoints

import (
	"net-go/server/backend/handler/cookies"
	"net-go/server/backend/logger"

	"github.com/gin-gonic/gin"
)

func (rhandler RouteHandler) Signout(c *gin.Context) {
	cookies.DeleteAuthCookiesInResponse(c)

	// redirect to root route
	c.Request.URL.Path = "/"
	rhandler.Provider.R.HandleContext(c)
	logger.Info("Manual user signout")
}
