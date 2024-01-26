package services

import (
	"context"
	"fmt"
	"math/rand"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"net-go/server/backend/apperrors"
	"net-go/server/backend/model"
	"net-go/server/backend/services/mocks"
)

func TestUserServiceGet(t *testing.T) {
	t.Run("Success", func(t *testing.T) {
		uid := uint(rand.Uint32())

		mockUserResp := &model.User{
			Username: "jim",
			Password: "pretty_unsafe",
		}
		mockUserResp.ID = uid

		mockUserRepository := new(mocks.MockUserRepository)
		us := NewUserService(UserServiceDeps{
			UserRepository: mockUserRepository,
		})
		mockUserRepository.On("FindByID", mock.Anything, uid).Return(mockUserResp, nil)

		u, err := us.Get(context.TODO(), uid)

		assert.NoError(t, err)
		assert.Equal(t, mockUserResp, u)
		mockUserRepository.AssertExpectations(t)
	})

	t.Run("Error", func(t *testing.T) {
		uid := uint(rand.Uint32())

		mockUserRepository := new(mocks.MockUserRepository)
		us := NewUserService(UserServiceDeps{
			UserRepository: mockUserRepository,
		})
		mockUserRepository.On("FindByID", mock.Anything, uid).Return(nil, fmt.Errorf("Some error"))

		u, err := us.Get(context.TODO(), uid)

		assert.Error(t, err)
		assert.Nil(t, u)
		mockUserRepository.AssertExpectations(t)
	})
}

func TestUserServiceSignup(t *testing.T) {
	t.Run("Success", func(t *testing.T) {
		uid := uint(rand.Uint32())

		mockUser := &model.User{
			Username: "tim",
			Password: "sercrtn",
		}

		mockUserRepository := new(mocks.MockUserRepository)
		userService := NewUserService(UserServiceDeps{
			UserRepository: mockUserRepository,
		})

		// We can use Run method to modify the user when the Create method is called.
		// We can then chain on a Return method to return no error.
		mockUserRepository.
			On("Create", mock.AnythingOfType("*context.emptyCtx"), mock.AnythingOfType("*model.User")).
			Run(func(args mock.Arguments) {
				userArg := args.Get(1).(*model.User)
				userArg.ID = uid
			}).Return(nil)

		ctx := context.TODO()
		actualUser, err := userService.Signup(ctx, mockUser.Username, mockUser.Password)

		assert.NoError(t, err)

		// verify user now has a UID assigned (by being passed through our mock repo)
		assert.Equal(t, uid, actualUser.ID)

		mockUserRepository.AssertExpectations(t)
	})

	t.Run("DB create error", func(t *testing.T) {
		mockUser := &model.User{
			Username: "tim",
			Password: "sercrtn",
		}

		mockUserRepository := new(mocks.MockUserRepository)
		userService := NewUserService(UserServiceDeps{
			UserRepository: mockUserRepository,
		})

		mockErr := apperrors.NewConflict("Username", mockUser.Username)
		mockUserRepository.
			On("Create", mock.AnythingOfType("*context.emptyCtx"), mock.AnythingOfType("*model.User")).
			Return(mockErr)

		ctx := context.TODO()
		_, err := userService.Signup(ctx, mockUser.Username, mockUser.Password)

		// validate error type
		assert.Equal(t, mockErr.Error(), err.Error())

		mockUserRepository.AssertExpectations(t)
	})
}

func TestUserServiceSignin(t *testing.T) {
	t.Run("Success", func(t *testing.T) {
		uid := uint(rand.Uint32())

		rawPassword := "password"
		mockUser := &model.User{
			Username: "tim",
			Password: "87bf38a508832455cd6aea07a1f57e787b30c90f716212a483cca7d7f414d596.4b299672c289b4e05ecf9e8bb96e870c1615807fcbc446d84f9fb73c8f82f8a3",
		}
		mockUser.ID = uid

		mockUserRepository := new(mocks.MockUserRepository)
		userService := NewUserService(UserServiceDeps{
			UserRepository: mockUserRepository,
		})

		// We can use Run method to modify the user when the Create method is called.
		// We can then chain on a Return method to return no error.
		mockUserRepository.
			On("FindByUsername", mock.AnythingOfType("*context.emptyCtx"), mockUser.Username).
			Return(mockUser, nil)

		ctx := context.TODO()
		actualUser, err := userService.Signin(ctx, mockUser.Username, rawPassword)

		assert.NoError(t, err)

		assert.Equal(t, uid, actualUser.ID)

		mockUserRepository.AssertExpectations(t)
	})

	t.Run("DB username not found error", func(t *testing.T) {
		mockUser := &model.User{
			Username: "tim",
			Password: "sercrtn",
		}

		mockUserRepository := new(mocks.MockUserRepository)
		userService := NewUserService(UserServiceDeps{
			UserRepository: mockUserRepository,
		})

		mockErr := apperrors.NewNotFound("User", mockUser.Username)
		mockUserRepository.
			On("FindByUsername", mock.AnythingOfType("*context.emptyCtx"), mockUser.Username).
			Return(nil, mockErr)

		ctx := context.TODO()
		_, err := userService.Signin(ctx, mockUser.Username, mockUser.Password)

		// validate error type
		assert.Equal(t, mockErr.Error(), err.Error())

		mockUserRepository.AssertExpectations(t)
	})

	t.Run("password mismatch error", func(t *testing.T) {
		mockUser := &model.User{
			Username: "tim",
			Password: "sercrtn.salt",
		}

		mockUserRepository := new(mocks.MockUserRepository)
		userService := NewUserService(UserServiceDeps{
			UserRepository: mockUserRepository,
		})

		mockErr := apperrors.NewNotFound("User", mockUser.Username)
		mockUserRepository.
			On("FindByUsername", mock.AnythingOfType("*context.emptyCtx"), mockUser.Username).
			Return(mockUser, nil)

		ctx := context.TODO()
		// expect mock password to mismatch when hashed version is compared to plaintext version
		_, err := userService.Signin(ctx, mockUser.Username, "incorrect_password")

		// validate error type
		assert.Equal(t, mockErr.Error(), err.Error())

		mockUserRepository.AssertExpectations(t)
	})
}
