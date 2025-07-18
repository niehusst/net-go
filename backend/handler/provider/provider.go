package provider

import (
	"net-go/server/backend/services"
	"net-go/server/backend/subscriptions"

	"github.com/gin-gonic/gin"
)

// servicer provider
type Provider struct {
	R             *gin.Engine
	UserService   services.IUserService
	GameService   services.IGameService
	Subscriptions subscriptions.GameSubscriptions
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
