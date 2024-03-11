package endpoints

import (
	"bytes"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"net-go/server/backend/handler/provider"
	"net-go/server/backend/model"
	"net-go/server/backend/model/types"
	"net-go/server/backend/services/mocks"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func buildGameRouter(mockGameService *mocks.MockGameService, ctxUser *model.User) *gin.Engine {
	router := gin.Default()

	p := provider.Provider{
		R:           router,
		GameService: mockGameService,
	}
	rhandler := NewRouteHandler(p)
	if ctxUser != nil {
		router.Use(func(c *gin.Context) {
			c.Set("user", *ctxUser)
		})
	}

	// keep this in sync w/ route defintion in router.go
	// (couldnt use SetRouter directly w/o import cycle)
	router.GET("/api/games/:id", rhandler.GetGame)
	return router
}

func TestGetGameIntegration(t *testing.T) {
	gin.SetMode(gin.TestMode)

	t.Run("success", func(t *testing.T) {
		user := model.User{
			Username: "tim",
			Password: "pwnd",
		}
		game := model.Game{
			Board: types.Board{
				Size: types.Full,
				Map:  [][]types.Piece{},
			},
			Score:       types.Score{},
			BlackPlayer: user,
		}
		mockGameService := new(mocks.MockGameService)
		mockGameService.
			On(
				"Get",
				mock.AnythingOfType("*gin.Context"),
				uint(123),
			).
			Return(&game, nil)

		// record responses
		rr := httptest.NewRecorder()
		router := buildGameRouter(mockGameService, &user)

		// do request
		req, err := http.NewRequest(http.MethodGet, "/api/games/123", bytes.NewBuffer([]byte{}))
		assert.NoError(t, err)

		router.ServeHTTP(rr, req)

		// validate
		var expectedGame ElmGame
		expectedGame.fromGame(game, user)
		expectedResp, err := json.Marshal(gin.H{
			"game": expectedGame,
		})
		assert.Equal(t, 200, rr.Code)
		assert.Equal(t, expectedResp, rr.Body.Bytes())

		mockGameService.AssertExpectations(t)
	})
	t.Run("404 returned when game isn't found", func(t *testing.T) {
		user := model.User{
			Username: "tim",
			Password: "pwnd",
		}
		mockGameService := new(mocks.MockGameService)
		mockGameService.
			On(
				"Get",
				mock.AnythingOfType("*gin.Context"),
				uint(123),
			).
			Return(nil, errors.New("game not found"))

		// record responses
		rr := httptest.NewRecorder()
		router := buildGameRouter(mockGameService, &user)

		// do request
		req, err := http.NewRequest(http.MethodGet, "/api/games/123", bytes.NewBuffer([]byte{}))
		assert.NoError(t, err)

		router.ServeHTTP(rr, req)

		// validate
		assert.Equal(t, 404, rr.Code)
		mockGameService.AssertExpectations(t)
	})
	t.Run("incorrect URI fails as bad request", func(t *testing.T) {
		mockGameService := new(mocks.MockGameService)
		user := model.User{
			Username: "tim",
			Password: "pwnd",
		}

		// record responses
		rr := httptest.NewRecorder()
		router := buildGameRouter(mockGameService, &user)

		// do request
		req, err := http.NewRequest(http.MethodGet, "/api/games/abc", bytes.NewBuffer([]byte{}))
		assert.NoError(t, err)

		router.ServeHTTP(rr, req)

		assert.Equal(t, 400, rr.Code)
		mockGameService.AssertNotCalled(t, "Get")
	})
	t.Run("request is rejected when user is not set by middleware", func(t *testing.T) {
		mockGameService := new(mocks.MockGameService)

		// record responses
		rr := httptest.NewRecorder()
		router := buildGameRouter(mockGameService, nil)

		// do request
		req, err := http.NewRequest(http.MethodGet, "/api/games/abc", bytes.NewBuffer([]byte{}))
		assert.NoError(t, err)

		router.ServeHTTP(rr, req)

		assert.Equal(t, 401, rr.Code)
		mockGameService.AssertNotCalled(t, "Get")
	})
}

//func TestCreateGameIntegration(t *testing.T) {
//	gin.SetMode(gin.TestMode)
//
//	t.Run("success", func(t *testing.T) {
//		// create mock req
//		mockReqBody, err := json.Marshal(gin.H{})
//	})
//
//}
