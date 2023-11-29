package router

import (
	"github.com/gin-gonic/gin"
	"log"
	"net-go/server/backend/apperrors"
	"net-go/server/backend/handler/binding"
	"net/http"
)

// lowercase typename bcus this type is PRIVATE
type signupReq struct {
	Username string `json:"username" binding:"required,gte=1,lte=30"`
	Password string `json:"password" binding:"required,gte=8,lte=30"`
}

func (handler RouteHandler) Signup(c *gin.Context) {
	// bind json to req struct
	var req signupReq
	if ok := binding.BindData(c, &req); !ok {
		// BindData failure already sends own c.JSON fail message
		return
	}

	user, err := handler.p.UserService.Signup(c, req.Username, req.Password)

	if err != nil {
		log.Printf("Failed to sign up user: %v\n", err.Error())
		c.JSON(apperrors.Status(err), gin.H{
			"ok":    false,
			"error": err,
		})
		return
	}

	SetAuthCookieInResponse(*user, c)

	c.JSON(http.StatusCreated, gin.H{
		"ok": true,
	})
}
