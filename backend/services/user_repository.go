package services

import (
	"context"

	"github.com/google/uuid"
	"net-go/server/backend/model"
)

/* interface */

// methods for interacting with the data layer
type IUserRepository interface {
	FindByID(ctx context.Context, uid uuid.UUID) (*model.User, error)
	Create(ctx context.Context, u *model.User) error
}

/* implementation */

// TODO: use real db connection
type UserRepository struct {
}

func NewUserRepository( /*deps*/ ) IUserRepository {
	return &UserRepository{}
}

func (u *UserRepository) FindByID(ctx context.Context, uid uuid.UUID) (*model.User, error) {
	// TODO: impl
	return nil, nil
}

func (u *UserRepository) Create(ctx context.Context, user *model.User) error {
	// TODO: impl
	return nil
}
