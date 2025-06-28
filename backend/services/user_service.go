package services

import (
	"context"
	"github.com/google/uuid"
	"net-go/server/backend/apperrors"
	"net-go/server/backend/logger"
	"net-go/server/backend/model"
	"strconv"
)

/* interfaces */

// methods the router handler layer interacts with
type IUserService interface {
	IMigratable
	Get(ctx context.Context, id uint) (*model.User, error)
	FindByUsername(ctx context.Context, username string) (*model.User, error)
	Signup(ctx context.Context, username string, password string) (*model.User, error)
	Signin(ctx context.Context, username string, password string) (*model.User, error)
	UpdateSessionToken(ctx context.Context, user *model.User) error
	Update(ctx context.Context, user *model.User) error
}

/* implementation */

type UserService struct {
	userRepository IUserRepository
}

// injectable deps
type UserServiceDeps struct {
	UserRepository IUserRepository
}

func NewUserService(d UserServiceDeps) IUserService {
	return &UserService{
		userRepository: d.UserRepository,
	}
}

// Get retrieves a user based on their id
func (s *UserService) Get(ctx context.Context, id uint) (*model.User, error) {
	user, err := s.userRepository.FindByID(ctx, id)
	if err != nil {
		return user, apperrors.NewNotFound("User", strconv.FormatUint(uint64(id), 10))
	}
	return user, err
}

// create a new user in the db
func (s *UserService) Signup(ctx context.Context, username string, password string) (*model.User, error) {
	hashedPassword, err := hashPassword(password)
	if err != nil {
		logger.Debug("Unable to signup user for username: %v", username)
		return nil, apperrors.NewInternal()
	}

	// set the user model into the db
	u := &model.User{
		Username: username,
		Password: hashedPassword,
	}
	if err := s.userRepository.Create(ctx, u); err != nil {
		logger.Debug("User signup creation error: %v", err)
		return nil, apperrors.NewConflict("Username", username)
	}

	return u, nil
}

// fetch user from db, if present
// always returns 404 err on any failure for secrecy
func (s *UserService) Signin(ctx context.Context, username string, password string) (*model.User, error) {
	user, err := s.FindByUsername(ctx, username)
	if err != nil {
		return user, err
	}

	matching, err := comparePasswords(user.Password, password)
	if err != nil {
		logger.Warn("Error comparing passwords: %v", err)
	}
	if !matching || err != nil {
		// wrong password, but return 404 for security
		return user, apperrors.NewNotFound("User", username)
	}

	// successful signin
	return user, nil
}

func (s *UserService) FindByUsername(ctx context.Context, username string) (*model.User, error) {
	user, err := s.userRepository.FindByUsername(ctx, username)
	if err != nil {
		return user, apperrors.NewNotFound("User", username)
	}
	return user, nil
}

func (s *UserService) UpdateSessionToken(ctx context.Context, user *model.User) error {
	sessToken := uuid.New().String()
	user.SessionToken = sessToken
	return s.Update(ctx, user)
}

func (s *UserService) Update(ctx context.Context, user *model.User) error {
	if err := s.userRepository.Update(ctx, user); err != nil {
		logger.Error("Unable to update user: %v", err)
		return apperrors.NewInternal()
	}
	return nil
}

func (s *UserService) MigrateAll() error {
	return s.userRepository.MigrateAll()
}
