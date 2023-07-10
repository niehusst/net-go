package mocks

import (
	"context"

	"github.com/stretchr/testify/mock"
	"net-go/server/backend/model"
)

// MockUserRepository is a mock type for model.UserRepository
type MockUserRepository struct {
	mock.Mock
}

// FindByID is mock of UserRepository FindByID
func (m *MockUserRepository) FindByID(ctx context.Context, id uint) (*model.User, error) {
	// "call" testify mock w/ provided params
	ret := m.Called(ctx, id)

	// check if a return value was preset for position 0
	var r0 *model.User
	if ret.Get(0) != nil {
		// perform type assertion on mock return value obtained
		r0 = ret.Get(0).(*model.User)
	}

	// check if a return value was preset for position 1
	var r1 error
	if ret.Get(1) != nil {
		r1 = ret.Get(1).(error)
	}

	// return preset values (or nil if no preset found)
	return r0, r1
}

func (m *MockUserRepository) Create(ctx context.Context, user *model.User) error {
	ret := m.Called(ctx, user)

	var r0 error
	if ret.Get(0) != nil {
		r0 = ret.Get(0).(error)
	}

	return r0
}

func (m *MockUserRepository) FindByUsername(ctx context.Context, username string) (*model.User, error) {
	ret := m.Called(ctx, username)

	var r0 *model.User
	if ret.Get(0) != nil {
		r0 = ret.Get(0).(*model.User)
	}

	var r1 error
	if ret.Get(1) != nil {
		r1 = ret.Get(1).(error)
	}

	return r0, r1
}

func (m *MockUserRepository) MigrateAll() error {
	// this will never need testing
	return nil
}
