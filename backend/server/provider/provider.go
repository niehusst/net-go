package provider

import (
	"net-go/server/backend/services"
)

// servicer provider
type Provider struct {
	UserService services.IUserService
}
