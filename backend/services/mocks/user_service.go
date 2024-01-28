package mocks

import (
	"context"

	"github.com/stretchr/testify/mock"
	"net-go/server/backend/model"
)

type MockUserService struct {
	mock.Mock
}

func (m MockUserService) Get(ctx context.Context, id uint) (*model.User, error) {
	// fetch mocked return values
	ret := m.Called(ctx, id)

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

func (m MockUserService) Signup(ctx context.Context, username string, password string) (*model.User, error) {
	ret := m.Called(ctx, username, password)

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

func (m MockUserService) Signin(ctx context.Context, username string, password string) (*model.User, error) {
	ret := m.Called(ctx, username, password)

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

func (m MockUserService) UpdateSessionToken(ctx context.Context, user *model.User) error {
	ret := m.Called(ctx, user)

	var r0 error
	if ret.Get(0) != nil {
		r0 = ret.Get(0).(error)
	}

	return r0
}

func (m MockUserService) MigrateAll() error {
	// no need to test
	return nil
}
