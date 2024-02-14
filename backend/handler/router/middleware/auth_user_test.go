package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"net-go/server/backend/handler/provider"
	"net-go/server/backend/handler/router/endpoints"
	"net-go/server/backend/services/mocks"
)

func buildRouterWithMiddleware(mockUserService *mocks.MockUserService) *gin.Engine {
	// add a dummy endpoint for us to test against in isolation from other code
	router := gin.Default()
	router.GET("/test", func(c *gin.Context) {
		c.String(http.StatusOK, "success")
	})

	// use the middleware under test
	p := provider.Provider{
		R:           router,
		UserService: mockUserService,
	}
	rhandler := endpoints.NewRouteHandler(p)
	router.Use(AuthUser(rhandler))

	return router
}

func TestAuthUser(t *testing.T) {
	gin.SetMode(gin.TestMode)

	t.Run("Valid auth data continues middleware", func(t *testing.T) {
		// TODO: set our dummy mocks
		mockUserService := new(mocks.MockUserService)
		mockUserService.
			On(
				"Get",
				mock.AnythingOfType("*gin.Context"),
				mock.AnythingOfType("string"),
				mock.AnythingOfType("string")).
			Return(nil)

		router := buildRouterWithMiddleware(mockUserService)

		rr := httptest.NewRecorder()

		// build the request
		request, err := http.NewRequest(http.MethodGet, "/test", nil)
		assert.NoError(t, err)

		// TODO: set the auth cookie!!
		cookie := &http.Cookie{
			Name:  "test_cookie",
			Value: "cookie_value",
		}
		request.AddCookie(cookie)

		// perform request
		router.ServeHTTP(rr, request)

		// request should pass middleware and return success
		assert.Equal(t, 200, rr.Code)
		mockUserService.AssertCalled(t, "Get")
	})

	t.Run("No auth cookie value returns error", func(t *testing.T) {

	})

	t.Run("Invalid auth cookie value returns error", func(t *testing.T) {

	})
}
