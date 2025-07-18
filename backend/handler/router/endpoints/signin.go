package endpoints

import (
	"github.com/gin-gonic/gin"
	"net-go/server/backend/apperrors"
	"net-go/server/backend/handler/binding"
	"net-go/server/backend/handler/cookies"
	"net-go/server/backend/logger"
	"net/http"
)

type signinReq struct {
	Username string `json:"username" binding:"required,gte=1,lte=30"`
	Password string `json:"password" binding:"required,gte=8,lte=30"`
}

func (rhandler RouteHandler) Signin(c *gin.Context) {
	// bind json to req struct
	var req signinReq
	if ok := binding.BindData(c, &req); !ok {
		return // BindData handles server response on fail
	}

	user, err := rhandler.Provider.UserService.Signin(c, req.Username, req.Password)
	if err != nil {
		logger.Debug("Failed to signin user: %v", err)
		c.JSON(apperrors.Status(err), gin.H{
			"error": err.Error(),
		})
		return
	}

	// make sure we have an updated sess token
	err = rhandler.Provider.UserService.UpdateSessionToken(c, user)
	if err != nil {
		logger.Warn("Failed to update user session: %v", err.Error())
		c.JSON(apperrors.Status(err), gin.H{
			"error": err.Error(),
		})
		return
	}

	// set auth cookie to preserve session
	cookies.SetAuthCookiesInResponse(*user, c)

	c.JSON(http.StatusOK, gin.H{
		"uid":      user.ID,
		"username": user.Username,
	})
}
