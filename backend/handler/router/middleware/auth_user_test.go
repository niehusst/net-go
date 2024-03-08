package middleware

import (
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"net-go/server/backend/handler/provider"
	"net-go/server/backend/handler/router/endpoints"
	"net-go/server/backend/model"
	"net-go/server/backend/services/mocks"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func buildRouterWithMiddleware(mockUserService *mocks.MockUserService) *gin.Engine {
	router := gin.Default()

	// use the middleware under test
	p := provider.Provider{
		R:           router,
		UserService: mockUserService,
	}
	rhandler := endpoints.NewRouteHandler(p)
	router.Use(AuthUser(rhandler))

	// add a dummy endpoint for us to test against in isolation from other code
	router.GET("/test", func(c *gin.Context) {
		c.String(http.StatusOK, "success")
	})
	return router
}

func TestAuthUser(t *testing.T) {
	gin.SetMode(gin.TestMode)

	t.Run("Valid auth data continues middleware", func(t *testing.T) {
		mockUser := model.User{
			Username:     "tim",
			Password:     "doesnt-matter",
			SessionToken: "value",
		}

		mockUserService := new(mocks.MockUserService)
		mockUserService.
			On(
				"Get",
				mock.AnythingOfType("*gin.Context"),
				mock.AnythingOfType("uint")).
			Return(&mockUser, nil)

		router := buildRouterWithMiddleware(mockUserService)

		rr := httptest.NewRecorder()

		// build the request
		request, err := http.NewRequest(http.MethodGet, "/test", nil)
		assert.NoError(t, err)

		// set the valid auth cookie
		cookie := &http.Cookie{
			Name:  "ngo_auth",
			Value: "1::value",
		}
		request.AddCookie(cookie)

		// perform request
		router.ServeHTTP(rr, request)

		// request should pass middleware and return success
		assert.Equal(t, 200, rr.Code)
		mockUserService.AssertCalled(t, "Get", mock.Anything, mock.Anything)
	})

	t.Run("No user corresponding to auth token returns error", func(t *testing.T) {
		mockUserService := new(mocks.MockUserService)
		mockUserService.
			On(
				"Get",
				mock.AnythingOfType("*gin.Context"),
				mock.AnythingOfType("uint")).
			Return(nil, errors.New("no user found"))

		router := buildRouterWithMiddleware(mockUserService)

		rr := httptest.NewRecorder()

		// build the request
		request, err := http.NewRequest(http.MethodGet, "/test", nil)
		assert.NoError(t, err)

		// set the auth cookie
		cookie := &http.Cookie{
			Name:  "ngo_auth",
			Value: "1::value",
		}
		request.AddCookie(cookie)

		// perform request
		router.ServeHTTP(rr, request)

		// request should fail middleware after calling UserService.Get
		assert.Equal(t, 401, rr.Code)
		mockUserService.AssertCalled(t, "Get", mock.Anything, mock.Anything)
	})

	t.Run("Invalid auth cookie value returns error", func(t *testing.T) {
		mockUserService := new(mocks.MockUserService)

		router := buildRouterWithMiddleware(mockUserService)

		rr := httptest.NewRecorder()

		// build the request
		request, err := http.NewRequest(http.MethodGet, "/test", nil)
		assert.NoError(t, err)

		// invalid auth cookie
		cookie := &http.Cookie{
			Name:  "ngo_auth",
			Value: "invalid_cookie_value",
		}
		request.AddCookie(cookie)

		// perform request
		router.ServeHTTP(rr, request)

		// request should faile middleware
		assert.Equal(t, 401, rr.Code)
	})

	t.Run("No auth cookie fails middleware check", func(t *testing.T) {
		mockUserService := new(mocks.MockUserService)

		router := buildRouterWithMiddleware(mockUserService)

		rr := httptest.NewRecorder()

		// build the request
		request, err := http.NewRequest(http.MethodGet, "/test", nil)
		assert.NoError(t, err)

		// perform request
		router.ServeHTTP(rr, request)

		// request should fail middleware
		assert.Equal(t, 401, rr.Code)
	})
}
