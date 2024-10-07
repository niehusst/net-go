package provider

import (
	"github.com/gin-gonic/gin"
	"net-go/server/backend/services"
)

// servicer provider
type Provider struct {
	R           *gin.Engine
	UserService services.IUserService
	GameService services.IGameService
}

func (p *Provider) MigrateAll() error {
	var err error
	if err = p.UserService.MigrateAll(); err != nil {
		return err
	}
	if err = p.GameService.MigrateAll(); err != nil {
		return err
	}

	return nil
}
