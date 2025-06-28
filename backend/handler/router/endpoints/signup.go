package endpoints

import (
	"github.com/gin-gonic/gin"
	"net-go/server/backend/apperrors"
	"net-go/server/backend/handler/binding"
	"net-go/server/backend/handler/cookies"
	"net-go/server/backend/logger"
	"net/http"
)

// lowercase typename bcus this type is PRIVATE
type signupReq struct {
	Username string `json:"username" binding:"required,gte=1,lte=30"`
	Password string `json:"password" binding:"required,gte=8,lte=30"`
}

func (rhandler RouteHandler) Signup(c *gin.Context) {
	// bind json to req struct
	var req signupReq
	if ok := binding.BindData(c, &req); !ok {
		// BindData failure already sends own c.JSON fail message
		return
	}

	user, err := rhandler.Provider.UserService.Signup(c, req.Username, req.Password)
	if err != nil {
		logger.Warn("Failed to sign up user: %v", err.Error())
		c.JSON(apperrors.Status(err), gin.H{
			"error": err.Error(),
		})
		return
	}

	// make sure we have an updated sess token
	err = rhandler.Provider.UserService.UpdateSessionToken(c, user)
	if err != nil {
		logger.Error("Failed to generate user session: %v", err.Error())
		c.JSON(apperrors.Status(err), gin.H{
			"error": err.Error(),
		})
		return
	}

	cookies.SetAuthCookiesInResponse(*user, c)

	c.JSON(http.StatusCreated, gin.H{
		"uid":      user.ID,
		"username": user.Username,
	})
}
