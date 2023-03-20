package mocks

import (
	"context"

	"github.com/google/uuid"
	"github.com/stretchr/testify/mock"
	"net-go/server/backend/model"
)

type MockUserService struct {
	mock.Mock
}

func (m MockUserService) Get(ctx context.Context, uid uuid.UUID) (*model.User, error) {
	// fetch mocked return values
	ret := m.Called(ctx, uid)

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
