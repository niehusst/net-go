package router

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"net-go/server/backend/apperrors"
	"net-go/server/backend/handler/provider"
	"net-go/server/backend/model"
	"net-go/server/backend/services/mocks"
)

func TestSignup(t *testing.T) {
	gin.SetMode(gin.TestMode)

	t.Run("username and password required", func(t *testing.T) {
		// set our dummy mocks
		mockUserService := new(mocks.MockUserService)
		mockUserService.On("Signup", mock.AnythingOfType("*gin.Context"), mock.AnythingOfType("*model.User")).Return(nil)

		// response recorder for saving http resps
		rr := httptest.NewRecorder()

		router := gin.Default()

		SetRouter(provider.Provider{
			R:           router,
			UserService: mockUserService,
		})

		// create json req w/ no password field
		reqBody, err := json.Marshal(gin.H{
			"username": "",
		})
		assert.NoError(t, err)

		// create reader using NewBuffer
		request, err := http.NewRequest(http.MethodPost, "/api/accounts/signup", bytes.NewBuffer(reqBody))
		assert.NoError(t, err)

		request.Header.Set("Content-Type", "application/json")

		router.ServeHTTP(rr, request)

		assert.Equal(t, 400, rr.Code)
		mockUserService.AssertNotCalled(t, "Signup")
	})
	t.Run("password too short", func(t *testing.T) {
		// set our dummy mocks
		mockUserService := new(mocks.MockUserService)
		mockUserService.On("Signup", mock.AnythingOfType("*gin.Context"), mock.AnythingOfType("*model.User")).Return(nil)

		// response recorder for saving http resps
		rr := httptest.NewRecorder()

		router := gin.Default()

		SetRouter(provider.Provider{
			R:           router,
			UserService: mockUserService,
		})

		// create json req w/ no password field
		reqBody, err := json.Marshal(gin.H{
			"username": "jim",
			"password": "nope",
		})
		assert.NoError(t, err)

		// create reader using NewBuffer
		request, err := http.NewRequest(http.MethodPost, "/api/accounts/signup", bytes.NewBuffer(reqBody))
		assert.NoError(t, err)

		request.Header.Set("Content-Type", "application/json")

		router.ServeHTTP(rr, request)

		assert.Equal(t, 400, rr.Code)
		mockUserService.AssertNotCalled(t, "Signup")
	})
	t.Run("password too long", func(t *testing.T) {
		// set our dummy mocks
		mockUserService := new(mocks.MockUserService)
		mockUserService.On("Signup", mock.AnythingOfType("*gin.Context"), mock.AnythingOfType("*model.User")).Return(nil)

		// response recorder for saving http resps
		rr := httptest.NewRecorder()

		router := gin.Default()

		SetRouter(provider.Provider{
			R:           router,
			UserService: mockUserService,
		})

		// create json req w/ no password field
		reqBody, err := json.Marshal(gin.H{
			"username": "jim",
			"password": "123456789012345678901234567890123456789012345678901234567890",
		})
		assert.NoError(t, err)

		// create reader using NewBuffer
		request, err := http.NewRequest(http.MethodPost, "/api/accounts/signup", bytes.NewBuffer(reqBody))
		assert.NoError(t, err)

		request.Header.Set("Content-Type", "application/json")

		router.ServeHTTP(rr, request)

		assert.Equal(t, 400, rr.Code)
		mockUserService.AssertNotCalled(t, "Signup")
	})
	t.Run("Error calling UserService", func(t *testing.T) {
		u := &model.User{
			Username: "bob",
			Password: "avalidpassword",
		}

		mockUserService := new(mocks.MockUserService)
		mockUserService.On("Signup", mock.AnythingOfType("*gin.Context"), u).Return(apperrors.NewConflict("User Already Exists", u.Username))

		// a response recorder for getting written http response
		rr := httptest.NewRecorder()

		// don't need a middleware as we don't yet have authorized user
		router := gin.Default()

		SetRouter(provider.Provider{
			R:           router,
			UserService: mockUserService,
		})

		reqBody, err := json.Marshal(gin.H{
			"username": u.Username,
			"password": u.Password,
		})
		assert.NoError(t, err)

		// use bytes.NewBuffer to create a reader
		request, err := http.NewRequest(http.MethodPost, "/api/accounts/signup", bytes.NewBuffer(reqBody))
		assert.NoError(t, err)

		request.Header.Set("Content-Type", "application/json")

		router.ServeHTTP(rr, request)

		assert.Equal(t, 409, rr.Code)
		mockUserService.AssertExpectations(t)
	})

}
