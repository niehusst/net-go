package services

import (
	"context"
	"log"
	"net-go/server/backend/apperrors"
	"net-go/server/backend/model"
)

/* interfaces */

// methods the router handler layer interacts with
type IUserService interface {
	Get(ctx context.Context, id uint) (*model.User, error)
	Signup(ctx context.Context, username string, password string) (*model.User, error)
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
	return &UserService{
		UserRepository: d.UserRepository,
	}
}

// Get retrieves a user based on their id
func (s *UserService) Get(ctx context.Context, id uint) (*model.User, error) {
	return s.UserRepository.FindByID(ctx, id)
}

// create a new user in the db
func (s *UserService) Signup(ctx context.Context, username string, password string) (*model.User, error) {
	hashedPassword, err := hashPassword(password)
	if err != nil {
		log.Printf("Unable to signup user for username: %v\n", username)
		return nil, apperrors.NewInternal()
	}

	// set the user model into the db
	u := &model.User{
		Username: username,
		Password: hashedPassword,
	}
	if err := s.UserRepository.Create(ctx, u); err != nil {
		return nil, err
	}

	return u, nil
}
