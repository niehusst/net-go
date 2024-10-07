package services

import (
	"context"
	"fmt"
	"math/rand"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"net-go/server/backend/model"
	"net-go/server/backend/model/types"
	"net-go/server/backend/services/mocks"
)

func TestGameServiceGet(t *testing.T) {
	t.Run("Success", func(t *testing.T) {
		uid := uint(rand.Uint32())

		mockUser := &model.User{
			Username: "tim",
			Password: "aaaaa",
		}
		mockGameResp := &model.Game{
			Board:       types.Board{},
			History:     []types.Move{},
			IsOver:      false,
			Score:       types.Score{},
			BlackPlayer: *mockUser, // TODO: don't use same user for both?
			WhitePlayer: *mockUser,
		}
		mockGameResp.ID = uid

		mockGameRepository := new(mocks.MockGameRepository)
		us := NewGameService(GameServiceDeps{
			GameRepository: mockGameRepository,
		})
		mockGameRepository.On("FindByID", mock.Anything, uid).Return(mockGameResp, nil)

		u, err := us.Get(context.TODO(), uid)

		assert.NoError(t, err)
		assert.Equal(t, mockGameResp, u)
		mockGameRepository.AssertExpectations(t)
	})

	t.Run("Error", func(t *testing.T) {
		uid := uint(rand.Uint32())

		mockGameRepository := new(mocks.MockGameRepository)
		us := NewGameService(GameServiceDeps{
			GameRepository: mockGameRepository,
		})
		mockGameRepository.On("FindByID", mock.Anything, uid).Return(nil, fmt.Errorf("Some error"))

		u, err := us.Get(context.TODO(), uid)

		assert.Error(t, err)
		assert.Nil(t, u)
		mockGameRepository.AssertExpectations(t)
	})
}
