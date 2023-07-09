package services

import (
	"context"
	"fmt"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"net-go/server/backend/apperrors"
	"net-go/server/backend/model"
	"net-go/server/backend/services/mocks"
)

func TestGet(t *testing.T) {
	t.Run("Success", func(t *testing.T) {
		uid, _ := uuid.NewRandom()

		mockUserResp := &model.User{
			UID:      uid,
			Username: "jim",
			Password: "pretty_unsafe",
		}

		mockUserRepository := new(mocks.MockUserRepository)
		us := NewUserService(UserServiceDeps{
			UserRepository: mockUserRepository,
		})
		mockUserRepository.On("FindByID", mock.Anything, uid).Return(mockUserResp, nil)

		u, err := us.Get(context.TODO(), uid)

		assert.NoError(t, err)
		assert.Equal(t, u, mockUserResp)
		mockUserRepository.AssertExpectations(t)
	})

	t.Run("Error", func(t *testing.T) {
		uid, _ := uuid.NewRandom()

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

func TestSignup(t *testing.T) {
	t.Run("Success", func(t *testing.T) {
		uid, _ := uuid.NewRandom()

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
				userArg.UID = uid
			}).Return(nil)

		ctx := context.TODO()
		actualUser, err := userService.Signup(ctx, mockUser.Username, mockUser.Password)

		assert.NoError(t, err)

		// verify user now has a UID assigned (by being passed through our mock repo)
		assert.Equal(t, uid, actualUser.UID)

		mockUserRepository.AssertExpectations(t)
	})

	t.Run("Error", func(t *testing.T) {
		mockUser := &model.User{
			Username: "tim",
			Password: "sercrtn",
		}

		mockUserRepository := new(mocks.MockUserRepository)
		userService := NewUserService(UserServiceDeps{
			UserRepository: mockUserRepository,
		})

		mockErr := apperrors.NewConflict("username", mockUser.Username)
		mockUserRepository.
			On("Create", mock.AnythingOfType("*context.emptyCtx"), mock.AnythingOfType("*model.User")).
			Return(mockErr)

		ctx := context.TODO()
		_, err := userService.Signup(ctx, mockUser.Username, mockUser.Password)

		// validate error type
		assert.Equal(t, err.Error(), mockErr.Error())

		mockUserRepository.AssertExpectations(t)
	})
}
