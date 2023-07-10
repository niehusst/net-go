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
	Signin(ctx context.Context, username string, password string) (*model.User, error)
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
		log.Printf("User signup creation error: %v\n", err)
		return nil, apperrors.NewConflict("Username", username)
	}

	return u, nil
}

// fetch user from db, if present
func (s *UserService) Signin(ctx context.Context, username string, password string) (*model.User, error) {
	// fetch user from db w/ username
	user, err := s.UserRepository.FindByUsername(ctx, username)
	if err != nil {
		log.Printf("Error fetching user: %v\n", err)
		return user, apperrors.NewNotFound("User", username)
	}

	matching, err := comparePasswords(user.Password, password)
	if err != nil {
		log.Printf("Error comparing passwords: %v\n", err)
	}
	if !matching {
		// wrong password
		return user, apperrors.NewNotFound("User", username)
	}

	// successful signin
	return user, nil
}
