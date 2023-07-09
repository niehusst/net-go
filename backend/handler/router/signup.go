package router

import (
	"github.com/gin-gonic/gin"
	"log"
	"net-go/server/backend/apperrors"
	"net-go/server/backend/handler/binding"
)

// lowercase typename bcus this type is PRIVATE
type signupReq struct {
	Username string `json:"username" binding:"required,gte=1,lte=30"`
	Password string `json:"password" binding:"required,gte=8,lte=30"` // TODO: this should be a hash! hash pswd on frontend before sending to backend for further salt+hash and then store in db
}

func (handler RouteHandler) Signup(c *gin.Context) {
	// bind json to req struct
	var req signupReq
	if ok := binding.BindData(c, &req); !ok {
		return
	}

	_, err := handler.p.UserService.Signup(c, req.Username, req.Password)

	if err != nil {
		log.Printf("Failed to sign up user: %v\n", err.Error())
		c.JSON(apperrors.Status(err), gin.H{
			"error": err,
		})
		return
	}
}
