package services

import (
	"context"
	"fmt"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
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
