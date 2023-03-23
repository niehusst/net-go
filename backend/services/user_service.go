package services

import (
	"context"
	"github.com/google/uuid"
	"net-go/server/backend/model"
)

/* interfaces */

// methods the router handler layer interacts with
type IUserService interface {
	Get(ctx context.Context, uid uuid.UUID) (*model.User, error)
}

/* implementation */

type UserService struct {
	UserRepository IUserRepository
}

// injectable deps
type UserServiceDeps struct {
	UserRepository IUserRepository
}

func NewUserService(d UserServiceDeps) IUserService {
	return UserService{
		UserRepository: d.UserRepository,
	}
}

// Get retrieves a user based on their uuid
func (s UserService) Get(ctx context.Context, uid uuid.UUID) (*model.User, error) {
	return s.UserRepository.FindByID(ctx, uid)
}
