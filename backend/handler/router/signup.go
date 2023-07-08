package router

import (
	"github.com/gin-gonic/gin"
	"net-go/server/backend/handler/binding"
	"net/http"
)

// lowercase typename bcus this type is PRIVATE
type signupReq struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required,gte=8"` // TODO: this should be a hash! hash pswd on frontend before sending to backend for further salt+hash and then store in db
}

func (handler RouteHandler) Signup(c *gin.Context) {
	// bind json to req struct
	var req signupReq
	if ok := binding.BindData(c, &req); !ok {
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"dummy": "data",
	})
}
