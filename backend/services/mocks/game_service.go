package mocks

import (
	"context"

	"github.com/stretchr/testify/mock"
	"net-go/server/backend/model"
)

type MockGameService struct {
	mock.Mock
}

func (m MockGameService) Get(ctx context.Context, id uint) (*model.Game, error) {
	// fetch mocked return values
	ret := m.Called(ctx, id)

	var r0 *model.Game
	if ret.Get(0) != nil {
		r0 = ret.Get(0).(*model.Game)
	}

	var r1 error
	if ret.Get(1) != nil {
		r1 = ret.Get(1).(error)
	}

	return r0, r1
}

func (m MockGameService) Create(ctx context.Context, game *model.Game) error {
	ret := m.Called(ctx, game)

	var r0 error
	if v0 := ret.Get(0); v0 != nil {
		r0 = v0.(error)
	}

	return r0
}

func (m MockGameService) Update(ctx context.Context, game *model.Game) error {
	ret := m.Called(ctx, game)

	var r0 error
	if v0 := ret.Get(0); v0 != nil {
		r0 = v0.(error)
	}

	return r0
}
