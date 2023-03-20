package services

import (
	"context"

	"github.com/google/uuid"
	"net-go/server/backend/model"
)

/* interface */

// methods for interacting with the data layer
type IUserRepository interface {
	FindById(ctx context.Context, uid uuid.UUID) (*model.User, error)
}

/* implementation */

type UserRepository struct {
}

func NewUserRepository( /*deps*/ ) IUserRepository {
	return UserRepository{}
}

func (u UserRepository) FindById(ctx context.Context, uid uuid.UUID) (*model.User, error) {
	// stub
	return nil, nil
}
