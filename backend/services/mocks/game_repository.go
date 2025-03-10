package mocks

import (
	"context"

	"github.com/stretchr/testify/mock"
	"net-go/server/backend/model"
)

// MockGameRepository is a mock type for services.GameRepository
type MockGameRepository struct {
	mock.Mock
}

// FindByID is mock of GameRepository FindByID
func (m *MockGameRepository) FindByID(ctx context.Context, id uint) (*model.Game, error) {
	// "call" testify mock w/ provided params
	ret := m.Called(ctx, id)

	// check if a return value was preset for position 0
	var r0 *model.Game
	if ret.Get(0) != nil {
		// perform type assertion on mock return value obtained
		r0 = ret.Get(0).(*model.Game)
	}

	// check if a return value was preset for position 1
	var r1 error
	if ret.Get(1) != nil {
		r1 = ret.Get(1).(error)
	}

	// return preset values (or nil if no preset found)
	return r0, r1
}

func (m *MockGameRepository) ListByUserID(ctx context.Context, userId uint) ([]model.Game, error) {
	ret := m.Called(ctx, userId)

	var r0 []model.Game
	if ret.Get(0) != nil {
		r0 = ret.Get(0).([]model.Game)
	}

	var r1 error
	if ret.Get(1) != nil {
		r1 = ret.Get(1).(error)
	}
	return r0, r1
}

func (m *MockGameRepository) Create(ctx context.Context, game *model.Game) error {
	ret := m.Called(ctx, game)

	var r0 error
	if ret.Get(0) != nil {
		r0 = ret.Get(0).(error)
	}

	return r0
}

func (m *MockGameRepository) Update(ctx context.Context, game *model.Game) error {
	ret := m.Called(ctx, game)

	var r0 error = nil
	if ret.Get(0) != nil {
		r0 = ret.Get(0).(error)
	}

	return r0
}

func (m *MockGameRepository) Delete(ctx context.Context, gameID uint) error {
	ret := m.Called(ctx, gameID)

	var r0 error
	if v0 := ret.Get(0); v0 != nil {
		r0 = v0.(error)
	}

	return r0
}

func (m *MockGameRepository) MigrateAll() error {
	// this will never need testing
	return nil
}
