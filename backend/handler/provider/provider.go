package provider

import (
	"github.com/gin-gonic/gin"
	"net-go/server/backend/services"
)

// servicer provider
type Provider struct {
	R           *gin.Engine
	UserService services.IUserService
}
