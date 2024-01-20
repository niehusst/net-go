package router

import (
	"github.com/gin-gonic/gin"
	"log"
	"net-go/server/backend/apperrors"
	"net-go/server/backend/handler/binding"
	"net/http"
)

type signinReq struct {
	Username string `json:"username" binding:"required,gte=1,lte=30"`
	Password string `json:"password" binding:"required,gte=8,lte=30"`
}

func (handler RouteHandler) Signin(c *gin.Context) {
	// bind json to req struct
	var req signinReq
	if ok := binding.BindData(c, &req); !ok {
		return // BindData handles server response on fail
	}

	user, err := handler.p.UserService.Signin(c, req.Username, req.Password)
	if err != nil {
		log.Printf("Failed to signin user: %v\n", err)
		c.JSON(apperrors.Status(err), gin.H{
			"error": err,
		})
		return
	}

	// make sure we have an updated sess token
	err = handler.p.UserService.UpdateSessionToken(c, user)
	if err != nil {
		log.Printf("Failed to sign up user: %v\n", err.Error())
		c.JSON(apperrors.Status(err), gin.H{
			"ok":    false,
			"error": err,
		})
		return
	}

	// set auth cookie to preserve session
	SetAuthCookiesInResponse(*user, c)

	c.JSON(http.StatusOK, gin.H{
		"uid": user.ID,
	})
}
