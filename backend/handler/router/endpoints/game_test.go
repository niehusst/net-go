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

func buildGameRouter(mockGameService *mocks.MockGameService, mockUserService *mocks.MockUserService, ctxUser *model.User) *gin.Engine {
	router := gin.Default()

	p := provider.Provider{
		R:           router,
		GameService: mockGameService,
		UserService: mockUserService,
	}
	rhandler := NewRouteHandler(p)
	if ctxUser != nil {
		router.Use(func(c *gin.Context) {
			c.Set("user", ctxUser)
		})
	}

	// keep this in sync w/ route defintion in router.go
	// (couldnt use SetRouter directly w/o import cycle)
	router.GET("/api/games/:id", rhandler.GetGame)
	router.POST("/api/games/", rhandler.CreateGame)
	router.POST("/api/games/:id", rhandler.UpdateGame)
	router.GET("/api/games/", rhandler.ListGamesByUser)
	return router
}

func TestGetGameIntegration(t *testing.T) {
	gin.SetMode(gin.TestMode)

	t.Run("success", func(t *testing.T) {
		user := model.User{
			Username: "tim",
			Password: "pwnd",
		}
		user.ID = 123
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
		router := buildGameRouter(mockGameService, nil, &user)

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
		user.ID = 123
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
		router := buildGameRouter(mockGameService, nil, &user)

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
		user.ID = 123

		// record responses
		rr := httptest.NewRecorder()
		router := buildGameRouter(mockGameService, nil, &user)

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
		router := buildGameRouter(mockGameService, nil, nil)

		// do request
		req, err := http.NewRequest(http.MethodGet, "/api/games/abc", bytes.NewBuffer([]byte{}))
		assert.NoError(t, err)

		router.ServeHTTP(rr, req)

		assert.Equal(t, 401, rr.Code)
		mockGameService.AssertNotCalled(t, "Get")
	})
}

func TestCreateGameIntegration(t *testing.T) {
	gin.SetMode(gin.TestMode)

	t.Run("success", func(t *testing.T) {
		user := model.User{
			Username: "tim",
			Password: "pwnd",
		}
		user.ID = 123
		opponentUser := model.User{
			Username: "tom",
			Password: "watever",
		}
		opponentUser.ID = 456
		game := model.Game{
			Board: types.Board{
				Size: types.Full,
				Map:  [][]types.Piece{},
			},
			Score:       types.Score{},
			BlackPlayer: user,
			WhitePlayer: opponentUser,
		}
		mockGameService := new(mocks.MockGameService)
		mockGameService.
			On(
				"Create",
				mock.AnythingOfType("*gin.Context"),
				mock.AnythingOfType("*model.Game"),
			).
			Return(nil)
		mockUserService := new(mocks.MockUserService)
		mockUserService.
			On(
				"FindByUsername",
				mock.AnythingOfType("*gin.Context"),
				"tom",
			).
			Return(&opponentUser, nil)

		// record responses
		rr := httptest.NewRecorder()
		router := buildGameRouter(mockGameService, mockUserService, &user)

		// create mock req
		mockReqBody, err := json.Marshal(gin.H{
			"game": ElmGame{
				BoardSize:       types.Full,
				Board:           make([]types.Piece, 0),
				History:         make([]types.Move, 0),
				IsOver:          false,
				Score:           types.Score{},
				PlayerColor:     types.Black,
				BlackPlayerName: "tim",
				WhitePlayerName: "tom",
			},
		})
		assert.NoError(t, err)

		// do request
		req, err := http.NewRequest(http.MethodPost, "/api/games/", bytes.NewBuffer(mockReqBody))
		assert.NoError(t, err)

		router.ServeHTTP(rr, req)

		// validate
		expectedResp, err := json.Marshal(gin.H{
			"uid": game.ID,
		})
		assert.Equal(t, 201, rr.Code)
		assert.Equal(t, expectedResp, rr.Body.Bytes())

		mockGameService.AssertExpectations(t)
	})
	t.Run("when game players do not include requesting user, reject", func(t *testing.T) {
		user := model.User{
			Username: "tim",
			Password: "pwnd",
		}
		user.ID = 123
		mockGameService := new(mocks.MockGameService)
		mockUserService := new(mocks.MockUserService)

		// record responses
		rr := httptest.NewRecorder()
		router := buildGameRouter(mockGameService, mockUserService, &user)

		// create mock req
		mockReqBody, err := json.Marshal(gin.H{
			"game": ElmGame{
				BoardSize:       types.Full,
				Board:           make([]types.Piece, 0),
				History:         make([]types.Move, 0),
				IsOver:          false,
				Score:           types.Score{},
				PlayerColor:     types.Black,
				BlackPlayerName: "foo",
				WhitePlayerName: "bar",
			},
		})
		assert.NoError(t, err)

		// do request
		req, err := http.NewRequest(http.MethodPost, "/api/games/", bytes.NewBuffer(mockReqBody))
		assert.NoError(t, err)

		router.ServeHTTP(rr, req)

		// validate
		assert.Equal(t, 401, rr.Code)

		mockGameService.AssertExpectations(t)
	})
	t.Run("when requesting user color choice doesnt match player color id, reject", func(t *testing.T) {
		user := model.User{
			Username: "tim",
			Password: "pwnd",
		}
		user.ID = 123
		mockGameService := new(mocks.MockGameService)
		mockUserService := new(mocks.MockUserService)

		// record responses
		rr := httptest.NewRecorder()
		router := buildGameRouter(mockGameService, mockUserService, &user)

		// create mock req
		mockReqBody, err := json.Marshal(gin.H{
			"game": ElmGame{
				BoardSize:       types.Full,
				Board:           make([]types.Piece, 0),
				History:         make([]types.Move, 0),
				IsOver:          false,
				Score:           types.Score{},
				PlayerColor:     types.Black,
				BlackPlayerName: "foo",
				WhitePlayerName: "tim",
			},
		})
		assert.NoError(t, err)

		// do request
		req, err := http.NewRequest(http.MethodPost, "/api/games/", bytes.NewBuffer(mockReqBody))
		assert.NoError(t, err)

		router.ServeHTTP(rr, req)

		// validate
		assert.Equal(t, 401, rr.Code)

		mockGameService.AssertExpectations(t)
	})
	t.Run("when requested opponent username not found, reject", func(t *testing.T) {
		user := model.User{
			Username: "tim",
			Password: "pwnd",
		}
		user.ID = 123
		mockGameService := new(mocks.MockGameService)
		mockUserService := new(mocks.MockUserService)
		mockUserService.
			On(
				"FindByUsername",
				mock.AnythingOfType("*gin.Context"),
				"tom",
			).Return(nil, errors.New("user not found by username"))

		// record responses
		rr := httptest.NewRecorder()
		router := buildGameRouter(mockGameService, mockUserService, &user)

		// create mock req
		mockReqBody, err := json.Marshal(gin.H{
			"game": ElmGame{
				BoardSize:       types.Full,
				Board:           make([]types.Piece, 0),
				History:         make([]types.Move, 0),
				IsOver:          false,
				Score:           types.Score{},
				PlayerColor:     types.Black,
				BlackPlayerName: "tim",
				WhitePlayerName: "tom",
			},
		})
		assert.NoError(t, err)

		// do request
		req, err := http.NewRequest(http.MethodPost, "/api/games/", bytes.NewBuffer(mockReqBody))
		assert.NoError(t, err)

		router.ServeHTTP(rr, req)

		// validate
		assert.Equal(t, 404, rr.Code)

		mockGameService.AssertExpectations(t)
	})
	t.Run("when user not in ctx, reject", func(t *testing.T) {
		mockGameService := new(mocks.MockGameService)
		mockUserService := new(mocks.MockUserService)

		// record responses
		rr := httptest.NewRecorder()
		router := buildGameRouter(mockGameService, mockUserService, nil)

		// do request
		req, err := http.NewRequest(http.MethodPost, "/api/games/", bytes.NewBuffer([]byte{}))
		assert.NoError(t, err)

		router.ServeHTTP(rr, req)

		assert.Equal(t, 401, rr.Code)
	})
}

func TestUpdateGameIntegration(t *testing.T) {
	gin.SetMode(gin.TestMode)

	t.Run("success", func(t *testing.T) {
		user := model.User{
			Username: "tim",
			Password: "pwnd",
		}
		user.ID = 123
		game := model.Game{
			Board: types.Board{
				Size: types.Full,
				Map:  [][]types.Piece{},
			},
			History:       make([]types.Move, 0),
			Score:         types.Score{},
			WhitePlayer:   user,
			WhitePlayerId: user.ID,
		}
		game.ID = 123
		mockGameService := new(mocks.MockGameService)
		mockGameService.
			On(
				"Get",
				mock.AnythingOfType("*gin.Context"),
				uint(123),
			).
			Return(&game, nil)
		mockGameService.
			On(
				"Update",
				mock.AnythingOfType("*gin.Context"),
				mock.AnythingOfType("*model.Game"),
			).
			Return(nil)

		// record responses
		rr := httptest.NewRecorder()
		router := buildGameRouter(mockGameService, nil, &user)

		// create mock req
		mockReqBody, err := json.Marshal(gin.H{
			"game": ElmGame{
				BoardSize:       types.Full,
				Board:           make([]types.Piece, 0),
				History:         make([]types.Move, 0),
				IsOver:          false,
				Score:           types.Score{},
				PlayerColor:     types.White,
				BlackPlayerName: "sally",
				WhitePlayerName: "tim",
			},
		})
		assert.NoError(t, err)

		// do request
		req, err := http.NewRequest(http.MethodPost, "/api/games/123", bytes.NewBuffer(mockReqBody))
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
	t.Run("404 returned when game to update isn't found", func(t *testing.T) {
		user := model.User{
			Username: "tim",
			Password: "pwnd",
		}
		user.ID = 123
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
		router := buildGameRouter(mockGameService, nil, &user)

		// create mock req
		mockReqBody, err := json.Marshal(gin.H{
			"game": ElmGame{
				BoardSize:       types.Full,
				Board:           make([]types.Piece, 0),
				History:         make([]types.Move, 0),
				IsOver:          false,
				Score:           types.Score{},
				PlayerColor:     types.Black,
				BlackPlayerName: "sally",
				WhitePlayerName: "tim",
			},
		})
		assert.NoError(t, err)

		// do request
		req, err := http.NewRequest(http.MethodPost, "/api/games/123", bytes.NewBuffer(mockReqBody))
		assert.NoError(t, err)

		router.ServeHTTP(rr, req)

		// validate
		assert.Equal(t, 404, rr.Code)
		mockGameService.AssertExpectations(t)
	})
	t.Run("forbidden when requesting player is not a member of the indicated game", func(t *testing.T) {
		user := model.User{
			Username: "tim",
			Password: "pwnd",
		}
		user.ID = 123
		game := model.Game{
			Board: types.Board{
				Size: types.Full,
				Map:  [][]types.Piece{},
			},
			Score: types.Score{},
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
		router := buildGameRouter(mockGameService, nil, &user)

		// create mock req
		mockReqBody, err := json.Marshal(gin.H{
			"game": ElmGame{
				BoardSize:       types.Full,
				Board:           make([]types.Piece, 0),
				History:         make([]types.Move, 0),
				IsOver:          false,
				Score:           types.Score{},
				PlayerColor:     types.Black,
				BlackPlayerName: "sally",
				WhitePlayerName: "tim",
			},
		})
		assert.NoError(t, err)

		// do request
		req, err := http.NewRequest(http.MethodPost, "/api/games/123", bytes.NewBuffer(mockReqBody))
		assert.NoError(t, err)

		router.ServeHTTP(rr, req)

		// validate
		assert.Equal(t, 403, rr.Code)
		mockGameService.AssertExpectations(t)
	})
	t.Run("incorrect URI fails as bad request", func(t *testing.T) {
		mockGameService := new(mocks.MockGameService)
		user := model.User{
			Username: "tim",
			Password: "pwnd",
		}
		user.ID = 123

		// record responses
		rr := httptest.NewRecorder()
		router := buildGameRouter(mockGameService, nil, &user)

		// create mock req
		mockReqBody, err := json.Marshal(gin.H{
			"game": ElmGame{
				BoardSize:       types.Full,
				Board:           make([]types.Piece, 0),
				History:         make([]types.Move, 0),
				IsOver:          false,
				Score:           types.Score{},
				PlayerColor:     types.Black,
				BlackPlayerName: "sally",
				WhitePlayerName: "tim",
			},
		})
		assert.NoError(t, err)

		// do request
		req, err := http.NewRequest(http.MethodPost, "/api/games/abc", bytes.NewBuffer(mockReqBody))
		assert.NoError(t, err)

		router.ServeHTTP(rr, req)

		assert.Equal(t, 400, rr.Code)
		mockGameService.AssertNotCalled(t, "Update")
	})
	t.Run("request is rejected when user is not set by middleware", func(t *testing.T) {
		mockGameService := new(mocks.MockGameService)

		// record responses
		rr := httptest.NewRecorder()
		router := buildGameRouter(mockGameService, nil, nil)

		// create mock req
		mockReqBody, err := json.Marshal(gin.H{
			"game": ElmGame{
				BoardSize:       types.Full,
				Board:           make([]types.Piece, 0),
				History:         make([]types.Move, 0),
				IsOver:          false,
				Score:           types.Score{},
				PlayerColor:     types.Black,
				BlackPlayerName: "tim",
				WhitePlayerName: "sally",
			},
		})
		assert.NoError(t, err)

		// do request
		req, err := http.NewRequest(http.MethodPost, "/api/games/123", bytes.NewBuffer(mockReqBody))
		assert.NoError(t, err)

		router.ServeHTTP(rr, req)

		assert.Equal(t, 401, rr.Code)
		mockGameService.AssertNotCalled(t, "Update")
	})
}

func TestListGameIntegration(t *testing.T) {
	gin.SetMode(gin.TestMode)

	t.Run("success", func(t *testing.T) {
		user := model.User{
			Username: "tim",
			Password: "pwnd",
		}
		user.ID = 123
		game1 := model.Game{
			Board: types.Board{
				Size: types.Full,
				Map:  [][]types.Piece{},
			},
			Score:       types.Score{},
			BlackPlayer: user,
		}
		game2 := model.Game{
			Board: types.Board{
				Size: types.Full,
				Map:  [][]types.Piece{},
			},
			Score:       types.Score{},
			WhitePlayer: user,
		}
		mockGameService := new(mocks.MockGameService)
		mockGameService.
			On(
				"ListByUser",
				mock.AnythingOfType("*gin.Context"),
				uint(123),
			).
			Return([]model.Game{game1, game2}, nil)

		// record responses
		rr := httptest.NewRecorder()
		router := buildGameRouter(mockGameService, nil, &user)

		// do request
		req, err := http.NewRequest(http.MethodGet, "/api/games/", bytes.NewBuffer([]byte{}))
		assert.NoError(t, err)

		router.ServeHTTP(rr, req)

		// validate
		var expectedGames []ElmGame = make([]ElmGame, 2)
		expectedGames[0].fromGame(game1, user)
		expectedGames[1].fromGame(game2, user)
		expectedResp, err := json.Marshal(gin.H{
			"games": expectedGames,
		})
		assert.Equal(t, 200, rr.Code)
		assert.Equal(t, expectedResp, rr.Body.Bytes())

		mockGameService.AssertExpectations(t)
	})
	t.Run("empty slice returned when no games found", func(t *testing.T) {
		user := model.User{
			Username: "tim",
			Password: "pwnd",
		}
		user.ID = 123
		mockGameService := new(mocks.MockGameService)
		mockGameService.
			On(
				"ListByUser",
				mock.AnythingOfType("*gin.Context"),
				uint(123),
			).
			Return([]model.Game{}, nil)

		// record responses
		rr := httptest.NewRecorder()
		router := buildGameRouter(mockGameService, nil, &user)

		// do request
		req, err := http.NewRequest(http.MethodGet, "/api/games/", bytes.NewBuffer([]byte{}))
		assert.NoError(t, err)

		router.ServeHTTP(rr, req)

		// validate
		expectedResp, err := json.Marshal(gin.H{
			"games": []ElmGame{},
		})
		assert.Equal(t, 200, rr.Code)
		assert.Equal(t, expectedResp, rr.Body.Bytes())

		mockGameService.AssertExpectations(t)
	})
	t.Run("request is rejected when user is not set by middleware", func(t *testing.T) {
		mockGameService := new(mocks.MockGameService)

		// record responses
		rr := httptest.NewRecorder()
		router := buildGameRouter(mockGameService, nil, nil)

		// do request
		req, err := http.NewRequest(http.MethodGet, "/api/games/", bytes.NewBuffer([]byte{}))
		assert.NoError(t, err)

		router.ServeHTTP(rr, req)

		assert.Equal(t, 401, rr.Code)
		mockGameService.AssertNotCalled(t, "ListByUser")
	})
}
