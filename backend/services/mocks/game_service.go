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
